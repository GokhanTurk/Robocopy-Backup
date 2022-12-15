Clear-Host
Add-Type -AssemblyName System.Windows.Forms
function Select-Disk {
    $disk = @(get-wmiobject win32_logicaldisk -filter "drivetype=3" | select-object -expandproperty name)
    $D_Index_List = @()
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
    $Selected_Disk = $disk[$Disk_Index]
    Clear-Host
    Write-Output "You chose the $Selected_Disk drive."
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
    for ($i = 0; $i -le $Users.length - 1; $i++) {
        $Users_List = "${i}) "
        $Users_List += $Users[$i]
        $U_Index_List += @($i)
        Write-Host $Users_List
    }
    do {
        $User_Index = Read-Host "Select the username"
        if ($User_Index -eq "") { $User_Index = -1 }
    } while ($U_Index_List -notcontains $User_Index )
    $Selected_User = $Users[$User_Index]
    $sourcePath = "$Selected_Disk\Users\${Selected_User}"
    $Folder_Name = Get-Date -Format "dd.MM.yyyy"
    $Folder_Name += "_${Selected_User}"
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('MyComputer') }
    $null = $FileBrowser.ShowDialog()
    Write-Output $FileBrowser
    #    $destinationPath = Read-Host "Enter the destination path"
#    $destinationPath += $Folder_Name
#    $destinationPath = "C:\YEDEKLER\${Folder_Name}"
    Start-Copy
}

Select-Disk
Select-User
