# Define the target for the bootloader
.PHONY: all clean verbose blankimg release

# Output and source directories
OUTDIR = ./Binaries
SRCDIR = ./Source

# Linker script content
LINKER_SCRIPT = OUTPUT_FORMAT("elf64-x86-64")\nENTRY(start)\n\nSECTIONS\n{\n    . = 0xffff800000200000;\n    .text : {\n        *(.text)\n    }\n\n    .rodata : {\n        *(.rodata)\n    }\n\n    . = ALIGN(16);\n    .data : {\n        *(.data)\n    }\n\n    .bss : {\n        *(.bss)\n    }\n}

# Default target
all: $(OUTDIR)/boot.img

# Rule to create the output directory if it doesn't exist
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Compile boot.asm, loader.asm, and kernel.asm
$(OUTDIR)/boot.bin: $(SRCDIR)/boot.asm | $(OUTDIR)
	nasm -f bin -o $(OUTDIR)/boot.bin $(SRCDIR)/boot.asm
	nasm -f bin -o $(OUTDIR)/loader.bin $(SRCDIR)/loader.asm
	nasm -f elf64 -o $(OUTDIR)/kernel.o $(SRCDIR)/kernel.asm
	nasm -f elf64 -o $(OUTDIR)/trapa.o $(SRCDIR)/trap.asm
	nasm -f elf64 -o $(OUTDIR)/liba.o $(SRCDIR)/lib.asm

# Compile main.c to object file
$(OUTDIR)/main.o: $(SRCDIR)/main.c | $(OUTDIR)
	gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c $(SRCDIR)/main.c -o $(OUTDIR)/main.o
	gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c $(SRCDIR)/trap.c -o $(OUTDIR)/trap.o
	gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c $(SRCDIR)/print.c -o $(OUTDIR)/print.o
	gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c $(SRCDIR)/debug.c -o $(OUTDIR)/debug.o
	gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c $(SRCDIR)/memory.c -o $(OUTDIR)/memory.o

# Link kernel components using the linker script
$(OUTDIR)/kernel.bin: $(OUTDIR)/kernel.o $(OUTDIR)/main.o
	ld -nostdlib -T <(echo -e "$(LINKER_SCRIPT)") -o $(OUTDIR)/kernel $(OUTDIR)/kernel.o $(OUTDIR)/main.o $(OUTDIR)/trapa.o $(OUTDIR)/trap.o $(OUTDIR)/liba.o $(OUTDIR)/print.o $(OUTDIR)/debug.o $(OUTDIR)/memory.o
	objcopy -O binary $(OUTDIR)/kernel $(OUTDIR)/kernel.bin

# Rule to create a blank 10MB boot.img file filled with zeros
$(OUTDIR)/blank.img: | $(OUTDIR)
	dd if=/dev/zero of=$(OUTDIR)/boot.img bs=512 count=20480

# Rule to create the boot.img file from boot.bin, loader.bin, and kernel.bin
$(OUTDIR)/boot.img: $(OUTDIR)/boot.bin $(OUTDIR)/loader.bin $(OUTDIR)/kernel.bin $(OUTDIR)/blank.img
	dd if=$(OUTDIR)/boot.bin of=$(OUTDIR)/boot.img bs=512 count=1 conv=notrunc
	dd if=$(OUTDIR)/loader.bin of=$(OUTDIR)/boot.img bs=512 count=5 seek=1 conv=notrunc
	dd if=$(OUTDIR)/kernel.bin of=$(OUTDIR)/boot.img bs=512 count=100 seek=6 conv=notrunc

# Print all messages along with the output of each command run
verbose:
	@echo "Verbose mode enabled"
	@echo "=> Compiling boot.asm..."
	nasm -f bin -o $(OUTDIR)/boot.bin $(SRCDIR)/boot.asm
	@echo "=> Compiling loader.asm..."
	nasm -f bin -o $(OUTDIR)/loader.bin $(SRCDIR)/loader.asm
	@echo "=> Compiling kernel.asm..."
	nasm -f elf64 -o $(OUTDIR)/kernel.o $(SRCDIR)/kernel.asm
	@echo "=> Compiling main.c..."
	gcc -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone -c $(SRCDIR)/main.c -o $(OUTDIR)/main.o
	@echo "=> Linking kernel components..."
	ld -nostdlib -T <(echo -e "$(LINKER_SCRIPT)") -o $(OUTDIR)/kernel $(OUTDIR)/kernel.o $(OUTDIR)/main.o
	@echo "=> Creating kernel.bin..."
	objcopy -O binary $(OUTDIR)/kernel $(OUTDIR)/kernel.bin
	@echo "=> Boot image created."
	@echo "--- BUILD COMPLETE ---"

# Create the empty 10MB disk image file
blankimg: $(OUTDIR)/blank.img
	@echo "Blank image created"

clean:
	rm -rf $(OUTDIR)/*

release: all
	rm -f $(OUTDIR)/*.o $(OUTDIR)/*.bin
	@echo "Release: Removed .o and .bin files"
