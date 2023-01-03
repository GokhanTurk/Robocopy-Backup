try {
    Add-Type -AssemblyName System.Windows.Forms
    [string[]]$confirm
    $inputWarning = "INPUTS MUST BE A NUMBER!"
    Clear-Host
    Function Select-Action {
        Write-Host "1) Backup User Data" -BackgroundColor DarkGreen -ForegroundColor White
        Write-Host "(It will copy the following folders of selected user: Desktop, Documents, Downloads, Google Chrome user data)" -BackgroundColor DarkGreen -ForegroundColor White
        Write-Host "2) Recover User Data" -BackgroundColor DarkMagenta -ForegroundColor White
        Write-Host "3) Backup a Folder or Entire Disk" -BackgroundColor DarkBlue -ForegroundColor White
        Write-Host "4) Exit" -BackgroundColor DarkRed -ForegroundColor White
    
        switch (Read-Host $SelectedAction "What do you want to do?") {
            1 { Select-Disk }
            2 { Recover_UserData }
            3 { Backup-Folder }
            4 { Exit }
            default { Clear-Host; Write-Warning $inputWarning; Select-Action }
        }
    }
    Function Select-Disk {
        $disk = @(get-wmiobject win32_logicaldisk -filter "drivetype=3" | select-object -expandproperty name)
        $D_Index_List = @()
        Write-Host "########### DISK LIST ###########" -Backgroundcolor DarkCyan -ForeGroundColor White
        for ($i = 0; $i -le $disk.length - 1; $i++) {
            $Disk_List = "${i}) "
            $Disk_List += $disk[$i]
            $D_Index_List += @($i)
            Write-Output $Disk_List
        }
        do {
            $Disk_Index = Read-Host "Select the source drive"
            if (($D_Index_List -notcontains $Disk_index) -or ($Disk_index -notmatch "\d+")) { Write-Warning $inputWarning }
        } while (($D_Index_List -notcontains $Disk_index) -or ($Disk_index -notmatch "\d+"))
        $script:Selected_Disk = $disk[$Disk_Index]
        Select-User(1)

    }
    Function Select-User {
        param(
            $Action
        )
        $Users = @(Get-ChildItem -Path "${Selected_Disk}\Users\" -Name -ErrorAction Stop)
        $U_Index_List = @()
        Write-Host "########### USER LIST IN $Selected_Disk ###########" -Backgroundcolor DarkCyan -ForeGroundColor White
        for ($i = 0; $i -le $Users.length - 1; $i++) {
            $Users_List = "${i}) "
            $Users_List += $Users[$i]
            $U_Index_List += @($i)
            Write-Host $Users_List
        }
        do {
            $User_Index = Read-Host "Select the username"
            if (($U_Index_List -notcontains $User_index) -or ($User_index -notmatch "\d+")) { Write-Warning $inputWarning }
        } while (($U_Index_List -notcontains $User_index) -or ($User_index -notmatch "\d+"))
        $Selected_User = $Users[$User_Index]
        $sourcePath = "$Selected_Disk\Users\${Selected_User}"
        if ($Action -eq 0) {
            return $sourcePath
        }
        elseif ($Action -eq 1) {
            $Folder_Name = (Get-Date -Format "dd.MM.yyyy") + "_${Selected_User}"
            Write-Host "Please select the destination folder:" -Backgroundcolor DarkCyan -ForeGroundColor White
            Timeout /t 1 | Out-Null
            $destinationPath = Get-Folder
            if ("" -eq $destinationPath) {
                Clear-Host
                Write-Warning "You have not selected a destination folder!"
                Select-Action
            }
            $destinationPath += "\${Folder_Name}"
            [string] $DestinationDisk = $destinationPath[0] + ":"
            if ($DestinationDisk -eq $Selected_Disk) { Clear-Host; Write-Warning "You cannot copy to the same drive. It causes a loop. Please select a different drive!"; Select-Action }
            else { Backup-UserData }
        }
    }
    Function Backup-UserData {
        do {
            $confirm = Read-Host "Are you confirming that $Selected_User files will be copied to ${destinationPath} (Y/N)"
        } while ("y", "n" -notcontains $confirm )
        if ($confirm -eq "y") {
            robocopy "$sourcePath\Desktop\" "$destinationPath\Desktop"  /s /e /mt:32 /r:0 /w:0 /tee /fp /eta /v /xf /xn /xo /xjd *.tmp /A-:SH /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log
            robocopy "$sourcePath\Downloads\" "$destinationPath\Downloads"  /s /e /mt:32 /r:0 /w:0 /tee /fp /eta /v /xf /xn /xo /xjd *.tmp /A-:SH /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log
            robocopy "$sourcePath\Documents\" "$destinationPath\Documents"  /mir /mt:32 /r:0 /w:0 /fp /tee /eta /v /xf /xn /xo /xjd *.tmp /A-:SH /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log
            robocopy "$sourcePath\AppData\Local\Google\" "$destinationPath\Google"  /s /e /mt:32 /r:0 /w:0 /tee /fp /eta /v /xf /xn /xo /xjd *.tmp /A-:SH /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log
            attrib.exe -h  -s  -a $destinationPath\Desktop
            attrib.exe -h  -s  -a $destinationPath\Downloads
            attrib.exe -h  -s  -a $destinationPath\Documents
            attrib.exe -h  -s  -a $destinationPath\Google
            Write-Host "The process is completed! You can check the log $env:userprofile\Desktop\Robocopy-Backup.log" -BackgroundColor DarkGreen -ForegroundColor White
            Read-Host -Prompt "Press Enter to exit!"
            Exit
        }
        else { Clear-Host; Select-Action }
    }
    Function Backup-Folder {
        Write-Host "Please select the source folder:" -Backgroundcolor DarkCyan -ForeGroundColor White
        Timeout /t 1 | Out-Null
        $sourcePath = Get-Folder
        if ("" -eq $sourcePath) {
            Clear-Host
            Write-Warning "You have not selected a source folder!"
            Select-Action
        }
        Write-Host "Please select the destination folder:" -Backgroundcolor DarkGreen -ForeGroundColor White
        Timeout /t 1 | Out-Null
        $destinationPath = Get-Folder
        if ("" -eq $destinationPath) {
            Clear-Host
            Write-Warning "You have not selected a destination folder!"
            Select-Action
        }
        $sourceFolderName = Split-Path $sourcePath -Leaf
        if ($sourceFolderName.Contains(":")) {
            $sourceDisk = $sourceFolderName
            $sourceFolderName = $sourceFolderName -replace ":", " Backup"
        }
        $destinationPath += "\Backup_" + (Get-Date -Format "dd.MM.yyyy") + "\" + ${sourceFolderName}.TrimEnd('\')
        
        do {
            Clear-Host
            Write-Host "Source: " $sourcePath -BackgroundColor DarkRed -ForegroundColor White
            Write-Host "Destination: " $destinationPath -BackgroundColor DarkGreen -ForegroundColor White
            $confirm = Read-Host "The copying process will start. Do you confirm? (Y/N)"
        } while ("y", "n" -notcontains $confirm )
        if ($confirm -eq "y") {
            robocopy "$sourcePath" "$destinationPath " /s /e /mt:32 /r:0 /w:0 /fp /eta /v /xf /xn /xo /xjd *.tmp /A-:SH /tee /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log /xf "pagefile.sys" /xd "${sourceDisk}System Volume Information" /xd "RECYCLER" /xd "Temporary Files" /xd "Config.Msi" /xd ${sourceDisk}'$RECYCLE.BIN"'
            attrib.exe -h  -s  -a $destinationPath
            Write-Host "The process is completed! You can check the log $env:userprofile\Desktop\Robocopy-Backup.log" -BackgroundColor DarkGreen -ForegroundColor White
            Read-Host -Prompt "Press Enter to exit!"
            Exit
        }
        else { Clear-Host; Select-Action }
    }
    Function Recover_UserData {
        Write-Host "Please select the backup folder that contains user data:" -Backgroundcolor DarkCyan -ForeGroundColor White
        Timeout /t 1 | Out-Null
        $BackupFolder = Get-Folder
        if ("" -eq $BackupFolder) {
            Clear-Host
            Write-Warning "You have not selected a backup folder!"
            Select-Action
        }
        Clear-Host
        Write-Host "Please select the user that you want to recover:" -Backgroundcolor DarkCyan -ForeGroundColor White
        Timeout /t 1 | Out-Null
        $destinationUser = "C:"
        $destinationUser += Select-User(0)
        Write-Host "Backup Folder path (source): $BackupFolder" -BackgroundColor DarkRed -ForegroundColor White
        Write-Host "User to recover (destination): $destinationUser" -BackgroundColor DarkBlue -ForegroundColor White
        do {
            $confirm = Read-Host "The recovery process will start. Do you confirm? (Y/N)"
        } while ("y", "n" -notcontains $confirm )
        if ($confirm -eq "y") {
            robocopy "$BackupFolder\Desktop\" "$destinationUser\Desktop"  /s /e /mt:32 /r:0 /w:0 /tee /fp /eta /v /A-:SH /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log
            robocopy "$BackupFolder\Downloads\" "$destinationUser\Downloads"  /s /e /mt:32 /r:0 /w:0 /tee /fp /eta /v /A-:SH /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log
            robocopy "$BackupFolder\Documents\" "$destinationUser\Documents"  /mir /mt:32 /r:0 /w:0 /fp /tee /eta /v /A-:SH /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log
            robocopy "$BackupFolder\Google\" "$destinationUser\AppData\Local\Google\"  /s /e /mt:32 /r:0 /w:0 /tee /fp /eta /v /A-:SH /log+:$env:USERPROFILE\Desktop\Robocopy-Backup.log
            attrib.exe -h  -s  -a $destinationUser\Desktop
            attrib.exe -h  -s  -a $destinationUser\Downloads
            attrib.exe -h  -s  -a $destinationUser\Documents
            attrib.exe -h  -s  -a $destinationUser\Google
            Write-Host "The process is completed! You can check the log $env:userprofile\Desktop\Robocopy-Backup.log" -BackgroundColor DarkGreen -ForegroundColor White
            Read-Host -Prompt "Press Enter to exit!"
            Exit
        }
        else { Clear-Host; Select-Action }
    }
    Function Get-Folder($initialDirectory = "") {
        $AssemblyFullName = 'System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
        $Assembly = [System.Reflection.Assembly]::Load($AssemblyFullName)
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.AddExtension = $false
        $OpenFileDialog.CheckFileExists = $false
        $OpenFileDialog.DereferenceLinks = $true
        $OpenFileDialog.Filter = "Folders|`n"
        $OpenFileDialog.Multiselect = $false
        $OpenFileDialog.Title = "Select the folder"
        $OpenFileDialogType = $OpenFileDialog.GetType()
        $FileDialogInterfaceType = $Assembly.GetType('System.Windows.Forms.FileDialogNative+IFileDialog')
        $IFileDialog = $OpenFileDialogType.GetMethod('CreateVistaDialog', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($OpenFileDialog, $null)
        $null = $OpenFileDialogType.GetMethod('OnBeforeVistaDialog', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($OpenFileDialog, $IFileDialog)
        [uint32]$PickFoldersOption = $Assembly.GetType('System.Windows.Forms.FileDialogNative+FOS').GetField('FOS_PICKFOLDERS').GetValue($null)
        $FolderOptions = $OpenFileDialogType.GetMethod('get_Options', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($OpenFileDialog, $null) -bor $PickFoldersOption
        $null = $FileDialogInterfaceType.GetMethod('SetOptions', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, $FolderOptions)
        $VistaDialogEvent = [System.Activator]::CreateInstance($AssemblyFullName, 'System.Windows.Forms.FileDialog+VistaDialogEvents', $false, 0, $null, $OpenFileDialog, $null, $null).Unwrap()
        [uint32]$AdviceCookie = 0
        $AdvisoryParameters = @($VistaDialogEvent, $AdviceCookie)
        $AdviseResult = $FileDialogInterfaceType.GetMethod('Advise', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, $AdvisoryParameters)
        $AdviceCookie = $AdvisoryParameters[1]
        $Result = $FileDialogInterfaceType.GetMethod('Show', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, [System.IntPtr]::Zero)
        $null = $FileDialogInterfaceType.GetMethod('Unadvise', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, $AdviceCookie)
        if ($Result -eq [System.Windows.Forms.DialogResult]::OK) {
            $FileDialogInterfaceType.GetMethod('GetResult', @('NonPublic', 'Public', 'Static', 'Instance')).Invoke($IFileDialog, $null)
        }
        $folder = $OpenFileDialog.FileName
        return $folder
    }
    Select-Action
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Warning "An error has occurred! The cause of this may be that there is no user profile on the disk you have selected!"
    Select-Action
}
catch {
    Write-Warning "An error has occurred!"
    Write-Host $_
    exit
}
