section .data
VGA_START_ADDR:   dd 0xb8000
BYTES_PER_ROW:    dd 16
VGA_LINE_LENGTH:  dd 160
TEXT_ATTR:        dd 0x0F00      ; Extend to 32-bits
hex_chars         db "0123456789ABCDEF"
sample db "BIG TEST", 0
num_rows dd 16                      ; For example, to display 4 rows

section .text
global kernel_main

print_address:
    pusha
    mov ecx, 8  ; We are processing half-bytes, so we iterate 8 times for a 32-bit address.

.addr_loop:
    rol eax, 4  ; Rotate left to process the highest nibble
    and eax, 0x0F ; Mask the last 4 bits 
    lea ebx, [hex_chars]
    movzx edx, byte [ebx + eax] ; Fetch the hex character
    or edx, [TEXT_ATTR]   ; Add the attribute
    mov [esi], edx ; Store the character to VGA buffer
    add esi, 2 ; Move to the next position in VGA buffer

    loop .addr_loop

    ; Add two spaces for formatting after the address
    mov edx, ' ' 
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2
    mov [esi], edx
    add esi, 2

    popa
    ret

print_byte_as_hex:
    ; First half of the byte
    shr eax, 4
    and al, 0x0F
    lea ebx, [hex_chars]
    add ebx, eax
    movzx edx, byte [ebx]
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2

    ; Second half of the byte
    and eax, 0x0F
    lea ebx, [hex_chars]
    add ebx, eax
    movzx edx, byte [ebx]
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2

    ; Space after each byte
    mov edx, ' '
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
    mov edx, '.'
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2
    ret

hexdump:
    pusha
    mov eax, [num_rows]

.row_loop:
    ; Save initial state of edi and esi for each row iteration
    push edi
    push esi

    ; Dump the current row
    call dump_row

    ; Restore initial state of edi and esi
    pop esi
    pop edi

    ; Move edi to the next block of memory for the next row
    add edi, [BYTES_PER_ROW]

    ; Move esi to the start of the next line on the VGA buffer
    add esi, [VGA_LINE_LENGTH]

    ; Decrement row counter and loop if more rows are left
    dec eax
    test eax, eax
    jnz .row_loop

    popa
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
    ; Additional space for formatting after 8 bytes
    mov edx, ' '
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2
.continue:
    test ecx, ecx
    jnz .dump_loop

    ; Add a space between hex and ascii display
    mov edx, '|'
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2

    mov ecx, [BYTES_PER_ROW]

.ascii_loop:
    movzx eax, byte [edi]
    call print_ascii
    add edi, 1
    dec ecx
    test ecx, ecx
    jnz .ascii_loop

    ; End the line with a '|'
    mov edx, '|'
    or edx, [TEXT_ATTR]
    mov [esi], edx
    add esi, 2

    ; Go to next line
    add esi, (80*2 - 144)

    popa
    ret

kernel_main:
    pusha
    mov esi, [VGA_START_ADDR]
    mov edi, esp
    push sample
    call hexdump
    popa
    ret

