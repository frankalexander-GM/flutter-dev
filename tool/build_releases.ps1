# Genera los binarios de DevPlay y los publica en web/downloads/
#
#   powershell -ExecutionPolicy Bypass -File tool\build_releases.ps1 -All
#
# Requisitos:
#   - Android: Android SDK + JDK 17 (flutter doctor debe decir "Android toolchain OK")
#   - Windows: Visual Studio 2022 con "Desarrollo para el escritorio con C++"
#
# Los archivos quedan en web/downloads/ y son los que sirve el boton de
# descarga de la app (devplay.apk y devplay-windows.zip).

param(
    [switch]$Android,
    [switch]$Windows,
    [switch]$All
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (-not ($Android -or $Windows -or $All)) { $All = $true }
if ($All) { $Android = $true; $Windows = $true }

# El entorno de AutoClaw no trae estas variables; Flutter las necesita.
$env:LOCALAPPDATA = "C:\Users\$env:USERNAME\AppData\Local"
$env:APPDATA      = "C:\Users\$env:USERNAME\AppData\Roaming"
$env:PUB_CACHE    = "$env:LOCALAPPDATA\Pub\Cache"

$out = Join-Path $root "web\downloads"
New-Item -ItemType Directory -Force -Path $out | Out-Null

Write-Host "== flutter doctor ==" -ForegroundColor Cyan
flutter doctor

if ($Android) {
    Write-Host "`n== Android: APK release ==" -ForegroundColor Cyan
    try {
        flutter build apk --release
        Copy-Item "build\app\outputs\flutter-apk\app-release.apk" `
            (Join-Path $out "devplay.apk") -Force
        $size = [math]::Round((Get-Item (Join-Path $out "devplay.apk")).Length / 1MB, 1)
        Write-Host "OK  web/downloads/devplay.apk  ($size MB)" -ForegroundColor Green
    } catch {
        Write-Host "FALLO Android: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Instala Android Studio / SDK y vuelve a lanzar el script." -ForegroundColor Yellow
    }
}

if ($Windows) {
    Write-Host "`n== Windows: build release ==" -ForegroundColor Cyan
    try {
        if (-not (Test-Path "windows")) {
            Write-Host "Falta la carpeta windows/: habilitando plataforma..." -ForegroundColor Yellow
            flutter create --platforms=windows .
        }
        flutter build windows --release

        $release = Get-ChildItem "build\windows" -Recurse -Directory |
            Where-Object { $_.FullName -match "runner\\Release$" } |
            Select-Object -First 1

        if (-not $release) { throw "No se encontro la carpeta runner\Release" }

        $zip = Join-Path $out "devplay-windows.zip"
        if (Test-Path $zip) { Remove-Item $zip -Force }
        Compress-Archive -Path (Join-Path $release.FullName "*") -DestinationPath $zip
        $size = [math]::Round((Get-Item $zip).Length / 1MB, 1)
        Write-Host "OK  web/downloads/devplay-windows.zip  ($size MB)" -ForegroundColor Green
    } catch {
        Write-Host "FALLO Windows: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Instala Visual Studio 2022 + workload C++." -ForegroundColor Yellow
    }
}

Write-Host "`nListo. Contenido de web/downloads/:" -ForegroundColor Cyan
Get-ChildItem $out | Select-Object Name, @{n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } } |
    Format-Table -AutoSize
