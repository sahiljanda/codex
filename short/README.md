# Viral Short builder

Assembles four source clips into a beat-synced 1080x1920 Short with music,
animated captions, glitter and glitch effects.

## Pipeline

1. `beats.py` — spectral-flux onset detection + autocorrelation over the music
   track, producing a BPM, a phase offset and a beat grid. Every cut and every
   effect is keyed to this grid.
2. `sparkle.py` — renders a glitter overlay (four-point diffraction stars on
   pure black) that is later screen-blended, so the black drops out.
3. `captions.py` — emits an ASS subtitle file: a headline that slams in and
   overshoots, plus word-chunk captions that scale-pop.
4. `build.py` — plans bar-aligned segment lengths, then builds one
   `-filter_complex` graph: per-clip zoom punch + shake, concat, RGB glitch at
   each cut, glitter overlay, burned-in captions, and the music bed.

## Requirements

`ffmpeg` with `libass` and `libx264`. The bundled static build works:

    pip install imageio-ffmpeg numpy pillow
    python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"

Note this build has no `drawtext`; all text goes through `libass` instead,
which is also what makes the per-word animation possible.

## Usage

    ./make_short.sh clip1.mp4 clip2.mp4 clip3.mp4 clip4.mp4

Caption and hook copy live in `script.json`.
