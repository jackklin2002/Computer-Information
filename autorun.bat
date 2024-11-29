@echo off
:: Check if the script is running with admin privileges
NET SESSION >nul 2>&1
if %errorlevel% == 0 (
    :: If the script is running as administrator, run PowerShell script
    powershell -ExecutionPolicy Bypass -File "%~dp0SystemInfoCollector.ps1"
) else (
    :: If the script is not running as administrator, relaunch as admin
    echo Requesting elevated permissions...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~dp0autorun.bat\"' -Verb runAs"
)
