<#
.SYNOPSIS
  Recursively remove common LaTeX auxiliary files from a project directory.

.DESCRIPTION
  This script searches the given path (default: the repository/scripts folder) for common
  LaTeX generated files (aux, log, fdb_latexmk, fls, synctex, bbl, etc.) and deletes them.
  It supports a dry-run mode and an option to also remove generated PDFs.

.PARAMETER Path
  Root path to search and clean. Defaults to the script's parent directory (project root when run from scripts/).

.PARAMETER RemovePdf
  If specified, also remove '*.pdf' files found.

.PARAMETER DryRun
  If specified, the script will only list matching files without deleting them.

.EXAMPLE
  # Dry-run (default path)
  .\clean-latex.ps1 -DryRun

  # Remove aux/log/etc but keep PDFs
  .\clean-latex.ps1

  # Remove everything including generated PDFs
  .\clean-latex.ps1 -RemovePdf
#>

param(
    [string]$Path = (Split-Path -Parent $MyInvocation.MyCommand.Definition),
    [switch]$RemovePdf,
    [switch]$DryRun
)

$patterns = @(
    '*.aux',
    '*.fdb_latexmk',
    '*.fls',
    '*.log',
    '*.out',
    '*.toc',
    '*.synctex.gz',
    '*.bbl',
    '*.blg',
    '*.lof',
    '*.lot',
    '*.nav',
    '*.snm',
    '*.xdv',
    '*.synctex'
)

if ($RemovePdf) { $patterns += '*.pdf' }

# Exclude common VCS / IDE folders
$excludePathRegex = '(\\\.git\\|\\\.vs\\|\\\.github\\)'

Write-Host "Cleaning LaTeX auxiliary files under: $Path"
if ($DryRun) { Write-Host "Dry-run enabled - no files will be deleted." }

try {
    $items = Get-ChildItem -Path $Path -Recurse -Force -File -ErrorAction SilentlyContinue
} catch {
  Write-Error ("Failed to enumerate files under {0}: {1}" -f $Path, $_.Exception.Message)
    exit 1
}
$foundFiles = @()
foreach ($p in $patterns) {
  $foundFiles += $items | Where-Object { $_.Name -like $p }
}

# Deduplicate
$foundFiles = $foundFiles | Sort-Object -Unique

# Exclude paths that match exclude regex
$foundFiles = $foundFiles | Where-Object { -not ($_.FullName -match $excludePathRegex) }

if (-not $foundFiles -or $foundFiles.Count -eq 0) {
  Write-Host "No matching LaTeX auxiliary files found under: $Path"
  exit 0
}

Write-Host "Found $($foundFiles.Count) files to" -NoNewline
if ($DryRun) { Write-Host " list (no deletion)." } else { Write-Host " delete." }

foreach ($f in $foundFiles) {
    if ($DryRun) {
        Write-Host "[DRY] $($f.FullName)"
    } else {
        try {
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
            Write-Host "Deleted: $($f.FullName)"
        } catch {
            Write-Warning "Failed to delete $($f.FullName): $_"
        }
    }
}

Write-Host "Done."
