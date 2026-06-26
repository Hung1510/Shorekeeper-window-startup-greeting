# shorekeeper-startup-voice

Play a game voice line when you log in to Windows — a tiny, silent player plus a
pipeline to extract clips from Square Enix **SAB** audio banks (e.g. Final
Fantasy XVI voice mods).

Built as a fun personal project. Works with any short `.wav`, so you can use any
voice you like.

> ⚠️ **Bring your own audio.** This repo ships **only the tools**, not any game
> audio. Voice lines from games (Wuthering Waves, Final Fantasy, etc.) are the
> publishers' copyrighted property and are **not** included or redistributed
> here. Extract clips from files you already own, for personal use only. Don't
> commit extracted audio to forks of this repo.

---

## What's inside

```
extract/
  extract_pipeline.sh        # SAB bank -> curated, normalized .wav clips (Linux/WSL)
player/
  shorekeeper_startup.cpp    # compiled silent player (no window) — C++/Win32
  shorekeeper_startup.vbs    # zero-install player — VBScript
  shorekeeper_startup.ps1    # alternative player — PowerShell
docs/
  SETUP_GUIDE.md             # full Windows setup (Task Scheduler etc.)
  HUONG_DAN_SHOREKEEPER.txt  # simplified Vietnamese guide
```

---

## Quick start

### 1. Get a clip

If you already have a `.wav`, skip ahead. To pull one from a Square Enix `.sab`
voice bank you own, on Linux/WSL:

```bash
./extract/extract_pipeline.sh path/to/yourfile.zip JP
# -> out/clips/   (curated, normalized candidates)
# -> out/shorekeeper_hello.wav   (default pick)
```

The script builds [vgmstream](https://github.com/vgmstream/vgmstream) (decodes
the SAB/CRI-HCA), decodes the phrase-length lines, then loudness-normalizes and
fades them with ffmpeg. On Windows you can do the same manually with the
prebuilt `vgmstream-cli` + `ffmpeg` — see `docs/SETUP_GUIDE.md`.

### 2. Build the player (optional — VBS needs no build)

```bash
# MinGW-w64
g++ player/shorekeeper_startup.cpp -o shorekeeper_startup.exe -municode -lwinmm -mwindows -O2 -static

# MSVC
cl /O2 player/shorekeeper_startup.cpp /link winmm.lib
```

The C++ player plays `shorekeeper_hello.wav` from its own folder (or a path
passed as the first argument). `PlaySound` handles PCM `.wav`.

### 3. Run it at login

Put your `.wav` and the player in `C:\Sounds\`, then create a **Task Scheduler**
task with an *At log on* trigger pointing at the player. Full steps in
`docs/SETUP_GUIDE.md`.

---

## How the extraction works

1. **Identify** — Square Enix SAB files start with the magic `sabf`.
2. **Decode** — vgmstream reads the container; audio inside is CRI HCA. Each
   `.sab` holds many "subsongs" (one per line).
3. **Filter** — keep lines above a length threshold (skips tiny combat grunts).
4. **Curate** — keep the fullest take of each distinct line, loudness-normalize,
   add a short fade-out.

Knobs at the top of `extract_pipeline.sh`: `MIN_SECS`, `TOP_N`, `LANG_PICK`.

---

## License

Code and docs in this repo are released under the MIT License (see `LICENSE`).
This license covers **only** the original tooling here — **not** any game audio,
which remains the property of its respective rights holders.
