param(
    [string]$Path = ".",
    [string[]]$ExcludeDirs = @(".git", "node_modules", "dist", "build", "out", "bin", "obj", ".vs", ".vscode", ".idea", "__pycache__", ".venv", "venv", "coverage", ".next", "target")
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path $Path).Path

$binaryExt = @(
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".webp", ".tiff", ".psd",
    ".mp3", ".wav", ".ogg", ".flac", ".mp4", ".avi", ".mov", ".mkv", ".webm",
    ".ttf", ".otf", ".woff", ".woff2", ".eot",
    ".zip", ".gz", ".tar", ".7z", ".rar", ".jar", ".war",
    ".exe", ".dll", ".so", ".dylib", ".bin", ".obj", ".o", ".a", ".lib", ".class", ".pyc", ".wasm",
    ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".db", ".sqlite"
)

function Test-IsBinary([string]$file) {
    $stream = [System.IO.File]::OpenRead($file)
    try {
        $buffer = New-Object byte[] 8000
        $read = $stream.Read($buffer, 0, $buffer.Length)
    } finally { $stream.Close() }
    if ($read -ge 2 -and (($buffer[0] -eq 0xFF -and $buffer[1] -eq 0xFE) -or ($buffer[0] -eq 0xFE -and $buffer[1] -eq 0xFF))) { return $false }
    for ($i = 0; $i -lt $read; $i++) { if ($buffer[$i] -eq 0) { return $true } }
    return $false
}

$gitFiles = $null
if (Get-Command git -ErrorAction SilentlyContinue) {
    Push-Location $root
    try {
        $gitFiles = git ls-files --cached --others --exclude-standard 2>$null
        if ($LASTEXITCODE -ne 0) { $gitFiles = $null }
    } finally { Pop-Location }
}

if ($gitFiles) {
    Write-Output "Mode : git ls-files (.gitignore respecte)"
    $files = $gitFiles | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path $_ -PathType Leaf } | Get-Item -Force
} else {
    Write-Output "Mode : parcours du dossier (dossiers exclus : $($ExcludeDirs -join ', '))"
    $files = Get-ChildItem -Path $root -Recurse -File -Force | Where-Object {
        $relParts = $_.FullName.Substring($root.Length).TrimStart('\', '/') -split '[\\/]'
        -not ($relParts[0..($relParts.Count - 2)] | Where-Object { $ExcludeDirs -contains $_ })
    }
}

$results = @()
$skipped = @()
foreach ($f in $files) {
    $rel = $f.FullName.Substring($root.Length).TrimStart('\', '/')
    if ($binaryExt -contains $f.Extension.ToLower() -or ($f.Length -gt 0 -and (Test-IsBinary $f.FullName))) {
        $skipped += $rel
        continue
    }
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    $results += [PSCustomObject]@{ Fichier = $rel; Lignes = $lines.Count }
}

$results | Sort-Object Lignes -Descending | Format-Table -AutoSize | Out-String -Width 200 | Write-Output

Write-Output "Fichiers texte analyses : $($results.Count)"
Write-Output "Fichiers binaires ignores : $($skipped.Count)"
Write-Output "Total lignes : $(($results | Measure-Object Lignes -Sum).Sum)"
