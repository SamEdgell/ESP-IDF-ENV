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
echo.
echo Available commands:
echo -------------------
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
idf.py flash -p %port%
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
set port=COM%port_num%
echo Port set to %port%
if errorlevel 1 (
    echo Port selection failed.
)
goto :menu

:set_target
echo Setting target...
set /p target="Enter target (e.g., esp32, esp32s2, esp32c3, esp32s3): "
if "%target%"=="" (
    echo No target entered.
    goto :menu
)
idf.py set-target %target%
echo Target set to %target%
if errorlevel 1 (
    echo Set target failed.
)
goto :menu

:exit
:: Keep the command prompt open for further commands.
cmd /k
