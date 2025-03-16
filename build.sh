#!/bin/bash

# Simple build script for the ATtiny412 Temperature Sensor project

# Set build directory
BUILD_DIR="build_cmake"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ATtiny412 memory specifications
FLASH_SIZE=4096  # 4KB Flash memory
SRAM_SIZE=256    # 256 bytes of SRAM
EEPROM_SIZE=128  # 128 bytes of EEPROM

# Create build directory if it doesn't exist
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${YELLOW}Creating build directory...${NC}"
    mkdir -p "$BUILD_DIR"
fi

# Function to display usage
show_usage() {
    echo -e "${GREEN}ATtiny412 Temperature Sensor Project - Build Script${NC}"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  clean    - Clean the build directory"
    echo "  build    - Build the project (default if no command provided)"
    echo "  upload   - Upload the firmware to the microcontroller"
    echo "  debug    - Start avr-gdb debugger"
    echo "  all      - Clean, build, and upload"
    echo "  meminfo  - Display detailed memory usage information"
    echo ""
}

# Clean build directory
do_clean() {
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    rm -rf "$BUILD_DIR"/*
    echo -e "${GREEN}Clean completed.${NC}"
}

# Display basic memory usage
display_basic_memory_info() {
    local ELF_FILE="ATtiny412_Temp_Sensor"
    
    if [ ! -f "$ELF_FILE" ]; then
        echo -e "${RED}Error: ELF file not found. Build the project first.${NC}"
        return 1
    fi
    
    echo -e "\n${YELLOW}Memory Usage Summary:${NC}"
    
    # Show standard size output
    echo -e "${GREEN}Standard avr-size output:${NC}"
    avr-size --format=berkeley "$ELF_FILE"
    
    # Calculate percentages
    local TEXT_SIZE=$(avr-size --format=berkeley "$ELF_FILE" | tail -1 | awk '{print $1}')
    local DATA_SIZE=$(avr-size --format=berkeley "$ELF_FILE" | tail -1 | awk '{print $2}')
    local BSS_SIZE=$(avr-size --format=berkeley "$ELF_FILE" | tail -1 | awk '{print $3}')
    
    local FLASH_USED=$TEXT_SIZE
    local FLASH_PERCENT=$(echo "scale=1; $FLASH_USED * 100 / $FLASH_SIZE" | bc)
    
    local SRAM_USED=$((DATA_SIZE + BSS_SIZE))
    local SRAM_PERCENT=$(echo "scale=1; $SRAM_USED * 100 / $SRAM_SIZE" | bc)
    
    # Check for .eeprom section size
    local EEPROM_USED=0
    if avr-objdump -h "$ELF_FILE" | grep -q ".eeprom"; then
        EEPROM_USED=$(avr-objdump -h "$ELF_FILE" | grep ".eeprom" | awk '{print "0x"$3}' | xargs printf "%d")
    fi
    local EEPROM_PERCENT=$(echo "scale=1; $EEPROM_USED * 100 / $EEPROM_SIZE" | bc)
    
    # Display percentage usage with microcontroller context
    echo ""
    echo -e "${GREEN}ATtiny412 Memory Usage:${NC}"
    echo -e "${CYAN}Flash:${NC}  $FLASH_USED / $FLASH_SIZE bytes (${FLASH_PERCENT}% full)"
    echo -e "${CYAN}SRAM:${NC}   $SRAM_USED / $SRAM_SIZE bytes (${SRAM_PERCENT}% full)"
    echo -e "${CYAN}EEPROM:${NC} $EEPROM_USED / $EEPROM_SIZE bytes (${EEPROM_PERCENT}% full)"
    echo -e "\nFor detailed memory analysis, run: ${YELLOW}./build.sh meminfo${NC}"
}

# Build the project
do_build() {
    echo -e "${YELLOW}Building project...${NC}"
    cd "$BUILD_DIR" || { echo -e "${RED}Error: Cannot enter build directory${NC}"; exit 1; }
    
    cmake .. -DCMAKE_BUILD_TYPE=Debug || { echo -e "${RED}Error: CMake configuration failed${NC}"; exit 1; }
    make || { echo -e "${RED}Error: Build failed${NC}"; exit 1; }
    
    echo -e "${GREEN}Build completed successfully.${NC}"
    
    # Show basic memory usage after successful build
    display_basic_memory_info
}

# Upload to microcontroller
do_upload() {
    echo -e "${YELLOW}Uploading to ATtiny412...${NC}"
    cd "$BUILD_DIR" || { echo -e "${RED}Error: Cannot enter build directory${NC}"; exit 1; }
    
    make upload || { echo -e "${RED}Error: Upload failed${NC}"; exit 1; }
    
    echo -e "${GREEN}Upload completed successfully.${NC}"
}

# Debug with avr-gdb
do_debug() {
    echo -e "${YELLOW}Starting avr-gdb debugger...${NC}"
    cd "$BUILD_DIR" || { echo -e "${RED}Error: Cannot enter build directory${NC}"; exit 1; }
    
    # Start GDB and connect to the debug server
    make debug || { echo -e "${RED}Error: Debug failed${NC}"; exit 1; }
    
    echo -e "${GREEN}Debug session ended.${NC}"
}

# Display detailed memory usage information
do_meminfo() {
    cd "$BUILD_DIR" || { echo -e "${RED}Error: Cannot enter build directory${NC}"; exit 1; }
    
    local ELF_FILE="ATtiny412_Temp_Sensor"
    
    if [ ! -f "$ELF_FILE" ]; then
        echo -e "${RED}Error: ELF file not found. Build the project first.${NC}"
        return 1
    fi
    
    echo -e "\n${GREEN}=================================${NC}"
    echo -e "${GREEN}   MEMORY USAGE INFORMATION      ${NC}"
    echo -e "${GREEN}=================================${NC}"
    
    # Basic size information
    echo -e "\n${YELLOW}Basic Size Information:${NC}"
    avr-size --format=berkeley "$ELF_FILE"
    
    # Detailed section sizes
    echo -e "\n${YELLOW}Detailed Section Sizes:${NC}"
    avr-size --format=avr --mcu=attiny412 "$ELF_FILE"
    
    # Calculate percentages
    local TEXT_SIZE=$(avr-size --format=berkeley "$ELF_FILE" | tail -1 | awk '{print $1}')
    local DATA_SIZE=$(avr-size --format=berkeley "$ELF_FILE" | tail -1 | awk '{print $2}')
    local BSS_SIZE=$(avr-size --format=berkeley "$ELF_FILE" | tail -1 | awk '{print $3}')
    
    local FLASH_USED=$TEXT_SIZE
    local FLASH_PERCENT=$(echo "scale=1; $FLASH_USED * 100 / $FLASH_SIZE" | bc)
    
    local SRAM_USED=$((DATA_SIZE + BSS_SIZE))
    local SRAM_PERCENT=$(echo "scale=1; $SRAM_USED * 100 / $SRAM_SIZE" | bc)
    
    # Check for .eeprom section size
    local EEPROM_USED=0
    if avr-objdump -h "$ELF_FILE" | grep -q ".eeprom"; then
        EEPROM_USED=$(avr-objdump -h "$ELF_FILE" | grep ".eeprom" | awk '{print "0x"$3}' | xargs printf "%d")
    fi
    local EEPROM_PERCENT=$(echo "scale=1; $EEPROM_USED * 100 / $EEPROM_SIZE" | bc)
    
    # Display percentage usage
    echo -e "\n${YELLOW}Memory Usage Summary:${NC}"
    echo -e "${CYAN}Flash:${NC}  $FLASH_USED / $FLASH_SIZE bytes (${FLASH_PERCENT}% full)"
    echo -e "${CYAN}SRAM:${NC}   $SRAM_USED / $SRAM_SIZE bytes (${SRAM_PERCENT}% full)"
    echo -e "${CYAN}EEPROM:${NC} $EEPROM_USED / $EEPROM_SIZE bytes (${EEPROM_PERCENT}% full)"
    
    # Display section by section breakdown
    echo -e "\n${YELLOW}Section by Section Breakdown:${NC}"
    avr-readelf -S "$ELF_FILE" | grep -E '\.text|\.data|\.bss|\.noinit|\.eeprom' | awk '{printf "%-12s %8s bytes\n", $2, $6}'
    
    # Display symbol sizes (top 10 largest)
    echo -e "\n${YELLOW}Top 10 Largest Symbols:${NC}"
    avr-nm --size-sort -S "$ELF_FILE" | grep -v " [aUw] " | tail -10 | awk '{printf "%-30s %8s bytes\n", $3, $2}'
    
    # Display full EEPROM data if present
    if [ "$EEPROM_USED" -gt 0 ]; then
        echo -e "\n${YELLOW}EEPROM Contents:${NC}"
        avr-objdump -s -j .eeprom "$ELF_FILE"
    fi
    
    echo -e "\n${GREEN}=================================${NC}"
}

# Process command
case "$1" in
    "clean")
        do_clean
        ;;
    "build")
        do_build
        ;;
    "upload")
        do_upload
        ;;
    "debug")
        do_debug
        ;;
    "all")
        do_clean
        do_build
        do_upload
        ;;
    "meminfo")
        do_meminfo
        ;;
    "help")
        show_usage
        ;;
    "")
        # Default command is build
        do_build
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac

exit 0