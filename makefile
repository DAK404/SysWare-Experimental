# Variables
CC = gcc
NASM = nasm
LD = ld
OBJCOPY = objcopy
DD = dd
CFLAGS = -std=c99 -mcmodel=large -ffreestanding -fno-stack-protector -mno-red-zone
NASMFLAGS = -f elf64
NASMBINFLAGS = -f bin
LDFLAGS_KERNEL = -nostdlib -T $(SRCDIR)/kernel.lds
LDFLAGS_USR = -nostdlib -T $(SRCDIR)/usr/user.lds
BINDIR = ./Binaries
SRCDIR = ./Source

# Create directories if they do not exist
$(shell mkdir -p $(BINDIR)/usrlib $(BINDIR)/usr)

# Targets
all: $(BINDIR)/boot.img

# Compiling ./Source/usrlib directory
$(BINDIR)/usrlib/syscall.o: $(SRCDIR)/usrlib/syscall.asm
	$(NASM) $(NASMFLAGS) -o $@ $<
$(BINDIR)/usrlib/print.o: $(SRCDIR)/usrlib/print.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/usrlib/lib.a: $(BINDIR)/usrlib/print.o $(BINDIR)/usrlib/syscall.o
	ar rcs $@ $^

# Compiling the ./Source/usr directory
$(BINDIR)/usr/start.o: $(SRCDIR)/usr/start.asm
	$(NASM) $(NASMFLAGS) -o $@ $<
$(BINDIR)/usr/main.o: $(SRCDIR)/usr/main.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/usr/user: $(BINDIR)/usr/start.o $(BINDIR)/usr/main.o $(BINDIR)/usrlib/lib.a
	$(LD) $(LDFLAGS_USR) -o $@ $^
$(BINDIR)/usr/user.bin: $(BINDIR)/usr/user
	$(OBJCOPY) -O binary $< $@

# Compiling the ./Source directory
$(BINDIR)/boot.img: $(BINDIR)/boot.bin $(BINDIR)/loader.bin $(BINDIR)/kernel.bin $(BINDIR)/usr/user.bin
	$(DD) if=/dev/zero of=$@ bs=512 count=204800
	$(DD) if=$(BINDIR)/boot.bin of=$@ bs=512 count=1 conv=notrunc
	$(DD) if=$(BINDIR)/loader.bin of=$@ bs=512 count=5 seek=1 conv=notrunc
	$(DD) if=$(BINDIR)/kernel.bin of=$@ bs=512 count=100 seek=6 conv=notrunc
	$(DD) if=$(BINDIR)/usr/user.bin of=$@ bs=512 count=10 seek=106 conv=notrunc

$(BINDIR)/boot.bin: $(SRCDIR)/boot.asm
	$(NASM) $(NASMBINFLAGS) -o $@ $<
$(BINDIR)/loader.bin: $(SRCDIR)/loader.asm
	$(NASM) $(NASMBINFLAGS) -o $@ $<
$(BINDIR)/kernel.o: $(SRCDIR)/kernel.asm
	$(NASM) $(NASMFLAGS) -o $@ $<
$(BINDIR)/trapa.o: $(SRCDIR)/trap.asm
	$(NASM) $(NASMFLAGS) -o $@ $<
$(BINDIR)/liba.o: $(SRCDIR)/lib.asm
	$(NASM) $(NASMFLAGS) -o $@ $<
$(BINDIR)/main.o: $(SRCDIR)/main.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/trap.o: $(SRCDIR)/trap.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/print.o: $(SRCDIR)/print.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/debug.o: $(SRCDIR)/debug.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/memory.o: $(SRCDIR)/memory.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/process.o: $(SRCDIR)/process.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/syscall.o: $(SRCDIR)/syscall.c
	$(CC) $(CFLAGS) -c -o $@ $<
$(BINDIR)/kernel: $(BINDIR)/kernel.o $(BINDIR)/main.o $(BINDIR)/trapa.o $(BINDIR)/trap.o $(BINDIR)/liba.o $(BINDIR)/print.o $(BINDIR)/debug.o $(BINDIR)/memory.o $(BINDIR)/process.o $(BINDIR)/syscall.o
	$(LD) $(LDFLAGS_KERNEL) -o $@ $^
$(BINDIR)/kernel.bin: $(BINDIR)/kernel
	$(OBJCOPY) -O binary $< $@

# Clean up
clean:
	rm -f $(BINDIR)/usrlib/*.o $(BINDIR)/usrlib/*.a $(BINDIR)/usr/*.o $(BINDIR)/usr/*.bin $(BINDIR)/*.o $(BINDIR)/*.bin $(BINDIR)/kernel $(BINDIR)/boot.img
