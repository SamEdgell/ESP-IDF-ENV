:: This batch file allows you to set up your own ESP environment in a shell.
:: This points to the offline installation paths before navigating to a project to build.
:: The script assumes you have already downloaded and extracted the ESP-IDF offline installation somewhere on your system.

@echo off

:: Setup paths to the offline installation.
echo --------------------------------------------------
echo Setting up ESP-IDF environment...
set "IDF_TOOLS_PATH=C:\espressif"
set "IDF_PATH=C:\espressif\frameworks\esp-idf-v5.5.1"
echo IDF_TOOLS_PATH = %IDF_TOOLS_PATH%
echo IDF_PATH = %IDF_PATH%

:: Find the offline Python executable, this searches the python_env folder for the correct executable instead of using the system's default Python.
echo --------------------------------------------------
echo Locating offline Python executable...
for /f "delims=" %%i in ('dir /s /b "%IDF_TOOLS_PATH%\python_env\python.exe"') do (
    set "PYTHON=%%i"
    goto :found_python
)
:found_python
if "%PYTHON%"=="" (
    echo Could not find the offline Python executable in %IDF_TOOLS_PATH%\python_env
    exit /b 1
) else (
    echo PYTHON = %PYTHON%
)

:: Add the Python tool directory to the PATH to satisfy export.bat.
echo --------------------------------------------------
echo Prepending Python directory to PATH...
for /d %%d in ("%IDF_TOOLS_PATH%\tools\idf-python\*") do (
    set "PATH=%%d;%PATH%"
    echo PATH = %%d
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
cd /d "D:\esp_workspace\MetricsESPBluetooth"

:: Interactive menu for commands.
:menu
echo.
echo --------------------------------------------------
echo                Available commands:
echo --------------------------------------------------
echo.
echo a  - Build/Flash/Monitor all in sequence
echo b  - Build project
echo c  - Clean project
echo f  - Flash device
echo fc - Full clean project
echo m  - Monitor device
echo mc - Menu config
echo p  - Select port
echo t  - Set target
echo x  - Exit (Additional commands can be run after exit)
echo.
echo --------------------------------------------------
set /p choice="Enter command: "
echo --------------------------------------------------
echo.

if /i "%choice%"=="a" goto :all
if /i "%choice%"=="b" goto :build
if /i "%choice%"=="c" goto :clean
if /i "%choice%"=="f" goto :flash
if /i "%choice%"=="fc" goto :fullclean
if /i "%choice%"=="m" goto :monitor
if /i "%choice%"=="mc" goto :menuconfig
if /i "%choice%"=="p" goto :select_port
if /i "%choice%"=="t" goto :set_target
if /i "%choice%"=="x" goto :exit

echo Invalid command.
goto :menu

:all
if "%port%"=="" (
    echo No port selected. Use 'p' to select a port first.
    goto :menu
)
echo Running build, flash and monitor on port %port%...
idf.py build flash -p %port% monitor
if errorlevel 1 (
    echo Build/Flash/Monitor failed.
)
goto :menu

:build
echo Running build...
idf.py build
if errorlevel 1 (
    echo Build failed.
)
goto :menu

:clean
echo Running clean...
idf.py clean
if errorlevel 1 (
    echo Clean failed.
)
goto :menu

:flash
if "%port%"=="" (
    echo No port selected. Use 'p' to select a port first.
    goto :menu
)
echo Running flash on port %port%...
:: Purposely selecting esp32s3 here as this is the target device for this project.
"%PYTHON%" -m esptool --port %port% --chip esp32s3 --baud 921600 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_freq 40m --flash_size detect 0x0 .\build\bootloader\bootloader.bin 0x8000 .\build\partition_table\partition-table.bin 0x10000 .\build\MetricsBluetooth.bin
if errorlevel 1 (
    echo Flash failed.
)
goto :menu

:fullclean
echo Running full clean...
idf.py fullclean
if errorlevel 1 (
    echo Full clean failed.
)
goto :menu

:monitor
if "%port%"=="" (
    echo Running monitor, locating port automatically...
    idf.py monitor
) else (
    echo Running monitor on port %port%...
    idf.py monitor -p %port%
)
if errorlevel 1 (
    echo Monitor failed.
)
goto :menu

:menuconfig
echo Running menuconfig...
idf.py menuconfig
if errorlevel 1 (
    echo Menuconfig failed.
)
goto :menu

:select_port
echo Available COM ports:
powershell -command "Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match 'COM\d+' } | ForEach-Object { $_.Name }"
echo.
set /p port_num="Enter port number only (e.g., COM3 = 3): "
if "%port_num%"=="" (
    echo No port entered.
    goto :menu
)
set "port=COM%port_num%"
echo Port set to %port%
goto :menu

:set_target
echo Target setting not supported for this project.
goto :menu

:exit

:: Keep the command prompt open for further commands.
cmd /k
