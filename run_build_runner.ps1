# Main project directory
$mainProjectDir = Get-Location

# Function to run build_runner commands
function Invoke-BuildRunner {
    param (
        [string]$dir,
        [string]$name,
        [string]$repo
    )

    if (!(Test-Path -Path $dir)) {
        git clone $repo
    }

    Write-Host "Processing $name at $dir" -ForegroundColor Cyan
    Set-Location $dir

    Write-Host "Running 'flutter pub get' for $name" -ForegroundColor Green
    flutter pub get

    Write-Host "Running 'flutter pub upgrade' for $name" -ForegroundColor Green
    flutter pub upgrade

    Write-Host "Running 'dart run build_runner clean' for $name" -ForegroundColor Green
    dart run build_runner clean

    Write-Host "Running 'dart run build_runner build --delete-conflicting-outputs' for $name" -ForegroundColor Green
    dart run build_runner build --delete-conflicting-outputs

    Write-Host "Running 'flutter clean' for $name" -ForegroundColor Green
    flutter clean

    Set-Location ..
}

# Extract submodule paths and repositories from .gitmodules
$submodulePaths = @()

# Get submodule names (paths)
$submoduleNameKeys = git config --file .gitmodules --name-only --get-regexp submodule | ForEach-Object {
    if ($_ -match "^submodule\.(.*?)\.path$") {
        $Matches[1]
    }
} | Where-Object { $PSItem } # Filter out empty matches

foreach ($submoduleName in $submoduleNameKeys) {
    $submodulePath = git config --file .gitmodules --get "submodule.$submoduleName.path"
    $submoduleRepo = git config --file .gitmodules --get "submodule.$submoduleName.url"

    # Create custom object for each submodule
    $submoduleObject = [PSCustomObject]@{
        name = $submodulePath
        repo = $submoduleRepo
    }
    $submodulePaths += $submoduleObject
}

# Run build_runner for each submodule (modified to use object properties)
foreach ($submodule in $submodulePaths) {
    $submodulePath = Join-Path -Path $mainProjectDir -ChildPath $submodule.name
    Invoke-BuildRunner $submodulePath "submodule $($submodule.name)" $submodule.repo
}

# Run build_runner for the main project
Invoke-BuildRunner $mainProjectDir "main project"

# Clean and get dependencies for the main project again
Set-Location $mainProjectDir
Write-Host "Running 'flutter clean' for the main project" -ForegroundColor Yellow
flutter clean
Write-Host "Running 'flutter pub get' for the main project" -ForegroundColor Yellow
flutter pub get
