[BITS 16]                       ; Set 16-bit code generation
[ORG 0x7c00]                    ; Set the origin, the address where the code will be loaded

start:

    mov si, HEADER_MESSAGE      ; Load the address of the initialization message
    call PrintString            ; Print the initialization message

    mov si, INITIALIZE_REGISTERS; Load the address of the initialization message
    call PrintString            ; Print the initialization message

    xor ax, ax                  ; Clear AX register
    mov ds, ax                  ; Set Data Segment to 0
    mov es, ax                  ; Set Extra Segment to 0
    mov ss, ax                  ; Set Stack Segment to 0
    mov sp, 0x7c00              ; Set Stack Pointer to 0x7c00

TestDiskExtension:

    mov si, CHECK_DES_CAPABILITY ; Load the address of the DES capability check message
    call PrintString             ; Print the DES capability check message

    mov [DriveId], dl           ; Save drive ID from DL register
    mov ah, 0x41                ; BIOS function to check if extensions are supported
    mov bx, 0x55aa              ; Magic number to identify the request
    int 0x13                    ; Call BIOS interrupt
    jc NotSupported             ; Jump if carry flag is set (error)
    cmp bx, 0xaa55              ; Check if BIOS supports extensions
    jne NotSupported            ; Jump if not equal (extensions not supported)

    mov si, DES_SUPPORTED       ; Load the address of the DES supported message
    call PrintString            ; Print the DES supported message

StartBootLoader:

    mov si, START_BOOTLOADER    ; Load the address of the bootloader start message
    call PrintString            ; Print the bootloader start message

    mov si, ReadPacket          ; Load address of ReadPacket structure
    mov word [si], 0x10         ; Set size of packet
    mov word [si+2], 5          ; Set number of sectors to read
    mov word [si+4], 0x7e00     ; Set destination address
    mov word [si+6], 0          ; Set upper part of destination address
    mov dword [si+8], 1         ; Set starting LBA (Logical Block Address)
    mov dword [si+0xc], 0       ; Set upper part of LBA
    mov dl, [DriveId]           ; Load drive ID
    mov ah, 0x42                ; BIOS function to read with extensions
    int 0x13                    ; Call BIOS interrupt
    jc ReadError                ; Jump if carry flag is set (error)

    mov si, FOOTER_MESSAGE      ; Load the address of the initialization message
    call PrintString            ; Print the initialization message

    mov si, BOOTLOADER_STARTED  ; Load the address of the bootloader started message
    call PrintString            ; Print the bootloader started message

    jmp 0x7e00                  ; Jump to bootloader code

ReadError:
    mov si, LBA_UNSUPPORTED   ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message
    jmp End

NotSupported:
    mov si, DES_UNSUPPORTED   ; Load the address of the DES not supported message
    call PrintString            ; Print the DES not supported message
    jmp End

UnknownBootError:
    mov si, GENERIC_ERROR       ; Load the address of the generic error message
    call PrintString            ; Print the generic error message
    jmp End

End:
    hlt                         ; Halt the CPU
    jmp End                     ; Infinite loop to halt

PrintString:
    pusha                       ; Save all registers
PrintLoop:
    lodsb                       ; Load byte at DS:SI into AL and increment SI
    cmp al, 0                   ; Compare AL with null terminator
    je NewLine                  ; If null terminator, jump to NewLine
    mov ah, 0x0e                ; BIOS teletype output function
    int 0x10                    ; Call BIOS interrupt to print character in AL
    jmp PrintLoop               ; Repeat the loop
NewLine:
    mov al, 0x0D                ; Carriage return
    int 0x10                    ; Call BIOS interrupt to print character in AL
    mov al, 0x0A                ; Line feed
    int 0x10                    ; Call BIOS interrupt to print character in AL
Done:
    popa                        ; Restore all registers
    ret                         ; Return from the procedure

; --- HEADER/FOOTER MESSAGES --- ;
HEADER_MESSAGE:         db "=> Booting System", 0
FOOTER_MESSAGE:         db "=> BOOT COMPLETE!", 0

; --- PROGRESS MESSAGES ---;    : Messages to be printed onto the screen to denote progress during boot (null-terminated)
INITIALIZE_REGISTERS:   db "Initializing Registers", 0
CHECK_DES_CAPABILITY:   db "Checking Disk Extension Service", 0
DES_SUPPORTED:          db "Disk Extension Service Supported!", 0
START_BOOTLOADER:       db "Starting Ymir", 0
BOOTLOADER_STARTED:     db "Started: Ymir v0.0.1", 0

; --- BOOT ERROR MESSAGES --- ; : Messages to be printed onto the screen to denote any errors (null-terminated)
GENERIC_ERROR:          db "UNKNOWN BOOT ERROR!", 0
DES_UNSUPPORTED:        db "Disk Extension Service: NOT SUPPORTED.", 0
LBA_UNSUPPORTED:        db "LBA: SECTOR READ FAILED.", 0

ReadPacket:    times 16 db 0    ; Buffer for the read packet structure
DriveId:                db 0    ; Variable to store drive ID

times (0x1be-($-$$)) db 0       ; Fill the rest of the boot sector with zeros

    db 0x80                     ; Indicate partition is bootable
    db 0, 2, 0                  ; Indicate the CHS start value
    db 0x0f0                    ; Indicate the partition type as a Linux/PA-RISC partition
    db 0xff, 0xff, 0xff         ; Indicate the CHS end value
    dd 1                        ; Indicate the LBA address for starting sector
    dd (20*16*63-1)             ; Indicate the number of sectors the partition has (size of the partition)

    times (16*3) db 0           ; Insert 48 bytes of 0s to ensure that the boot sector is exactly 512 bytes long

    dw 0xaa55                   ; Signature of the boot file
