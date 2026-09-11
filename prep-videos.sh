#!/usr/bin/env bash
# Turn raw screen recordings into web-ready demo videos for the deck.
#
#   ./prep-videos.sh ~/Movies/raw-vibe.mov vibe-coding
#   ./prep-videos.sh ~/Movies/raw-control.mov control
#   ./prep-videos.sh ~/Movies/raw-validate.mov validate
#   ./prep-videos.sh ~/Movies/raw-audit.mov audit
#
# Produces demo-<name>.mp4 and poster-<name>.jpg in this folder, which is
# exactly what index.html looks for. Needs ffmpeg:  brew install ffmpeg

set -euo pipefail

SRC="${1:?usage: ./prep-videos.sh <source-file> <vibe-coding|control|validate|audit>}"
NAME="${2:?usage: ./prep-videos.sh <source-file> <vibe-coding|control|validate|audit>}"
OUT="demo-${NAME}.mp4"
POSTER="poster-${NAME}.jpg"

command -v ffmpeg >/dev/null || { echo "ffmpeg not found. brew install ffmpeg"; exit 1; }

echo "==> encoding $SRC -> $OUT"
ffmpeg -hide_banner -loglevel warning -y -i "$SRC" \
  -vf "scale='min(1920,iw)':-2:flags=lanczos,format=yuv420p" \
  -c:v libx264 -profile:v high -level 4.1 -preset slow -crf 24 \
  -maxrate 4M -bufsize 8M -g 60 \
  -c:a aac -b:a 128k -ac 2 \
  -movflags +faststart \
  "$OUT"
# +faststart puts the index at the front of the file. Without it the browser
# downloads the whole video before showing frame one.

echo "==> poster frame -> $POSTER"
ffmpeg -hide_banner -loglevel warning -y -ss 0.5 -i "$OUT" -frames:v 1 -q:v 3 "$POSTER"

SIZE_MB=$(( $(wc -c < "$OUT") / 1048576 ))
echo
echo "$OUT  ${SIZE_MB} MB"
[ "$SIZE_MB" -gt 45 ] && cat <<WARN

  WARNING: ${SIZE_MB} MB. GitHub warns at 50 MB and hard-rejects at 100 MB.
  Trim the recording, or raise -crf to 26 or 28, or drop the scale cap to 1280.
  Do NOT reach for Git LFS: GitHub Pages serves the LFS pointer file, not the
  video, and the slide will silently fall back to the placeholder card.

WARN

echo "Verify faststart (moov should appear before mdat):"
ffprobe -v error -show_entries format=duration,size,bit_rate -of default=nw=1 "$OUT" || true
