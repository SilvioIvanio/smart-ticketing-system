# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  Smart Ticketing System - Build All Services (PowerShell)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Set error action preference
$ErrorActionPreference = "Continue"

# Colors
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Track build results
$script:SuccessfulBuilds = 0
$script:FailedBuilds = 0
$TotalServices = 6

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  Building All Microservices" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""

# Define services
$Services = @(
    "passenger-service\passenger_service",
    "ticketing-service\ticketing_service",
    "payment-service\payment_service",
    "admin-service\admin_service",
    "transport-service\transport_service",
    "notification-service\notification_service"
)

# Function to build a service
function Build-Service {
    param (
        [string]$ServicePath
    )
    
    $ServiceName = Split-Path $ServicePath -Leaf
    
    Write-Host "▶ Building: $ServiceName" -ForegroundColor Yellow
    Write-Host "  Path: $ServicePath"
    
    if (-not (Test-Path $ServicePath)) {
        Write-Host "  ✗ ERROR: Directory not found" -ForegroundColor Red
        $script:FailedBuilds++
        Write-Host ""
        return
    }
    
    Push-Location $ServicePath
    
    try {
        $output = bal build 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ SUCCESS: $ServiceName built successfully" -ForegroundColor Green
            $script:SuccessfulBuilds++
        } else {
            Write-Host "  ✗ FAILED: $ServiceName build failed" -ForegroundColor Red
            Write-Host "     Run 'bal build' manually in $ServicePath for details" -ForegroundColor Red
            $script:FailedBuilds++
        }
    } catch {
        Write-Host "  ✗ FAILED: $ServiceName build failed" -ForegroundColor Red
        Write-Host "     Error: $_" -ForegroundColor Red
        $script:FailedBuilds++
    } finally {
        Pop-Location
    }
    
    Write-Host ""
}

# Save current directory
$OriginalDir = Get-Location

# Build each service
foreach ($Service in $Services) {
    Build-Service -ServicePath $Service
}

# Return to original directory
Set-Location $OriginalDir

# Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host "  Build Summary" -ForegroundColor Blue
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
Write-Host ""
Write-Host "  Total Services: $TotalServices"
Write-Host "  Successful: $script:SuccessfulBuilds" -ForegroundColor Green
Write-Host "  Failed: $script:FailedBuilds" -ForegroundColor Red
Write-Host ""

if ($script:FailedBuilds -eq 0) {
    Write-Host "✓ All services built successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Go to project root: cd .."
    Write-Host "  2. Start services: docker-compose up -d"
    Write-Host ""
    exit 0
} else {
    Write-Host "✗ Some services failed to build" -ForegroundColor Red
    Write-Host "Fix the errors and run this script again" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}