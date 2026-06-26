# Extracting from Square Enix SAB banks

SAB is Square Enix's audio-bank format (e.g. Final Fantasy XVI). Files start
with the magic `sabf` and hold CRI HCA audio, with many "subsongs" (one per
voice line) packed into a single `.sab`.

## One command (Linux / WSL)

```bash
./extract_sab.sh path/to/files.zip JP
# -> out/clips/      curated, normalized candidate clips
# -> out/voice.wav   default pick (longest clean line)
```

Pass a `.zip` (e.g. a voice mod) or point it at a folder of `.sab` files. The
second argument (`JP` / `EN`) just prefers that language folder if present.

## What it does

1. Builds [vgmstream](https://github.com/vgmstream/vgmstream) on first run.
2. Confirms each file's `sabf` magic.
3. Decodes every subsong longer than `MIN_SECS` (skips the tiny combat grunts).
4. For FFXVI banks it dedupes by the internal line tags (`sbe`, `ptf`, ...) and
   keeps the fullest take of each; for other games' SAB it falls back to keeping
   the longest clips by duration.
5. Loudness-normalizes and fades each keeper with ffmpeg.

## Knobs (top of `extract_sab.sh`)

- `MIN_SECS` — minimum clip length to keep (default 0.8s).
- `TOP_N` — how many curated clips to produce (default 16).
- `LANG_PICK` — preferred dub folder.

## On Windows (manual)

Grab prebuilt `vgmstream-cli` + `ffmpeg`, then:

```bat
vgmstream-cli -S 0 -o "out\line_?s.wav" yourfile.sab
```

`-S 0` extracts all subsongs; listen through and keep the one you want, then
normalize/trim with ffmpeg.

## Next

Once you have a `voice.wav`, follow `SETUP_GUIDE.md` (same folder) to play it at
Windows login.
