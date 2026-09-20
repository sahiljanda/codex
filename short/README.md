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
   `-filter_complex` graph: per-clip speed ramp, zoom punch + shake and colour
   grade, concat, RGB glitch at selected cuts, white flashes, glitter overlay,
   burned-in captions, and the music bed.

### Per-segment controls (`script.json`)

`segments[]` takes `start`, `bars`, `speed`, `look` and `grain`. `speed` below
1 is slow motion: the segment consumes less source and is stretched to fill its
bars, so cuts stay on the beat. `look` selects a grade from `LOOKS` in
`build.py`. Alongside them, `flashes` adds white hits, `glitch_cuts` limits the
RGB glitch to chosen cuts, and `sparkle_start` holds the glitter off until a
given time. Together these let one edit run a flat desaturated first act and
snap to full colour on a reveal.

### Narrated edits

Pass `--vo` and the voiceover is mixed over the music, which is ducked under
it by `sidechaincompress`. The voice is levelled with `speechnorm` first:
TTS tends to trail off on a closing word, which both buries the line and
leaves it too quiet to trigger the ducker. `music_dips` in `script.json`
steps the score back further over a given window. Cuts for a narrated piece
should use `secs` and follow the narration's phrase boundaries, which
`silencedetect` will find:

    ffmpeg -i vo.mp3 -af silencedetect=noise=-38dB:d=0.22 -f null -

`motion: "calm"` swaps the beat punch for a slow drift, which suits a
narrated read; `beats` allows cuts at beat rather than bar resolution.

### Gotcha: blend needs RGB

`screen` is an RGB operation. Handed yuv, `blend` screens the chroma planes
independently and the frame turns magenta. Whether the chain arrives in RGB
depends on which filters precede it — `rgbashift` forces RGB, `eq` forces yuv —
so both blend inputs are pinned with `format=gbrp` rather than left to
negotiation.

## Requirements

`ffmpeg` with `libass` and `libx264`. The bundled static build works:

    pip install imageio-ffmpeg numpy pillow
    python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())"

Note this build has no `drawtext`; all text goes through `libass` instead,
which is also what makes the per-word animation possible.

## Usage

    ./make_short.sh clip1.mp4 clip2.mp4 clip3.mp4 clip4.mp4

Caption and hook copy live in `script.json`.
