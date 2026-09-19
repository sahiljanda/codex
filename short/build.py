#!/usr/bin/env python3
"""Assemble four clips into a beat-synced vertical Short.

Pipeline: beat-aligned cuts -> per-clip zoom punch + shake -> RGB glitch at
each cut -> glitter overlay (screen blend) -> animated captions -> music bed.
"""
import argparse
import json
import os
import subprocess
import sys

from captions import Ass

W, H, FPS = 1080, 1920, 30


def run(cmd, **kw):
    p = subprocess.run(cmd, **kw)
    if p.returncode != 0:
        raise SystemExit(f"command failed: {' '.join(cmd[:4])}...")
    return p


def probe(ffmpeg, path):
    """Duration + dimensions, read back from ffmpeg's own stderr banner."""
    out = subprocess.run(
        [ffmpeg, "-hide_banner", "-i", path], stderr=subprocess.PIPE, text=True
    ).stderr
    dur, w, h = None, None, None
    for line in out.splitlines():
        if "Duration:" in line and dur is None:
            hms = line.split("Duration:")[1].split(",")[0].strip()
            hh, mm, ss = hms.split(":")
            dur = int(hh) * 3600 + int(mm) * 60 + float(ss)
        if "Video:" in line and w is None:
            for tok in line.split(","):
                tok = tok.strip().split(" ")[0]
                if "x" in tok:
                    a, _, b = tok.partition("x")
                    if a.isdigit() and b.isdigit():
                        w, h = int(a), int(b)
                        break
    if dur is None:
        raise SystemExit(f"could not read duration: {path}")
    return dur, w or W, h or H


def plan(durations, spb, target=30.0, bars_min=2, bars_max=5, override=None):
    """Give each clip a bar-aligned slice, biased toward filling `target`.

    `override` lets the script file pick the exact in-point and bar count per
    clip, which is how the hand-picked moments get used; anything it leaves out
    falls back to the automatic choice below.
    """
    bar = spb * 4

    if override:
        segs = []
        for i, d in enumerate(durations):
            o = override[i] if i < len(override) else {}
            bars = o.get("bars")
            start = float(o.get("start", 0.0))
            if bars is None:
                bars = max(1, int((d - start - 0.05) // bar))
            length = bars * bar
            if start + length > d - 0.02:      # never run past the last frame
                length = max(bar / 2, (d - start - 0.05) // bar * bar)
            segs.append((round(start, 3), round(length, 3)))
        return segs

    n = len(durations)
    want_bars = max(bars_min, round(target / bar / n))

    segs = []
    for d in durations:
        usable = max(0.0, d - 0.10)  # keep off the very last frame
        bars = min(bars_max, want_bars, int(usable // bar))
        if bars < 1:
            # Clip is shorter than one bar: take a half-bar if we can.
            length = min(usable, bar / 2)
            if length < 0.3:
                length = usable
        else:
            length = bars * bar
        # Start a little into the clip so we skip camera settling, when there
        # is enough material to afford it.
        start = min(0.25, max(0.0, usable - length)) if usable - length > 0.4 else 0.0
        segs.append((round(start, 3), round(length, 3)))
    return segs


def esc_filter_path(p):
    return p.replace("\\", "/").replace(":", "\\:").replace("'", "\\'")


def build_filtergraph(n_clips, segs, spb, cuts, sparkle, ass_path, total):
    """Assemble the full -filter_complex string."""
    parts = []

    # --- per-clip: fit to frame, then beat-driven zoom punch + shake ---
    for i, (st, ln) in enumerate(segs):
        # Downbeat-aware punch: every beat kicks, bar starts kick harder.
        beat_p = f"mod(it,{spb:.5f})/{spb:.5f}"
        bar_p = f"mod(it,{spb * 4:.5f})/{spb * 4:.5f}"
        zoom = (
            f"1.055"
            f"+0.085*exp(-pow({beat_p}/0.20,2))"
            f"+0.055*exp(-pow({bar_p}/0.10,2))"
        )
        env = f"exp(-pow({beat_p}/0.26,2))"
        # Alternate shake direction per clip so consecutive cuts feel distinct.
        sgn = 1 if i % 2 == 0 else -1
        sx = f"{sgn * 26}*{env}*sin(6.28318*10.5*it)"
        sy = f"{sgn * 20}*{env}*cos(6.28318*8.5*it)"

        parts.append(
            f"[{i}:v]"
            f"trim=start={st}:duration={ln},setpts=PTS-STARTPTS,"
            f"fps={FPS},"
            f"scale={W}:{H}:force_original_aspect_ratio=increase,"
            f"crop={W}:{H},"
            f"setsar=1,"
            f"zoompan=z='{zoom}':"
            f"x='iw/2-(iw/zoom/2)+{sx}':"
            f"y='ih/2-(ih/zoom/2)+{sy}':"
            f"d=1:s={W}x{H}:fps={FPS},"
            f"eq=saturation=1.22:contrast=1.06,"
            f"unsharp=5:5:0.45"
            f"[v{i}]"
        )

    # --- concat the four segments ---
    parts.append("".join(f"[v{i}]" for i in range(n_clips)) +
                 f"concat=n={n_clips}:v=1:a=0[cat]")

    # --- RGB glitch at each cut, in short stepped windows ---
    src = "cat"
    step = 0.045
    for k, tc in enumerate(cuts):
        for j, (rh, rv, bh, bv) in enumerate(
            [(-16, 6, 14, -5), (22, -9, -19, 8), (-10, 4, 9, -3)]
        ):
            a = tc - step * 1.5 + j * step
            b = a + step
            dst = f"g{k}_{j}"
            parts.append(
                f"[{src}]rgbashift=rh={rh}:rv={rv}:bh={bh}:bv={bv}:"
                f"enable='between(t,{a:.3f},{b:.3f})'[{dst}]"
            )
            src = dst
        # A dusting of noise sells the digital-glitch read.
        dst = f"gn{k}"
        parts.append(
            f"[{src}]noise=alls=26:allf=t+u:"
            f"enable='between(t,{tc - step * 1.5:.3f},{tc + step * 1.5:.3f})'[{dst}]"
        )
        src = dst

    # --- glitter overlay, screen-blended so black drops out ---
    parts.append(
        f"[{n_clips}:v]fps={FPS},scale={W}:{H},setsar=1,"
        f"trim=duration={total:.3f},setpts=PTS-STARTPTS[spk]"
    )
    parts.append(f"[{src}][spk]blend=all_mode=screen:all_opacity=0.85[glit]")

    # --- captions ---
    parts.append(
        f"[glit]subtitles='{esc_filter_path(ass_path)}':"
        f"fontsdir=/usr/share/fonts[outv]"
    )
    return ";".join(parts)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--clips", nargs="+", required=True)
    ap.add_argument("--music", required=True)
    ap.add_argument("--beats", required=True)
    ap.add_argument("--script", required=True, help="JSON with hook/caption copy")
    ap.add_argument("--sparkle", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--ffmpeg", required=True)
    ap.add_argument("--target", type=float, default=30.0)
    ap.add_argument("--plan-only", action="store_true")
    a = ap.parse_args()

    beats = json.load(open(a.beats))
    spb = beats["spb"]
    script = json.load(open(a.script))

    durations = []
    for c in a.clips:
        d, w, h = probe(a.ffmpeg, c)
        durations.append(d)
        print(f"  {os.path.basename(c)}: {d:.2f}s {w}x{h}", file=sys.stderr)

    segs = plan(durations, spb, target=a.target, override=script.get("segments"))
    lengths = [ln for _, ln in segs]
    total = sum(lengths)
    cuts = []
    acc = 0.0
    for ln in lengths[:-1]:
        acc += ln
        cuts.append(acc)

    print(f"  plan: {[f'{s}+{l}' for s, l in segs]}  total={total:.2f}s",
          file=sys.stderr)
    print(f"  cuts at: {[round(c, 3) for c in cuts]}", file=sys.stderr)

    if a.plan_only:
        json.dump({"segs": segs, "total": total, "cuts": cuts}, sys.stdout)
        return

    # --- captions from the script file ---
    ass = Ass()
    hook = script["hook"]
    ass.hook(hook.get("start", 0.15), hook.get("end", 2.6), hook["lines"],
             y=hook.get("y", 760), accent_idx=hook.get("accent_idx"))
    cues = [(c["start"], c["end"], c["text"]) for c in script.get("captions", [])]
    ass.pop(cues, y=script.get("caption_y", 1430),
            accent_words=script.get("accent_words", []))
    for t in script.get("tags", []):
        ass.tag(t["start"], t["end"], t["text"])
    ass_path = os.path.abspath("work/captions.ass")
    ass.render(ass_path)
    print(f"  captions -> {ass_path} ({len(ass.events)} events)", file=sys.stderr)

    fg = build_filtergraph(len(a.clips), segs, spb, cuts, a.sparkle, ass_path, total)
    with open("work/filtergraph.txt", "w") as f:
        f.write(fg.replace(";", ";\n"))

    cmd = [a.ffmpeg, "-y", "-hide_banner", "-loglevel", "warning", "-stats"]
    for c in a.clips:
        cmd += ["-i", c]
    cmd += ["-i", a.sparkle, "-i", a.music]
    cmd += [
        "-filter_complex", fg,
        "-map", "[outv]",
        "-map", f"{len(a.clips) + 1}:a",
        "-t", f"{total:.3f}",
        "-af", f"afade=t=in:st=0:d=0.25,"
               f"afade=t=out:st={max(0, total - 0.8):.3f}:d=0.8,"
               f"loudnorm=I=-14:TP=-1.5:LRA=11",
        "-c:v", "libx264", "-preset", "slow", "-crf", "19",
        "-profile:v", "high", "-level", "4.1",
        "-pix_fmt", "yuv420p", "-r", str(FPS),
        "-c:a", "aac", "-b:a", "192k", "-ar", "48000",
        "-movflags", "+faststart",
        a.out,
    ]
    run(cmd)
    print(f"  -> {a.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
