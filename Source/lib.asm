section .text
global memset              ; Declare memset as a global function
global memcpy              ; Declare memcpy as a global function
global memmove             ; Declare memmove as a global function
global memcmp              ; Declare memcmp as a global function

; memset: Fills a block of memory with a specified byte
; Inputs:
;   rdi: pointer to the memory area to fill
;   sil: byte to fill with
;   edx: number of bytes to fill
memset:
    cld                     ; Clear direction flag (forward direction for string operations)
    mov ecx, edx            ; Move the count (number of bytes) into ecx
    mov al, sil             ; Move the fill byte into al
    rep stosb               ; Repeat storing the byte in al to memory (rdi), ecx times
    ret                     ; Return from the function

; memcmp: Compares two blocks of memory byte by byte
; Inputs:
;   rsi: pointer to the first memory area
;   rdi: pointer to the second memory area
;   edx: number of bytes to compare
; Outputs:
;   eax: 0 if memory blocks are equal, non-zero if they are different
memcmp:
    cld                     ; Clear direction flag (forward direction for string operations)
    xor eax, eax            ; Set eax to 0 (this will be the return value for equality)
    mov ecx, edx            ; Move the count (number of bytes) into ecx
    repe cmpsb              ; Repeat comparing bytes from rsi and rdi, stop on mismatch or when ecx reaches 0
    setnz al                ; Set al to 1 if the comparison was not zero (memory blocks differ)
    ret                     ; Return from the function

; memcpy: Copies memory from source to destination
; memmove: Same as memcpy, but handles overlapping memory regions
; Inputs:
;   rdi: pointer to the destination memory area
;   rsi: pointer to the source memory area
;   edx: number of bytes to copy
memcpy:
memmove:
    cld                     ; Clear direction flag (forward direction for string operations)
    cmp rsi, rdi            ; Compare source and destination pointers
    jae .copy               ; If source address >= destination, no overlap, jump to .copy

    ; Handle overlapping memory regions (source < destination)
    ; This ensures memory is copied backwards to avoid overwriting data
    mov r8, rsi             ; Copy source pointer to r8
    add r8, rdx             ; r8 = source + number of bytes
    cmp r8, rdi             ; Compare (source + number of bytes) with destination
    jbe .copy               ; If there's no overlap, jump to .copy

.overlap:                   ; Handling overlapping memory (copy backwards)
    std                     ; Set direction flag (reverse direction for string operations)
    add rdi, rdx            ; Move destination pointer to the end of the memory region
    add rsi, rdx            ; Move source pointer to the end of the memory region
    sub rdi, 1              ; Adjust destination pointer by -1 (start copying from the last byte)
    sub rsi, 1              ; Adjust source pointer by -1

.copy:                      ; Main copy loop (for both forward and backward cases)
    mov ecx, edx            ; Move the count (number of bytes) into ecx
    rep movsb               ; Repeat copying bytes from source (rsi) to destination (rdi), ecx times
    cld                     ; Clear direction flag (restore forward direction)
    ret                     ; Return from the function
