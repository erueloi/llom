param (
    [Parameter(Mandatory = $false)]
    [string]$Version,
    
    [Parameter(Mandatory = $false)]
    [string]$ReleaseNotes
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Step { param([string]$Message) Write-Host "`n--- $Message ---" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-ErrorMsg { param([string]$Message) Write-Host "❌ Error: $Message" -ForegroundColor Red }

try {
    # --- Pas 0: Comprovació de paràmetres ---
    if (-not $Version) {
        Write-ErrorMsg "El número de versió és obligatori. Ús: .\release.ps1 -Version '1.0.0+1' [-ReleaseNotes 'Detall dels canvis']"
        exit 1
    }

    Write-Host "🚀 Preparant el Release v$Version per a Llom..." -ForegroundColor Magenta

    # --- Pas 1: Actualització de pubspec.yaml ---
    Write-Step "Pas 1: Actualitzant pubspec.yaml"
    $pubspecPath = "pubspec.yaml"
    if (-not (Test-Path $pubspecPath)) { throw "No s'ha trobat el fitxer pubspec.yaml!" }
    
    $content = Get-Content $pubspecPath -Raw
    if ($content -match "(?m)^version: .*") {
        $newContent = $content -replace "(?m)^version: .*", "version: $Version"
        Set-Content -Path $pubspecPath -Value $newContent -Encoding UTF8
        Write-Success "Versió actualitzada a $Version a pubspec.yaml"
    } else {
        Write-ErrorMsg "No s'ha trobat la clau 'version:' a pubspec.yaml"
    }

    # --- Pas 2: Actualització de Release Notes ---
    if ($ReleaseNotes) {
        Write-Step "Pas 2: Actualitzant Release Notes"
        $notesPath = "assets/release_notes.md"
        if (-not (Test-Path "assets")) { New-Item -ItemType Directory -Force -Path "assets" | Out-Null }
        
        $currentNotes = ""
        if (Test-Path $notesPath) { $currentNotes = Get-Content $notesPath -Raw }
        
        $formattedNotes = $ReleaseNotes -replace "\. ", ".`n"
        $header = "# Release Notes`n`n## v$Version`n$formattedNotes`n"
        $newNotes = $header + ($currentNotes -replace "# Release Notes\s+", "")
        Set-Content -Path $notesPath -Value $newNotes -Encoding UTF8
        Write-Success "Actualitzat $notesPath"
    }

    # --- Pas 3: Operacions Git (Commit & Tag) ---
    Write-Step "Pas 3: Git Commit, Tag & Push"
    $tagName = "v$Version"
    
    git add .
    
    $commitMsg = "Bump version to $Version"
    if ($ReleaseNotes) { $commitMsg = "Release v$Version`n`n$ReleaseNotes" }
    
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        git commit -m $commitMsg
        Write-Success "Canvis confirmats al repositori (commit)."
    } else {
        Write-Host "No hi ha canvis per confirmar (la versió podria ser la mateixa)." -ForegroundColor Yellow
    }

    $tagExists = git tag -l $tagName
    if (-not $tagExists) {
        git tag -a $tagName -m "Release $Version"
        Write-Success "Creat Git Tag: $tagName"
    } else {
        Write-Host "L'etiqueta $tagName ja existeix localment." -ForegroundColor Yellow
    }

    # --- Pas 4: Disparar GitHub Action (Push) ---
    Write-Step "Pas 4: Disparant GitHub Action (Push)"
    
    git push origin HEAD
    git push origin $tagName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Pujat a GitHub correctament!"
        
        # Detecció dinàmica de la URL del repositori
        $remoteUrl = (git config --get remote.origin.url) -replace '\.git$', '' -replace '^git@github\.com:', 'https://github.com/'
        $actionsUrl = if ($remoteUrl) { "$remoteUrl/actions" } else { "https://github.com/erueloi/llom/actions" }

        Write-Host "`n🚀 La GitHub Action hauria d'estar compilant i desplegant v$Version." -ForegroundColor Magenta
        Write-Host "Pots seguir el progrés a: $actionsUrl" -ForegroundColor Cyan
    } else {
        Write-ErrorMsg "Ha fallat el Git push."
    }
}
catch {
    Write-ErrorMsg $_.Exception.Message
    exit 1
}
