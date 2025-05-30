#include <stdint.h>

void keyboardBegin() ;
void keyboardPress(uint8_t key);
void keyboardRelease(uint8_t key);
void keyboardWrite(char c);

void pinMode(uint8_t pin, uint8_t mode);

void digitalWrite(uint8_t pin, uint8_t val);
int digitalRead(uint8_t pin);

void serialBegin(unsigned long baud);
void serialPrintln(const char str[]);

void delay(unsigned long ms);

unsigned long millis(void);
unsigned long micros(void);
