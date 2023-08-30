section .data
VGA_START_ADDR:   dd 0xb8000                           ; VGA buffer's starting address
BYTES_PER_ROW:    dd 16                               ; Number of bytes to display per row
VGA_LINE_LENGTH:  dd 160                              ; Length of one line in the VGA buffer
TEXT_ATTR:        dd 0x0F00                           ; Extend to 32-bits
hex_chars         db "0123456789ABCDEF", 0            ; Hexadecimal character lookup table
num_rows          dd 16                               ; For example, to display 4 rows
sample            db "AAAABBBBCCCCDDDDEEEEFFFFBIG TEST ABCDEF", 0 ; Sample data

section .text
global kernel_main

print_byte_as_hex:
    push eax                                           ; Save the original byte value
    shr eax, 4                                         ; First half of the byte
    and al, 0x0F
    lea ebx, [hex_chars]
    add ebx, eax
    movzx edx, byte [ebx]
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2

    pop eax                                            ; Restore the original byte value
    and eax, 0x0F                                      ; Second half of the byte
    lea ebx, [hex_chars]
    add ebx, eax
    movzx edx, byte [ebx]
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2

    mov edx, ' '                                       ; Space after each byte
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2
    ret

print_ascii:
    cmp eax, 0x20
    jl .non_printable
    cmp eax, 0x7E
    jg .non_printable

    or eax, [TEXT_ATTR]
    mov [esi], eax
    add esi, 2
    ret

.non_printable:
    mov edx, '.'                                       ; Replace non-printable with dot
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2
    ret

print_address:
    push eax
    push ecx
    push edx
    push ebx
    mov ecx, 8                                         ; Iterate 8 times for a 32-bit address.
    mov ebx, eax                                       ; Backup the original value of eax

.addr_loop:
    mov eax, ebx                                       ; Restore original eax for each iteration
    shr eax, 28                                        ; Start with the highest nibble
    and eax, 0x0F
    lea edx, [hex_chars]
    movzx edx, byte [edx + eax]
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2
    shl ebx, 4                                         ; Shift for the next iteration

    loop .addr_loop

    mov edx, ':'                                       ; Add a colon after address
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2
    mov edx, ' '                                       ; Followed by a space
    mov [esi], edx
    add esi, 2

    pop eax
    pop ecx
    pop edx
    pop ebx
    ret

dump_row:
    pusha
    mov eax, edi
    call print_address
    mov ecx, [BYTES_PER_ROW]

.dump_loop:
    movzx eax, byte [edi]
    call print_byte_as_hex
    add edi, 1
    dec ecx
    cmp ecx, 8

    jne .continue
    mov edx, ' '                                       ; Additional space after 8 bytes
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2

.continue:
    test ecx, ecx
    jnz .dump_loop
    
    mov edx, '|'                                       ; Delimiter at end of hex
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2
    
    mov ecx, [BYTES_PER_ROW]                           ; Reset counter for ASCII loop
    sub edi, [BYTES_PER_ROW]

.ascii_loop:
    movzx eax, byte [edi]
    call print_ascii
    add edi, 1
    dec ecx
    test ecx, ecx
    jnz .ascii_loop

    mov edx, '|'                                       ; Delimiter at end of ASCII
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2

    popa
    ret

hexdump:
    mov eax, [num_rows]

.row_loop:
    push edi                                           ; Save state for each row iteration
    push esi
    call dump_row
    pop esi
    pop edi
    add edi, [BYTES_PER_ROW]
    add esi, [VGA_LINE_LENGTH]
    dec eax
    test eax, eax
    jnz .row_loop
    ret

kernel_main:
    pusha
    mov esi, [VGA_START_ADDR]
    mov edi, sample
    call hexdump
    popa
    ret

