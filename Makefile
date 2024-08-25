# Define the target for the bootloader
.PHONY: all clean

# Output and source directories
OUTDIR = ./Binaries
SRCDIR = ./Source

# Default target
all: $(OUTDIR)/boot.img

# Rule to create the output directory if it doesn't exist
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Rule to create the boot.bin file from boot.asm
$(OUTDIR)/boot.bin: $(SRCDIR)/boot.asm | $(OUTDIR)
	nasm -f bin -o $(OUTDIR)/boot.bin $(SRCDIR)/boot.asm
	nasm -f bin -o $(OUTDIR)/loader.bin $(SRCDIR)/loader.asm

# Rule to create a blank 10MB boot.img file filled with zeros
$(OUTDIR)/blank.img: | $(OUTDIR)
	dd if=/dev/zero of=$(OUTDIR)/boot.img bs=512 count=20480

# Rule to create the boot.img file from boot.bin
$(OUTDIR)/boot.img: $(OUTDIR)/boot.bin $(OUTDIR)/blank.img
	dd if=$(OUTDIR)/boot.bin of=$(OUTDIR)/boot.img bs=512 count=1 conv=notrunc
	dd if=$(OUTDIR)/loader.bin of=$(OUTDIR)/boot.img bs=512 count=5 seek=1 conv=notrunc

# Clean up generated files
clean:
	rm -rf $(OUTDIR)/*
