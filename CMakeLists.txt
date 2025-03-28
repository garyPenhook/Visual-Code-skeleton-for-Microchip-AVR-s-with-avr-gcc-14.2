cmake_minimum_required(VERSION 3.12)

# AVR specific settings 
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR avr)

# Handle Windows/Linux compiler differences
if(WIN32)
    set(CMAKE_C_COMPILER "avr-gcc.exe")
    set(CMAKE_CXX_COMPILER "avr-g++.exe")
    set(AVRDUDE_CONF "-C${CMAKE_CURRENT_SOURCE_DIR}/avrdude.conf")
    set(SERIAL_PORT "COM1")  # Default Windows port
else()
    set(CMAKE_C_COMPILER "avr-gcc")
    set(CMAKE_CXX_COMPILER "avr-g++")
    set(AVRDUDE_CONF "")
    set(SERIAL_PORT "/dev/ttyUSB0")  # Default Linux port
    
    # Find AVR include directories on openSUSE
    execute_process(
        COMMAND avr-gcc -print-search-dirs
        OUTPUT_VARIABLE AVR_GCC_SEARCH_DIRS
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    # Extract and add include paths to our project
    string(REGEX MATCH "install: [^\n]+" AVR_INSTALL_DIR "${AVR_GCC_SEARCH_DIRS}")
    string(REPLACE "install: " "" AVR_INSTALL_DIR "${AVR_INSTALL_DIR}")
    
    # Add system include directories
    include_directories(
        "${AVR_INSTALL_DIR}/../include"
        "${AVR_INSTALL_DIR}/include"
        "/usr/lib/avr/include"
        "/usr/include/avr"
        "/usr/avr/include"
    )
endif()

# Project name
project(ATtiny412_Temp_Sensor C)

# Microcontroller settings
set(MCU attiny412)
set(F_CPU 3333333)

# Include directories
include_directories(include)

# Compiler flags
set(COMMON_FLAGS "-mmcu=${MCU} -DF_CPU=${F_CPU} -Os -Wall -Werror -std=gnu99 -ffunction-sections -fdata-sections")
set(DEBUG_FLAGS "-g -gdwarf-2") # Debug flags for avr-gdb
set(CMAKE_C_FLAGS "${COMMON_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG "${COMMON_FLAGS} ${DEBUG_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "-Wl,--gc-sections")

# Set build type to Debug by default for debugging
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

# Source files
file(GLOB SRC_FILES "src/*.c")

# Build the executable
add_executable(${PROJECT_NAME} ${SRC_FILES})

# Generate hex file
add_custom_command(
    OUTPUT ${PROJECT_NAME}.hex
    COMMAND avr-objcopy -O ihex -R .eeprom ${PROJECT_NAME} ${PROJECT_NAME}.hex
    DEPENDS ${PROJECT_NAME}
    COMMENT "Generating HEX file"
)

add_custom_target(hex ALL DEPENDS ${PROJECT_NAME}.hex)

# Show size after build
add_custom_command(
    TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND avr-size --format=berkeley ${PROJECT_NAME}
    COMMENT "Showing program size"
)

# Flash target (upload to microcontroller)
add_custom_target(
    upload
    COMMAND avrdude ${AVRDUDE_CONF} -c pickit4_isp -p ${MCU} -P ${SERIAL_PORT} -U flash:w:${PROJECT_NAME}.hex:i
    DEPENDS ${PROJECT_NAME}.hex
    COMMENT "Uploading to ATtiny412 using PICkit 4"
)

# Debug target with avr-gdb
add_custom_target(
    debug
    COMMAND avr-gdb -ex "target remote localhost:1234" ${PROJECT_NAME}
    DEPENDS ${PROJECT_NAME}
    COMMENT "Starting avr-gdb debugger"
)

# Clean target
add_custom_target(
    clean_all
    COMMAND ${CMAKE_COMMAND} -P cmake_clean.cmake
    COMMENT "Cleaning all build artifacts"
)