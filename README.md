# Robocopy-Backup
Robocopy is fastest way to copy files and folders in Windows. This Powershell script is taking backup userprofile(Desktop,Documents,Downloads and Chrome User Data)  with Robocopy.

You can use this script with this command via Powershell:
```Powershell

iwr -useb https://raw.githubusercontent.com/GokhanTurk/Robocopy-Backup/main/Backup.ps1 | iex $($ScriptFromGitHub.Content)

```
