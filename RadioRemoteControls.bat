:: This batch file allows you to set up your own ESP environment in a shell.
:: This points to the offline installation paths before navigating to a project to build.
:: The script assumes you have already downloaded and extracted the ESP-IDF offline installation somewhere on your system.

@echo off

:: Setup paths to the offline installation.
echo --------------------------------------------------
echo Setting up ESP-IDF environment...
set "IDF_TOOLS_PATH=C:\espressif"
set "IDF_PATH=C:\espressif\frameworks\esp-idf-v5.5.1"

:: Find the offline Python executable, this searches the python_env folder for the correct executable instead of using the system's default Python.
echo --------------------------------------------------
echo Locating offline Python executable...
for /f "delims=" %%i in ('dir /s /b "%IDF_TOOLS_PATH%\python_env\python.exe"') do (
    set "PYTHON=%%i"
    goto :found_python
)

:found_python
if "%PYTHON%"=="" (
    echo [ERROR] Could not find the offline Python executable in %IDF_TOOLS_PATH%\python_env
    exit /b 1
) else (
    echo [SUCCESS] Python offline executable: %PYTHON%
)

:: Locate and add the Pythons tool directory to the system path to satisfy export.bat.
echo --------------------------------------------------
echo Setting up Python tools path...
for /d %%d in ("%IDF_TOOLS_PATH%\tools\idf-python\*") do (
    set "PATH=%%d;%PATH%"
    echo [SUCCESS] Python tools path: %%d
)

:: Run the export script, use 'call' so that the script stays open for further commands.
echo --------------------------------------------------
echo Activating ESP-IDF from %IDF_PATH%
cd /d "%IDF_PATH%"
call export.bat

:: Print ESP-IDF version.
echo --------------------------------------------------
for /f "delims=" %%i in ('idf.py --version') do echo ESP-IDF version: %%i

:: Navigate to the desired project directory.
echo --------------------------------------------------
echo Navigating to ESP project...
cd /d "C:\Workspaces\radio-remote-controls"

:: Interactive menu for commands.
:menu
echo --------------------------------------------------
echo Available commands:
echo b - Build project (idf.py build)
echo c - Clean project (idf.py clean)
echo f - Full clean project (idf.py fullclean)
echo m - Menu config (idf.py menuconfig)
echo q - Quit
set /p choice="Enter command: "
if "%choice%"=="b" (
    echo Running build...
    idf.py build
) else if "%choice%"=="c" (
    echo Running clean...
    idf.py clean
) else if "%choice%"=="f" (
    echo Running full clean...
    idf.py fullclean
) else if "%choice%"=="m" (
    echo Running menuconfig...
    idf.py menuconfig
) else if "%choice%"=="q" (
    goto :end
) else (
    echo Invalid command.
)
goto :menu

:end
:: Keep the command prompt open for further commands.
cmd /k
