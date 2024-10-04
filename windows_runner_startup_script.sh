
<powershell>

$ErrorActionPreference = "Continue" 
$platform = "windows/amd64"

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))


Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False
Uninstall-WindowsFeature -Name Windows-Defender

New-Item -Path "C:\CircleCI" -ItemType Directory
$installDirPath = "C:\CircleCI"

cd C:\CircleCI

$runnerVersion = "current"
$availableAgents = (Invoke-WebRequest "https://circleci-binary-releases.s3.amazonaws.com/circleci-runner/manifest.json" -UseBasicParsing).Content.Trim() | ConvertFrom-Json
$agentURL = $availableAgents.releases.$runnerVersion.windows.amd64.url
$agentHash = $availableAgents.releases.$runnerVersion.windows.amd64.sha256
$agentFile = $agentURL.Split("/")[-1]

Invoke-WebRequest $agentURL -OutFile $agentFile -UseBasicParsing
if ((Get-FileHash "$agentFile" -Algorithm SHA256).Hash.ToLower() -ne $agentHash.ToLower()) {
    throw "Invalid checksum for CircleCI Machine Runner, please try download again"
}

tar -zxvf $agentFile
del $agentFile

 # Define Scheduled Task Name
$scheduledTaskName = "CircleCI-Runner-Windows"
# Circle Binary Path
$exePath = "C:\CircleCI\circleci-runner.exe"
# Circle Runner Agent Config Path
$configPath = "C:\CircleCI\runner-agent-config.yaml"
# Repeat Task every 3 minutes
$repetitionInterval = (New-TimeSpan -Minutes 3)
# Repeat for the next 20 years
$repetitionDuration = (New-TimeSpan -Days (365 * 20))
# Create the Scheduled Task
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $repetitionInterval -RepetitionDuration $repetitionDuration
# Create the Scheduled Task Action
$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "& $exePath machine --config $configPath"
# Use the system account instead of creating a user and dealing with random passwords
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
# Ensure that the Scheduled Task is compatible with Windows Server 2022
$STSet = New-ScheduledTaskSettingsSet -Compatibility "Win8"
# Register the task with all the parameters
Register-ScheduledTask $scheduledTaskName -Action $taskAction -Trigger $trigger -Principal $principal -Settings $STSet 

Get-ScheduledTaskInfo -TaskName $scheduledTaskName

New-Item -Name Workdir -ItemType Directory
@"
api:
  auth_token: "${win_runner_token}"
  url: https://runner.circleci.com
runner:
  name: "$env:COMPUTERNAME"
  mode: single-task
  working_directory: "./Workdir"
  cleanup_working_directory: true
logging:
  file: circleci-runner.log
"@ -replace "([^`r])`n", "`$1`r`n" | Out-File runner-agent-config.yaml -Encoding ascii


# Install Chocolatey
Write-Host "Installing Chocolatey as a prerequisite"
Invoke-Expression ((Invoke-WebRequest "https://chocolatey.org/install.ps1" -UseBasicParsing).Content)
Write-Host ""

# Install Git
Write-Host "Installing Git, which is required to run CircleCI jobs"
choco install -y git --params "/GitAndUnixToolsOnPath"
Write-Host ""

# Install Gzip
Write-Host "Installing Gzip, which is required to run CircleCI jobs"
choco install -y gzip
Write-Host ""

New-NetFirewallRule -DisplayName "Allow RDP (Port 3389)" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow

# Enable port 22 for SSH
New-NetFirewallRule -DisplayName "Allow SSH (Port 22)" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow

# Enable port 54782
New-NetFirewallRule -DisplayName "Allow Port 54782" -Direction Inbound -Protocol TCP -LocalPort 54782 -Action Allow

Set-Service -Name TermService -StartupType 'Automatic'
Set-Service -Name sshd -StartupType 'Automatic'

Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
# Install the OpenSSH Client
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Install the OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0



</powershell>
