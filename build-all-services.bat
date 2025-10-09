@echo off
setlocal enabledelayedexpansion

REM ==============================================================================
REM Smart Public Transport Ticketing System - Build All Services (Windows)
REM ==============================================================================
REM This script builds all 6 microservices
REM ==============================================================================

set TOTAL_SERVICES=6
set SUCCESSFUL_BUILDS=0
set FAILED_BUILDS=0

echo.
echo ================================================================
echo   Smart Ticketing System - Building All Microservices
echo ================================================================
echo.

REM Function to build a service
:build_service
set SERVICE_NAME=%~1
set SERVICE_PATH=%~2

echo [BUILD] Building %SERVICE_NAME%...

if not exist "%SERVICE_PATH%" (
    echo [ERROR] Directory not found: %SERVICE_PATH%
    set /a FAILED_BUILDS+=1
    goto :eof
)

cd "%SERVICE_PATH%"

bal build >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] %SERVICE_NAME% built successfully
    set /a SUCCESSFUL_BUILDS+=1
) else (
    echo [FAILED] %SERVICE_NAME% build failed
    echo Running build with output for debugging...
    bal build
    set /a FAILED_BUILDS+=1
)

cd "%~dp0"
goto :eof

REM Build all services
call :build_service "Passenger Service" "services\passenger-service\passenger_service"
call :build_service "Ticketing Service" "services\ticketing-service\ticketing_service"
call :build_service "Payment Service" "services\payment-service\payment_service"
call :build_service "Admin Service" "services\admin-service\admin_service"
call :build_service "Transport Service" "services\transport-service\transport_service"
call :build_service "Notification Service" "services\notification-service\notification_service"

REM Build summary
echo.
echo ================================================================
echo   Build Summary
echo ================================================================
echo.
echo Total Services:      %TOTAL_SERVICES%
echo Successful Builds:   %SUCCESSFUL_BUILDS%
echo Failed Builds:       %FAILED_BUILDS%
echo.

if %FAILED_BUILDS% equ 0 (
    echo ================================================================
    echo   All services built successfully!
    echo ================================================================
    echo.
    echo Next steps:
    echo   1. Start infrastructure: docker-compose up -d
    echo   2. Run all services: docker-compose up
    echo   3. Or run services individually with: bal run
    echo.
    exit /b 0
) else (
    echo ================================================================
    echo   Some services failed to build
    echo ================================================================
    echo.
    echo Please check the error messages above and fix the issues.
    echo.
    exit /b 1
)