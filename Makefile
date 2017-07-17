TEST_MINI ?= add
TEST_OBJS = $(addsuffix .o,$(basename $(wildcard tests/*.S)))
FIRMWARE_OBJS = firmware/start.o
GCC_WARNS  = -Werror -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings
GCC_WARNS += -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -pedantic # -Wconversion
TOOLCHAIN_PREFIX = riscv32-unknown-elf-

all: firmware.hex
	./run v
	
firmware_mini.hex: firmware/firmware_mini.bin firmware/makehex.py
	python3 firmware/makehex.py $< 16384 > $@

firmware/firmware_mini.bin: firmware/firmware_mini.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware/firmware_mini.elf: firmware/start_mini.o tests/$(TEST_MINI).o firmware/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -march=rv32im -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,firmware/sections.lds,-Map,firmware/firmware_mini.map,--strip-debug \
		firmware/start_mini.o tests/$(TEST_MINI).o -lgcc
	chmod -x $@
	
firmware/start_mini.o: firmware/start_mini.S
	$(TOOLCHAIN_PREFIX)gcc -c -march=rv32im -o $@ $< -DTEST_FUNC_NAME=$(TEST_MINI) -DTEST_FUNC_NAME_ret=$(TEST_MINI)_ret

firmware.hex: firmware/firmware.bin firmware/makehex.py
	python3 firmware/makehex.py $< 16384 > $@

firmware/firmware.bin: firmware/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

firmware/firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) firmware/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -march=rv32im -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,firmware/sections.lds,-Map,firmware/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@

firmware/start.o: firmware/start.S
	$(TOOLCHAIN_PREFIX)gcc -c -march=rv32im -o $@ $<

#firmware/%.o: firmware/%.c
#	$(TOOLCHAIN_PREFIX)gcc -c -march=RV32I -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

tests/%.o: tests/%.S tests/riscv_test.h tests/test_macros.h
	$(TOOLCHAIN_PREFIX)gcc -c -march=rv32im -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

clean:
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) \
		firmware/firmware.elf firmware/firmware.bin firmware/firmware.hex firmware/firmware.map \
		firmware/firmware_mini.elf firmware/firmware_mini.bin firmware/firmware_mini.hex firmware/firmware_mini.map firmware/*.o *.hex

.PHONY: all clean firmware_mini.hex firmware/firmware_mini.bin firmware/firmware_mini.elf firmware/start_mini.o

