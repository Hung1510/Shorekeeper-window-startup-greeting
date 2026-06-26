# Shorekeeper startup greeting - PowerShell player.
# Plays a PCM .wav and waits until it finishes.
# Run hidden via a shortcut:
#   powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Sounds\shorekeeper_startup.ps1"
$wav = "C:\Sounds\shorekeeper_hello.wav"   # <-- edit to your file's path
$player = New-Object System.Media.SoundPlayer $wav
$player.PlaySync()
