section .data
; Data segment for global variables

VGA_START_ADDR:   dd 0xb8000                           ; VGA buffer's starting address
BYTES_PER_ROW:    dd 16                                ; Number of bytes to display per row
VGA_LINE_LENGTH:  dd 160                               ; Length of one line in the VGA buffer
TEXT_ATTR:        dd 0x0F00                            ; Extend to 32-bits. 0Fh is the color attribute (white on black)
hex_chars         db "0123456789ABCDEF", 0             ; Hexadecimal character lookup table
num_rows          dd 32                                ; Number of rows to display
sample            db "AAAABBBBCCCCDDDDEEEEFFFFBIG TEST ABCDEF", 0 ; Sample data for testing

section .text
; Text segment for the code
extern stack_bottom
global kernel_main
; Entry point for the kernel

; Function: print_byte_as_hex
; Description: This function prints a single byte as a hexadecimal number.
; Parameters: eax - The byte to be printed.
; The byte is first split into two nibbles, each nibble is then looked up in the hex_chars table to find the corresponding
; hexadecimal character. Each character is then written to the VGA buffer with the appropriate text attributes.
print_byte_as_hex:
    push eax                                           ; Save the original byte value
    shr eax, 4                                         ; Shift right by 4 bits to get the high nibble
    and al, 0x0F                                       ; Mask the high nibble
    lea ebx, [hex_chars]                               ; Load the address of hex_chars into ebx
    add ebx, eax                                       ; Add the nibble to ebx to get the address of the corresponding hex character
    movzx edx, byte [ebx]                              ; Load the hex character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer

    pop eax                                            ; Restore the original byte value
    and eax, 0x0F                                      ; Mask the low nibble
    lea ebx, [hex_chars]                               ; Load the address of hex_chars into ebx
    add ebx, eax                                       ; Add the nibble to ebx to get the address of the corresponding hex character
    movzx edx, byte [ebx]                              ; Load the hex character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer

    mov edx, ' '                                       ; Load a space character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer
    ret

; Function: print_ascii
; Description: This function prints a single byte as an ASCII character.
; Parameters: eax - The byte to be printed.
; If the byte is a printable ASCII character, it is written to the VGA buffer with the appropriate text attributes.
; Otherwise, a dot character is written to the VGA buffer instead.
print_ascii:
    cmp eax, 0x20                                      ; Compare eax to the ASCII value of the space character
    jl .non_printable                                  ; If eax is less than 0x20, jump to .non_printable
    cmp eax, 0x7E                                      ; Compare eax to the ASCII value of the tilde character
    jg .non_printable                                  ; If eax is greater than 0x7E, jump to .non_printable

    or eax, [TEXT_ATTR]                                ; Add the text attributes to eax
    mov [esi], eax                                     ; Write eax to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer
    ret

.non_printable:
    mov edx, '.'                                       ; Load a dot character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer
    ret

; Function: print_address
; Description: This function prints a 32-bit address as a hexadecimal number.
; Parameters: eax - The address to be printed.
; The address is split into 4 bytes, and each byte is then split into two nibbles. Each nibble is then looked up in the hex_chars table to find the corresponding
; hexadecimal character. Each character is then written to the VGA buffer with the appropriate text attributes.
print_address:
    push eax                                           ; Save the original value of eax
    push ecx                                           ; Save the original value of ecx
    push edx                                           ; Save the original value of edx
    push ebx                                           ; Save the original value of ebx
    mov ecx, 8                                         ; Set ecx to 8 to repeat the loop 8 times
    mov ebx, eax                                       ; Copy the value of eax to ebx

.addr_loop:
    mov eax, ebx                                       ; Copy the value of ebx to eax
    shr eax, 28                                        ; Shift right by 28 bits to get the highest nibble
    and eax, 0x0F                                      ; Mask the highest nibble
    lea edx, [hex_chars]                               ; Load the address of hex_chars into edx
    movzx edx, byte [edx + eax]                        ; Load the hex character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer
    shl ebx, 4                                         ; Shift left by 4 bits for the next iteration

    loop .addr_loop                                    ; Repeat the loop

    mov edx, ':'                                       ; Load a colon character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer
    mov edx, ' '                                       ; Load a space character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer

    pop ebx                                            ; Restore the original value of ebx
    pop edx                                            ; Restore the original value of edx
    pop ecx                                            ; Restore the original value of ecx
    pop eax                                            ; Restore the original value of eax
    ret

; Function: dump_row
; Description: This function prints a row of memory as both hexadecimal numbers and ASCII characters.
; Parameters: edi - The address of the memory to be printed.
; The function first prints the address of the memory, then prints the memory as hexadecimal numbers,
; then prints a vertical bar, then prints the memory as ASCII characters, and finally prints another vertical bar.
dump_row:
    pusha                                              ; Save all registers
    mov eax, edi                                       ; Copy the value of edi to eax
    call print_address                                 ; Print the address
    mov ecx, [BYTES_PER_ROW]                           ; Set ecx to the number of bytes per row

.dump_loop:
    movzx eax, byte [edi]                              ; Load the next byte from memory into eax
    call print_byte_as_hex                             ; Print the byte as a hexadecimal number
    add edi, 1                                         ; Move to the next byte in memory
    dec ecx                                            ; Decrement ecx
    cmp ecx, 8                                         ; Compare ecx to 8
    jne .continue                                      ; If ecx is not equal to 8, jump to .continue

    mov edx, ' '                                       ; Load a space character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer

.continue:
    test ecx, ecx                                      ; Test if ecx is zero
    jnz .dump_loop                                     ; If ecx is not zero, repeat the loop

    mov edx, '|'                                       ; Load a vertical bar character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer

    mov ecx, [BYTES_PER_ROW]                           ; Set ecx to the number of bytes per row
    sub edi, [BYTES_PER_ROW]                           ; Move edi back to the start of the row

.ascii_loop:
    movzx eax, byte [edi]                              ; Load the next byte from memory into eax
    call print_ascii                                   ; Print the byte as an ASCII character
    add edi, 1                                         ; Move to the next byte in memory
    dec ecx                                            ; Decrement ecx
    test ecx, ecx                                      ; Test if ecx is zero
    jnz .ascii_loop                                    ; If ecx is not zero, repeat the loop

    mov edx, '|'                                       ; Load a vertical bar character into edx
    or edx, [TEXT_ATTR]                                ; Add the text attributes to edx
    mov [esi], edx                                     ; Write edx to the VGA buffer at the address in esi
    add esi, 2                                         ; Move to the next word in the VGA buffer

    popa                                               ; Restore all registers
    ret

; Function: hexdump
; Description: This function prints a block of memory as both hexadecimal numbers and ASCII characters.
; Parameters: edi - The address of the memory to be printed, num_rows - The number of rows to be printed.
; The function repeats the dump_row function for the specified number of rows, and then returns.
hexdump:
    mov eax, [num_rows]                                ; Set eax to the number of rows

.row_loop:
    push edi                                           ; Save the value of edi
    push esi                                           ; Save the value of esi
    call dump_row                                      ; Print a row
    pop esi                                            ; Restore the value of esi
    pop edi                                            ; Restore the value of edi
    add edi, [BYTES_PER_ROW]                           ; Move to the next row in memory
    add esi, [VGA_LINE_LENGTH]                         ; Move to the next line in the VGA buffer
    dec eax                                            ; Decrement eax
    test eax, eax                                      ; Test if eax is zero
    jnz .row_loop                                      ; If eax is not zero, repeat the loop
    ret

kernel_main:
    pusha                                              ; Save all registers
    mov esi, [VGA_START_ADDR]                          ; Set esi to the VGA buffer's starting address
    mov eax, 0x180
    push 0x12345678
    imul ebx, eax, 2794
    mov edi, ebp
    add edi, ebx                                       ; Set edi to the address of the sample data
    call hexdump                                       ; Print the hexdump
    popa                                               ; Restore all registers
    ret
