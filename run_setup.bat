@echo off
setlocal enabledelayedexpansion

REM Set console colors for better output
color 0A

echo.
echo ================================================================================
echo                    MicroVolts Server Setup v3.0
echo ================================================================================
echo.

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

echo [INFO] Script directory: %SCRIPT_DIR%
echo [INFO] Current user: %USERNAME%
echo [INFO] System: %OS%
echo.

REM Check for administrator privileges
echo [INFO] Checking administrator privileges...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [SUCCESS] Running with administrator privileges
) else (
    echo [WARNING] Administrator privileges not detected
    echo [INFO] Requesting administrator privileges...
    powershell -Command "Start-Process cmd.exe -ArgumentList '/c \"%~f0\"' -Verb RunAs -Wait"
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to elevate privileges
        goto :error
    )
    exit /b
)
echo.

REM Change to script directory
cd /d "%SCRIPT_DIR%"
if %errorLevel% neq 0 (
    echo [ERROR] Failed to change to script directory
    goto :error
)
echo [SUCCESS] Changed to script directory
echo.

REM Check for Git
echo [INFO] Checking for Git installation...
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Git is not installed or not in PATH
    echo [INFO] Please install Git from https://git-scm.com/
    goto :error
)
echo [SUCCESS] Git is available
echo.

REM Check for updates
echo [INFO] Checking for repository updates...
git remote update >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] Failed to update remote references
) else (
    git status -uno | findstr /C:"Your branch is behind" >nul 2>&1
    if !errorLevel! equ 0 (
        echo [INFO] New version available. Updating...
        git pull >nul 2>&1
        if !errorLevel! equ 0 (
            echo [SUCCESS] Repository updated successfully
            echo [INFO] Restarting script with updated version...
            timeout /t 3 >nul
            start "" "%~f0"
            exit /b 0
        ) else (
            echo [ERROR] Failed to pull updates
            goto :error
        )
    ) else (
        echo [SUCCESS] Repository is up to date
    )
)
echo.

REM Check for Python
echo [INFO] Checking for Python installation...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    python3 --version >nul 2>&1
    if !errorLevel! neq 0 (
        echo [ERROR] Python is not installed or not in PATH
        echo [INFO] Please install Python 3.7 or later from https://python.org
        goto :error
    ) else (
        set "PYTHON_CMD=python3"
    )
) else (
    set "PYTHON_CMD=python"
)

for /f "tokens=2" %%i in ('%PYTHON_CMD% --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [SUCCESS] Python %PYTHON_VERSION% found
echo.

REM Check Python version
for /f "tokens=2 delims=." %%i in ("%PYTHON_VERSION%") do set PYTHON_MAJOR=%%i
if %PYTHON_MAJOR% lss 7 (
    echo [ERROR] Python 3.7 or later is required. Current version: %PYTHON_VERSION%
    goto :error
)
echo [SUCCESS] Python version is compatible
echo.

REM Check for requirements.txt
if not exist "requirements.txt" (
    echo [WARNING] requirements.txt not found. Skipping dependency installation.
) else (
    echo [INFO] Installing Python dependencies...
    %PYTHON_CMD% -m pip install --upgrade pip >nul 2>&1
    %PYTHON_CMD% -m pip install -q -r requirements.txt
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to install Python dependencies
        goto :error
    )
    echo [SUCCESS] Python dependencies installed
)
echo.

REM Check for setup script
if not exist "microvolts_server_setup.py" (
    echo [ERROR] microvolts_server_setup.py not found in current directory
    goto :error
)
echo [SUCCESS] Setup script found
echo.

REM Run the setup script
echo ================================================================================
echo [INFO] Starting MicroVolts Server Setup GUI...
echo ================================================================================
echo.

%PYTHON_CMD% microvolts_server_setup.py

if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Setup script exited with error code %errorLevel%
    goto :error
)

echo.
echo ================================================================================
echo [SUCCESS] Setup completed successfully!
echo ================================================================================
goto :end

:error
echo.
echo ================================================================================
echo [ERROR] Setup failed! Please check the error messages above.
echo ================================================================================
echo.
echo Press any key to exit...
pause >nul
exit /b 1

:end
echo.
echo Press any key to exit...
pause >nul
exit /b 0
