# Creates one shared PUBLIC GitHub repository for the MATLAB/Simulink UAV project.
# It pushes main, creates one branch per team member, and can invite collaborators.
# Run this script from the project root in Windows PowerShell.

$ErrorActionPreference = "Stop"
$RepoOwner = "1anchay"
$RepoName  = "uav-matlab-team-project"
$RepoFull  = "$RepoOwner/$RepoName"

Write-Host "=== UAV MATLAB TEAM: GitHub bootstrap ===" -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git was not found. Install Git for Windows and run this script again."
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI (gh) was not found." -ForegroundColor Yellow
    Write-Host "Install it with: winget install --id GitHub.cli" -ForegroundColor Yellow
    throw "GitHub CLI is required."
}

& gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "GitHub login is required. Starting gh auth login..." -ForegroundColor Yellow
    & gh auth login
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub login was not completed."
    }
}

if (-not (Test-Path ".git")) {
    & git init
    if ($LASTEXITCODE -ne 0) { throw "git init failed." }
    & git branch -M main
}

$name = (& git config user.name)
$email = (& git config user.email)

if ([string]::IsNullOrWhiteSpace($name)) {
    $name = Read-Host "Git author name (example: Ivan Zhivoglyadov)"
    & git config user.name "$name"
}

if ([string]::IsNullOrWhiteSpace($email)) {
    $email = Read-Host "Email for Git commits"
    & git config user.email "$email"
}

& git add .
& git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    & git commit -m "Initial MATLAB UAV team project"
    if ($LASTEXITCODE -ne 0) { throw "Initial git commit failed." }
}

& gh repo view $RepoFull *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating PUBLIC repository $RepoFull ..." -ForegroundColor Green
    & gh repo create $RepoFull --public --source . --remote origin --push
    if ($LASTEXITCODE -ne 0) { throw "GitHub repository creation failed." }
} else {
    Write-Host "Repository already exists: $RepoFull" -ForegroundColor Yellow
    $origin = (& git remote get-url origin 2>$null)
    if ([string]::IsNullOrWhiteSpace($origin)) {
        & git remote add origin "https://github.com/$RepoFull.git"
    }
    & git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw "Push to main failed." }
}

$branches = @(
    "team/ernesto-navigation",
    "team/ivan-flight-control",
    "team/bodya-route-planning",
    "team/aleksandr-object-detection",
    "team/arseniy-ground-station"
)

foreach ($branch in $branches) {
    & git show-ref --verify --quiet "refs/heads/$branch"
    if ($LASTEXITCODE -ne 0) {
        & git branch $branch main
        if ($LASTEXITCODE -ne 0) { throw "Could not create branch $branch." }
    }
    & git push -u origin $branch
    if ($LASTEXITCODE -ne 0) { throw "Could not push branch $branch." }
}

Write-Host "" 
Write-Host "Team branches are ready." -ForegroundColor Cyan

$members = @(
    "Ernesto Horserofl",
    "Ivan Zhivoglyadov",
    "Bodya Lemchenko",
    "Aleksandr Lzedzei",
    "Arseniy Terekhov"
)

foreach ($member in $members) {
    $username = Read-Host "GitHub username for $member (press Enter to skip)"
    if (-not [string]::IsNullOrWhiteSpace($username)) {
        & gh api --method PUT -H "Accept: application/vnd.github+json" "/repos/$RepoFull/collaborators/$username" -f permission=push *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Invitation sent: $member -> @$username" -ForegroundColor Green
        } else {
            Write-Host "Could not invite @$username. Check the username and repository permissions." -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "DONE." -ForegroundColor Green
Write-Host "Repository: https://github.com/$RepoFull"
Write-Host "Each member should accept the GitHub invitation and work in their own branch."
