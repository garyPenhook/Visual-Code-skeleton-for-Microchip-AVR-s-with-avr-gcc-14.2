@echo off
setlocal EnableDelayedExpansion

:: ATtiny412 memory specifications
set FLASH_SIZE=4096
set SRAM_SIZE=256
set EEPROM_SIZE=128

:: Build directory
set BUILD_DIR=build_cmake

:: Check if build directory exists
if not exist %BUILD_DIR% (
    echo Creating build directory...
    mkdir %BUILD_DIR%
)

:: Process commands
if "%1"=="" goto build
if "%1"=="clean" goto clean
if "%1"=="build" goto build
if "%1"=="upload" goto upload
if "%1"=="debug" goto debug
if "%1"=="all" goto all
if "%1"=="meminfo" goto meminfo
if "%1"=="help" goto help
echo Unknown command: %1
goto help

:clean
echo Cleaning build directory...
if exist %BUILD_DIR% rd /s /q %BUILD_DIR%
mkdir %BUILD_DIR%
echo Clean completed.
goto :eof

:build
echo Building project...
cd %BUILD_DIR%
cmake -G "MinGW Makefiles" .. -DCMAKE_BUILD_TYPE=Debug || goto error
mingw32-make || goto error
call :display_memory_info
cd ..
echo Build completed successfully.
goto :eof

:upload
echo Uploading to ATtiny412...
cd %BUILD_DIR%
mingw32-make upload || goto error
cd ..
echo Upload completed successfully.
goto :eof

:debug
echo Starting avr-gdb debugger...
cd %BUILD_DIR%
mingw32-make debug || goto error
cd ..
echo Debug session ended.
goto :eof

:all
call :clean
call :build
call :upload
goto :eof

:meminfo
cd %BUILD_DIR%
if not exist ATtiny412_Temp_Sensor.exe (
    echo Error: ELF file not found. Build the project first.
    goto error
)

echo.
echo =================================
echo    MEMORY USAGE INFORMATION     
echo =================================
echo.

echo Basic Size Information:
avr-size --format=berkeley ATtiny412_Temp_Sensor.exe

echo.
echo Detailed Section Sizes:
avr-size --format=avr --mcu=attiny412 ATtiny412_Temp_Sensor.exe

:: Get section sizes using avr-size
for /f "skip=1" %%a in ('avr-size --format=berkeley ATtiny412_Temp_Sensor.exe') do (
    set text_size=%%a
    set data_size=%%b
    set bss_size=%%c
)

:: Calculate percentages
set /a flash_used=%text_size%
set /a sram_used=%data_size%+%bss_size%
set /a flash_percent=%flash_used%*100/%FLASH_SIZE%
set /a sram_percent=%sram_used%*100/%SRAM_SIZE%

echo.
echo Memory Usage Summary:
echo Flash: %flash_used% / %FLASH_SIZE% bytes (%flash_percent%%% full^)
echo SRAM:  %sram_used% / %SRAM_SIZE% bytes (%sram_percent%%% full^)

echo.
echo Section by Section Breakdown:
avr-readelf -S ATtiny412_Temp_Sensor.exe | findstr "\.text\|\.data\|\.bss\|\.noinit\|\.eeprom"

echo.
echo Top 10 Largest Symbols:
avr-nm --size-sort -S ATtiny412_Temp_Sensor.exe | findstr /V " [aUw] " | tail -10

cd ..
goto :eof

:help
echo ATtiny412 Temperature Sensor Project - Build Script
echo Usage: %0 [command]
echo.
echo Commands:
echo   clean    - Clean the build directory
echo   build    - Build the project (default if no command provided^)
echo   upload   - Upload the firmware to the microcontroller
echo   debug    - Start avr-gdb debugger
echo   all      - Clean, build, and upload
echo   meminfo  - Display detailed memory usage information
goto :eof

:display_memory_info
if not exist ATtiny412_Temp_Sensor.exe goto :eof

echo.
echo Memory Usage Summary:
avr-size --format=berkeley ATtiny412_Temp_Sensor.exe

for /f "skip=1" %%a in ('avr-size --format=berkeley ATtiny412_Temp_Sensor.exe') do (
    set text_size=%%a
    set data_size=%%b
    set bss_size=%%c
)

set /a flash_used=%text_size%
set /a sram_used=%data_size%+%bss_size%
set /a flash_percent=%flash_used%*100/%FLASH_SIZE%
set /a sram_percent=%sram_used%*100/%SRAM_SIZE%

echo.
echo ATtiny412 Memory Usage:
echo Flash: %flash_used% / %FLASH_SIZE% bytes (%flash_percent%%% full^)
echo SRAM:  %sram_used% / %SRAM_SIZE% bytes (%sram_percent%%% full^)
echo.
echo For detailed memory analysis, run: %0 meminfo
goto :eof

:error
echo Error: Command failed
cd ..
exit /b 1