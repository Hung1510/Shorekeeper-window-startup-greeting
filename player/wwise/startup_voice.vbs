Set sound = CreateObject("WMPlayer.OCX.7")
sound.settings.volume = 90 ' 0-100, lower if too loud at login
sound.URL = "C:\Sounds\voice.wav"' <-- edit to your file's path
sound.Controls.play
WScript.Sleep 4000 ' ms; must be >= clip length
