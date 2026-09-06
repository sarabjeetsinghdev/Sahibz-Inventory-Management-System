# Release helper: steps 1-3 (branch -> upload allowed files -> push).
# Usage:  .\scripts\release.ps1 -Version 1.0.5-beta -Message "what changed"
# Then merge on GitHub, then run the "Release Windows build" workflow.
param(
  [Parameter(Mandatory = $true)][string]$Version,
  [string]$Message = ''
)
$ErrorActionPreference = 'Stop'

# 0. pubspec version must match (this is how you "tell" the version).
$pub = ((Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value).Trim()
if ($pub -ne $Version) {
  Write-Error "pubspec.yaml says '$pub' but you asked for '$Version'. Update pubspec.yaml first."
  exit 1
}

# 1. New branch.
$branch = "beta-$Version"
git rev-parse --verify $branch 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
  Write-Error "Branch '$branch' already exists. Delete it or pick another version."
  exit 1
}
git checkout -b $branch

# 2. Upload allowed files (.gitignore decides what is allowed).
git add -A
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
  Write-Host 'Nothing new to commit. Pushing branch only.'
} else {
  $msg = "Release $Version"
  if (-not [string]::IsNullOrWhiteSpace($Message)) { $msg += " - $Message" }
  git commit -m $msg
}
git push -u origin $branch

# 3. Merge link.
$url = ((git remote get-url origin).Trim())
if ($url -match 'github\.com[:/](.+?)(?:\.git)?$') {
  $slug = $Matches[1]
  Write-Host ''
  Write-Host 'Done. Now merge in your browser:'
  Write-Host "  https://github.com/$slug/compare/main...$branch?expand=1"
  Write-Host ''
  Write-Host 'After merging, run the "Release Windows build" workflow from main.'
} else {
  Write-Host 'Pushed. Merge the branch on GitHub, then run the release workflow.'
}
