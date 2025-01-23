
all: build

build:
	alr build

ocd:
	openocd -f interface/cmsis-dap.cfg -c 'cmsis_dap_backend hid' -f target/stm32f4x.cfg

gdb:
	eval `alr printenv` && arm-eabi-gdb --command="gdbinit" ../bin/blackpill_stm32f401.elf
