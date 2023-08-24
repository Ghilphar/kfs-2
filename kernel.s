section .data
VGA_START_ADDR:   dd 0xb8000  ; VGA text buffer start address
PRINT_BYTE_COUNT: db 64       ; Number of bytes to print (change as needed)
TEXT_ATTR:        db 0x0F     ; White text on black background
BYTES_PER_ROW:    dd 16       ; How many bytes to print per line before adding a newline
VGA_LINE_LENGTH:  dd 160      ; 80 characters * 2 bytes per character

section .text
global printk
global kernel_main

; Entry point for the printk function
; EDI: Address to start printing from
printk:
    push ebx
    push ecx
    push edx
    push esi

    mov ecx, PRINT_BYTE_COUNT
    xor esi, esi   ; Reset counter for bytes printed in the current line

    call print_loop

    ; Cleanup and exit
done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

print_loop:
    ; Check if we're done printing
    cmp ecx, 0
    je done
    ; Convert byte at EDI to hex and print
    call print_byte_as_hex
    ; If we've printed 2 bytes, print a space
    inc esi
    cmp esi, 2
    jnz no_space
    call print_space
    ; Reset byte counter
    xor esi, esi

no_space:
    ; If we've reached the max bytes for a row, print newline
    cmp esi, BYTES_PER_ROW
    je print_newline

continue_loop:
    inc edi       ; Move to the next byte
    dec ecx       ; Decrement byte counter
    jmp print_loop

print_newline:
    call newline
    jmp continue_loop

; Converts the byte in AL to hex and prints it to the VGA buffer
print_byte_as_hex:
    xor eax, eax
    mov al, [edi]
    call byte_to_hex

    ; Print hex chars
    call print_char_al
    call print_char_ah

    ret

; Prints the char in AL to the VGA buffer with the set attribute
print_char_al:
    mov edx, [VGA_START_ADDR]
    mov byte [edx], al
    mov ebx, TEXT_ATTR
    mov al, [ebx]
    mov byte [edx + 1], al
    add dword [VGA_START_ADDR], 2
    ret

; Prints the char in AH to the VGA buffer with the set attribute
print_char_ah:
    mov edx, [VGA_START_ADDR]
    mov byte [edx], ah
    mov ebx, TEXT_ATTR
    mov al, [ebx]
    mov byte [edx + 1], al
    add dword [VGA_START_ADDR], 2
    ret

; Prints a space char to the VGA buffer
print_space:
    mov al, ' '
    call print_char_al
    ret

; Add a newline to VGA output
newline:
    add dword [VGA_START_ADDR], VGA_LINE_LENGTH
    ret

; Convert a byte in EAX to two hex chars in AX
byte_to_hex:
    push ebx
    mov  ebx, eax  ; Copy AL to BL for shifting
    shr  ebx, 4    ; Shift to get the high nibble
    and  ebx, 0x0F ; Mask high nibble
    call nibble_to_hex
    mov  ah, al    ; Store high nibble in AH
    and  eax, 0x0F ; Mask for low nibble
    call nibble_to_hex
    pop ebx
    ret

; Convert 4 bits in AL to a hex char
nibble_to_hex:
    cmp eax, 10
    jl  is_digit
    add al, 'A' - 10
    ret
is_digit:
    add al, '0'
    ret

; Kernel's main entry point
kernel_main:
    pusha
    mov edi, esp   ; Get the stack address to print
    call printk
    popa
    ret

