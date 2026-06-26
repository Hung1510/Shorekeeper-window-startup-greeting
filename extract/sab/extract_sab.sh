#!/usr/bin/env bash
set -uo pipefail
ZIP="${1:?usage: ./extract_pipeline.sh mod.zip [JA|EN]}"
LANG_PICK="${2:-JA}"
ROOT="$(pwd)"
WORK="$ROOT/work"
OUT="$ROOT/out"
VGM="$ROOT/vgmstream-master/build/cli/vgmstream-cli"
MIN_SECS=0.8
TOP_N=16
if [ ! -x "$VGM" ]; then
  echo "[0] Building vgmstream ..."
  apt-get update -qq
  apt-get install -y -qq cmake build-essential \
      libmpg123-dev libvorbis-dev \
      libavcodec-dev libavformat-dev libavutil-dev libswresample-dev
  curl -L -o "$ROOT/vgmstream.tar.gz" \
      https://codeload.github.com/vgmstream/vgmstream/tar.gz/refs/heads/master #giv star later
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
echo "[1] Unzipping ..."
rm -rf "$WORK" "$OUT"; mkdir -p "$WORK" "$OUT/raw" "$OUT/clips"
unzip -q "$ZIP" -d "$WORK"
mapfile -t SABS < <(find "$WORK" -iname '*.sab' | grep -iE "${LANG_PICK}|JP|JA" || true)
[ "${#SABS[@]}" -eq 0 ] && mapfile -t SABS < <(find "$WORK" -iname '*.sab')
echo "[1] Found ${#SABS[@]} .sab files:"; printf '    %s\n' "${SABS[@]}"
echo "[2] Header check:"
for f in "${SABS[@]}"; do
  magic=$(head -c 4 "$f")
  echo " $(basename "$f"): magic='$magic'"
done
echo "[3] Decoding phrase-length lines (>= ${MIN_SECS}s) ..."
for f in "${SABS[@]}"; do
  bank=$(basename "$f" .sab)
  total=$("$VGM" -i -m "$f" 2>/dev/null | grep -i 'stream count' | grep -oE '[0-9]+' | head -1)
  echo "    $bank: $total subsongs"
  for i in $(seq 1 "${total:-0}"); do
    meta=$("$VGM" -i -m -s "$i" "$f" 2>/dev/null)
    secs=$(printf '%s\n' "$meta" | sed -nE 's/.*play duration:.*0:([0-9.]+) seconds.*/\1/p' | head -1)
    [ -z "$secs" ] && continue
    if awk "BEGIN{exit !($secs >= $MIN_SECS)}"; then
      tag=$(printf '%s\n' "$meta" | sed -nE 's/.*stream name: (.*)/\1/p' | head -1 | tr '/; ' '___')
      "$VGM" -s "$i" -o "$OUT/raw/${bank}_$(printf %03d "$i")_${tag}_${secs}s.wav" "$f" >/dev/null 2>&1
    fi
  done
done
echo "[3] Decoded $(ls -1 "$OUT/raw" | wc -l) raw phrase clips."
echo "[4] Curating + normalizing ..."
declare -A best_dur best_file
for w in "$OUT"/raw/*.wav; do
  base=$(basename "$w")
  tag=$(printf '%s' "$base" | grep -oE '(sbe|sbs|ptf|ana|bas|bar|bwa|bac)_[0-9]+' | head -1 || true)
  [ -z "$tag" ] && continue
  bank=$(printf '%s' "$base" | grep -oE '^[a-z0-9]+_[a-z0-9]+' | head -1)
  key="${bank}_${tag}"
  dur=$(printf '%s' "$base" | grep -oE '[0-9]+\.[0-9]+s' | head -1 | tr -d s)
  cur=${best_dur[$key]:-0}
  awk "BEGIN{exit !($dur > $cur)}" && { best_dur[$key]=$dur; best_file[$key]="$w"; }
done
i=0
while read -r dur key; do
  i=$((i+1)); src="${best_file[$key]}"
  fs=$(awk "BEGIN{printf \"%.3f\", ($dur>0.2)?$dur-0.10:0}")
  ffmpeg -y -i "$src" \
    -af "loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=out:st=${fs}:d=0.10" \
    -ar 48000 -ac 1 "$OUT/clips/$(printf %02d "$i")_${key}.wav" >/dev/null 2>&1
done < <(for k in "${!best_dur[@]}"; do echo "${best_dur[$k]} $k"; done | sort -rn | head -"$TOP_N")
cp "$(ls "$OUT"/clips/*.wav | sort | head -1)" "$OUT/shorekeeper_hello.wav"
echo "[5] Done."
echo "Candidates: $OUT/clips/($(ls -1 "$OUT/clips" | wc -l) clips)"
echo "Default: $OUT/shorekeeper_hello.wav"