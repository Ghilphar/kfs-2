section .data                 ; Data section, where constants and global variables are defined.
VGA_START_ADDR:   dd 0xb8000  ; Start address of VGA text buffer in memory.
PRINT_BYTE_COUNT: db 64       ; Define the number of bytes to print.
TEXT_ATTR:        db 0x0F     ; Define text attributes (white text on black background).
BYTES_PER_ROW:    dd 16       ; Define how many bytes to print on a line before moving to the next line.
VGA_LINE_LENGTH:  dd 160      ; Define the length of a VGA line (80 characters * 2 bytes/character).

; LOGIC:
;   1. Entrypoint kernel_main calls function printk and feeds it the top of the stack (esp) as parameter in edi
;   2. Function printk sets two registers to values used for looping over the values in memory:
;     - ecx gets the constant PRINT_BYTE_COUNT
;     - esi is set to 0, designating the number of bytes printed on current line.
;
;
;
;
;
;

section .text             ; Text section, where the executable code is written.

global printk             ; Make printk function accessible from other modules.
global kernel_main        ; Make kernel_main function accessible from other modules.

print_newline:            ; Function to print a newline and then continue the loop.
    call newline          ; Call the function that increments VGA address to move to the next line.
    jmp continue_loop     ; Continue with the loop.

print_byte_as_hex:        ; Function to convert the byte in AL to hex and print it to VGA buffer.
    xor eax, eax          ; Clear EAX register.
    mov al, [edi]         ; Load the byte at address EDI into AL.
    call byte_to_hex      ; Convert the byte in AL to two hex digits in AX.
    call print_char_al    ; Print the hex character in AL.
    call print_char_ah    ; Print the hex character in AH.
    ret

print_char_al:                    ; Function to print the char in AL to the VGA buffer with specified text attributes.
    mov edx, [VGA_START_ADDR]     ; Load VGA start address into EDX.
    mov byte [edx], al            ; Write the character in AL to VGA buffer.
    mov ebx, TEXT_ATTR            ; Load text attributes into EBX.
    mov al, [ebx]                 ; Load text attributes into AL.
    mov byte [edx + 1], al        ; Write text attributes to VGA buffer.
    add dword [VGA_START_ADDR], 2 ; Increment VGA buffer address by 2 (char + attribute).
    ret

print_char_ah:                    ; Function to print the char in AH to the VGA buffer with specified text attributes.
    mov edx, [VGA_START_ADDR]     ; Load VGA start address into EDX.
    mov byte [edx], ah            ; Write the character in AH to VGA buffer.
    mov ebx, TEXT_ATTR            ; Load text attributes into EBX.
    mov al, [ebx]                 ; Load text attributes into AL.
    mov byte [edx + 1], al        ; Write text attributes to VGA buffer.
    add dword [VGA_START_ADDR], 2 ; Increment VGA buffer address by 2 (char + attribute).
    ret

newline:                                        ; Function to add a newline to VGA output.
    add dword [VGA_START_ADDR], VGA_LINE_LENGTH ; Increment VGA buffer address to move to the next line.
    ret

byte_to_hex:              ; Function to convert a byte in EAX to two hex characters in AX.
    push ebx              ; Save EBX onto the stack.
    mov  ebx, eax         ; Copy AL to BL.
    shr  ebx, 4           ; Shift BL right by 4 bits to get the high nibble.
    and  ebx, 0x0F        ; Mask high nibble to get only the last 4 bits.
    call nibble_to_hex    ; Convert the 4 bits in BL to a hex character in AL.
    mov  ah, al           ; Store the result in AH.
    and  eax, 0x0F        ; Mask EAX to get the low nibble.
    call nibble_to_hex    ; Convert the 4 bits in AL to a hex character.
    pop ebx               ; Restore EBX from the stack.
    ret

nibble_to_hex:         ; Function to convert 4 bits in AL to a hex character.
    cmp eax, 10        ; Check if the value in AL is less than 10.
    jl  is_digit       ; If it is, jump to is_digit.
    add al, 'A' - 10   ; Otherwise, convert it to an uppercase letter.
    ret

is_digit:
    add al, '0'        ; Convert the value in AL to a digit.
    ret

print_space:                ; Function to print a space character to the VGA buffer.
    mov al, ' '             ; Load space character into AL.
    call print_char_al      ; Print the space character.
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; PRINT_LOOP FUNCTION FALL-THROUGHS BLOCK START ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print_loop:                 ; Main print loop function.
    cmp ecx, 0              ; Check if we have printed all bytes.
    je end_of_print_loop    ; If we have, jump to the end of the print loop.
    call print_byte_as_hex  ; Otherwise, print the current byte as hex.
    inc esi                 ; Increment the counter for bytes printed on the current line.
    cmp esi, 2              ; Check if we've printed 2 bytes.
    jnz no_space            ; If we haven't, don't print a space.
    call print_space        ; If we have, print a space.
    xor esi, esi            ; Reset the byte counter for the current line.

no_space:
    cmp esi, BYTES_PER_ROW  ; Check if we've reached the end of the current line.
    je print_newline        ; If we have, print a newline.
    
continue_loop:
    inc edi                 ; Move to the next byte in memory.
    dec ecx                 ; Decrement the byte counter.
    jmp print_loop          ; Continue the print loop.

end_of_print_loop:          ; Explicit label to end the print loop.
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; PRINT_LOOP FUNCTION FALL-THROUGHS BLOCK END ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

printk:                       ; Entry point for the printk function.
    push ebx                  ; Save the value of EBX.
    push ecx                  ; Save the value of ECX.
    push edx                  ; Save the value of EDX.
    push esi                  ; Save the value of ESI.
    mov ecx, PRINT_BYTE_COUNT ; Load the number of bytes to print into ECX.
    xor esi, esi              ; Reset the counter for bytes printed on the current line.
    call print_loop           ; Call the main print loop.
    call done_cleanup         ; Call the cleanup function.
    ret

done_cleanup: ; Cleanup function to restore register values.
    pop esi   ; Restore the value of ESI.
    pop edx   ; Restore the value of EDX.
    pop ecx   ; Restore the value of ECX.
    pop ebx   ; Restore the value of EBX.
    ret

kernel_main:     ; Main entry point for the kernel.
    pusha        ; Save all general-purpose register values.
    mov edi, esp ; Load the top of the stack into EDI.
    call printk  ; Call the printk function.
    popa         ; Restore all general-purpose register values.
    ret
