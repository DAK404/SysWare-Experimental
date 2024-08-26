[BITS 16]                       ; Set 16-bit code generation mode (Real mode)
[ORG 0x7e00]                    ; Set the origin where the bootloader will be loaded (0x7e00)

start:
    mov [DriveId], dl           ; Save the drive ID from DL register for later use

    mov si, CHECK_CPU_ID_SUPPORT ; Load the address of the CPUID check message
    call PrintString            ; Print the "Checking Processor Capabilities" message

    ; --- CHECK CPUID SUPPORT --- ;
    mov eax, 0x80000000         ; Set EAX to 0x80000000 to get the highest extended function supported
    cpuid                       ; Call CPUID instruction
    cmp eax, 0x80000001         ; Compare EAX with 0x80000001 (minimum required extended function)
    jb CPUIDNotSupported        ; Jump if EAX is less than 0x80000001 (CPUID not supported)

    mov si, CPU_ID_SUPPORTED    ; Load the address of the "CPUID Supported" message
    call PrintString            ; Print the CPUID supported message

    ; --- CHECK LONG MODE SUPPORT --- ;
    mov si, CHECK_LONG_MODE_SUPPORT ; Load the address of the long mode support check message
    call PrintString            ; Print the "Checking Long Mode Support" message
    mov eax, 0x80000001         ; Set EAX to 0x80000001 to get extended processor info
    cpuid                       ; Call CPUID instruction
    test edx, (1 << 29)         ; Test if bit 29 of EDX is set (indicates long mode support)
    jz LongModeNotSupported     ; Jump if bit 29 is not set (long mode not supported)

    mov si, LONG_MODE_SUPPORTED ; Load the address of the "Long Mode Supported" message
    call PrintString            ; Print the long mode supported message

    ; --- CHECK 1G PAGE SUPPORT --- ;
    mov si, PAGE_1G_SUPPORT_CHECK ; Load the address of the 1G page support check message
    call PrintString            ; Print the "Checking 1G Page Support" message
    test edx, (1 << 26)         ; Test if bit 26 of EDX is set (indicates 1G page support)
    jz Page1GNotSupported       ; Jump if bit 26 is not set (1G page not supported)

    mov si, PAGE_1G_SUPPORTED   ; Load the address of the "1G Page Supported" message
    call PrintString            ; Print the 1G page supported message

StartLoader:

    mov si, START_LOADER        ; Load the address of the loader starting message
    call PrintString            ; Print the loader starting message

    ; --- BIOS EXTENDED READ USING LBA --- ;
    mov si, ReadPacket          ; Load address of the read packet structure
    mov word [si], 0x10         ; Set the packet size (16 bytes)
    mov word [si+2], 100        ; Set number of sectors to read
    mov word [si+4], 0          ; Set upper part of destination address
    mov word [si+6], 0x1000     ; Set destination address in memory
    mov dword [si+8], 6         ; Set starting LBA (Logical Block Address)
    mov dword [si+0xc], 0       ; Set upper part of LBA
    mov dl, [DriveId]           ; Load the previously stored drive ID
    mov ah, 0x42                ; BIOS function to read sectors using LBA
    int 0x13                    ; Call BIOS interrupt 0x13 to read sectors
    jc ReadError                ; Jump if carry flag is set (error occurred)

GetMemInfoStart:

    mov si, INITIALIZE_GET_MEMORY_INFO ; Load the address of the memory info initialization message
    call PrintString            ; Print the message for memory info initialization

    ; --- BIOS MEMORY MAP FETCH USING E820 --- ;
    mov eax, 0xe820             ; Set EAX to 0xe820 for memory map function
    mov edx, 0x534d4150         ; Set EDX to 'SMAP' signature
    mov ecx, 20                 ; Set ECX to size of the buffer (20 bytes)
    mov edi, 0x9000             ; Set EDI to the buffer address for memory map entries
    xor ebx, ebx                ; Clear EBX (EBX must be zero on the first call)
    int 0x15                    ; Call BIOS interrupt 0x15 to get the memory map
    jc GetMemoryInfoFailed      ; Jump if carry flag is set (error occurred)

GetMemInfo:

    mov si, GET_MEMORY_INFO     ; Load the address of the memory info message
    call PrintString            ; Print the memory info message

    add edi, 20                 ; Move to the next memory map entry (20-byte size)
    mov eax, 0xe820             ; Prepare to fetch the next memory map entry
    mov edx, 0x534d4150         ; Set EDX to 'SMAP' signature
    mov ecx, 20                 ; Set ECX to the size of the buffer (20 bytes)
    int 0x15                    ; Call BIOS interrupt to get the memory map
    jc GetMemDone               ; Jump to finish if carry flag is set (no more entries)

    test ebx, ebx               ; Check if EBX is zero (indicating no more entries)
    jnz GetMemInfo              ; If EBX is not zero, continue fetching memory map

GetMemDone:

    mov si, GET_MEMORY_INFO_FINISHED ; Load the address of the memory info completion message
    call PrintString            ; Print the memory info completion message

TestA20:

    mov si, TEST_A20_LINE       ; Load the address of the A20 line test message
    call PrintString            ; Print the A20 line test message

    ; --- A20 LINE TEST --- ;
    mov ax, 0xffff              ; Set AX to 0xffff (prepare to test A20 line)
    mov es, ax                  ; Set ES to 0xffff
    mov word [ds:0x7c00], 0xa200 ; Write a value to memory below 1MB
    cmp word [es:0x7c10], 0xa200 ; Compare with the same memory location above 1MB
    jne SetA20LineDone          ; If not equal, A20 line is working (jump to done)
    mov word [0x7c00], 0xb200   ; Write another value for confirmation
    cmp word [es:0x7c10], 0xb200 ; Compare again with memory above 1MB

    mov si, A20_LINE_UNSUPPORTED ; Load the address of the "A20 line unsupported" message
    call PrintString            ; Print the A20 unsupported message

    je End                      ; Jump to end if A20 line is not enabled
    
SetA20LineDone:

    mov si, A20_LINE_SUPPORTED  ; Load the address of the "A20 line supported" message
    call PrintString            ; Print the A20 supported message

    xor ax, ax                  ; Clear AX
    mov es, ax                  ; Set ES to 0

TestVideoMode:

    mov si, TEST_VIDEO_MODE     ; Load the address of the video mode test message
    call PrintStringVideoMode   ; Call procedure to print to the video buffer
    jmp End                     ; Jump to end


CPUIDNotSupported:
    mov si, CPU_ID_UNSUPPORTED   ; Load the address of the "CPUID unsupported" message
    call PrintString            ; Print the CPUID unsupported message
    jmp End

LongModeNotSupported:
    mov si, LONG_MODE_UNSUPPORTED ; Load the address of the "Long mode unsupported" message
    call PrintString            ; Print the long mode unsupported message
    jmp End

Page1GNotSupported:
    mov si, PAGE_1G_UNSUPPORTED  ; Load the address of the "1G page unsupported" message
    call PrintString            ; Print the 1G page unsupported message
    jmp End

ReadError:
    mov si, LBA_UNSUPPORTED     ; Load the address of the LBA read error message
    call PrintString            ; Print the LBA unsupported message
    jmp End

GetMemoryInfoFailed:
    mov si, GET_MEMORY_INFO_FAILED ; Load the address of the memory info fetch error message
    call PrintString            ; Print the memory info fetch failed message
    jmp End

End:
    hlt                         ; Halt the CPU
    jmp End                     ; Infinite loop to halt

; --- PRINT PROCEDURES AND DATA --- ;

PrintStringVideoMode:
    pusha                       ; Save all registers
    mov ax, 0xb800              ; Set video segment address for text mode (0xb800)
    mov es, ax                  ; Load video segment into ES
    xor di, di                  ; Set DI to 0 (start of video memory)

PrintStringVideoModeLoop:
    mov al, [si]                ; Load byte from string into AL
    cmp al, 0                   ; Check for null terminator
    je EndPrint                 ; End if null terminator is reached

    mov [es:di], al             ; Write character to video memory
    mov byte [es:di+1], 0xa     ; Set color attribute for the character

    add di, 2                   ; Move to the next character location (each char takes 2 bytes)
    add si, 1                   ; Increment string pointer
    jmp PrintStringVideoModeLoop; Repeat the loop

EndPrint:
    popa                        ; Restore all registers
    xor si, si                  ; Clear SI
    ret                         ; Return from the procedure

PrintString:
    pusha                       ; Save all registers
PrintLoop:
    lodsb                       ; Load byte at DS:SI into AL and increment SI
    cmp al, 0                   ; Compare AL with null terminator
    je NewLine                  ; If null terminator, jump to newline
    mov ah, 0x0e                ; Set function for BIOS teletype output
    int 0x10                    ; Call BIOS interrupt to print character in AL
    jmp PrintLoop               ; Repeat the loop
NewLine:
    mov al, 0x0D                ; Carriage return
    int 0x10                    ; Call BIOS interrupt for carriage return
    mov al, 0x0A                ; Line feed
    int 0x10                    ; Call BIOS interrupt for line feed
Done:
    popa                        ; Restore all registers
    ret                         ; Return from the procedure


; --- STATUS MESSAGES --- ;
HEADER_MESSAGE:             db "=> Ymir Bootloader v0.0.1", 0
FOOTER_MESSAGE:             db "=> Starting: SysWare", 0
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

; --- ERROR MESSAGES --- ;
CPU_ID_UNSUPPORTED:         db "[ FAILED ] CPUID 0x80000001 UNSUPPORTED", 0 
LONG_MODE_UNSUPPORTED:      db "[ FAILED ] Long Mode UNSUPPORTED", 0
LBA_UNSUPPORTED:            db "[ FAILED ] Reading Sector in LBA", 0
PAGE_1G_UNSUPPORTED:        db "[ FAILED ] 1G Page UNSUPPORTED", 0
A20_LINE_UNSUPPORTED:       db "[ FAILED ] A20 Line: DISABLED", 0
GET_MEMORY_INFO_FAILED:     db "[ FAILED ] Fetch Memory Info", 0
GENERIC_ERROR:              db "[ FAILED ] Unknown Loader Error", 0

; --- DATA STRUCTURES --- ;
ReadPacket:        times 16 db 0   ; Buffer for the read packet structure
DriveId:                    db 0   ; Variable to store drive ID
