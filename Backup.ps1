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
        if ($Disk_Index -eq "") { $Disk_Index = -1 }
    } while ($D_Index_List -notcontains $Disk_Index)
    $script:Selected_Disk = $disk[$Disk_Index]
    Clear-Host
    Select-User
#    Write-Host "You chose the $Selected_Disk drive." -Backgroundcolor DarkGreen -ForeGroundColor White
}
function Start-Copy {
    param(
        [string[]]$confirm
    )
    do {
        $confirm = Read-Host "Are you confirming that $Selected_User files will be copied to ${destinationPath}? (Y/N)"
    } while ("y", "n" -notcontains $confirm )
    if ($confirm -eq "y") {
        robocopy "$sourcePath\Desktop\" "$destinationPath\Desktop" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
        robocopy "$sourcePath\Downloads\" "$destinationPath\Downloads" /s /e /mt:32 /r:0 /w:0 /xjd /XF *.tmp
        robocopy "$sourcePath\Documents\" "$destinationPath\Documents" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
        robocopy "$sourcePath\AppData\Local\Google\" "$destinationPath\Google" /s /e /mt:32 /r:0 /w:0 /XF /xjd *.tmp
    }
    else { Clear-Host; Select-User }
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
        if ($User_Index -eq "") { $User_Index = -1 }
    } while ($U_Index_List -notcontains $User_Index )
    $Selected_User = $Users[$User_Index]
    $sourcePath = "$Selected_Disk\Users\${Selected_User}"
    $Folder_Name = Get-Date -Format "dd.MM.yyyy"
    $Folder_Name += "_${Selected_User}"
    Write-Host "Please select the destination folder:" -Backgroundcolor DarkCyan -ForeGroundColor White
    Timeout /t 1 | Out-Null
    $destinationPath = Get-Folder
    $destinationPath += "\${Folder_Name}"
    Start-Copy
}
Function Get-Folder($initialDirectory="")
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select the destination folder:"
    $foldername.ShowNewFolderButton = $True
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}
Select-Disk