# PowerShell script to create prod, stage, and dev branches from main
# This script assumes you're starting from the main branch

$ErrorActionPreference = "Stop"

Write-Host "=== Creating Environment Branches ===" -ForegroundColor Green
Write-Host ""

# Check if we're in a git repository
try {
    $null = git rev-parse --git-dir 2>$null
} catch {
    Write-Host "Error: Not a git repository" -ForegroundColor Red
    Write-Host "Initialize git first with: git init"
    exit 1
}

# Get the default branch (main or master)
$defaultBranch = "main"
try {
    $remoteHead = git symbolic-ref refs/remotes/origin/HEAD 2>$null
    if ($remoteHead) {
        $defaultBranch = $remoteHead -replace '^refs/remotes/origin/', ''
    }
} catch {
    # Default to main if we can't determine
    $defaultBranch = "main"
}

# Check if main/master exists locally, if not try to fetch
$branchExists = git show-ref --verify --quiet "refs/heads/$defaultBranch" 2>$null
if (-not $branchExists) {
    Write-Host "Default branch '$defaultBranch' not found locally" -ForegroundColor Yellow
    Write-Host "Fetching from remote..."
    try {
        git fetch origin 2>$null
    } catch {
        Write-Host "No remote configured, will create from current branch"
    }
    
    # Try to checkout main from remote
    $remoteBranchExists = git show-ref --verify --quiet "refs/remotes/origin/$defaultBranch" 2>$null
    if ($remoteBranchExists) {
        git checkout -b $defaultBranch "origin/$defaultBranch" 2>$null
    }
}

# Get current branch
$currentBranch = git branch --show-current 2>$null
if (-not $currentBranch) {
    $currentBranch = git rev-parse --abbrev-ref HEAD
}

# If we're not on main, switch to it or create it
if ($currentBranch -ne $defaultBranch) {
    $branchExists = git show-ref --verify --quiet "refs/heads/$defaultBranch" 2>$null
    if ($branchExists) {
        Write-Host "Switching to $defaultBranch branch..."
        git checkout $defaultBranch
    } else {
        Write-Host "Creating $defaultBranch branch from current branch ($currentBranch)" -ForegroundColor Yellow
        git checkout -b $defaultBranch
    }
}

# Branches to create
$branches = @("dev", "stage", "prod")

Write-Host "Creating branches from $defaultBranch:"
foreach ($branch in $branches) {
    $branchExists = git show-ref --verify --quiet "refs/heads/$branch" 2>$null
    if ($branchExists) {
        Write-Host "  Branch '$branch' already exists, skipping..." -ForegroundColor Yellow
    } else {
        Write-Host "  Creating branch: $branch"
        git checkout -b $branch
        git checkout $defaultBranch
        Write-Host "  ✓ Created branch: $branch" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== Branches Created Successfully ===" -ForegroundColor Green
Write-Host ""
Write-Host "Available branches:"
git branch -a
Write-Host ""
Write-Host "To push branches to remote:"
Write-Host "  git push -u origin dev"
Write-Host "  git push -u origin stage"
Write-Host "  git push -u origin prod"

