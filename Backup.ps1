Clear-Host
Add-Type -AssemblyName System.Windows.Forms
function Select-Disk {
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
    $Users = @(Get-ChildItem -Path "${Selected_Disk}\Users\" -Name)
    $U_Index_List = @()
    Write-Host "########### USER LIST IN $Selected_Disk ###########" -Backgroundcolor DarkCyan -ForeGroundColor White
    for ($i = 0; $i -le $Users.length - 1; $i++) {
        $Users_List = "${i}) "
        $Users_List += $Users[$i]
        $U_Index_List += @($i)
        Write-Host $Users_List -Backgroundcolor DarkMagenta -ForeGroundColor White
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
    else { Start-Copy }
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
    $OpenFileDialog.Title = "Select the destination folder"
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

function Start-Copy {
    param(
        [string[]]$confirm
    )
    do {
        $confirm = Read-Host "Are you confirming that $Selected_User files will be copied to ${destinationPath} (Y/N)"
    } while ("y", "n" -notcontains $confirm )
    if ($confirm -eq "y") {
        robocopy "$sourcePath\Desktop\" "$destinationPath\Desktop" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
        robocopy "$sourcePath\Downloads\" "$destinationPath\Downloads" /s /e /mt:32 /r:0 /w:0 /xjd /XF *.tmp
        robocopy "$sourcePath\Documents\" "$destinationPath\Documents" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
        robocopy "$sourcePath\AppData\Local\Google\" "$destinationPath\Google" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
        Read-Host -Prompt "Press Enter to exit!"
    }
    else { Clear-Host; Select-User }
}
Select-Disk
