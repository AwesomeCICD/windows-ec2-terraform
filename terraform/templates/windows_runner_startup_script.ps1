
<powershell>

# Set error handling preference to continue on errors
$ErrorActionPreference = "Continue"

# Define the platform architecture
$platform = "windows/amd64"

# Set the HOST_IP environment variable to the machine's IPv4 address
$env:HOST_IP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress

# Install Chocolatey (package manager for Windows)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Disable Windows Firewall for all profiles
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False

# Uninstall Windows Defender
Uninstall-WindowsFeature -Name Windows-Defender

# Create a directory for CircleCI
New-Item -Path "C:\CircleCI" -ItemType Directory
$installDirPath = "C:\CircleCI"

# Navigate to the newly created directory
cd C:\CircleCI

# Set the version of CircleCI runner to 'current'
$runnerVersion = "current"

# Fetch available agents and download the CircleCI runner
$availableAgents = (Invoke-WebRequest "https://circleci-binary-releases.s3.amazonaws.com/circleci-runner/manifest.json" -UseBasicParsing).Content.Trim() | ConvertFrom-Json
$agentURL = $availableAgents.releases.$runnerVersion.windows.amd64.url
$agentHash = $availableAgents.releases.$runnerVersion.windows.amd64.sha256
$agentFile = $agentURL.Split("/")[-1]

# Download the CircleCI runner binary
Invoke-WebRequest $agentURL -OutFile $agentFile -UseBasicParsing

# Verify the downloaded file's checksum
if ((Get-FileHash "$agentFile" -Algorithm SHA256).Hash.ToLower() -ne $agentHash.ToLower()) {
    throw "Invalid checksum for CircleCI Machine Runner, please try download again"
}

# Extract the runner binary
tar -zxvf $agentFile
del $agentFile

# Scheduled Task parameters
$scheduledTaskName = "CircleCI-Runner-Windows"
$exePath = "C:\CircleCI\circleci-runner.exe"
$configPath = "C:\CircleCI\runner-agent-config.yaml"
$repetitionInterval = (New-TimeSpan -Minutes 3)
$repetitionDuration = (New-TimeSpan -Days (365 * 20)) # Repeat for 20 years

# Create the scheduled task trigger and action
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $repetitionInterval -RepetitionDuration $repetitionDuration
$taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "& $exePath machine --config $configPath"
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$STSet = New-ScheduledTaskSettingsSet -Compatibility "Win8"

# Register the scheduled task
Register-ScheduledTask $scheduledTaskName -Action $taskAction -Trigger $trigger -Principal $principal -Settings $STSet 

# Get details about the scheduled task
Get-ScheduledTaskInfo -TaskName $scheduledTaskName

# Create the working directory and configure the runner agent
New-Item -Name Workdir -ItemType Directory
@"
api:
  auth_token: "${win_runner_token}"
  url: https://${circle_server_endpoint}
runner:
  name: "$env:HOST_IP"
  mode: single-task
  working_directory: "./Workdir"
  cleanup_working_directory: true
logging:
  file: circleci-runner.log
"@ -replace "([^`r])`n", "`$1`r`n" | Out-File runner-agent-config.yaml -Encoding ascii

# Install Chocolatey (as a prerequisite for the next steps)
Write-Host "Installing Chocolatey as a prerequisite"
Invoke-Expression ((Invoke-WebRequest "https://chocolatey.org/install.ps1" -UseBasicParsing).Content)
Write-Host ""

# Install Git (required for running CircleCI jobs)
Write-Host "Installing Git, which is required to run CircleCI jobs"
choco install -y git --params "/GitAndUnixToolsOnPath"
Write-Host ""

# Install Gzip (required for running CircleCI jobs)
Write-Host "Installing Gzip, which is required to run CircleCI jobs"
choco install -y gzip
Write-Host ""

# Install Visual Studio 2022 Community Edition
Write-Host "Install Visual Studio 2022 Community"
choco install -y visualstudio2022community
Write-Host ""

# Install Google Chrome
Write-Host "Install Google Chrome"
choco install -y googlechrome
Write-Host ""

# Install Git SCM
Write-Host "Install Git SCM as well"
choco install - y git
Write-Host ""

# Install Notepad++
Write-Host "Install Notepad++"
choco install -y notepadplusplus
Write-Host ""

# Update Firewall Rules to allow RDP, SSH, and a custom port
Write-Host "Update Firewall Rules..."
New-NetFirewallRule -DisplayName "Allow RDP (Port 3389)" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow
New-NetFirewallRule -DisplayName "Allow SSH (Port 22)" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
New-NetFirewallRule -DisplayName "Allow Port 54782" -Direction Inbound -Protocol TCP -LocalPort 54782 -Action Allow

# Set services to start automatically
Set-Service -Name TermService -StartupType 'Automatic'
Set-Service -Name sshd -StartupType 'Automatic'

# Check if OpenSSH is installed and install it if necessary
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0


</powershell>
