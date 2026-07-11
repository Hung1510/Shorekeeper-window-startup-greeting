#!/usr/bin/env bash
set -uo pipefail
ZIP="${1:?usage: ./extract_cri.sh mod.zip [name-filter]}"
NAME_FILTER="${2:-}"
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
# CRI ADX2/Atom: .awb (AFS2 wave bank = the audio) usually paired with a .acb (@UTF cue sheet = the names).
# Decode the .awb and vgmstream pulls cue names from the sibling .acb on its own, so keep the pair together.
mapfile -t AWBS < <(find "$WORK" -iname '*.awb')
mapfile -t ACBS < <(find "$WORK" -iname '*.acb')
declare -A has_awb
for a in "${AWBS[@]}"; do has_awb["$(basename "$a" | sed -E 's/\.awb$//I' | tr 'A-Z' 'a-z')"]=1; done
BANKS=("${AWBS[@]}")
for c in "${ACBS[@]}"; do
  b="$(basename "$c" | sed -E 's/\.acb$//I' | tr 'A-Z' 'a-z')"
  [ -n "${has_awb[$b]:-}" ] || BANKS+=("$c")   # .acb with embedded audio (no sibling .awb)
done
if [ -n "$NAME_FILTER" ]; then
  filtered=(); for b in "${BANKS[@]}"; do echo "$b" | grep -iqE "$NAME_FILTER" && filtered+=("$b"); done
  [ "${#filtered[@]}" -gt 0 ] && BANKS=("${filtered[@]}")
fi
echo "[1] Found ${#BANKS[@]} bank targets:"; printf '    %s\n' "${BANKS[@]}"

echo "[2] Header check:"
for f in "${BANKS[@]}"; do
  magic=$(head -c 4 "$f")
  echo " $(basename "$f"): magic='$magic'"   # expect AFS2 (.awb) or @UTF (.acb)
done
echo "[3] Decoding phrase-length lines (>= ${MIN_SECS}s) ..."
for f in "${BANKS[@]}"; do
  bank=$(basename "$f" | sed -E 's/\.(awb|acb)$//I' | tr 'A-Z /;.' 'a-z____')
  total=$("$VGM" -i -m "$f" 2>/dev/null | grep -i 'stream count' | grep -oE '[0-9]+' | head -1)
  echo "    $bank: ${total:-0} subsongs"
  for i in $(seq 1 "${total:-0}"); do
    meta=$("$VGM" -i -m -s "$i" "$f" 2>/dev/null)
    secs=$(printf '%s\n' "$meta" | sed -nE 's/.*play duration:.*0:([0-9.]+) seconds.*/\1/p' | head -1)
    [ -z "$secs" ] && continue
    if awk "BEGIN{exit !($secs >= $MIN_SECS)}"; then
      # with the .acb companion the stream name is the cue name; without it we tag 'na' and rank by duration
      tag=$(printf '%s\n' "$meta" | sed -nE 's/.*stream name: (.*)/\1/p' | head -1 | tr '/;. ' '____')
      [ -z "$tag" ] && tag=na
      "$VGM" -s "$i" -o "$OUT/raw/${bank}~$(printf %03d "$i")~${tag}~${secs}s.wav" "$f" >/dev/null 2>&1
    fi
  done
done
echo "[3] Decoded $(ls -1 "$OUT/raw" 2>/dev/null | wc -l) raw phrase clips."

echo "[4] Curating + normalizing ..."
declare -A best_dur best_file
for w in "$OUT"/raw/*.wav; do
  [ -e "$w" ] || continue
  base=$(basename "$w")
  dur=${base##*~}; dur=${dur%s.wav}
  case "$dur" in ''|*[!0-9.]*) continue;; esac
  # dedupe by cue name when present, else keep each clip unique (longest-by-duration)
  mid=${base#*~}; mid=${mid#*~}; name=${mid%~*}
  if [ -z "$name" ] || [ "$name" = "na" ]; then key="$base"; else key="$name"; fi
  cur=${best_dur[$key]:-0}
  awk "BEGIN{exit !($dur > $cur)}" && { best_dur[$key]=$dur; best_file[$key]="$w"; }
done
i=0
while read -r dur key; do
  i=$((i+1)); src="${best_file[$key]}"
  fs=$(awk "BEGIN{printf \"%.3f\", ($dur>0.2)?$dur-0.10:0}")
  safe=$(printf '%s' "$key" | tr -c 'A-Za-z0-9._-' '_')
  ffmpeg -y -i "$src" \
    -af "loudnorm=I=-16:TP=-1.5:LRA=11,afade=t=out:st=${fs}:d=0.10" \
    -ar 48000 -ac 1 "$OUT/clips/$(printf %02d "$i")_${safe}.wav" >/dev/null 2>&1
done < <(for k in "${!best_dur[@]}"; do echo "${best_dur[$k]} $k"; done | sort -rn | head -"$TOP_N")
cp "$(ls "$OUT"/clips/*.wav | sort | head -1)" "$OUT/shorekeeper_hello.wav"
cp "$OUT/shorekeeper_hello.wav" "$OUT/voice.wav"   # player looks for voice.wav next to itself
echo "[5] Done."
echo "Candidates: $OUT/clips/ ($(ls -1 "$OUT/clips" | wc -l) clips)"
echo "Default: $OUT/voice.wav"