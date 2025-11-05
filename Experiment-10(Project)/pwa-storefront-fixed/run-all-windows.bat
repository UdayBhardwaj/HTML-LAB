@echo off
REM run-all-windows.bat - wrapper to run the PowerShell automation script
SET ROOT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -Command "%ROOT_DIR%run-all-windows.ps1"
