# 讓中文輸入法（速成、倉頡、注音、拼音等）改用日文 JIS 鍵盤佈局
# 用法（以系統管理員身分開啟 PowerShell）：
#   套用：  powershell -ExecutionPolicy Bypass -File .\jis-for-chinese-ime.ps1
#   還原：  powershell -ExecutionPolicy Bypass -File .\jis-for-chinese-ime.ps1 -Restore
#   檢查：  powershell -ExecutionPolicy Bypass -File .\jis-for-chinese-ime.ps1 -Verify   （毋須管理員）
# 完成後請登出再登入（或重新開機），之後可用 -Verify 確認。
#
# 注意：KBDJPN.DLL 只是一個「轉接」檔，它會按鍵盤類型（Keyboard Type）決定載入
# KBD106.DLL（日文）或 KBD101.DLL（美式）。中文佈局 ID 下，USB 鍵盤回報的類型是 4（101 鍵），
# 所以設成 KBDJPN.DLL 仍然會得到美式佈局。因此這裡直接指向真正的日文佈局 KBD106.DLL。
param([switch]$Restore, [switch]$Verify)

# 繁中(台)、簡中、繁中(港)、新加坡、澳門 的鍵盤佈局 ID
$ids    = '00000404', '00000804', '00000C04', '00001004', '00001404'
$base   = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts'
$hwKeys = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters',  # PS/2 鍵盤
          'HKLM:\SYSTEM\CurrentControlSet\Services\kbdhid\Parameters'     # USB / 藍牙 (HID) 鍵盤
$hwVals = [ordered]@{
    'LayerDriver JPN'            = 'kbd106.dll'
    'OverrideKeyboardIdentifier' = 'PCAT_106KEY'
    'OverrideKeyboardType'       = 7
    'OverrideKeyboardSubtype'    = 2
}
$backup = Join-Path $PSScriptRoot 'jis-backup.json'

if ($Verify) {
    Add-Type @'
using System; using System.Runtime.InteropServices;
public static class Kbd {
    [DllImport("user32.dll")] public static extern int GetKeyboardLayoutList(int n, IntPtr[] list);
    [DllImport("user32.dll")] public static extern short VkKeyScanEx(char c, IntPtr hkl);
}
'@
    $n = [Kbd]::GetKeyboardLayoutList(0, $null)
    $list = New-Object IntPtr[] $n
    [void][Kbd]::GetKeyboardLayoutList($n, $list)
    # JIS 佈局中「@」在 Enter 左上方那顆鍵（VK_OEM_3 = 0xC0）；美式佈局是 Shift+2
    foreach ($h in $list) {
        $vk = [Kbd]::VkKeyScanEx('@', $h) -band 0xFF
        $layout = if ($vk -eq 0xC0) { 'JIS' } else { 'US' }
        '{0:X8}  {1}' -f $h.ToInt64(), $layout
    }
    Write-Host '（HKL 低 4 位是語言：0404 繁中、0804 簡中、0C04 港、0411 日、0409 英）'
    return
}

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrators')
if (-not $admin) { throw '請以系統管理員身分執行（-Verify 除外）。' }

if ($Restore) {
    $saved = if (Test-Path $backup) { Get-Content $backup -Raw -Encoding UTF8 | ConvertFrom-Json }
    foreach ($id in $ids) {
        $key = Join-Path $base $id
        if (-not (Test-Path $key)) { continue }
        Set-ItemProperty -Path $key -Name 'Layout File' -Value 'KBDUS.DLL'
        Write-Host "$id -> KBDUS.DLL"
    }
    foreach ($hw in $hwKeys) {
        if (-not (Test-Path $hw)) { continue }
        foreach ($name in $hwVals.Keys) {
            $old = if ($saved) { $saved.$hw.$name }
            if ($null -ne $old) {
                Set-ItemProperty -Path $hw -Name $name -Value $old
            } elseif ($name -eq 'LayerDriver JPN') {
                Set-ItemProperty -Path $hw -Name $name -Value 'kbd101.dll'   # Windows 預設值
            } else {
                Remove-ItemProperty -Path $hw -Name $name -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host '硬件鍵盤設定已還原'
} else {
    # 第一次套用時備份硬件鍵盤設定，供 -Restore 使用
    if (-not (Test-Path $backup)) {
        $saved = @{}
        foreach ($hw in $hwKeys) {
            $saved[$hw] = @{}
            if (-not (Test-Path $hw)) { continue }
            $p = Get-ItemProperty -Path $hw
            foreach ($name in $hwVals.Keys) { $saved[$hw][$name] = $p.$name }
        }
        $saved | ConvertTo-Json -Depth 3 | Set-Content -Path $backup -Encoding UTF8
        Write-Host "已備份原設定到 $backup"
    }

    foreach ($id in $ids) {
        $key = Join-Path $base $id
        if (-not (Test-Path $key)) { continue }
        $old = (Get-ItemProperty -Path $key).'Layout File'
        Set-ItemProperty -Path $key -Name 'Layout File' -Value 'KBD106.DLL'
        Write-Host "$id : $old -> KBD106.DLL"
    }

    # 硬件鍵盤設為日文 106/109 鍵（等同「設定」裡選擇日文鍵盤）
    foreach ($hw in $hwKeys) {
        if (-not (Test-Path $hw)) { New-Item -Path $hw -Force | Out-Null }
        foreach ($name in $hwVals.Keys) {
            $v = $hwVals[$name]
            if ($v -is [int]) { Set-ItemProperty -Path $hw -Name $name -Value $v -Type DWord }
            else              { Set-ItemProperty -Path $hw -Name $name -Value $v }
        }
    }
    Write-Host '硬件鍵盤已設為日文 106/109 鍵（PS/2 及 USB）'
}

Write-Host '完成，請登出再登入或重新開機，然後用 -Verify 檢查。'
