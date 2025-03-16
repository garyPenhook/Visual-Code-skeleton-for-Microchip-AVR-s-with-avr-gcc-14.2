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

The project is configured to use a PICkit 4 programmer. Connect your PICkit 4 to the ATtiny412 with the following pins:

- MCLR/VPP (Pin 1)
- VDD (Pin 2)
- VSS (Pin 3)
- ICSPDAT/PGD (Pin 4)
- ICSPCLK/PGC (Pin 5)

Then run:
```bash
./build.sh upload
```

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

## License

This project is open source and available under the MIT License.