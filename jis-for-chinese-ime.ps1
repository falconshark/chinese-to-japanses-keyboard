# 讓中文輸入法（速成、倉頡、注音、拼音等）改用日文 JIS 鍵盤佈局
# 用法（以系統管理員身分開啟 PowerShell）：
#   套用：  powershell -ExecutionPolicy Bypass -File .\jis-for-chinese-ime.ps1
#   還原：  powershell -ExecutionPolicy Bypass -File .\jis-for-chinese-ime.ps1 -Restore
# 完成後請登出再登入（或重新開機）。
#Requires -RunAsAdministrator
param([switch]$Restore)

# 繁中(台)、簡中、繁中(港)、新加坡、澳門 的鍵盤佈局 ID
$ids  = '00000404', '00000804', '00000C04', '00001004', '00001404'
$base = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts'
$new  = if ($Restore) { 'KBDUS.DLL' } else { 'KBDJPN.DLL' }

foreach ($id in $ids) {
    $key = Join-Path $base $id
    if (-not (Test-Path $key)) { continue }
    $old = (Get-ItemProperty -Path $key).'Layout File'
    Set-ItemProperty -Path $key -Name 'Layout File' -Value $new
    Write-Host "$id : $old -> $new"
}

if (-not $Restore) {
    # 硬件鍵盤設為日文 106/109 鍵（等同「設定」裡選擇日文鍵盤），USB 鍵盤亦會讀取此處
    $hw = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
    Set-ItemProperty -Path $hw -Name 'LayerDriver JPN'            -Value 'kbd106.dll'
    Set-ItemProperty -Path $hw -Name 'OverrideKeyboardIdentifier' -Value 'PCAT_106KEY'
    Set-ItemProperty -Path $hw -Name 'OverrideKeyboardType'       -Value 7 -Type DWord
    Set-ItemProperty -Path $hw -Name 'OverrideKeyboardSubtype'    -Value 2 -Type DWord
    Write-Host '硬件鍵盤已設為日文 106/109 鍵'
}

Write-Host '完成，請登出再登入或重新開機。'
