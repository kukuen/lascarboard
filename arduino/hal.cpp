#include "Arduino.h"
#include "Keyboard.h"

extern "C" {
    void keyboardBegin() {
        pinMode(LED_BUILTIN, OUTPUT);
        Keyboard.begin(KeyboardLayout_fr_FR);
    }

    void keyboardPress(uint8_t key) {
        Keyboard.press(key);
    }

    void keyboardRelease(uint8_t key) {
        Keyboard.release(key);
    }

    void keyboardWrite(char c){
        Keyboard.write(c);
    }

    void serialBegin(unsigned long baud){
        Serial.begin(baud);
    }

    void serialPrintln(const char str[]){
        Serial.println(str);
    }
}