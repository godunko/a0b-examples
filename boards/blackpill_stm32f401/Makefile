
all: build

build:
	alr build
	alr exec -- arm-eabi-objcopy -O binary ../bin/blackpill_stm32f401.elf ../bin/blackpill_stm32f401.bin
	ls -l ../bin/blackpill_stm32f401.bin ../bin/blackpill_stm32f401.elf

clean:
	alr clean
	rm -rf ../.objs ../bin

flash:
	openocd -f openocd.cfg -c 'program ../bin/blackpill_stm32f401.bin verify reset exit 0x08000000'

ocd:
	openocd -f openocd.cfg

gdb:
	eval `alr printenv` && arm-eabi-gdb --command="gdbinit" ../bin/blackpill_stm32f401.elf
