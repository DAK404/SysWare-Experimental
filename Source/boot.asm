[BITS 16]                       ; Set 16-bit code generation mode (Real mode)
[ORG 0x7c00]                    ; Set the origin where the bootloader will be loaded (0x7c00)

start:

    mov si, HEADER_MESSAGE      ; Load the address of the boot header message
    call PrintString            ; Print the boot header message

    mov si, INITIALIZE_REGISTERS; Load the address of the register initialization message
    call PrintString            ; Print the register initialization message

    xor ax, ax                  ; Clear AX register
    mov ds, ax                  ; Set Data Segment (DS) to 0
    mov es, ax                  ; Set Extra Segment (ES) to 0    
    mov ss, ax                  ; Set Stack Segment (SS) to 0
    mov sp, 0x7c00              ; Set Stack Pointer (SP) to 0x7c00, as a safe location below 1MB

TestDiskExtension:

    mov si, CHECK_DES_CAPABILITY ; Load the address of the disk extension service check message
    call PrintString             ; Print the disk extension service check message

    mov [DriveId], dl           ; Save the drive ID (from DL register)
    mov ah, 0x41                ; BIOS function to check if Disk Extension Services (DES) are supported
    mov bx, 0x55aa              ; Magic number to identify DES support request
    int 0x13                    ; Call BIOS interrupt for disk services
    jc NotSupported             ; Jump to NotSupported if carry flag is set (error occurred)
    cmp bx, 0xaa55              ; Check if BIOS returned the correct identifier for DES
    jne NotSupported            ; Jump if DES is not supported

    mov si, DES_SUPPORTED       ; Load the address of the DES supported message
    call PrintString            ; Print that DES is supported

StartBootLoader:

    mov si, START_BOOTLOADER    ; Load the address of the bootloader start message
    call PrintString            ; Print the bootloader start message

    mov si, ReadPacket          ; Load the address of the read packet structure
    mov word [si], 0x10         ; Set the size of the packet (16 bytes)
    mov word [si+2], 5          ; Set the number of sectors to read (5 sectors)
    mov word [si+4], 0x7e00     ; Set the destination memory address to load the sectors
    mov word [si+6], 0          ; Clear the upper part of the destination address (since it's in 16-bit mode)
    mov dword [si+8], 1         ; Set the starting LBA (Logical Block Address) to 1
    mov dword [si+0xc], 0       ; Clear the upper part of the LBA
    mov dl, [DriveId]           ; Load the drive ID previously saved
    mov ah, 0x42                ; BIOS function for reading using LBA
    int 0x13                    ; Call BIOS interrupt to read sectors
    jc ReadError                ; Jump to ReadError if an error occurred

    mov si, FOOTER_MESSAGE      ; Load the address of the footer message
    call PrintString            ; Print the footer message

    mov si, BOOTLOADER_STARTED  ; Load the address of the bootloader started message
    call PrintString            ; Print the bootloader started message

    jmp 0x7e00                  ; Jump to the address where the bootloader code is loaded

ReadError:
    mov si, LBA_UNSUPPORTED     ; Load the address of the LBA read error message
    call PrintString            ; Print the LBA read error message
    jmp End                     ; Jump to the end (halt)

NotSupported:
    mov si, DES_UNSUPPORTED     ; Load the address of the DES unsupported message
    call PrintString            ; Print the DES unsupported message
    jmp End                     ; Jump to the end (halt)

UnknownBootError:
    mov si, GENERIC_ERROR       ; Load the address of the generic error message
    call PrintString            ; Print the generic error message
    jmp End                     ; Jump to the end (halt)

End:
    hlt                         ; Halt the CPU
    jmp End                     ; Infinite loop to halt the system

; --- PrintString Procedure --- ;
PrintString:
    pusha                       ; Save all general-purpose registers
PrintLoop:
    lodsb                       ; Load byte from the string (DS:SI) into AL and increment SI
    cmp al, 0                   ; Compare AL with null terminator (0)
    je NewLine                  ; If null terminator is reached, jump to NewLine
    mov ah, 0x0e                ; Set BIOS teletype output function (AH = 0x0E)
    int 0x10                    ; Call BIOS interrupt to print character in AL
    jmp PrintLoop               ; Repeat the loop until the end of the string
NewLine:
    mov al, 0x0D                ; Carriage return (CR)
    int 0x10                    ; Call BIOS interrupt to print CR
    mov al, 0x0A                ; Line feed (LF)
    int 0x10                    ; Call BIOS interrupt to print LF
Done:
    popa                        ; Restore all general-purpose registers
    ret                         ; Return from the procedure

; --- STATUS MESSAGES --- ;
HEADER_MESSAGE:         db "=> Booting System", 0       ; Initialization message
FOOTER_MESSAGE:         db "=> BOOT COMPLETE!", 0       ; Boot completion message
INITIALIZE_REGISTERS:   db "Initializing Registers", 0  ; Register initialization message
CHECK_DES_CAPABILITY:   db "Checking Disk Extension Service", 0  ; Check for DES support
DES_SUPPORTED:          db "Disk Extension Service Supported!", 0 ; DES supported message
START_BOOTLOADER:       db "Starting Ymir", 0           ; Bootloader start message
BOOTLOADER_STARTED:     db "Started: Ymir v0.0.1", 0    ; Bootloader started message

; --- ERROR MESSAGES --- ;
GENERIC_ERROR:          db "UNKNOWN BOOT ERROR!", 0     ; Generic error message
DES_UNSUPPORTED:        db "Disk Extension Service: NOT SUPPORTED.", 0 ; DES unsupported message
LBA_UNSUPPORTED:        db "LBA: SECTOR READ FAILED.", 0 ; LBA read error message

; --- DATA STRUCTURES --- ;
ReadPacket:    times 16 db 0    ; Buffer for the read packet structure (16 bytes)
DriveId:                db 0    ; Variable to store drive ID

; --- BOOT SECTOR DATA --- ;
times (0x1be-($-$$)) db 0       ; Fill the remaining space before the partition table with zeros

    db 0x80                     ; Indicate that the partition is bootable
    db 0, 2, 0                  ; CHS start value
    db 0x0f0                    ; Partition type (Linux/PA-RISC)
    db 0xff, 0xff, 0xff         ; CHS end value
    dd 1                        ; LBA starting sector
    dd (20*16*63-1)             ; Number of sectors (partition size)

    times (16*3) db 0           ; Pad with 48 bytes of zeros to make the boot sector 512 bytes

    dw 0xaa55                   ; Boot sector signature (0xAA55)
