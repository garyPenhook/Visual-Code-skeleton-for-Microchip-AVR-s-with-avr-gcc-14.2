#ifndef TEMP_SENSOR_H
#define TEMP_SENSOR_H

#include <avr/io.h>
#include <stdint.h>

// Function prototypes
void adc_init(void);
uint16_t adc_read(void);
void uart_init(void);
void uart_transmit(uint8_t data);
void uart_print_string(const char* str);
void uart_print_value(uint16_t value);

// Convert raw ADC reading to temperature in degrees Celsius
static inline float convert_to_celsius(uint16_t adc_value) {
    // This formula needs calibration for your specific ATtiny412
    // Refer to the datasheet for the temperature sensor calibration
    return (adc_value - 300) / 1.0f;
}

#endif // TEMP_SENSOR_H