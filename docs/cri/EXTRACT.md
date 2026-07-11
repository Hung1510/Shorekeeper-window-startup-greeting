# Extracting from CRI ADX2 (Atom) banks

CRI's ADX2 / Atom is everywhere in Japanese console and gacha games, and its the
same HCA codec family living inside Square's SAB, so this one's a close cousin of
the sab pipeline. Two files matter:

- `.awb` - AFS2 wave bank, the actual audio (one subsong per voice line).
- `.acb` - `@UTF` cue sheet, holds the cue **names**.

Usually they ship as a pair (`Voice_EN.awb` + `Voice_EN.acb`). Sometimes the
audio is embedded straight into the `.acb` and theres no separate `.awb`. The
script handles both.

## One command (Linux / WSL)

```bash
./extract_cri.sh path/to/files.zip
# -> out/clips/      curated, normalized candidate clips
# -> out/voice.wav   default pick (longest clean line)
```

Optional second arg is a name filter (e.g. prefer the EN/JP dub bank):

```bash
./extract_cri.sh dump.zip 'voice|vo|en'
```

> Keep the `.acb` next to its `.awb`. Point the script at the `.awb` and
> vgmstream finds the sibling `.acb` on its own to recover proper cue names - pull
> them apart and you just get numbered streams.

## What it does

1. Builds [vgmstream](https://github.com/vgmstream/vgmstream) on first run.
2. Picks targets: every `.awb`, plus any `.acb` that has no sibling `.awb`
   (those carry their audio embedded).
3. Prints each file's magic (`AFS2` for `.awb`, `@UTF` for `.acb`).
4. Decodes every subsong longer than `MIN_SECS` (skips the tiny grunts).
5. When the `.acb` companion is present it dedupes by cue name and keeps the
   fullest take of each; otherwise it falls back to longest clips by duration.
6. Loudness-normalizes and fades each keeper with ffmpeg.

## Knobs (top of `extract_cri.sh`)

- `MIN_SECS` - minimum clip length to keep (default 0.8s).
- `TOP_N` - how many curated clips to produce (default 16).
- second CLI arg - optional name filter for which banks to scan.

## On Windows (manual)

Grab prebuilt `vgmstream-cli` + `ffmpeg`, drop the `.acb` and `.awb` in the same
folder, then:

```bat
vgmstream-cli -S 0 -o "out\line_?s.wav" Voice_EN.awb
```

`-S 0` extracts all subsongs; listen through and keep the one you want, then
normalize/trim with ffmpeg.

## Next

Once you have a `voice.wav`, follow `SETUP_GUIDE.md` (same folder) to play it at
Windows login.