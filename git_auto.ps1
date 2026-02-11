param(
    [string]$Directory = "",
    [string]$CommitMessage = ""
)

# ----------- Color Functions -----------
function Write-Success { Write-Host $args[0] -ForegroundColor Green }
function Write-Info    { Write-Host $args[0] -ForegroundColor Cyan }
function Write-Warn    { Write-Host $args[0] -ForegroundColor Yellow }
function Write-Err     { Write-Host $args[0] -ForegroundColor Red }

Clear-Host
Write-Info "========== Git Automation Script =========="
Write-Host ""

# ----------- Check Git Installation -----------
Write-Info "[1] Checking Git..."
try {
    git --version | Out-Null
}
catch {
    Write-Err "Git is not installed!"
    exit 1
}
Write-Success "Git is installed."
Write-Host ""

# ----------- Set Working Directory -----------
if (-not $Directory) {
    $Directory = Get-Location
}

if (-not (Test-Path $Directory)) {
    Write-Err "Directory not found: $Directory"
    exit 1
}

Set-Location $Directory
Write-Success "Using directory: $Directory"
Write-Host ""

# ----------- Initialize Repo if Needed -----------
Write-Info "[2] Checking repository..."
git rev-parse --git-dir 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Warn "Not a Git repository."
    $initChoice = Read-Host "Initialize repository? (Y/N) [Y]"
    if ($initChoice -notmatch "^[Nn]") {
        git init | Out-Null
        git branch -M main | Out-Null
        Write-Success "Repository initialized."
    }
    else {
        Write-Err "Cannot continue without repository."
        exit 1
    }
}
else {
    Write-Success "Repository exists."
}

Write-Host ""

# ----------- Stage Changes -----------
Write-Info "[3] Checking changes..."
$status = git status --porcelain

if ($status) {
    git add .
    Write-Success "Changes staged."

    # Ask for commit message if not provided
    if (-not $CommitMessage) {
        $defaultMsg = "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        $inputMsg = Read-Host "Enter commit message [$defaultMsg]"
        if ($inputMsg) {
            $CommitMessage = $inputMsg
        }
        else {
            $CommitMessage = $defaultMsg
        }
    }

    git commit -m "$CommitMessage"
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Commit created: $CommitMessage"
    }
    else {
        Write-Err "Commit failed."
        exit 1
    }
}
else {
    Write-Info "No changes to commit."
}

Write-Host ""

# ----------- Check Remote -----------
Write-Info "[4] Checking remote..."
$remoteUrl = git remote get-url origin 2>$null

if (-not $remoteUrl) {
    Write-Warn "No remote configured."
    $repoUrl = Read-Host "Enter GitHub repository URL"

    if ($repoUrl) {
        git remote add origin $repoUrl
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Remote added successfully."
            $remoteUrl = $repoUrl
        }
        else {
            Write-Err "Failed to add remote."
            exit 1
        }
    }
    else {
        Write-Err "Remote URL required to push."
        exit 1
    }
}
else {
    Write-Success "Remote exists: $remoteUrl"
}

Write-Host ""

# ----------- Push to Remote -----------
Write-Info "[5] Pushing to remote..."
$currentBranch = git rev-parse --abbrev-ref HEAD

git push -u origin $currentBranch

if ($LASTEXITCODE -ne 0) {
    Write-Warn "Push failed. Attempting pull --rebase..."
    git pull origin $currentBranch --rebase
    git push -u origin $currentBranch

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Push successful after rebase."
    }
    else {
        Write-Err "Push failed. Manual intervention required."
        exit 1
    }
}
else {
    Write-Success "Push successful."
}

Write-Host ""
Write-Success "============= Completed ============="
Write-Info "Directory : $Directory"
Write-Info "Branch    : $currentBranch"
Write-Info "Remote    : $remoteUrl"
Write-Host ""
