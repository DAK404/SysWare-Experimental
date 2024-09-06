section .data                ; Data section starts here
global Tss

Gdt64:                       ; 64-bit Global Descriptor Table (GDT) starts here
    dq 0                     ; Null descriptor (first entry is always unused)
    dq 0x0020980000000000     ; 64-bit Code Segment Descriptor
                              ; Access byte: 1001 1010 (Present, DPL=0, Code segment, Executable)
                              ; Flags: 0010 1000 (Long Mode, 4KB granularity)
    dq 0x0020f80000000000     ; 64-bit Data Segment Descriptor
                              ; Access byte: 1001 0010 (Present, DPL=0, Data segment, Writable)
                              ; Flags: 1111 1000 (4KB granularity, 64-bit)
    dq 0x0000f20000000000     ; 64-bit Stack Segment Descriptor (optional, not commonly used)
                              ; Access byte: 1001 0010 (Present, DPL=0, Stack segment)
                              ; Flags: 1111 0010 (4KB granularity)

TssDesc:                     ; Task State Segment (TSS) descriptor
    dw TssLen-1              ; TSS segment limit (TssLen - 1)
    dw 0                     ; TSS segment base address (lower 16 bits)
    db 0                     ; Base address (bits 16-23)
    db 0x89                  ; Access byte: 1000 1001 (Present, DPL=0, TSS descriptor, not busy)
    db 0                     ; Flags (bits 20-23 unused, 4-bit)
    db 0                     ; Base address (bits 24-31)
    dq 0                     ; Base address (bits 32-63)

Gdt64Len: equ $-Gdt64        ; Calculate the length of the GDT

Gdt64Ptr: dw Gdt64Len-1      ; GDT length minus 1 (for the `lgdt` instruction)
          dq Gdt64           ; Pointer to the GDT base (GDT64)

Tss:                         ; Task State Segment (TSS) structure
    dd 0                     ; Reserved
    dq 0xffff800000190000    ; Stack pointer (top of stack)
    times 88 db 0            ; Reserved and other fields (zeroed out)
    dd TssLen                ; TSS length field

TssLen: equ $-Tss            ; Calculate the length of the TSS

section .text                ; Code section starts here
extern KMain                 ; Declare external function KMain
global start                 ; Make 'start' globally accessible

start:
    mov rax, Gdt64Ptr
    lgdt [rax]          ; Load the 64-bit GDT with the lgdt instruction

SetTss:                      ; Set up the TSS descriptor
    mov rax, Tss             ; Load the address of the TSS into RAX
    mov rdi, TssDesc
    mov [rdi+2], ax      ; Set the lower 16 bits of the TSS base in the descriptor
    shr rax, 16              ; Shift RAX to get the next 8 bits
    mov [rdi+4], al      ; Set the next 8 bits of the TSS base
    shr rax, 8               ; Shift again for the next 8 bits
    mov [rdi+7], al      ; Set the next 8 bits of the TSS base
    shr rax, 8               ; Shift again for the remaining 32 bits
    mov [rdi+8], eax     ; Set the remaining 32 bits of the TSS base
    mov ax, 0x20             ; Load the TSS segment selector (0x20 corresponds to the TSS entry in the GDT)
    ltr ax                   ; Load the Task Register with the TSS descriptor

InitPIT:                     ; Initialize the Programmable Interval Timer (PIT)
    mov al, (1<<2)|(3<<4)    ; Set PIT to mode 3 (square wave generator) on channel 0
    out 0x43, al             ; Send the command byte to the PIT control port (0x43)
    
    mov ax, 11931            ; Set the PIT frequency to 100 Hz (1193182 / 100)
    out 0x40, al             ; Send the low byte to the PIT channel 0 data port (0x40)
    mov al, ah               ; Send the high byte
    out 0x40, al             ; Send the high byte to the PIT channel 0 data port

InitPIC:                     ; Initialize the Programmable Interrupt Controller (PIC)
    mov al, 0x11             ; Start initialization sequence (ICW1)
    out 0x20, al             ; Send ICW1 to master PIC (port 0x20)
    out 0xa0, al             ; Send ICW1 to slave PIC (port 0xa0)

    mov al, 32               ; Set interrupt vector offset for master PIC to 32
    out 0x21, al             ; Send ICW2 to master PIC (port 0x21)
    mov al, 40               ; Set interrupt vector offset for slave PIC to 40
    out 0xa1, al             ; Send ICW2 to slave PIC (port 0xa1)

    mov al, 4                ; Tell master PIC there is a slave at IRQ2
    out 0x21, al             ; Send ICW3 to master PIC
    mov al, 2                ; Tell slave PIC its cascade identity (connected to IRQ2 of master)
    out 0xa1, al             ; Send ICW3 to slave PIC

    mov al, 1                ; Set 8086/88 (MCS-80/85) mode
    out 0x21, al             ; Send ICW4 to master PIC
    out 0xa1, al             ; Send ICW4 to slave PIC

    mov al, 11111110b        ; Enable all IRQs except IRQ0 (timer interrupt) on master PIC
    out 0x21, al             ; Send mask to master PIC
    mov al, 11111111b        ; Mask all IRQs on slave PIC
    out 0xa1, al             ; Send mask to slave PIC

    mov rax, KernelEntry
    push 8                   ; Push the code segment selector for the kernel (0x08) onto the stack
    push rax                 ; Push the address of KernelEntry onto the stack
    db 0x48                  ; Indicate that we are using 64-bit mode for the far return
    retf                     ; Far return to the KernelEntry in 64-bit mode

KernelEntry:                 ; Kernel entry point
    mov rsp,0xffff800000200000
    call KMain               ; Call the main kernel function
    sti                      ; Enable interrupts

End:
    hlt                      ; Halt the CPU
    jmp End                  ; Infinite loop to prevent returning from kernel
