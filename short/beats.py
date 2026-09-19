#!/usr/bin/env python3
"""Estimate tempo and a beat grid from an audio file.

Spectral-flux onset detection, autocorrelation for the period, then a phase
search to lock the grid onto the strongest onsets. Prints JSON.
"""
import argparse
import json
import subprocess

import numpy as np

SR = 22050
HOP = 256
NFFT = 1024


def decode(path, ffmpeg):
    raw = subprocess.run(
        [ffmpeg, "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(SR), "pipe:1"],
        stdout=subprocess.PIPE, check=True,
    ).stdout
    return np.frombuffer(raw, dtype=np.float32)


def onset_envelope(x):
    """Half-wave-rectified spectral flux over a log-magnitude mel-ish band set."""
    win = np.hanning(NFFT).astype(np.float32)
    n = 1 + (len(x) - NFFT) // HOP
    frames = np.lib.stride_tricks.as_strided(
        x, shape=(n, NFFT), strides=(x.strides[0] * HOP, x.strides[0])
    ) * win
    spec = np.abs(np.fft.rfft(frames, axis=1))
    logspec = np.log1p(spec * 8.0)

    flux = np.diff(logspec, axis=0)
    env = np.maximum(flux, 0.0).sum(axis=1)
    env = np.concatenate([[0.0], env])

    # Smooth lightly, then remove the slow-moving floor so quiet and loud
    # sections contribute comparable onset strength.
    k = np.hanning(5)
    env = np.convolve(env, k / k.sum(), mode="same")
    floor = np.convolve(env, np.ones(64) / 64.0, mode="same")
    env = np.maximum(env - floor, 0.0)
    return env / (env.max() + 1e-9)


def estimate(env, fps_env, bpm_lo=70.0, bpm_hi=190.0):
    e = env - env.mean()
    ac = np.correlate(e, e, mode="full")[len(e) - 1:]
    ac[0] = 0.0

    lags = np.arange(len(ac))
    with np.errstate(divide="ignore"):
        bpms = 60.0 * fps_env / np.maximum(lags, 1)
    ok = (bpms >= bpm_lo) & (bpms <= bpm_hi)
    if not ok.any():
        return 120.0, 0.0

    cand = np.where(ok)[0]
    # Score each lag by its own autocorrelation plus its harmonics, so we lock
    # onto the true beat rather than a half/double-time alias.
    scores = []
    for lag in cand:
        s = ac[lag]
        for m in (2, 3, 4):
            if lag * m < len(ac):
                s += ac[lag * m] * (0.5 / m)
        scores.append(s)
    lag = int(cand[int(np.argmax(scores))])
    bpm = 60.0 * fps_env / lag

    # Phase: slide the grid and keep the offset with the most onset energy.
    best_off, best_val = 0.0, -1.0
    for off in np.linspace(0, lag, 64, endpoint=False):
        pos = np.round(np.arange(off, len(env), lag)).astype(int)
        pos = pos[pos < len(env)]
        v = float(env[pos].sum())
        if v > best_val:
            best_val, best_off = v, float(off)
    return bpm, best_off / fps_env


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--audio", required=True)
    ap.add_argument("--ffmpeg", required=True)
    ap.add_argument("--duration", type=float, default=None)
    a = ap.parse_args()

    x = decode(a.audio, a.ffmpeg)
    env = onset_envelope(x)
    fps_env = SR / HOP

    bpm, phase = estimate(env, fps_env)
    total = a.duration if a.duration else len(x) / SR
    spb = 60.0 / bpm

    beats = []
    t = phase
    while t < total:
        if t >= 0:
            beats.append(round(t, 4))
        t += spb

    # Strength of each beat, for picking the biggest hits later.
    strength = []
    for b in beats:
        i = int(round(b * fps_env))
        lo, hi = max(0, i - 2), min(len(env), i + 3)
        strength.append(round(float(env[lo:hi].max()) if hi > lo else 0.0, 4))

    print(json.dumps({
        "bpm": round(bpm, 2),
        "phase": round(phase, 4),
        "spb": round(spb, 5),
        "beats": beats,
        "strength": strength,
    }))


if __name__ == "__main__":
    main()
