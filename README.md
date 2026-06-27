# shorekeeper-startup-voice

Play a game voice line when you log in to Windows -> a tiny silent player plus a pipeline to extract clips from Square Enix SAB audio banks (Final Fantasy XVI voice mods for Shorekeeper in my case) cause I for my own sake cant find any usable file of Shorekeeper voice without entering the game and record it with bandicam or something so Ive built this tool for my future use and anyone that might be interested

Built as a fun personal project. Works with any short `.wav`, so you can use any voice you like. It now also pulls from Wwise (.bnk / .wem), FMOD (.fsb / .bank) and CRI ADX2 (.acb / .awb) banks. Gonna keep expanding it when I have free time from work, open for any sound format if anyone is interested

---

> Bring your own audio. This repo ships only the tools, not any game audio.
> Game voice lines are the publishers' copyrighted property and are not included
> or redistributed here. Extract clips from files you already own, personal use only.

---

## What's inside

Each sound format has its own folder so you can grab just what you need.

```
extract/
  sab/ extract_sab.sh # Square Enix SAB bank -> normalized .wav clips
  wwise/ extract_wwise.sh # Wwise .bnk / .wem -> normalized .wav clips
  fmod/ extract_fmod.sh # FMOD .fsb / .bank -> normalized .wav clips
  cri/ extract_cri.sh # CRI ADX2 .acb / .awb -> normalized .wav clips
player/ # same player for any format, just plays the final .wav
  sab/ startup_voice.cpp / .vbs / .ps1
  wwise/ startup_voice.cpp / .vbs / .ps1
  fmod/ startup_voice.cpp / .vbs / .ps1
  cri/ startup_voice.cpp / .vbs / .ps1
docs/
  sab/ EXTRACT.md + SETUP_GUIDE.md
  wwise/ EXTRACT.md + SETUP_GUIDE.md
  fmod/ EXTRACT.md + SETUP_GUIDE.md
  cri/ EXTRACT.md + SETUP_GUIDE.md
```

The player is identical in every folder -> it doesnt care where the audio came from, its duplicated only so each format folder is self-contained.

---

## Quick start

### 1 -> Get a clip

If you already have a `.wav`, skip ahead. Otherwise pick your format and run its script (Linux/WSL):

```bash
# Square Enix SAB
./extract/sab/extract_sab.sh path/to/yourfile.zip JP

# Wwise (.bnk / .wem)
./extract/wwise/extract_wwise.sh path/to/folder_or_files.zip

# FMOD (.fsb / .bank)
./extract/fmod/extract_fmod.sh path/to/folder_or_files.zip

# CRI ADX2 (.acb / .awb)
./extract/cri/extract_cri.sh path/to/folder_or_files.zip

# all give you:
# -> out/clips/
# -> out/voice.wav (default pick)
```

Each script builds [vgmstream](https://github.com/vgmstream/vgmstream) (decodes the container/codec), pulls the phrase-length streams,
then loudness-normalizes and fades them with ffmpeg. On Windows you can do the same manually with the prebuilt `vgmstream-cli` + `ffmpeg` -> see the matching `docs/<format>/EXTRACT.md`.

### 2 -> Build the player (optional, VBS needs no build)

```bash
# MinGW-w64
g++ player/sab/startup_voice.cpp -o startup_voice.exe -municode -lwinmm -mwindows -O2 -static

# MSVC
cl /O2 player/sab/startup_voice.cpp /link winmm.lib
```

(every `player/<format>/startup_voice.cpp` is the same file, build any.) The player plays `voice.wav` from its own folder (or a path passed as the first argument). It uses the Windows MCI engine, so it handles any WAV variant plus mp3.

### 3 -> Run it at login

Put your `.wav` and the player in `C:\Sounds\`, then create a Task Scheduler task
with an "At log on" trigger pointing at the player. Full steps in
`docs/<format>/SETUP_GUIDE.md`.

---

## How the extraction works

1. Identify -> SAB files start with the magic `sabf`; Wwise ships `.bnk` banks and `.wem` streams; FMOD ships `.fsb` banks (magic `FSB5`) and FMOD Studio `.bank` containers; CRI ADX2 ships `.awb` wave banks (`AFS2`) paired with `.acb` cue sheets (`@UTF`).
2. Decode -> vgmstream reads the container and auto-detects the codec (CRI HCA for SAB; Vorbis / Opus / ADPCM / PCM for Wwise; FADPCM / Vorbis / MPEG / PCM for FMOD; HCA / ADX for CRI ADX2). Banks hold many "subsongs".
3. Filter -> keep streams above a length threshold (skips tiny grunts/blips).
4. Curate -> keep the fullest/longest takes, loudness-normalize, add a short fade-out

Knobs at the top of each script: `MIN_SECS`, `TOP_N` (and `LANG_PICK` for SAB, an optional name filter for FMOD and CRI).

---

## License

Code and docs in this repo are released under the MIT License (see `LICENSE`).
This license covers only the original tooling here -> not any game audio, which remains the property of its respective rights holders.