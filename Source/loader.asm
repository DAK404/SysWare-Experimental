[BITS 16]                       ; Set 16-bit code generation
[ORG 0x7e00]                    ; Set the origin, the address where the code will be loaded

start:
    mov [DriveId], dl           ; Save the drive ID from DL register

    mov si, CHECK_CPU_ID_SUPPORT; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    ; --- CHECK CPUID SUPPORT --- ;
    mov eax, 0x80000000         ; Set EAX to 0x80000000 to get the highest extended function supported
    cpuid                       ; Call CPUID instruction
    cmp eax, 0x80000001         ; Compare EAX with 0x80000001
    jb CPUIDNotSupported        ; Jump to NotSupport if EAX is below 0x80000001

    mov si, CPU_ID_SUPPORTED    ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    ; --- CHECK LONG MODE SUPPORT --- ;
    mov si, CHECK_LONG_MODE_SUPPORT; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message
    mov eax, 0x80000001         ; Set EAX to 0x80000001 to get extended processor info
    cpuid                       ; Call CPUID instruction
    test edx, (1 << 29)         ; Test if bit 29 of EDX is set (long mode support)
    jz LongModeNotSupported     ; Jump to LongModeNotSupported if bit 29 is not set

    mov si, LONG_MODE_SUPPORTED; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    ; --- CHECK 1G PAGE SUPPORT --- ;
    mov si, PAGE_1G_SUPPORT_CHECK; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    test edx, (1 << 26)         ; Test if bit 26 of EDX is set (1G Page support)
    jz Page1GNotSupported       ; Jump to 1GPageNotSupported if bit 26 is not set

    mov si, PAGE_1G_SUPPORTED   ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

StartLoader:

    mov si, START_LOADER        ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    mov si, ReadPacket          ; Load address of ReadPacket structure
    mov word [si], 0x10         ; Set size of packet
    mov word [si+2], 100        ; Set number of sectors to read
    mov word [si+4], 0          ; Set upper part of destination address
    mov word [si+6], 0x1000     ; Set destination address
    mov dword [si+8], 6         ; Set starting LBA (Logical Block Address)
    mov dword [si+0xc], 0       ; Set upper part of LBA
    mov dl, [DriveId]           ; Load drive ID
    mov ah, 0x42                ; BIOS function to read with extensions
    int 0x13                    ; Call BIOS interrupt
    jc ReadError                ; Jump to ReadError if carry flag is set (error)

GetMemInfoStart:

    mov si, INITIALIZE_GET_MEMORY_INFO     ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    mov eax, 0xe820             ; Set EAX to 0xe820 for memory map
    mov edx, 0x534d4150         ; Set EDX to 'SMAP' signature
    mov ecx, 20                 ; Set ECX to size of the buffer
    mov edi, 0x9000             ; Set EDI to buffer address
    xor ebx, ebx                ; Clear EBX
    int 0x15                    ; Call BIOS interrupt
    jc GetMemoryInfoFailed      ; Jump to NotSupport if carry flag is set (error)

GetMemInfo:

    mov si, GET_MEMORY_INFO; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    add edi, 20                 ; Move to the next memory map entry
    mov eax, 0xe820             ; Set EAX to 0xe820 for memory map
    mov edx, 0x534d4150         ; Set EDX to 'SMAP' signature
    mov ecx, 20                 ; Set ECX to size of the buffer
    int 0x15                    ; Call BIOS interrupt
    jc GetMemDone               ; Jump to GetMemDone if carry flag is set (error)

    test ebx, ebx               ; Test if EBX is zero
    jnz GetMemInfo              ; Jump to GetMemInfo if EBX is not zero

GetMemDone:

    mov si, GET_MEMORY_INFO_FINISHED; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

TestA20:

    mov si, TEST_A20_LINE       ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    mov ax, 0xffff              ; Set AX to 0xffff
    mov es, ax                  ; Set ES to 0xffff
    mov word [ds:0x7c00], 0xa200 ; Write 0xa200 to memory at DS:0x7c00
    cmp word [es:0x7c10], 0xa200 ; Compare with memory at ES:0x7c10
    jne SetA20LineDone          ; Jump to SetA20LineDone if not equal
    mov word [0x7c00], 0xb200   ; Write 0xb200 to memory at 0x7c00
    cmp word [es:0x7c10], 0xb200 ; Compare with memory at ES:0x7c10

    mov si, A20_LINE_UNSUPPORTED ; Load the address of the LBA not supported message
    call PrintString             ; Print the LBA not supported message

    je End                      ; Jump to End if equal
    
SetA20LineDone:

    mov si, A20_LINE_SUPPORTED  ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message

    xor ax, ax                  ; Clear AX
    mov es, ax                  ; Set ES to 0

TestVideoMode:

    mov si, TEST_VIDEO_MODE
    call PrintStringVideoMode
    jmp End


CPUIDNotSupported:
    mov si, CPU_ID_UNSUPPORTED   ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message
    jmp End

LongModeNotSupported:
    mov si, LONG_MODE_UNSUPPORTED   ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message
    jmp End

Page1GNotSupported:
    mov si, PAGE_1G_UNSUPPORTED   ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message
    jmp End

ReadError:
    mov si, LBA_UNSUPPORTED   ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message
    jmp End

GetMemoryInfoFailed:
    mov si, GET_MEMORY_INFO_FAILED   ; Load the address of the LBA not supported message
    call PrintString            ; Print the LBA not supported message
    jmp End

End:
    hlt                         ; Halt the CPU
    jmp End                     ; Infinite loop to halt

; --- VIDEO MODE PRINT LABELS --- ;

PrintStringVideoMode:
    pusha
    mov ax, 0xb800
    mov es, ax
    xor di, di

PrintStringVideoModeLoop:
    mov al, [si]
    cmp al, 0
    je EndPrint

    mov [es:di], al
    mov byte [es:di+1], 0xa

    add di, 2
    add si, 1
    jmp PrintStringVideoModeLoop

EndPrint:
    popa
    xor si, si
    ret

; --- BIOS PRINT LABELS --- ;

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
HEADER_MESSAGE:         db "=> Ymir Bootloader v0.0.1", 0
FOOTER_MESSAGE:         db "=> Starting: SysWare", 0

; --- PROGRESS MESSAGES ---;    : Messages to be printed onto the screen to denote progress during kernel loading (null-terminated)
CHECK_CPU_ID_SUPPORT:       db "> CHECKING: Processor Capabilities...", 0
CPU_ID_SUPPORTED:           db "[  DONE  ] CPUID Capabilities Supported", 0
CHECK_LONG_MODE_SUPPORT:    db "> CHECKING: Long Mode Support", 0
LONG_MODE_SUPPORTED:        db "[  DONE  ] Long Mode Supported!", 0
PAGE_1G_SUPPORT_CHECK:      db "> CHECKING: 1G Page Support", 0
PAGE_1G_SUPPORTED:          db "[  DONE  ] 1G Page Supported!", 0
START_LOADER:               db "> STARTING: SysWare Loader v0.0.1", 0
INITIALIZE_GET_MEMORY_INFO: db "> STARTING: Fetch Memory Information", 0
GET_MEMORY_INFO:            db "> CHECKING: Memory Information", 0 
GET_MEMORY_INFO_FINISHED:   db "[  DONE  ] Fetch Memory Information", 0
TEST_A20_LINE:              db "> CHECKING: A20 Line", 0
A20_LINE_SUPPORTED:         db "[  DONE  ] A20 Line: ENABLED", 0
SET_VIDEO_MODE:             db "[  DONE  ] Set Video Mode -> Text Mode", 0
TEST_VIDEO_MODE:            db "[  DONE  ] Text Video Mode: ENABLED",0

; --- LOAD ERROR MESSAGES --- ; : Messages to be printed onto the screen to denote any errors (null-terminated)
CPU_ID_UNSUPPORTED:         db "[ FAILED ] CPUID 0x80000001 UNSUPPORTED", 0 
LONG_MODE_UNSUPPORTED:      db "[ FAILED ] Long Mode UNSUPPORTED", 0
LBA_UNSUPPORTED:            db "[ FAILED ] Reading Sector in LBA", 0
PAGE_1G_UNSUPPORTED:        db "[ FAILED ] 1G Page UNSUPPORTED", 0
A20_LINE_UNSUPPORTED:       db "[ FAILED ] A20 Line: DISABLED", 0
GET_MEMORY_INFO_FAILED:     db "[ FAILED ] Fetch Memory Info", 0
GENERIC_ERROR:              db "[ FAILED ] Unknown Loader Error", 0

ReadPacket: times 16 db 0       ; Buffer for the read packet structure
DriveId:    db 0                ; Variable to store drive ID
