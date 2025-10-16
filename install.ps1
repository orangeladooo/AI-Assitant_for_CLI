# --- AI CLI Assistant Setup for PowerShell ---

Write-Host "--- Starting AskAI CLI Setup (Windows/PowerShell) ---" -ForegroundColor Green

# 1. Define the full path to the Python script (Uses the script's directory)
# Note: PSScriptRoot is only available when run with .\install.ps1
$PythonScriptPath = "$PSScriptRoot\cli_assistant.py"

if (-not (Test-Path $PythonScriptPath)) {
    Write-Host "Error: cli_assistant.py not found at $PythonScriptPath" -ForegroundColor Red
    exit 1
}

# 2. Get the PowerShell profile path
$ProfilePath = $PROFILE

# 3. Create the profile file if it doesn't exist
if (-not (Test-Path $ProfilePath)) {
    New-Item -Path $ProfilePath -ItemType File -Force | Out-Null
}

# 4. The PowerShell function to be injected (with command extraction fix)
$ShellFunction = @"
# --- AI CLI Assistant (askai) ---
function askai {
    param(
        [Parameter(Mandatory=`$true)]
        [string[]]`$Request
    )
    
    `$fullRequest = `$Request -join " "
    `$scriptPath = "$PythonScriptPath" # Path set during installation

    # 1. Run the Python script and capture its output
    `$output = python `$scriptPath `$fullRequest
    
    # 2. Check for the special execution token for 'cd'
    if (`$output -match "__EXEC_COMMAND__") {
        
        # --- FIX: Robustly extract the command after the special tag ---
        `$execCommand = (`$output | Select-String -Pattern '__EXEC_COMMAND__:' | ForEach-Object { 
            `$_.Line.Split(':', 2)[1].Trim() 
        })
        # -------------------------------------------------------------
        
        # Print non-command output
        `$output -notmatch "__EXEC_COMMAND__"
        
        # 3. Execute the command directly in the current session
        if (`$execCommand -ne `$null -and `$execCommand -ne "") {
            Invoke-Expression `$execCommand
        }
        
    } else {
        # 4. Print all output
        Write-Output `$output
    }
}
# --------------------------------
"@

# 5. Check if the function is already installed
if ((Get-Content $ProfilePath) -match "function askai {") {
    Write-Host "Function 'askai' already exists in your PowerShell profile. Please remove the old function manually and re-run the installer." -ForegroundColor Yellow
} else {
    Add-Content -Path $ProfilePath -Value $ShellFunction
    Write-Host "✅ 'askai' is installed! Open a new PowerShell window to start." -ForegroundColor Green
    Write-Host "Usage: askai 'your request in quotes'" -ForegroundColor Cyan
}