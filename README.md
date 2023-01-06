# Robocopy-Backup
Robocopy is fastest way to copy files and folders in Windows. This PowerShell script does the following using robocopy.

1) This option will copy the following folders of selected user to specified destination: Desktop, Documents, Downloads, Videos, Pictures, Music Google Chrome user data
2) If the backup was taken with this script, using this option, the data in the backup folder you selected will be copied to the folders specified in the top line.
3) This option; copies a selected folder (this could be the entire disk) to the specified folder.

You can use this script with this command via PowerShell:
```Powershell

irm raw.githubusercontent.com/GokhanTurk/Robocopy-Backup/main/Backup.ps1 | iex

```
Or shorter:
```Powershell

irm tinyurl.com/backupps1 | iex

```
