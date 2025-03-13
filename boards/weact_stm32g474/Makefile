
all: build

build:
	alr build
	alr exec -- arm-eabi-objcopy -O binary ../bin/weact_stm32g474.elf ../bin/weact_stm32g474.bin
	ls -l ../bin/weact_stm32g474.bin ../bin/weact_stm32g474.elf

clean:
	alr clean
	rm -rf ../.objs ../bin

flash:
	openocd -f openocd.cfg -c 'program ../bin/weact_stm32g474.bin verify reset exit 0x08000000'

ocd:
	openocd -f openocd.cfg

gdb:
	eval `alr printenv` && arm-eabi-gdb --command="gdbinit" ../bin/weact_stm32g474.elf
