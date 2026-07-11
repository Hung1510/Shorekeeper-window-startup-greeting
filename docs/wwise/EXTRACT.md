# Extracting from Wwise (.bnk / .wem)

Wwise is the most widely used game-audio middleware, so this covers a huge range
of titles. Audio ships in two shapes:

- `.bnk` soundbanks - may embed many streams ("subsongs") in one file.
- `.wem` streams - individual audio files (Vorbis / Opus / ADPCM / PCM inside).

vgmstream decodes all of these and auto-detects the codec, so the pipeline is the
same regardless of which Wwise codec a game used.

## One command (Linux / WSL)

```bash
./extract_wwise.sh path/to/folder_or_files.zip
# -> out/clips/      curated, normalized candidate clips
# -> out/voice.wav   default pick (longest clean line)
```

Point it at a folder containing `.bnk` and/or `.wem` files, or a `.zip` of them.

## What it does

1. Builds [vgmstream](https://github.com/vgmstream/vgmstream) on first run.
2. Decodes each `.bnk` - if the bank embeds multiple streams, every subsong
   longer than `MIN_SECS` is pulled out; metadata-only banks are skipped.
3. Decodes each standalone `.wem`.
4. Curates by duration (Wwise streams have no readable names - they're hashed
   IDs), keeping the longest clips, then loudness-normalizes and fades them.

## Knobs (top of `extract_wwise.sh`)

- `MIN_SECS` - minimum clip length to keep (default 0.8s).
- `TOP_N` - how many curated clips to produce (default 20).

## Notes

- A `.bnk` that decodes to nothing usually means it only holds event/metadata and
  points at external `.wem` files - extract those `.wem` instead.
- Since Wwise streams are unnamed, you'll want to listen through `out/clips/` to
  find the line you want; the filenames are just bank/stream IDs.

## On Windows (manual)

Grab prebuilt `vgmstream-cli` + `ffmpeg`, then for a bank:

```bat
vgmstream-cli -S 0 -o "out\stream_?s.wav" yourbank.bnk
```

or for loose streams, drag the `.wem` files onto `vgmstream-cli`. Listen, keep
the one you want, normalize/trim with ffmpeg.

## Next

Once you have a `voice.wav`, follow `SETUP_GUIDE.md` (same folder) to play it at
Windows login.
