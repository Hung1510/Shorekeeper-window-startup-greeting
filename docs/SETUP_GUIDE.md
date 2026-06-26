# Shorekeeper Startup Greeting — Complete Setup Guide

Make your PC play a Shorekeeper voice clip when you log in, using the compiled
`shorekeeper_startup.exe`. Reliable timing via Task Scheduler.

Everything here is standard, reversible Windows configuration. Nothing edits
system files or can damage your PC. Undo steps are at the end.

---

## What you need (from the pack)

- `shorekeeper_startup.exe`  — the silent player (plays a .wav, no window)
- one voice clip renamed to `shorekeeper_hello.wav`

---

## Step 1 — Put the files in place

1. Create the folder `C:\Sounds` if it doesn't exist.
2. Copy into it:
   - `shorekeeper_startup.exe`
   - your chosen clip, renamed exactly `shorekeeper_hello.wav`
3. They must sit in the **same folder** — the exe looks for the wav next to
   itself.

> To use a different line later, just replace `shorekeeper_hello.wav` with
> another clip of the same name. Nothing else changes.

---

## Step 2 — Test the player by itself

1. Double-click `shorekeeper_startup.exe`.
2. You should hear the clip, with no window appearing.
   - First run may show a blue **"Windows protected your PC"** SmartScreen
     popup (normal for any unsigned program) → **More info → Run anyway**.
   - No sound? Confirm the wav is named exactly `shorekeeper_hello.wav` and is
     in the same folder.

---

## Step 3 — Create the login task (Task Scheduler)

1. Press Start, type **Task Scheduler**, open it.
2. Right panel → **Create Task…**  (the full version, not "Basic Task").
3. **General** tab:
   - Name: `Shorekeeper Greeting`
   - Leave **"Run only when user is logged on"** selected.
4. **Triggers** tab → **New…**
   - Begin the task: **At log on**
   - Settings: **Specific user** = your account
   - Leave **"Delay task for"** unchecked for now → **OK**
5. **Actions** tab → **New…**
   - Action: **Start a program**
   - Program/script: `C:\Sounds\shorekeeper_startup.exe`
   - Leave **Add arguments** blank → **OK**
6. **Conditions** tab:
   - Uncheck **"Start the task only if the computer is on AC power"**
     (so it plays on battery too).
   - Leave **"Start only if network connection is available"** unchecked
     (you don't want it waiting on WiFi).
7. Click **OK** to save.

---

## Step 4 — Remove the old Startup-folder shortcut

So it doesn't fire twice:

1. Press `Win + R`, type `shell:startup`, press Enter.
2. Delete `shorekeeper_startup.exe - Shortcut` from that folder.

---

## Step 5 — Test the task

1. In Task Scheduler, find **Shorekeeper Greeting** under *Task Scheduler
   Library*.
2. Right-click it → **Run**. It should play immediately.
3. Restart the PC to check real-login timing.

---

## Step 6 (optional) — Tighten the timing

Some delay after boot is normal: the audio service and sound device must be
up before anything can play. Tune based on what you see:

- **Plays every time, just a little late:** you're done. This is expected and
  harmless.
- **Want it earlier / more consistent:** turn off **Fast Startup** —
  Control Panel → **Power Options** → **Choose what the power buttons do** →
  **Change settings that are currently unavailable** → uncheck
  **Turn on fast startup** → Save changes. This makes login timing more
  predictable (costs ~1–2s of boot time).
- **Sometimes plays silence (too early):** the audio stack wasn't ready. In
  the task's **Triggers** → edit the trigger → check **"Delay task for"** and
  set **2 seconds** (or up to 5). A tiny delay for guaranteed playback.

---

## How to undo everything

- **Stop the greeting:** Task Scheduler → right-click **Shorekeeper Greeting**
  → **Delete**.
- **Re-enable Fast Startup** (if you turned it off): same Power Options screen,
  re-check **Turn on fast startup** → Save.
- **Remove the files:** delete the `C:\Sounds` folder.

Nothing above leaves anything behind once these are reversed.

---

## Quick troubleshooting

| Symptom | Fix |
|---|---|
| SmartScreen popup on first run | More info → Run anyway (normal for unsigned exe) |
| No sound at all on double-click | Wav must be named `shorekeeper_hello.wav`, same folder as exe |
| Plays late, around WiFi connect | Use the task (Step 3); leave network condition unchecked |
| Occasionally silent at login | Add "Delay task for: 2 seconds" on the trigger |
| Want a different / shorter clip | Replace the wav, or trim with: `ffmpeg -ss 0.2 -to 1.5 -i in.wav shorekeeper_hello.wav` |
| Plays twice | Remove the old Startup-folder shortcut (Step 4) |
