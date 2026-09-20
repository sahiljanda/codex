#!/usr/bin/env python3
"""Assemble clips into a beat-synced vertical Short.

Pipeline: beat-aligned cuts -> per-clip speed ramp, zoom punch + shake and
colour grade -> transitions at each cut -> glitter overlay (screen blend)
-> animated captions -> music bed.

Per-segment `look` and `speed`, plus `flashes` and `sparkle_start`, let one
edit run a flat desaturated first act and snap to full colour on a reveal.
"""
import argparse
import json
import os
import subprocess
import sys

from captions import Ass

W, H, FPS = 1080, 1920, 30

# Named grades. Chosen so a "before" beat reads deliberately flat and cold,
# and the reveal lands as a jump in saturation and contrast rather than a
# change the viewer has to look for.
LOOKS = {
    "flat":    {"sat": 0.42, "con": 1.06, "gam": 0.94, "bri": -0.03, "sharp": 0.30},
    "cool":    {"sat": 0.62, "con": 1.08, "gam": 0.97, "bri": -0.02, "sharp": 0.35},
    "normal":  {"sat": 1.15, "con": 1.05, "gam": 1.00, "bri": 0.00,  "sharp": 0.45},
    "reveal":  {"sat": 1.52, "con": 1.16, "gam": 1.03, "bri": 0.02,  "sharp": 0.70},
}


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


def plan(durations, spb, spec, target=20.0):
    """Resolve each clip's slice.

    Returns dicts with the output length (always a whole number of bars, so
    every cut lands on a downbeat), the source length to consume, and the
    playback rate. `speed` below 1 is slow motion: the segment eats less
    source and is stretched to fill its bars.
    """
    bar = spb * 4
    segs = []
    for i, d in enumerate(durations):
        o = (spec[i] if spec and i < len(spec) else {}) or {}
        start = float(o.get("start", 0.0))
        speed = float(o.get("speed", 1.0))
        bars = o.get("bars")

        if bars is None:
            bars = max(1, int(((d - start - 0.05) / speed) // bar))
        out_len = bars * bar
        trim = out_len * speed

        avail = d - start - 0.02
        if trim > avail:                    # never read past the last frame
            bars = max(1, int((avail / speed) // bar))
            out_len = bars * bar
            trim = out_len * speed
            if trim > avail:                # still short: take a half bar
                out_len = bar / 2
                trim = min(avail, out_len * speed)

        segs.append({
            "start": round(start, 3),
            "trim": round(trim, 3),
            "out": round(out_len, 3),
            "speed": speed,
            "look": o.get("look", "normal"),
            "grain": float(o.get("grain", 0.0)),
        })
    return segs


def esc_filter_path(p):
    return p.replace("\\", "/").replace(":", "\\:").replace("'", "\\'")


def build_filtergraph(segs, spb, cuts, ass_path, total, flashes,
                      sparkle_start, glitch_cuts):
    parts = []

    for i, s in enumerate(segs):
        beat_p = f"mod(it,{spb:.5f})/{spb:.5f}"
        bar_p = f"mod(it,{spb * 4:.5f})/{spb * 4:.5f}"
        zoom = (
            f"1.055"
            f"+0.085*exp(-pow({beat_p}/0.20,2))"
            f"+0.055*exp(-pow({bar_p}/0.10,2))"
        )
        env = f"exp(-pow({beat_p}/0.26,2))"
        sgn = 1 if i % 2 == 0 else -1
        sx = f"{sgn * 26}*{env}*sin(6.28318*10.5*it)"
        sy = f"{sgn * 20}*{env}*cos(6.28318*8.5*it)"

        lk = LOOKS.get(s["look"], LOOKS["normal"])
        # setpts runs before everything else so `it` inside zoompan is the
        # segment's own output time, keeping the beat maths aligned after a ramp.
        chain = (
            f"[{i}:v]"
            f"trim=start={s['start']}:duration={s['trim']},"
            f"setpts={1.0 / s['speed']:.6f}*(PTS-STARTPTS),"
            f"fps={FPS},"
            f"scale={W}:{H}:force_original_aspect_ratio=increase,"
            f"crop={W}:{H},"
            f"setsar=1,"
            f"zoompan=z='{zoom}':"
            f"x='iw/2-(iw/zoom/2)+{sx}':"
            f"y='ih/2-(ih/zoom/2)+{sy}':"
            f"d=1:s={W}x{H}:fps={FPS},"
            f"eq=saturation={lk['sat']}:contrast={lk['con']}:"
            f"gamma={lk['gam']}:brightness={lk['bri']},"
            f"unsharp=5:5:{lk['sharp']}"
        )
        if s["grain"] > 0:
            chain += f",noise=alls={int(s['grain'])}:allf=t"
        parts.append(chain + f"[v{i}]")

    parts.append("".join(f"[v{i}]" for i in range(len(segs))) +
                 f"concat=n={len(segs)}:v=1:a=0[cat]")

    # RGB glitch only on the cuts that ask for it, so the reveal can be a
    # clean flash instead of competing with a glitch.
    src = "cat"
    step = 0.045
    for k, tc in enumerate(cuts):
        if k not in glitch_cuts:
            continue
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
        dst = f"gn{k}"
        parts.append(
            f"[{src}]noise=alls=26:allf=t+u:"
            f"enable='between(t,{tc - step * 1.5:.3f},{tc + step * 1.5:.3f})'[{dst}]"
        )
        src = dst

    # White flashes, as a per-frame brightness spike.
    if flashes:
        terms = "+".join(
            f"{f.get('amount', 0.75)}*exp(-pow((t-{f['t']:.3f})/{f.get('width', 0.085)},2))"
            for f in flashes
        )
        parts.append(
            f"[{src}]eq=eval=frame:brightness='{terms}':"
            f"saturation='1-0.55*({terms})'[fl]"
        )
        src = "fl"

    # Glitter. Held black (invisible under screen blend) until the reveal.
    spk = f"[{len(segs)}:v]fps={FPS},scale={W}:{H},setsar=1,trim=duration={total:.3f},setpts=PTS-STARTPTS"
    if sparkle_start is not None:
        spk += f",fade=t=in:st={sparkle_start:.3f}:d=0.30"
    # Both blend inputs are pinned to gbrp. `screen` is an RGB operation, and
    # if blend is handed yuv it screens the chroma planes independently, which
    # drives them toward the maximum and turns the whole frame magenta. Whether
    # the chain happens to arrive in RGB depends on which filters precede this
    # (rgbashift forces RGB, eq forces yuv), so it is set explicitly rather
    # than left to format negotiation.
    parts.append(spk + ",format=gbrp[spk]")
    parts.append(
        f"[{src}]format=gbrp[base];"
        f"[base][spk]blend=all_mode=screen:all_opacity=0.9,format=yuv420p[glit]"
    )

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
    ap.add_argument("--script", required=True)
    ap.add_argument("--sparkle", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--ffmpeg", required=True)
    ap.add_argument("--target", type=float, default=20.0)
    ap.add_argument("--crf", type=int, default=19)
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

    segs = plan(durations, spb, script.get("segments"), target=a.target)
    total = sum(s["out"] for s in segs)
    cuts, acc = [], 0.0
    for s in segs[:-1]:
        acc += s["out"]
        cuts.append(round(acc, 4))

    for i, s in enumerate(segs):
        print(f"  seg{i}: src {s['start']}+{s['trim']} -> {s['out']}s "
              f"@{s['speed']}x [{s['look']}]", file=sys.stderr)
    print(f"  total={total:.2f}s  cuts={cuts}", file=sys.stderr)

    if a.plan_only:
        json.dump({"segs": segs, "total": total, "cuts": cuts}, sys.stdout)
        return

    ass = Ass()
    hook = script["hook"]
    ass.hook(hook.get("start", 0.15), hook.get("end", 2.6), hook["lines"],
             y=hook.get("y", 760), accent_idx=hook.get("accent_idx"))
    cues = [(c["start"], c["end"], c["text"]) for c in script.get("captions", [])]
    ass.pop(cues, y=script.get("caption_y", 1430),
            accent_words=script.get("accent_words", []))
    for t in script.get("tags", []):
        ass.tag(t["start"], t["end"], t["text"], y=t.get("y", 1760))
    ass_path = os.path.abspath("work/captions.ass")
    ass.render(ass_path)
    print(f"  captions -> {len(ass.events)} events", file=sys.stderr)

    fg = build_filtergraph(
        segs, spb, cuts, ass_path, total,
        script.get("flashes", []),
        script.get("sparkle_start"),
        set(script.get("glitch_cuts", range(len(cuts)))),
    )
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
        "-c:v", "libx264", "-preset", "slow", "-crf", str(a.crf),
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
