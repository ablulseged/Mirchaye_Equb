# PowerShell script to encode Firebase Service Account JSON to Base64
# Usage: .\encode-base64.ps1 <path-to-serviceAccountKey.json>

param(
    [Parameter(Mandatory=$true)]
    [string]$JsonFilePath
)

Write-Host "`n=== Encoding Firebase Service Account JSON to Base64 ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $JsonFilePath)) {
    Write-Host "❌ Error: File not found: $JsonFilePath" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Reading JSON file: $JsonFilePath" -ForegroundColor Yellow
    $content = Get-Content $JsonFilePath -Raw -Encoding UTF8
    
    Write-Host "Encoding to Base64..." -ForegroundColor Yellow
    $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
    
    Write-Host "`n✅ Base64 encoded successfully!`n" -ForegroundColor Green
    Write-Host "📋 Copy the following and paste it into Render Dashboard:" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host $base64 -ForegroundColor White
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "`n📝 Instructions:" -ForegroundColor Yellow
    Write-Host "1. Copy the Base64 string above (the long text)" -ForegroundColor White
    Write-Host "2. Go to Render Dashboard → Your Service → Environment" -ForegroundColor White
    Write-Host "3. Add/Update variable:" -ForegroundColor White
    Write-Host "   - Key: FIREBASE_SERVICE_ACCOUNT_BASE64" -ForegroundColor Yellow
    Write-Host "   - Value: Paste the Base64 string" -ForegroundColor Yellow
    Write-Host "4. Save and redeploy`n" -ForegroundColor White
    
    # Also save to clipboard if possible
    try {
        Set-Clipboard -Value $base64
        Write-Host "✅ Base64 string copied to clipboard!`n" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not copy to clipboard automatically`n" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error encoding file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

