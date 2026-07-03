@echo off
title Lumina Native Host Launcher

:: Elevate to Administrator to open firewall and host port
NET SESSION >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [Lumina] Elevating privileges for strict local hosting...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Starting Lumina LAN System via PowerShell...
powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
