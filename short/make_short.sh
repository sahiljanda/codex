#!/usr/bin/env bash
# Build a viral Short from four clips. Usage: ./make_short.sh a.mp4 b.mp4 c.mp4 d.mp4
set -euo pipefail

if [ "$#" -ne 4 ]; then
  echo "usage: $0 clip1 clip2 clip3 clip4" >&2
  exit 1
fi

cd "$(dirname "$0")"
mkdir -p work out assets

FFMPEG=$(python3 -c "import imageio_ffmpeg;print(imageio_ffmpeg.get_ffmpeg_exe())")
MUSIC=${MUSIC:-assets/music.wav}
TARGET=${TARGET:-30}

if [ ! -f "$MUSIC" ]; then
  echo "missing music track at $MUSIC" >&2
  exit 1
fi

echo "[1/4] detecting beats"
python3 beats.py --audio "$MUSIC" --ffmpeg "$FFMPEG" > work/beats.json
python3 -c "import json;d=json.load(open('work/beats.json'));print(f\"      {d['bpm']} BPM, beat every {d['spb']}s\")"

echo "[2/4] planning cuts"
python3 build.py --clips "$@" --music "$MUSIC" --beats work/beats.json \
  --script script.json --sparkle /dev/null --out out/short.mp4 \
  --ffmpeg "$FFMPEG" --target "$TARGET" --plan-only > work/plan.json
TOTAL=$(python3 -c "import json;print(json.load(open('work/plan.json'))['total'])")

echo "[3/4] rendering glitter overlay (${TOTAL}s)"
BURSTS=$(python3 -c "
import json
d=json.load(open('work/beats.json')); t=float('$TOTAL')
print(','.join(str(x) for i,x in enumerate(d['beats']) if i%4==0 and x<t))")
python3 sparkle.py --out work/sparkle.mp4 --duration "$(python3 -c "print(float('$TOTAL')+0.2)")" \
  --fps 30 --count 160 --bursts "$BURSTS" --ffmpeg "$FFMPEG"

echo "[4/4] rendering final video"
python3 build.py --clips "$@" --music "$MUSIC" --beats work/beats.json \
  --script script.json --sparkle work/sparkle.mp4 --out out/short.mp4 \
  --ffmpeg "$FFMPEG" --target "$TARGET"

echo "done -> out/short.mp4"
