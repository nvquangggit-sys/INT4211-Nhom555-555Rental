# Cài APK, chụp ảnh màn hình và quay video demo phần App Admin (nhóm 555).
#
# Ví dụ:
#   .\tools\minh-chung.ps1 -Cai
#   .\tools\minh-chung.ps1 -Chup 03-tong-quan
#   .\tools\minh-chung.ps1 -Quay
#   .\tools\minh-chung.ps1 -KiemTra
#
# Yêu cầu: bật "Gỡ lỗi USB" trên điện thoại và đã cài Android SDK platform-tools.

param(
    [switch]$Cai,
    [string]$Chup,
    [switch]$Quay,
    [switch]$KiemTra,
    [int]$GiayToiDa = 300
)

$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent          # admin-android
$repo = Split-Path $root -Parent                  # goc repo
$apk = Join-Path $root 'releases\555Rental-Admin-v1.0.0.apk'
$outDir = Join-Path $repo 'docs\minh-chung'
$package = 'com.nhom555.rentaladmin'
$activity = 'com.nhom555.rentaladmin/.ui.login.LoginActivity'

function Get-Adb {
    $candidates = @()
    if ($env:ANDROID_HOME) { $candidates += (Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe') }
    if ($env:ANDROID_SDK_ROOT) { $candidates += (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools\adb.exe') }
    $candidates += 'C:\Users\ADMIN\AppData\Local\Android\Sdk\platform-tools\adb.exe'
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    $cmd = Get-Command adb -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Khong tim thay adb. Cai Android SDK platform-tools hoac them adb vao PATH."
}

$adb = Get-Adb

function Assert-ThietBi {
    $lines = & $adb devices
    $ok = $lines | Where-Object { $_ -match "\sdevice$" }
    if (-not $ok) {
        Write-Host "Khong thay dien thoai nao o trang thai 'device'." -ForegroundColor Red
        Write-Host "Kiem tra: cap USB, che do truyen file (MTP), da bat 'Go loi USB', da bam 'Cho phep' tren may."
        Write-Host "Chay lai: `"$adb devices`""
        exit 1
    }
    Write-Host "Thiet bi: $($ok -join ', ')" -ForegroundColor Green
}

function Get-DanhSach {
    @(
        '01-cai-apk',
        '02-dang-nhap',
        '03-tong-quan',
        '04-drawer-quan-ly',
        '05-ghi-chi-so',
        '06-loi-400-dien-cuoi',
        '07-canh-bao-tang-vot',
        '08-phat-hanh-hoa-don',
        '09-chi-tiet-hoa-don',
        '10-thanh-toan-bien-lai',
        '11-su-co',
        '12-bao-cao',
        '13-mat-mang',
        '14-xoay-ngang'
    )
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

if ($KiemTra) {
    Write-Host "Thu muc minh chung: $outDir"
    $thieu = 0
    foreach ($ten in (Get-DanhSach)) {
        $co = Get-ChildItem $outDir -Filter "$ten.*" -File -ErrorAction SilentlyContinue
        if ($co) {
            Write-Host ("  [x] {0}  ({1})" -f $ten, $co[0].Name) -ForegroundColor Green
        } else {
            Write-Host ("  [ ] {0}" -f $ten) -ForegroundColor Yellow
            $thieu++
        }
    }
    $video = Get-ChildItem $outDir -Filter 'admin-demo*.mp4' -File -ErrorAction SilentlyContinue
    if ($video) {
        Write-Host ("  [x] video  ({0}, {1:N1} MB)" -f $video[0].Name, ($video[0].Length / 1MB)) -ForegroundColor Green
    } else {
        Write-Host "  [ ] video admin-demo.mp4" -ForegroundColor Yellow
        $thieu++
    }
    Write-Host ""
    if ($thieu -eq 0) { Write-Host "Du minh chung." -ForegroundColor Green }
    else { Write-Host "Con thieu $thieu muc." -ForegroundColor Yellow }
    exit 0
}

if ($Cai) {
    Assert-ThietBi
    if (-not (Test-Path $apk)) { throw "Khong thay APK: $apk" }
    Write-Host "Dang cai $apk ..."
    $ketQua = & $adb install -r $apk 2>&1
    $ketQua | ForEach-Object { Write-Host "  $_" }
    if ($ketQua -notmatch 'Success') {
        Write-Host "Cai that bai. Thu go ban cu: `"$adb uninstall $package`" roi chay lai." -ForegroundColor Red
        exit 1
    }
    & $adb shell am start -n $activity | Out-Null
    Write-Host "Da cai va mo app. Chup man hinh Cai dat > Ung dung de lam anh 01-cai-apk." -ForegroundColor Green
    exit 0
}

if ($Chup) {
    Assert-ThietBi
    $ten = $Chup.Trim()
    if ($ten -match '\.(png|jpg|jpeg)$') { $ten = [IO.Path]::GetFileNameWithoutExtension($ten) }
    $remote = '/sdcard/_minhchung.png'
    $local = Join-Path $outDir "$ten.png"
    & $adb shell screencap -p $remote | Out-Null
    & $adb pull $remote $local | Out-Null
    & $adb shell rm $remote | Out-Null
    if (Test-Path $local) {
        Write-Host "Da luu: $local" -ForegroundColor Green
    } else {
        Write-Host "Chup that bai." -ForegroundColor Red
        exit 1
    }
    exit 0
}

if ($Quay) {
    Assert-ThietBi
    $remote = '/sdcard/_admin-demo.mp4'
    $local = Join-Path $outDir 'admin-demo.mp4'
    & $adb shell rm $remote 2>$null | Out-Null
    Write-Host "Bat dau quay (toi da $GiayToiDa giay). Thao tac theo docs/kich-ban-video-admin.md."
    Write-Host "Bam Enter de DUNG quay..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath $adb `
        -ArgumentList @('shell', 'screenrecord', '--bit-rate', '8000000', '--time-limit', "$GiayToiDa", $remote) `
        -PassThru -WindowStyle Hidden
    Read-Host | Out-Null
    & $adb shell pkill -INT screenrecord 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { & $adb shell killall -INT screenrecord 2>$null | Out-Null }
    try { $proc | Wait-Process -Timeout 15 } catch { }
    Start-Sleep -Seconds 2
    & $adb pull $remote $local | Out-Null
    & $adb shell rm $remote | Out-Null
    if (Test-Path $local) {
        $f = Get-Item $local
        Write-Host ("Da luu: {0} ({1:N1} MB)" -f $f.FullName, ($f.Length / 1MB)) -ForegroundColor Green
        Write-Host "Kiem tra lai bang: ffplay `"$local`" hoac mo bang Windows Media Player."
    } else {
        Write-Host "Khong lay duoc video. Thu lai voi -GiayToiDa 120." -ForegroundColor Red
        exit 1
    }
    exit 0
}

Write-Host "Chua chon viec gi. Dung mot trong: -Cai | -Chup <ten> | -Quay | -KiemTra"
Write-Host "Xem danh sach ten anh trong docs/minh-chung/README.md"
