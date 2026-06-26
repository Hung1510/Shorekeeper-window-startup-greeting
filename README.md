# shorekeeper-startup-voice

Play a game voice line when you log in to Windows -> a tiny silent player plus a pipeline to extract clips from Square Enix SAB audio banks (Final FantasyXVI voice mods for Shorekeeper in my case) cause I for my own sake cant find any usable file of Shorekeeper voice without entering the game and record it with bandicam or something so Ive built this tool for my future use and anyone that might be interested

Built as a fun personal project. Works with any short `.wav`, so you can use any voice you like. Gonna keep expanding it when I have free time from work

---

> Bring your own audio. This repo ships only the tools, not any game audio.
> Game voice lines are the publishers' copyrighted property and are not included
> or redistributed here. Extract clips from files you already own, personal use only.

---

## What's inside

```
extract/
  extract_pipeline.sh # SAB bank -> normalized .wav clips (Linux/WSL)
player/
  startup_voice.cpp # compiled silent player (no window) - C++/Win32
  startup_voice.vbs # zero-install player - VBScript
  startup_voice.ps1 # alternative player - PowerShell
docs/
  SETUP_GUIDE.md # full setup
```

---

## Quick start

### 1 -> Get a clip

If you already have a `.wav`, skip ahead. To pull one from a Square Enix `.sab` voice bank you own, on Linux/WSL:

```bash
./extract/extract_pipeline.sh path/to/yourfile.zip JP
# -> out/clips/
# -> out/voice.wav (default pick)
```

The script builds [vgmstream](https://github.com/vgmstream/vgmstream) (decodes the SAB/CRI-HCA), pulls the phrase-length lines,
then loudness-normalizes and fades them with ffmpeg. On Windows you can do the same manually with the prebuilt `vgmstream-cli` + `ffmpeg` -> see `docs/SETUP_GUIDE.md`.

### 2 -> Build the player (optional, VBS needs no build)

```bash
# MinGW-w64
g++ player/startup_voice.cpp -o startup_voice.exe -municode -lwinmm -mwindows -O2 -static

# MSVC
cl /O2 player/startup_voice.cpp /link winmm.lib
```

The C++ player plays `voice.wav` from its own folder (or a path
passed as the first argument). `PlaySound` handles PCM `.wav`.

### 3 -> Run it at login

Put your `.wav` and the player in `C:\Sounds\`, then create a Task Scheduler task
with an "At log on" trigger pointing at the player. Full steps in
`docs/SETUP_GUIDE.md`.

---

## How the extraction works

1. Identify -> Square Enix SAB files start with the magic `sabf`.
2. Decode -> vgmstream reads the container; audio inside is CRI HCA. Each `.sab` holds many "subsongs"
3. Filter -> keep lines above a length threshold (skips tiny combat grunts).
4. Curate -> keep the fullest take of each distinct line, loudness-normalize, add a short fade-out

Knobs at the top of `extract_pipeline.sh`: `MIN_SECS`, `TOP_N`, `LANG_PICK`.

---

## License

Code and docs in this repo are released under the MIT License (see `LICENSE`).
This license covers only the original tooling here -> not any game audio, which remains the property of its respective rights holders.