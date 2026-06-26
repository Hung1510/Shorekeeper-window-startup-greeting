#!/usr/bin/env bash
# extract_wwise.sh — Wwise .bnk soundbanks / .wem streams -> curated .wav clips
set -uo pipefail

SRC="${1:?usage: ./extract_wwise.sh <folder-or-zip>}"
ROOT="$(pwd)"
WORK="$ROOT/work"
OUT="$ROOT/out"
VGM="$ROOT/vgmstream-master/build/cli/vgmstream-cli"
MIN_SECS=0.8 # keep streams at least this long (drop blips)
TOP_N=20 # how many curated clips to keep

if [ ! -x "$VGM" ]; then
  echo "[0] Building vgmstream ..."
  apt-get update -qq
  apt-get install -y -qq cmake build-essential \
      libmpg123-dev libvorbis-dev \
      libavcodec-dev libavformat-dev libavutil-dev libswresample-dev
  curl -L -o "$ROOT/vgmstream.tar.gz" \
      https://codeload.github.com/vgmstream/vgmstream/tar.gz/refs/heads/master
  tar xzf "$ROOT/vgmstream.tar.gz" -C "$ROOT"
  mkdir -p "$ROOT/vgmstream-master/build"
  ( cd "$ROOT/vgmstream-master/build" && \
    cmake -DBUILD_CLI=ON -DBUILD_V123=OFF -DBUILD_AUDACIOUS=OFF \
          -DUSE_FFMPEG=ON -DUSE_VORBIS=ON -DUSE_MPEG=ON \
          -DUSE_CELT=OFF -DUSE_ATRAC9=OFF -DUSE_G719=OFF \
          -DUSE_G7221=OFF -DUSE_SPEEX=OFF .. >/dev/null && \
    cmake --build . --target vgmstream_cli -j4 >/dev/null )
fi
echo "[0] vgmstream: $("$VGM" 2>&1 | grep -i 'CLI decoder' | head -1)"

rm -rf "$WORK" "$OUT"; mkdir -p "$WORK" "$OUT/raw" "$OUT/clips"
if [ -d "$SRC" ]; then
  SEARCH="$SRC"
elif [[ "$SRC" == *.zip ]]; then
  echo "[1] Unzipping ..."; unzip -q "$SRC" -d "$WORK"; SEARCH="$WORK"
else
  echo "Input must be a folder or a .zip"; exit 1
fi

mapfile -t BNKS < <(find "$SEARCH" -iname '*.bnk' | sort)
mapfile -t WEMS < <(find "$SEARCH" -iname '*.wem' | sort)
echo "[1] Found ${#BNKS[@]} .bnk and ${#WEMS[@]} .wem files"

echo "[2] Decoding .bnk soundbanks ..."
for f in "${BNKS[@]}"; do
  name=$(basename "$f" .bnk)
  total=$("$VGM" -i -m "$f" 2>/dev/null | grep -i 'stream count' | grep -oE '[0-9]+' | head -1)
  total=${total:-0}
  if [ "$total" -le 1 ]; then
    # bank holds 0-1 stream (often metadata-only, pointing at external .wem)
    secs=$("$VGM" -i -m "$f" 2>/dev/null | sed -nE 's/.*play duration:.*0:([0-9.]+) seconds.*/\1/p' | head -1)
    [ -n "$secs" ] && awk "BEGIN{exit !($secs >= $MIN_SECS)}" && \
      "$VGM" -o "$OUT/raw/bnk_${name}.wav" "$f" >/dev/null 2>&1 || true
  else
    for i in $(seq 1 "$total"); do
      secs=$("$VGM" -i -m -s "$i" "$f" 2>/dev/null | sed -nE 's/.*play duration:.*0:([0-9.]+) seconds.*/\1/p' | head -1)
      [ -z "$secs" ] && continue
      awk "BEGIN{exit !($secs >= $MIN_SECS)}" && \
        "$VGM" -s "$i" -o "$OUT/raw/bnk_${name}_$(printf %04d "$i")_${secs}s.wav" "$f" >/dev/null 2>&1
    done
  fi
done

echo "[3] Decoding .wem streams ..."
for f in "${WEMS[@]}"; do
  name=$(basename "$f" .wem)
  secs=$("$VGM" -i -m "$f" 2>/dev/null | sed -nE 's/.*play duration:.*0:([0-9.]+) seconds.*/\1/p' | head -1)
  [ -z "$secs" ] && continue
  awk "BEGIN{exit !($secs >= $MIN_SECS)}" && \
    "$VGM" -o "$OUT/raw/wem_${name}_${secs}s.wav" "$f" >/dev/null 2>&1
done
echo "[3] Decoded $(ls -1 "$OUT/raw" 2>/dev/null | wc -l) raw phrase clips."

echo "[4] Curating + normalizing ..."
declare -A dur_of
for w in "$OUT"/raw/*.wav; do
  [ -e "$w" ] || continue
  d=$(printf '%s' "$(basename "$w")" | grep -oE '[0-9]+\.[0-9]+s' | head -1 | tr -d s)
  [ -z "$d" ] && continue
  dur_of["$w"]=$d
done

i=0
while read -r dur src; do
  i=$((i+1))
  label=$(basename "$src" .wav)
  fs=$(awk "BEGIN{printf \"%.3f\", ($dur>0.2)?$dur-0.10:0}")
  ffmpeg -y -i "$src" \
    -af "loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=out:st=${fs}:d=0.10" \
    -ar 48000 -ac 1 "$OUT/clips/$(printf %02d "$i")_${label}.wav" >/dev/null 2>&1
done < <(for k in "${!dur_of[@]}"; do echo "${dur_of[$k]} $k"; done | sort -rn | head -"$TOP_N")

if ls "$OUT"/clips/*.wav >/dev/null 2>&1; then
  cp "$(ls "$OUT"/clips/*.wav | sort | head -1)" "$OUT/voice.wav"
fi

echo "[5] Done."
echo "    Candidates : $OUT/clips/  ($(ls -1 "$OUT/clips" 2>/dev/null | wc -l) clips)"
echo "    Default    : $OUT/voice.wav"
