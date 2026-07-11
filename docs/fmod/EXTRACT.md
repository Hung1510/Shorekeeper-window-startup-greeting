# Extracting from FMOD sound banks

FMOD is one of the two big game-audio middlewares (Wwise being the other), so
between this, the Wwise pipeline and SAB you can crack open most games. Its
files are `.fsb` (FMOD Sound Bank, magic `FSB5` / older `FSB4` `FSB3`) and the
FMOD Studio `.bank` container. A single bank packs many "subsongs" (one per
voice line), usually in FADPCM, Vorbis, MPEG or plain PCM.

## One command (Linux / WSL)

```bash
./extract_fmod.sh path/to/files.zip
# -> out/clips/      curated, normalized candidate clips
# -> out/voice.wav   default pick (longest clean line)
```

Pass a `.zip` (e.g. a voice mod) or point it at a folder of `.fsb` / `.bank`
files. Optional second argument is just a name filter, handy when a dump has one
huge `Master.bank` plus a `VO_EN.fsb` you actually want:

```bash
./extract_fmod.sh dump.zip 'vo|voice|en'
```

## What it does

1. Builds [vgmstream](https://github.com/vgmstream/vgmstream) on first run.
2. Prints each file's magic so you can eyeball it (`FSB5` for most modern
   banks; some `.bank` show `RIFF` and still decode fine).
3. Decodes every subsong longer than `MIN_SECS` (skips the tiny combat grunts).
4. When the bank carries per-subsong names it dedupes by those and keeps the
   fullest take of each; when it doesnt (lots of FSBs ship nameless), it falls
   back to keeping the longest clips by duration.
5. Loudness-normalizes and fades each keeper with ffmpeg.

## Knobs (top of `extract_fmod.sh`)

- `MIN_SECS` - minimum clip length to keep (default 0.8s).
- `TOP_N` - how many curated clips to produce (default 16).
- second CLI arg - optional name filter for which banks to scan.

## On Windows (manual)

Grab prebuilt `vgmstream-cli` + `ffmpeg`, then:

```bat
vgmstream-cli -S 0 -o "out\line_?s.wav" yourfile.fsb
```

`-S 0` extracts all subsongs; listen through and keep the one you want, then
normalize/trim with ffmpeg. Same trick works on a `.bank` if vgmstream opens it
directly - if it refuses, pop the embedded `.fsb` out first (python-fsb5 /
fsbext) and point vgmstream at that.

## Next

Once you have a `voice.wav`, follow `SETUP_GUIDE.md` (same folder) to play it at
Windows login.