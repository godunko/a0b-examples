# A0B Examples

This repository contains various examples of use of A0B's components for bare board programming.

 * Turn on/off LED by button click.
 * Controls position of the servo motor connected to PCA9685 PWM controller by joystick of the PlayStation2 gamepad.
 * Calibration of the MPU9250 sensor.

## Build

All examples use [Alire](https://alire.ada.dev/) package manager to obtain all dependencies and build executables. So just type

```
alr build
```

to build example. You can use your favorable tools/IDE to flash executable into MCU.

## Repository file tree structure

 * `<example>` directories contains all files for the given example
   * `<board>` directories contains `alire.toml` file to build an example
   * `bin` directory contains executable files
   * `gnat` directory constains project files
   * `source` directory contains platform independed part of the source code
     * `<board>` directories for board specific code
 * `source` contains common source code shared between examples

## Example packages structure

 * `<Example>` root package
 * `<Example>.Application` primary application code
 * `<Exmaple>.Configuration` board specific configuration
 * `<Example>.Driver` main subprogram to run an example
