# ATtiny412 Temperature Sensor Project

This project creates a temperature sensor using the ATtiny412 microcontroller. It reads the internal temperature sensor and outputs the readings via UART.

## Project Structure

```
temp_sensor/
├── build_cmake/         # CMake build output directory
├── include/             # Header files
│   └── temp_sensor.h    # Main header file
├── src/                 # Source code
│   └── main.c          # Main application code
├── CMakeLists.txt      # CMake build configuration
├── build.sh            # Build helper script
└── README.md           # This file
```

## Requirements

- AVR-GCC compiler (installed in /opt/gcc-14.2.0-avr)
- CMake 3.12 or higher
- AVR development tools (avrdude for programming)
- PICkit 4 programmer
- ATtiny412 microcontroller
- avr-gdb for debugging

## Building the Project

The project uses CMake as its build system. A build script is provided for convenience:

```bash
# Build the project
./build.sh build

# Clean the build directory
./build.sh clean

# Upload to microcontroller
./build.sh upload

# Debug with avr-gdb
./build.sh debug

# Clean, build, and upload
./build.sh all

# Display detailed memory usage information
./build.sh meminfo

# Show help
./build.sh help
```

## Memory Usage Reporting

The build script provides insight into the memory usage of your application, which is critical for the resource-constrained ATtiny412 microcontroller:

- **Basic memory report**: After each build, you'll automatically see a summary of Flash, SRAM, and EEPROM usage, showing both the absolute values and percentages of the available memory.

- **Detailed memory analysis**: Running `./build.sh meminfo` provides comprehensive information:
  - Breakdown of memory usage by section (.text, .data, .bss, etc.)
  - Lists of the top 10 largest symbols (functions/variables)
  - EEPROM contents (when used)
  - Full section-by-section memory details

This helps you optimize your code to fit within the ATtiny412's limited resources:
- 4KB Flash memory
- 256 bytes of SRAM
- 128 bytes of EEPROM

## Programming the Microcontroller

The project supports multiple programmers through avrdude. The default configuration uses a PICkit 4, but you can use other programmers by modifying the upload command in CMakeLists.txt.

### Supported Programmers

1. **PICkit 4 (Default Configuration)**
   ```bash
   # In CMakeLists.txt
   avrdude -c pickit4_isp -p ${MCU} -U flash:w:${PROJECT_NAME}.hex:i
   ```
   Connections:
   - MCLR/VPP (Pin 1)
   - VDD (Pin 2)
   - VSS (Pin 3)
   - ICSPDAT/PGD (Pin 4)
   - ICSPCLK/PGC (Pin 5)

2. **USBasp Programmer**
   ```bash
   # In CMakeLists.txt
   avrdude -c usbasp -p ${MCU} -U flash:w:${PROJECT_NAME}.hex:i
   ```
   Standard 6-pin ISP connection:
   - MOSI
   - MISO
   - SCK
   - RESET
   - VCC
   - GND

3. **Arduino as ISP**
   ```bash
   # In CMakeLists.txt
   avrdude -c arduino -P /dev/ttyACM0 -b 19200 -p ${MCU} -U flash:w:${PROJECT_NAME}.hex:i
   ```
   Connect using standard ISP pinout on Arduino:
   - Digital Pin 11 (MOSI)
   - Digital Pin 12 (MISO)
   - Digital Pin 13 (SCK)
   - Digital Pin 10 (RESET)
   - 5V
   - GND

4. **USBtiny**
   ```bash
   # In CMakeLists.txt
   avrdude -c usbtiny -p ${MCU} -U flash:w:${PROJECT_NAME}.hex:i
   ```
   Uses standard 6-pin ISP header

5. **STK500v1 Protocol**
   ```bash
   # In CMakeLists.txt
   avrdude -c stk500v1 -P /dev/ttyUSB0 -b 19200 -p ${MCU} -U flash:w:${PROJECT_NAME}.hex:i
   ```
   For programmers/boards using the STK500v1 protocol (many Arduino bootloaders)

### Debugging Options

The project supports multiple debugging configurations:

1. **avarice + JTAG/debugWIRE**
   ```bash
   # Start the debug server
   avarice --jtag usb --file ATtiny412_Temp_Sensor :1234
   
   # In another terminal
   ./build.sh debug
   ```
   avarice supports various Atmel JTAG ICE devices

2. **simulavr**
   ```bash
   # Start the simulator
   simulavr --device ${MCU} --gdbserver :1234 build_cmake/ATtiny412_Temp_Sensor
   
   # In another terminal
   ./build.sh debug
   ```
   Useful for debugging without hardware

3. **PICkit 4 Debug**
   - Requires PICkit 4 in debug mode
   - Supports real-time debugging and breakpoints
   - Configure in CMakeLists.txt:
     ```cmake
     add_custom_target(
         debug
         COMMAND avr-gdb -ex "target remote localhost:1234" ${PROJECT_NAME}
         DEPENDS ${PROJECT_NAME}
         COMMENT "Starting avr-gdb debugger"
     )
     ```

### Common Debugging Commands

Advanced GDB commands for AVR debugging:
- `monitor reset` - Reset the microcontroller
- `monitor break` - Set a hardware breakpoint
- `monitor erase` - Erase flash memory
- `x/16xb $pc` - Examine 16 bytes of memory at program counter
- `set $pc = 0x0` - Set program counter to address 0x0
- `info registers` - Display all AVR registers
- `print/x $sreg` - Show status register in hex
- `set $pc = $pc + 2` - Skip current instruction
- `stepi` - Step one instruction

## Debugging with avr-gdb

The project includes support for debugging using avr-gdb. Debug symbols are automatically included when building. To start a debug session:

1. Build the project with debug symbols:
   ```bash
   ./build.sh build
   ```
   This automatically includes debug information (-g -gdwarf-2).

2. Start a debug server (e.g., avarice, simulavr) on port 1234.

3. Start the debug session:
   ```bash
   ./build.sh debug
   ```

Common avr-gdb commands:
- `break <function/line>` - Set breakpoint
- `continue` - Continue execution
- `step` - Step into
- `next` - Step over
- `print <variable>` - Print variable value
- `info registers` - Show AVR registers
- `x/<n>x <address>` - Examine memory
- `quit` - Exit debugger

## Functionality

The program reads the internal temperature sensor of the ATtiny412 and sends the readings via UART at 9600 baud. The temperature is read once per second and transmitted as a raw ADC value.

## Hardware Connections

- UART TX: PA0 (PIN0)

## Adapting for Different AVR Microcontrollers

To use this project with a different AVR microcontroller, you'll need to make the following changes:

### 1. Update CMakeLists.txt

Modify the microcontroller settings in `CMakeLists.txt`:

```cmake
# Microcontroller settings
set(MCU your_mcu_name)  # e.g., atmega328p, attiny85, etc.
set(F_CPU your_clock_speed)  # in Hz, e.g., 16000000 for 16MHz
```

### 2. Update Memory Specifications in build.sh

Modify the memory specifications in `build.sh` to match your target microcontroller:

```bash
# AVR memory specifications
FLASH_SIZE=your_flash_size  # Flash memory in bytes
SRAM_SIZE=your_sram_size    # SRAM in bytes
EEPROM_SIZE=your_eeprom_size  # EEPROM in bytes
```

Common AVR memory sizes (in bytes):
- **ATmega328P**: Flash: 32768, SRAM: 2048, EEPROM: 1024
- **ATtiny85**: Flash: 8192, SRAM: 512, EEPROM: 512
- **ATmega2560**: Flash: 262144, SRAM: 8192, EEPROM: 4096
- **ATtiny13**: Flash: 1024, SRAM: 64, EEPROM: 64

### 3. Update avrdude Configuration

Modify the upload target in `CMakeLists.txt` to use the correct programmer and MCU:

```cmake
add_custom_target(
    upload
    COMMAND avrdude -c your_programmer -p ${MCU} -U flash:w:${PROJECT_NAME}.hex:i
    DEPENDS ${PROJECT_NAME}.hex
    COMMENT "Uploading to your device using your programmer"
)
```

Common programmers include:
- `arduino` for Arduino as ISP
- `usbasp` for USBasp programmers
- `usbtiny` for USBtiny-based programmers
- `stk500v1` for many Arduino bootloaders
- `pickit4_isp` for PICkit 4 in ISP mode (current configuration)

### 4. Adjust Pin Definitions

Update pin definitions in your code to match the new microcontroller's pinout. This typically involves:

- Reviewing all port and pin definitions in `src/main.c`
- Checking that peripheral registers are correctly addressed
- Ensuring timer configurations are valid for the new MCU

### 5. Check Peripheral Availability

Not all AVR microcontrollers have the same peripherals. Ensure that:

- The internal temperature sensor (if used) is available and accessed correctly
- UART or other communication interfaces are available and configured properly
- ADC, timers, and other peripherals have similar functionality or are adapted appropriately

### 6. Update Compiler Flags

You may need to update compiler flags for specific optimizations or features related to your target MCU in `CMakeLists.txt`.

### 7. Test Memory Usage

After porting, run the memory usage analysis to ensure your code fits within the new constraints:

```bash
./build.sh meminfo
```

## Cross-Platform Setup Instructions

### Linux Distributions

#### Ubuntu/Debian
```bash
# Install required packages
sudo apt-get update
sudo apt-get install gcc-avr avr-libc avrdude cmake make git
# Optional debugging tools
sudo apt-get install avarice simulavr gdb-avr
```

#### Fedora
```bash
sudo dnf install avr-gcc avr-libc avrdude cmake make git
# Optional debugging tools
sudo dnf install avarice simulavr avr-gdb
```

#### Arch Linux
```bash
sudo pacman -S avr-gcc avr-libc avrdude cmake make git
# Optional debugging tools
sudo pacman -S avarice simulavr avr-gdb
```

#### openSUSE
```bash
sudo zypper install cross-avr-gcc cross-avr-gcc-c++ cross-avr-libc avrdude cmake make git
# Optional debugging tools
sudo zypper install avarice simulavr gdb-avr
```

### Windows

1. **Install Required Software**
   - Download and install [MSYS2](https://www.msys2.org/)
   - Download and install [CMake](https://cmake.org/download/)
   - Download and install [Git for Windows](https://gitforwindows.org/)

2. **Install AVR Toolchain via MSYS2**
   Open MSYS2 MinGW64 terminal and run:
   ```bash
   pacman -Syu
   pacman -S mingw-w64-x86_64-avr-toolchain mingw-w64-x86_64-avrdude
   # Optional debugging tools
   pacman -S mingw-w64-x86_64-simulavr mingw-w64-x86_64-avarice
   ```

3. **Update Environment Variables**
   - Open Windows System Properties → Advanced → Environment Variables
   - Add to System PATH:
     ```
     C:\msys64\mingw64\bin
     C:\msys64\usr\bin
     C:\Program Files\CMake\bin
     ```

4. **Project Setup**
   ```bash
   # Clone the project
   git clone <project-url>
   cd temp_sensor
   
   # Create build directory
   mkdir build_cmake
   cd build_cmake
   
   # Configure with CMake
   cmake -G "MinGW Makefiles" ..
   
   # Build
   mingw32-make
   ```

5. **Windows-Specific Notes**
   - Use `mingw32-make` instead of `make`
   - Serial ports are named differently (COM1, COM2, etc.)
   - Modify CMakeLists.txt for Windows paths:
     ```cmake
     # For Windows serial ports
     if(WIN32)
         set(SERIAL_PORT "COM1")  # Adjust as needed
     else()
         set(SERIAL_PORT "/dev/ttyUSB0")
     endif()
     ```
   - Use `avrdude.conf` from your MSYS2 installation:
     ```cmake
     # In upload target
     if(WIN32)
         set(AVRDUDE_CONF "-C${CMAKE_CURRENT_SOURCE_DIR}/avrdude.conf")
     endif()
     ```

### Project Structure Setup

Regardless of your platform, maintain this structure:
```
temp_sensor/
├── build_cmake/         # CMake build output directory
├── include/             # Header files
│   └── temp_sensor.h    # Main header file
├── src/                 # Source code
│   └── main.c          # Main application code
├── CMakeLists.txt      # CMake build configuration
├── build.sh            # Build helper script (Linux)
├── build.bat           # Build helper script (Windows)
└── README.md           # This file
```

### Troubleshooting Common Issues

1. **AVR Toolchain Not Found**
   - Linux: Verify installation with `avr-gcc --version`
   - Windows: Check PATH variables and MSYS2 installation

2. **CMake Configuration Fails**
   - Ensure CMake version is 3.12 or higher
   - Check if AVR toolchain is properly installed
   - Verify compiler paths in CMakeLists.txt

3. **Programmer Connection Issues**
   - Check USB connections and permissions
   - Linux: Add user to dialout group: `sudo usermod -a -G dialout $USER`
   - Windows: Check Device Manager for COM port assignments

4. **Build Script Permissions (Linux)**
   ```bash
   chmod +x build.sh
   ```

5. **Windows Line Endings**
   - If scripts fail on Linux after editing on Windows:
   ```bash
   dos2unix build.sh
   ```

## License

This project is open source and available under the MIT License.