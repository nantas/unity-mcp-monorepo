# AnkleBreaker Unity MCP Plugin Snapshot Installer (Windows)
# Usage: .\scripts\install-plugin.ps1 -UnityProject <path-to-unity-project>

param(
    [Parameter(Mandatory = $true)]
    [string]$UnityProject
)

# Resolve paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MonorepoRoot = Split-Path -Parent $ScriptDir
$PluginSrc = Join-Path $MonorepoRoot "plugin"
$TargetDir = Join-Path $UnityProject "Packages\com.anklebreaker.unity-mcp"

# Validate source exists
if (-not (Test-Path $PluginSrc)) {
    Write-Error "Plugin source not found at $PluginSrc"
    exit 1
}

Write-Host "Installing AnkleBreaker Unity MCP plugin..."
Write-Host "  Source: $PluginSrc"
Write-Host "  Target: $TargetDir"

# Remove existing installation
if (Test-Path $TargetDir) {
    Write-Host "Removing existing installation..."
    Remove-Item -Recurse -Force $TargetDir
}

# Ensure target parent exists
$TargetParent = Split-Path -Parent $TargetDir
if (-not (Test-Path $TargetParent)) {
    New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
}

# Copy plugin directory
Copy-Item -Recurse -Force $PluginSrc $TargetDir

# Exclude development-only files
$ExcludePatterns = @('.git', '.github', 'docs', 'CHANGELOG.md', '.gitignore')

foreach ($pattern in $ExcludePatterns) {
    $excludePath = Join-Path $TargetDir $pattern
    if (Test-Path $excludePath) {
        Remove-Item -Recurse -Force $excludePath
    }
}

# Preserve README.md and its .meta (remove from exclusion if they were caught)
# README.md is not in the exclusion list above, so it remains.
# Ensure any other .md files are removed, but README.md stays.
$mdFiles = Get-ChildItem -Path $TargetDir -Filter "*.md" -File
foreach ($md in $mdFiles) {
    if ($md.Name -ne "README.md") {
        Remove-Item -Force $md.FullName
    }
}

Write-Host "Done. Plugin installed at: $TargetDir"
