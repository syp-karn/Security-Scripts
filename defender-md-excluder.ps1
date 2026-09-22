param(
    [string]$VaultPaths,

    [switch]$Help
)

$script_name = Split-Path -Leaf $MyInvocation.MyCommand.Path
$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$log_dir = Join-Path $script_dir "logs"
$log_file = Join-Path $log_dir "activity.log"

function show-help {
    Write-Host ""
    Write-Host "defender-md-excluder.ps1" -ForegroundColor Cyan
    Write-Host "Recursively adds individual .md files to Microsoft Defender exclusions."
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\$script_name -VaultPaths `"PATH1;PATH2;PATH3`""
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  .\$script_name -VaultPaths `"C:\Notes\Dir1;C:\Notes\Dir2`""
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -VaultPaths    Semicolon-separated directories to scan."
    Write-Host ""
    Write-Host "Behavior:"
    Write-Host "  - Adds only individual .md files to Defender exclusions."
    Write-Host "  - Does not exclude the supplied directories themselves."
    Write-Host ""
}

if ([string]::IsNullOrWhiteSpace($VaultPaths)) {
    show-help
    exit 0
}

# Check for administrator privileges.
$current_identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($current_identity)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "ERROR: Administrator privileges are required." -ForegroundColor Red
    Write-Host ""
    Write-Host "Open PowerShell as Administrator and run the script again."
    Write-Host ""
    exit 1
}

New-Item -ItemType Directory -Path $log_dir -Force | Out-Null

$vault_paths = $VaultPaths -split ';' |
    ForEach-Object { $_.Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

if ($vault_paths.Count -eq 0) {
    Write-Host "ERROR: No valid paths were supplied." -ForegroundColor Red
    show-help
    exit 1
}

$current_exclusions = @(
    (Get-MpPreference).ExclusionPath
)

$md_files = @()

foreach ($path in $vault_paths) {

    if (-not (Test-Path $path -PathType Container)) {
        Write-Host "WARNING: Directory not found: $path" -ForegroundColor Yellow

        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - WARNING: Directory not found: $path" |
            Add-Content $log_file

        continue
    }

    Write-Host "Scanning: $path"

    $files = Get-ChildItem `
        -Path $path `
        -Filter "*.md" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue

    $md_files += $files
}

$added = 0
$already_excluded = 0
$failed = 0

foreach ($file in $md_files) {

    $full_path = $file.FullName

    if ($current_exclusions -contains $full_path) {
        $already_excluded++
        continue
    }

    try {
        Add-MpPreference `
            -ExclusionPath $full_path `
            -ErrorAction Stop

        $current_exclusions += $full_path
        $added++

        Write-Host "Added: $full_path"
    }
    catch {
        $failed++

        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - FAILED: $full_path - $($_.Exception.Message)" |
            Add-Content $log_file

        Write-Host "Failed: $full_path" -ForegroundColor Red
    }
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$log_entry = "$timestamp - scanned: $($md_files.Count) | already excluded: $already_excluded | newly excluded: $added | failed: $failed"

$log_entry | Add-Content $log_file

Write-Host ""
Write-Host "Completed." -ForegroundColor Green
Write-Host $log_entry
Write-Host ""