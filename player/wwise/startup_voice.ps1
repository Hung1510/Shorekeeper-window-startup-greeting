# Run hidden by a shortcut:powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Sounds\startup_voice.ps1"
$wav = "C:\Sounds\voice.wav"# <-- edit to your file path
$player = New-Object System.Med ia.SoundPlayer $wav
$player.PlaySync()
