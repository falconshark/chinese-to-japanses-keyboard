# chinese-to-japanses-keyboard

> ⚠️ 本 README 及 `jis-for-chinese-ime.ps1` 的大部分內容由 AI（Claude）編寫，使用前請自行檢查。

讓 Windows 的中文輸入法（速成、倉頡、注音、拼音等）使用**日文 JIS（106/109 鍵）鍵盤佈局**。

Windows 預設會讓中文輸入法使用美式鍵盤佈局。如果你用的是日文鍵盤，切換到中文輸入法後，`@`、`;`、`:`、`[` 等符號的位置會跟鍵帽上印的不一樣。這個腳本可以解決這個問題。

## 用法

以**系統管理員身分**開啟 PowerShell，進入本資料夾：

```powershell
# 套用
powershell -ExecutionPolicy Bypass -File .\jis-for-chinese-ime.ps1

# 還原
powershell -ExecutionPolicy Bypass -File .\jis-for-chinese-ime.ps1 -Restore

# 檢查目前已載入的佈局是 JIS 還是 US（毋須管理員）
powershell -ExecutionPolicy Bypass -File .\jis-for-chinese-ime.ps1 -Verify
```

套用或還原後，**必須登出再登入或重新開機**。在這之前，已載入的佈局會繼續沿用舊設定。

`-Verify` 的輸出範例：

```
04040404  JIS    ← 繁中（台）
04110411  JIS    ← 日文
04090409  US     ← 英文（不受影響）
```

HKL 的低 4 位是語言代碼：`0404` 繁中（台）、`0804` 簡中、`0C04` 繁中（港）、`1004` 新加坡、`1404` 澳門、`0411` 日文、`0409` 英文。

## 腳本做了甚麼

1. 把以下中文鍵盤佈局的 `Layout File` 改成 `KBD106.DLL`（日文 106/109 鍵）：
   `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\{00000404, 00000804, 00000C04, 00001004, 00001404}`
2. 把硬件鍵盤類型設為日文 106/109 鍵（`OverrideKeyboardType = 7` 等），同時寫入：
   - `HKLM\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters`（PS/2 鍵盤）
   - `HKLM\SYSTEM\CurrentControlSet\Services\kbdhid\Parameters`（USB／藍牙鍵盤）
3. 第一次套用時，把原本的硬件鍵盤設定備份到 `jis-backup.json`，供 `-Restore` 使用。

`-Restore` 會把中文佈局改回 `KBDUS.DLL`，並從備份還原硬件鍵盤設定。

## 為甚麼不用 `KBDJPN.DLL`？

舊版腳本把 `Layout File` 設成 `KBDJPN.DLL`，但結果仍然是美式佈局。

`KBDJPN.DLL` 只是一個轉接檔，它會按**鍵盤類型**決定實際載入 `KBD106.DLL`（日文）還是 `KBD101.DLL`（美式）。在中文佈局 ID 下，USB 鍵盤回報的類型是 4（101 鍵），所以最後載入的是美式佈局。直接指向 `KBD106.DLL` 可以繞過這個判斷。

## 已知限制

- 中文輸入法在**中文模式**下的全形標點，是由輸入法自己根據按鍵決定的，可能仍然跟美式佈局的位置一樣。英文模式和一般輸入則會跟隨 JIS 佈局。
- Windows 大型更新可能會重設 `Keyboard Layouts` 的設定。如果失效，請重新執行腳本。
- 請不要同時保留舊版腳本並再次執行，否則設定會被改回 `KBDJPN.DLL`。
