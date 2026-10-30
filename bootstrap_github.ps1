# Bootstrap seven team branches and optionally invite collaborators.
# Run from project root in Windows PowerShell.
$ErrorActionPreference = "Stop"
$RepoOwner = "1anchay"
$RepoName = "uav-matlab-team-project"
$RepoFull = "$RepoOwner/$RepoName"

Write-Host "=== UAV MATLAB TEAM: 7 participants ===" -ForegroundColor Cyan
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git not found. Install Git for Windows."
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI not found. Install: winget install --id GitHub.cli"
}
& gh auth status *> $null
if ($LASTEXITCODE -ne 0) {
    & gh auth login
    if ($LASTEXITCODE -ne 0) { throw "GitHub authentication failed." }
}
if (-not (Test-Path ".git")) {
    & git init
    if ($LASTEXITCODE -ne 0) { throw "git init failed." }
    & git branch -M main
}
$name = (& git config user.name)
$email = (& git config user.email)
if ([string]::IsNullOrWhiteSpace($name)) {
    & git config user.name (Read-Host "Git author name")
}
if ([string]::IsNullOrWhiteSpace($email)) {
    & git config user.email (Read-Host "Email for Git commits")
}
& git add .
& git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    & git commit -m "Update UAV team project"
    if ($LASTEXITCODE -ne 0) { throw "git commit failed." }
}
& gh repo view $RepoFull *> $null
if ($LASTEXITCODE -ne 0) {
    & gh repo create $RepoFull --public --source . --remote origin --push
    if ($LASTEXITCODE -ne 0) { throw "Repository creation failed." }
} else {
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
    "team/arseniy-ground-station",
    "team/artem-flight-safety",
    "team/ivan-kasimov-energy"
)
foreach ($b in $branches) {
    & git show-ref --verify --quiet "refs/heads/$b"
    if ($LASTEXITCODE -ne 0) {
        & git branch $b main
        if ($LASTEXITCODE -ne 0) { throw "Cannot create $b" }
    }
    & git push -u origin $b
    if ($LASTEXITCODE -ne 0) { throw "Cannot push $b" }
}
$members = @(
    "Ernesto Horserofl",
    "Ivan Zhivoglyadov",
    "Bodya Lemchenko",
    "Aleksandr Lzedzei",
    "Arseniy Terekhov",
    "Artem Puchkov",
    "Ivan Kasimov"
)
foreach ($m in $members) {
    $username = Read-Host "GitHub username for $m (Enter to skip)"
    if (-not [string]::IsNullOrWhiteSpace($username)) {
        & gh api --method PUT -H "Accept: application/vnd.github+json" "/repos/$RepoFull/collaborators/$username" -f permission=push *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Invitation sent: $m -> @$username" -ForegroundColor Green
        } else {
            Write-Host "Invitation failed: @$username" -ForegroundColor Red
        }
    }
}
Write-Host "Seven team branches ready: https://github.com/$RepoFull" -ForegroundColor Green
