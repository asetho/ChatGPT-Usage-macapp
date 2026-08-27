[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$version = (Get-Content (Join-Path $repoRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw 'VERSION must use semantic versioning (for example 1.0.1).'
}

$windowsRoot = Join-Path $repoRoot 'Windows'
$payload = Join-Path $windowsRoot 'InstallerPayload'
Remove-Item $payload -Recurse -Force -ErrorAction SilentlyContinue

& (Join-Path $repoRoot 'scripts\generate-windows-icon.ps1') -OutputPath (Join-Path $windowsRoot 'Assets\ChatGPTUsage.ico')

dotnet publish (Join-Path $windowsRoot 'ChatGPTUsage.Windows.csproj') `
    -c Release `
    -r win-x64 `
    --self-contained true `
    -p:Version=$version `
    -p:FileVersion=$version `
    -p:AssemblyVersion=$version `
    -o $payload

$compiler = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($null -eq $compiler) {
    throw 'Inno Setup 6 is required to build the Windows installer.'
}

& $compiler "/DMyAppVersion=$version" (Join-Path $windowsRoot 'Installer.iss')
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$installer = Join-Path $windowsRoot "dist\ChatGPTUsage-Setup-$version.exe"
$packages = Get-ChildItem (Join-Path $windowsRoot 'dist') -File -Filter 'ChatGPTUsage-Setup-*.exe' |
    ForEach-Object {
        if ($_.BaseName -match '^ChatGPTUsage-Setup-(\d+\.\d+\.\d+)$') {
            [PSCustomObject]@{ File = $_; Version = [version]$Matches[1] }
        }
    } |
    Sort-Object Version -Descending

$packages | Select-Object -Skip 3 | ForEach-Object {
    Remove-Item $_.File.FullName -Force
    Write-Output "Removed old package $($_.File.FullName)"
}

Write-Output "Created $installer"
