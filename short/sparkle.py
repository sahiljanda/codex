#!/usr/bin/env python3
"""Generate a glitter/sparkle overlay video.

Renders bright star-shaped particles on pure black. The result is meant to be
composited with ffmpeg's `blend=all_mode=screen`, where black becomes fully
transparent and only the sparkles show through.
"""
import argparse
import subprocess
import sys

import numpy as np

W, H = 1080, 1920


def star_sprite(size, spike_len, core=0.16, spike_w=0.030, diag=0.34):
    """A four-point diffraction star: bright core plus cross spikes."""
    n = size | 1  # force odd so the star has an exact centre pixel
    ax = np.linspace(-1.0, 1.0, n)
    gx, gy = np.meshgrid(ax, ax)

    r = np.sqrt(gx * gx + gy * gy)
    img = np.exp(-(r / core) ** 2)  # core glow

    # Horizontal / vertical spikes, tapering out to the sprite edge.
    taper_x = np.clip(1.0 - np.abs(gx) / spike_len, 0.0, 1.0) ** 1.7
    taper_y = np.clip(1.0 - np.abs(gy) / spike_len, 0.0, 1.0) ** 1.7
    img += np.exp(-(gy / spike_w) ** 2) * taper_x
    img += np.exp(-(gx / spike_w) ** 2) * taper_y

    # Fainter 45-degree spikes give it a more jewel-like look.
    du, dv = (gx + gy) / 1.414, (gx - gy) / 1.414
    taper_u = np.clip(1.0 - np.abs(du) / (spike_len * 0.6), 0.0, 1.0) ** 2.0
    taper_v = np.clip(1.0 - np.abs(dv) / (spike_len * 0.6), 0.0, 1.0) ** 2.0
    img += diag * np.exp(-(dv / spike_w) ** 2) * taper_u
    img += diag * np.exp(-(du / spike_w) ** 2) * taper_v

    img *= np.clip(1.0 - (r / 1.05) ** 3, 0.0, 1.0)  # fade sprite edges
    return (img / img.max()).astype(np.float32)


# Warm gold / champagne / icy white — reads as "glitter" rather than confetti.
PALETTE = np.array(
    [
        [1.00, 0.86, 0.48],
        [1.00, 0.94, 0.72],
        [1.00, 1.00, 1.00],
        [1.00, 0.76, 0.32],
        [0.82, 0.93, 1.00],
        [1.00, 0.68, 0.85],
    ],
    dtype=np.float32,
)


def build(out_path, duration, fps, count, seed, burst_times, ffmpeg):
    rng = np.random.default_rng(seed)
    frames = int(round(duration * fps))

    sizes = [37, 55, 79, 111, 151]
    sprites = [star_sprite(s, spike_len=1.0) for s in sizes]

    # Particle field. Each sparkle twinkles on its own period and phase, so the
    # field never visibly loops.
    idx = rng.integers(0, len(sizes), count)
    px = rng.uniform(-60, W + 60, count)
    py = rng.uniform(-60, H + 60, count)
    drift = rng.uniform(14, 62, count)          # px/sec upward drift
    sway = rng.uniform(6, 30, count)            # horizontal sway amplitude
    sway_hz = rng.uniform(0.12, 0.5, count)
    period = rng.uniform(0.55, 2.1, count)      # twinkle period (sec)
    phase = rng.uniform(0, 1, count)
    gain = rng.uniform(0.35, 1.0, count) ** 1.5  # bias toward dimmer specks
    color = PALETTE[rng.integers(0, len(PALETTE), count)]

    bursts = np.asarray(burst_times, dtype=np.float32)

    proc = subprocess.Popen(
        [
            ffmpeg, "-y", "-loglevel", "error",
            "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
            "-r", str(fps), "-i", "pipe:0",
            "-an", "-c:v", "libx264", "-preset", "veryfast", "-crf", "16",
            "-pix_fmt", "yuv420p", out_path,
        ],
        stdin=subprocess.PIPE,
    )

    for f in range(frames):
        t = f / fps
        canvas = np.zeros((H, W, 3), dtype=np.float32)

        # Sparkle density swells right after each beat we were asked to accent.
        if bursts.size:
            dt = t - bursts
            dt = dt[dt >= 0]
            boost = 1.0 + 2.3 * float(np.exp(-(dt.min() / 0.16) ** 2)) if dt.size else 1.0
        else:
            boost = 1.0

        tw = 0.5 + 0.5 * np.sin(2 * np.pi * (t / period + phase))
        bright = (tw ** 3.2) * gain * boost
        live = bright > 0.02

        cx = px + sway * np.sin(2 * np.pi * sway_hz * t + phase * 6.28)
        cy = (py - drift * t) % (H + 240) - 120

        for i in np.nonzero(live)[0]:
            spr = sprites[idx[i]]
            s = spr.shape[0]
            half = s // 2
            x0, y0 = int(cx[i]) - half, int(cy[i]) - half

            # Clip the sprite against the canvas bounds.
            sx0, sy0 = max(0, -x0), max(0, -y0)
            dx0, dy0 = max(0, x0), max(0, y0)
            dx1, dy1 = min(W, x0 + s), min(H, y0 + s)
            if dx1 <= dx0 or dy1 <= dy0:
                continue

            patch = spr[sy0:sy0 + (dy1 - dy0), sx0:sx0 + (dx1 - dx0), None]
            canvas[dy0:dy1, dx0:dx1] += patch * color[i] * bright[i]

        frame = (np.clip(canvas, 0.0, 1.0) ** 0.85 * 255.0).astype(np.uint8)
        proc.stdin.write(frame.tobytes())

        if f % 150 == 0:
            print(f"  sparkle {f}/{frames}", file=sys.stderr, flush=True)

    proc.stdin.close()
    if proc.wait() != 0:
        raise SystemExit("sparkle: ffmpeg encode failed")
    print(f"  sparkle -> {out_path}", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--duration", type=float, required=True)
    ap.add_argument("--fps", type=int, default=30)
    ap.add_argument("--count", type=int, default=150)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--ffmpeg", required=True)
    ap.add_argument("--bursts", default="", help="comma-separated seconds to accent")
    a = ap.parse_args()

    bursts = [float(x) for x in a.bursts.split(",") if x.strip()]
    build(a.out, a.duration, a.fps, a.count, a.seed, bursts, a.ffmpeg)


if __name__ == "__main__":
    main()
