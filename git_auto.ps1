param(
    [string]$Directory = "",
    [string]$CommitMessage = ""
)

# ---------- Color Functions ----------
function Write-Success { Write-Host $args[0] -ForegroundColor Green }
function Write-Info    { Write-Host $args[0] -ForegroundColor Cyan }
function Write-Warn    { Write-Host $args[0] -ForegroundColor Yellow }
function Write-Err     { Write-Host $args[0] -ForegroundColor Red }

Clear-Host
Write-Info "=========== Git Automation Script ==========="
Write-Host ""

# ---------- Check Git ----------
Write-Info "[1] Checking Git installation..."
try {
    git --version | Out-Null
}
catch {
    Write-Err "Git is not installed!"
    exit 1
}
Write-Success "Git is installed."
Write-Host ""

# ---------- Working Directory ----------
Write-Info "[2] Setting working directory..."

if (-not $Directory) {
    $Directory = Get-Location
    Write-Info "Current directory: $Directory"
    $dirChoice = Read-Host "Use this directory? (Y/N) [Y]"
    if ($dirChoice -match "^[Nn]") {
        $Directory = Read-Host "Enter full path"
    }
}

if (-not (Test-Path $Directory)) {
    Write-Err "Directory not found."
    exit 1
}

Set-Location $Directory
Write-Success "Using directory: $Directory"
Write-Host ""

# ---------- Initialize Repo ----------
Write-Info "[3] Checking repository..."
git rev-parse --git-dir 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Warn "Not a Git repository."
    $initChoice = Read-Host "Initialize repository? (Y/N) [Y]"
    if ($initChoice -notmatch "^[Nn]") {
        git init | Out-Null
        git branch -M main | Out-Null
        Write-Success "Repository initialized with branch 'main'."
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

# ---------- Stage & Commit ----------
Write-Info "[4] Checking for changes..."
$status = git status --porcelain

if ($status) {
    git add .
    Write-Success "Changes staged."

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

# ---------- Remote Configuration ----------
Write-Info "[5] Checking remote..."
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
        Write-Err "Remote URL required."
        exit 1
    }
}
else {
    Write-Success "Remote found: $remoteUrl"
}
Write-Host ""

# ---------- Branch Selection ----------
Write-Info "[6] Branch selection..."

$currentBranch = git rev-parse --abbrev-ref HEAD
Write-Info "Current branch: $currentBranch"

$branchChoice = Read-Host "Enter branch to push (default: main)"

if (-not $branchChoice) {
    $branchChoice = "main"
}

# Check if branch exists
git show-ref --verify --quiet refs/heads/$branchChoice

if ($LASTEXITCODE -ne 0) {
    Write-Warn "Branch '$branchChoice' does not exist."
    $createChoice = Read-Host "Create and switch to '$branchChoice'? (Y/N) [Y]"

    if ($createChoice -notmatch "^[Nn]") {
        git checkout -b $branchChoice
        Write-Success "Switched to new branch: $branchChoice"
    }
    else {
        Write-Err "Cannot continue without valid branch."
        exit 1
    }
}
else {
    git checkout $branchChoice
    Write-Success "Switched to branch: $branchChoice"
}

Write-Host ""

# ---------- Confirm Push ----------
$confirmPush = Read-Host "Push to '$branchChoice'? (Y/N) [Y]"

if ($confirmPush -notmatch "^[Nn]") {

    git push -u origin $branchChoice

    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Push failed. Attempting pull --rebase..."
        git pull origin $branchChoice --rebase
        git push -u origin $branchChoice
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Push successful to $branchChoice"
    }
    else {
        Write-Err "Push failed. Manual intervention required."
        exit 1
    }
}
else {
    Write-Info "Push cancelled."
}

Write-Host ""
Write-Success "=========== Completed Successfully ==========="
Write-Info "Directory : $Directory"
Write-Info "Branch    : $branchChoice"
Write-Info "Remote    : $remoteUrl"
Write-Host ""
