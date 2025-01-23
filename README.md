# A0B Examples

This repository contains various examples of use of A0B's components for bare board programming.
 * `blink_led` Just blink LED. Shows how to configure ARM's SysTick timer and to use `A0B.Timer` package.
 * `button_led` Turn on/off LED by button click. Shows how to configure and handle external interrupts.
 * `mpu9250_calibration` Calibration of the MPU9250 sensor. Shows how to use UART as console, run main loop and suspend CPU till callback arrived inside it, and configure and obtain data from MPU9050 IMU sensor.
 * `pca9685_ps2c_servo` Controls position of the servo motor connected to PCA9685 PWM controller by joystick of the PlayStation2 gamepad. Shows how to use one of MCU's timers instead of SysTick's timer to improve precision, configure I2C and SPI buses, use PCA9685 chip to generate PWM, and use PlayStation 2 gamepad.

## Build

All examples use [Alire](https://alire.ada.dev/) package manager to obtain all dependencies and build executables. So just type

```
alr build
```

to build example. You can use your favorable tools/IDE to flash executable into MCU.

Some examples might use crates from the [A0B Alire Index](https://github.com/godunko/a0b-alire-index), so you might need to add it

```
alr index --name a0b --add https://github.com/godunko/a0b-alire-index.git
```

## Repository file tree structure

* `<example>` directories contains all files for the given example
  * `<board>` directories contains `alire.toml` file to build an example
  * `bin` directory contains executable files
  * `gnat` directory constains project files
  * `source` directory contains platform independed part of the source code
    * `<board>` directories for board specific code
* `boards` various utilities to build, flash and debug examples on particular boards
* `source` contains common source code shared between examples

## Example packages structure

 * `<Example>` root package
 * `<Example>.Application` primary application code
 * `<Exmaple>.Configuration` board specific configuration
 * `<Example>.Driver` main subprogram to run an example
