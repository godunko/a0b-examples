BOSSAC = bossac
PORT = /dev/ttyACM0

build:
	alr build
	alr exec -- arm-eabi-objcopy -O binary ../bin/arduino_due.elf ../bin/arduino_due.bin
	ls -l ../bin/arduino_due.bin ../bin/arduino_due.elf

flash: build
	$(BOSSAC) --port $(PORT) --arduino-erase
	$(BOSSAC) --port $(PORT) --info --write --verify --boot ../bin/arduino_due.bin

ocd:
	openocd -f interface/cmsis-dap.cfg -c 'cmsis_dap_backend hid' -f maintainers-tools/debug/arduino_due.cfg

gdb:
	eval `alr printenv`; arm-eabi-gdb --command="gdbinit" ../bin/arduino_due.elf
