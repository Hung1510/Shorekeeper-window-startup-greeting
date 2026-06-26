# Startup Voice Greeting — Complete Setup Guide

Make your Windows PC play a voice clip when you log in, using the compiled
`startup_voice.exe`


---

## What you need

- `startup_voice.exe` — download it from the [Releases page](../../releases) (no need to build anything)
- one voice clip renamed to `voice.wav`

---

## 1 — Put the files in place

1. Create the folder `C:\Sounds` if it doesn't exist.
2. Copy into it:
   - `startup_voice.exe`
   - your chosen clip, renamed exactly `voice.wav`
3. They must sit in the same folder — the exe looks for the wav next to itself.

> To use a different line later, just replace `voice.wav` with
> another clip of the same name. Nothing else changes.

---

## 2 — Test the player

1. Double-click `startup_voice.exe`.
2. You should hear the clip
   - First run may show a blue "Windows protected your PC" SmartScreen popup -> More info -> Run anyway.
   - No sound? Confirm the wav is named exactly `voice.wav` and is in the same folder

---

## 3 — Create Task Scheduler task

1. Press Start, type Task Scheduler, open it
2. Right panel -> Create Task… (the full version, not "Basic Task").
3. General tab:
   - Name: `Startup Voice`
   - Leave "Run only when user is logged on" selected.
4. Triggers tab -> New…
   - Begin the task: At log on
   - Settings: Specific user = your account
   - Leave "Delay task for" unchecked for now -> OK
5. Actions tab -> New…
   - Action: Start a program
   - Program/script: `C:\Sounds\startup_voice.exe`
   - Leave Add arguments blank -> OK
6. Conditions tab:
   - Uncheck "Start the task only if the computer is on AC power"
   - Leave "Start only if network connection is available" unchecked
7. Click OK to save.

---

## How to undo everything

- Stop the greeting: Task Scheduler -> right-click Startup Voice -> Delete.
- Re-enable Fast Startup (if you turned it off): same Power Options screen, re-check Turn on fast startup -> Save.
- Remove the files: delete the `C:\Sounds` folder.

---
