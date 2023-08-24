section .data
vga_buffer_ptr: dd 0xb8000   ; VGA text buffer start address
bytes_to_print: db 64        ; Number of bytes to print (change as needed)
attribute_byte: db 0x0F      ; White text on black background

section .text
global printk
global kernel_main

printk:
    ; Input: edi - address to start printing from
    ; Save registers
    push ebx
    push ecx
    push edx
    push esi
    mov  ecx, bytes_to_print
    call print_loop

print_loop:
    cmp ecx, 0
    je done
    
    ; Load byte from memory address edi
    xor eax, eax
    mov al, [edi]
    
    ; Convert byte to two hex characters
    call byte_to_hex

    ; Get the current VGA buffer address
    mov edx, [vga_buffer_ptr]

    ; Print first hex character
    mov byte [edx], al
    mov al, [attribute_byte]
    mov byte [edx + 1], al
    add edx, 2

    ; Print second hex character
    mov byte [edx], ah
    mov al, [attribute_byte]
    mov byte [edx + 1], al
    add edx, 2

    ; Print a space for separation
    mov al, ' '
    mov byte [edx], al
    mov al, [attribute_byte]
    mov byte [edx + 1], al
    add edx, 2

    ; Update the VGA buffer pointer
    mov [vga_buffer_ptr], edx

    ; Advance to the next byte and check if you've printed 16 bytes
    inc edi
    dec ecx
    test ecx, 15
    jnz print_loop

    ; Add a newline after every 16 bytes
    call newline
    jmp print_loop


newline:
    ; Print a newline to the VGA
    push ebx
    mov ebx, 64  ; Move to the next line
    add [vga_buffer_ptr], ebx
    pop  ebx
    ret

done:
    ; Restore registers and return
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

byte_to_hex:
    ; Convert a byte in rax to two hex characters in ax
    push ebx
    mov  ebx, eax      ; Copy eax to ebx for use with shifting
    shr  ebx, 4        ; Shift to get the high nibble
    and  ebx, 0x0F     ; Mask high nibble
    call nibble_to_hex; Convert high nibble to hex character in al
    mov  ah, al        ; Store high nibble in ah
    and  eax, 0x0F     ; Mask to get the low nibble
    call nibble_to_hex; Convert low nibble to hex character in al

    pop  ebx
    ret

nibble_to_hex:
    ; Convert a nibble in rax to a hex character in al
    cmp eax, 10
    jl  not_alpha
    add al, 'A' - 10
    ret

not_alpha:
    add al, '0'
    ret

kernel_main:
    pusha
    mov edi, esp
    call printk
    popa
    ret
