section .text
    extern handler             ; External function to handle the interrupts
    global vector0             ; Define vector0 as global
    global vector1             ; Define vector1 as global
    global vector2             ; Define vector2 as global
    global vector3             ; Define vector3 as global
    global vector4             ; Define vector4 as global
    global vector5             ; Define vector5 as global
    global vector6             ; Define vector6 as global
    global vector7             ; Define vector7 as global
    global vector8             ; Define vector8 as global
    global vector10            ; Define vector10 as global
    global vector11            ; Define vector11 as global
    global vector12            ; Define vector12 as global
    global vector13            ; Define vector13 as global
    global vector14            ; Define vector14 as global
    global vector16            ; Define vector16 as global
    global vector17            ; Define vector17 as global
    global vector18            ; Define vector18 as global
    global vector19            ; Define vector19 as global
    global vector32            ; Define vector32 as global
    global vector39            ; Define vector39 as global
    global eoi                 ; End of Interrupt handler
    global read_isr            ; Read In-Service Register (ISR)
    global load_idt            ; Load the Interrupt Descriptor Table (IDT)

; Trap: This is a generic interrupt handler that saves the state of all registers
Trap:
    push rax                   ; Save general-purpose registers
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    ; inc byte[0xb8000]          ; Increment the value at memory address 0xb8000 (for visual feedback)
    ; mov byte[0xb8001],0xe      ; Set color attribute (light yellow text) for output at 0xb8000

    mov rdi, rsp               ; Pass current stack pointer to the handler
    call handler               ; Call the external handler function

TrapReturn:
    pop r15                    ; Restore all registers
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    add rsp, 16                ; Adjust the stack pointer
    iretq                      ; Return from the interrupt (64-bit interrupt return)

; Interrupt Vectors: Each vector pushes the interrupt number onto the stack and jumps to Trap

vector0:
    push 0                     ; Push interrupt number 0
    push 0                     ; Push error code 0
    jmp Trap                   ; Jump to the common Trap handler

vector1:
    push 0
    push 1
    jmp Trap

vector2:
    push 0
    push 2
    jmp Trap

vector3:
    push 0
    push 3
    jmp Trap

vector4:
    push 0
    push 4
    jmp Trap

vector5:
    push 0
    push 5
    jmp Trap

vector6:
    push 0
    push 6
    jmp Trap

vector7:
    push 0
    push 7
    jmp Trap

vector8:
    push 8                     ; Vector 8 has a predefined error code 8
    jmp Trap

vector10:
    push 10                    ; Vector 10 has a predefined error code 10
    jmp Trap

vector11:
    push 11                    ; Vector 11 has a predefined error code 11
    jmp Trap

vector12:
    push 12                    ; Vector 12 has a predefined error code 12
    jmp Trap

vector13:
    push 13                    ; Vector 13 has a predefined error code 13
    jmp Trap

vector14:
    push 14                    ; Vector 14 has a predefined error code 14
    jmp Trap

vector16:
    push 0
    push 16
    jmp Trap

vector17:
    push 17                    ; Vector 17 has a predefined error code 17
    jmp Trap

vector18:
    push 0
    push 18
    jmp Trap

vector19:
    push 0
    push 19
    jmp Trap

vector32:
    push 0                     ; IRQ 0 (Timer interrupt)
    push 32                    ; Push interrupt number 32
    jmp Trap

vector39:
    push 0                     ; IRQ 7 (Parallel port interrupt)
    push 39                    ; Push interrupt number 39
    jmp Trap

; End of Interrupt (EOI) handler: Sends EOI signal to the Programmable Interrupt Controller (PIC)
eoi:
    mov al, 0x20               ; Prepare EOI signal
    out 0x20, al               ; Send EOI to PIC
    ret                        ; Return from the function

; Read In-Service Register (ISR) from PIC
read_isr:
    mov al, 11                 ; Command to read ISR
    out 0x20, al               ; Send command to PIC
    in al, 0x20                ; Read ISR into al
    ret                        ; Return from the function

; Load IDT (Interrupt Descriptor Table)
; Input:
;   rdi: pointer to the IDT descriptor
load_idt:
    lidt [rdi]                 ; Load the IDT using the address in rdi
    ret                        ; Return from the function
