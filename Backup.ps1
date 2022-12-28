try {
Clear-Host
Add-Type -AssemblyName System.Windows.Forms
[string[]]$confirm

function Select-Action {
    Write-Warning "INPUTS MUST BE NUMBER!"
    Write-Host "1) Backup User Data" -BackgroundColor DarkGreen -ForegroundColor White
    Write-Host "(It will copy the following folders of selected user: Desktop, Documents, Downloads, Google Chrome user data)" -BackgroundColor DarkGreen -ForegroundColor White
    Write-Host "2) Backup a Specific Folder" -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host "(You can copy whole disk or one folder with this selection)" -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host "3) Exit" -BackgroundColor DarkRed -ForegroundColor White
    
switch (Read-Host $SelectedAction "What do you want to do?") {
     1 {Select-Disk}
     2 {Backup-Folder}
     3 {Exit}
     default {Clear-Host; Select-Action}
}
}
function Select-Disk {
    param (
        [int] $Action
    )
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
    } while (($D_Index_List -notcontains $Disk_index) -or ($Disk_index -notmatch "\d+"))
    $script:Selected_Disk = $disk[$Disk_Index]
    Clear-Host
    Select-User

}
function Select-User {
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
    } while (($U_Index_List -notcontains $User_index) -or ($User_index -notmatch "\d+"))
    $Selected_User = $Users[$User_Index]
    $sourcePath = "$Selected_Disk\Users\${Selected_User}"
    $Folder_Name = Get-Date -Format "dd.MM.yyyy"
    $Folder_Name += "_${Selected_User}"
    Write-Host "Please select the destination folder:" -Backgroundcolor DarkCyan -ForeGroundColor White
    Timeout /t 1 | Out-Null
    $destinationPath = Get-Folder
    if ("" -eq $destinationPath) {
        Clear-Host
        Write-Warning "You have not selected a destination folder!"
        Select-User
    }
    $destinationPath += "\${Folder_Name}"
    [string] $DestinationDisk = $destinationPath[0]
    $DestinationDisk += ":"
    if ($DestinationDisk -eq $Selected_Disk) { Clear-Host; Write-Warning "You cannot copy to the same drive. It causes a loop. Please select a different drive!"; Select-Disk }
    else { Copy-UserData }
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

function Copy-UserData {
    do {
        $confirm = Read-Host "Are you confirming that $Selected_User files will be copied to ${destinationPath} (Y/N)"
    } while ("y", "n" -notcontains $confirm )
    if ($confirm -eq "y") {
        robocopy "$sourcePath\Desktop\" "$destinationPath\Desktop" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
        robocopy "$sourcePath\Downloads\" "$destinationPath\Downloads" /s /e /mt:32 /r:0 /w:0 /xjd /XF *.tmp
        robocopy "$sourcePath\Documents\" "$destinationPath\Documents" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
        robocopy "$sourcePath\AppData\Local\Google\" "$destinationPath\Google" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
        Read-Host -Prompt "Press Enter to exit!"
        Exit
    }
    else { Clear-Host; Select-Action }
}
function Backup-Folder {
    function Select-Source{
    Write-Host "Please select the source folder:" -Backgroundcolor DarkCyan -ForeGroundColor White
    Timeout /t 1 | Out-Null
    $sourcePath = Get-Folder
    if ("" -eq $sourcePath) {
        Clear-Host
        Write-Warning "You have not selected a source folder!"
        Select-Source
    }
    return $sourcePath
    }
    function Select-Destination {
    Write-Host "Please select the destination folder:" -Backgroundcolor DarkGreen -ForeGroundColor White
    Timeout /t 1 | Out-Null
    $destinationPath = Get-Folder
    if ("" -eq $destinationPath) {
        Clear-Host
        Write-Warning "You have not selected a destination folder!"
        Select-Destination
    }
    return $destinationPath
    }
    $sourcePath = Select-Source
    $destinationPath = Select-Destination
    Copy-Folder($sourcePath, $destinationPath)
    exit
}
function Copy-Folder($path) {
    $source = $path[0]
    $destination = $path[1]
    do {
        $confirm = Read-Host "Are you confirming that $source files will be copied to ${destination} (Y/N)"
    } while ("y", "n" -notcontains $confirm )
    if ($confirm -eq "y") {
        robocopy "$source" "$destination" /s /e /mt:32 /r:0 /w:0 /xf /xn /xo /xjd *.tmp
        Read-Host -Prompt "Press Enter to exit!"
        Exit
    }
    else { Clear-Host; Select-Action }
}
Select-Action
}
catch [System.Management.Automation.ItemNotFoundException] {
    Write-Warning "An error has occurred! The cause of this may be that there is no user profile on the disk you have selected!"
    Select-Action
}
catch{
    Write-Warning "An unknown error has occurred!"
    exit
}
