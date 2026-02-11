param(
    [string]$Directory = "",
    [string]$CommitMessage = ""
)

function Write-Success { Write-Host $args[0] -ForegroundColor Green }
function Write-Info    { Write-Host $args[0] -ForegroundColor Cyan }
function Write-Warn    { Write-Host $args[0] -ForegroundColor Yellow }
function Write-Err     { Write-Host $args[0] -ForegroundColor Red }

Clear-Host
Write-Info "=== Git Automation Script ==="
Write-Host ""

# Check Git
Write-Info "Checking Git..."
try {
    git --version | Out-Null
}
catch {
    Write-Err "Git is not installed!"
    exit 1
}

Write-Success "Git is installed."
Write-Host ""

# Set directory
if (-not $Directory) {
    $Directory = Get-Location
}

if (-not (Test-Path $Directory)) {
    Write-Err "Directory not found."
    exit 1
}

Set-Location $Directory
Write-Success "Using directory: $Directory"
Write-Host ""

# Initialize if needed
git rev-parse --git-dir 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Not a git repo. Initializing..."
    git init | Out-Null
    git branch -M main | Out-Null
    Write-Success "Repository initialized."
}
else {
    Write-Success "Already a git repository."
}

Write-Host ""

# Stage and commit
$status = git status --porcelain
if ($status) {
    git add .
    Write-Success "Changes staged."

    if (-not $CommitMessage) {
        $CommitMessage = "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }

    git commit -m "$CommitMessage"
    Write-Success "Commit created."
}
else {
    Write-Info "No changes to commit."
}

Write-Host ""

# Push if remote exists
$remoteUrl = git remote get-url origin 2>$null
if ($remoteUrl) {
    $branch = git rev-parse --abbrev-ref HEAD
    Write-Info "Pushing to remote..."
    git push -u origin $branch
}
else {
    Write-Warn "No remote configured."
}

Write-Host ""
Write-Success "Done."
