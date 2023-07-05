[org 0x7c00]

mov ax, 0x0003
int 0x10            ;int 0x10 is a commonly used BIOS interrupt for video services.
                    ;the ah register is set to 0x00 This correspond to Set Video Mode Funciton
                    ;On the other hand 0x03 on al correspond to 80x25 color text mode
                    ; When this mode is set, the BIOS automatically clears the screen. 

mov ah, 0x0e
mov bx, prompt;

print_prompt:
    mov al, [bx]
    cmp al, 0
    je get_input
    int 0x10
    inc bx
    jmp print_prompt

get_input:
    mov bx, variable
    input_loop:
        mov ah, 0
        int 0x16  ; Here we get the input of the keyboard
        cmp al, 0x0D
        je new_line
        mov [bx], al
        inc bx
        jmp input_loop

new_line:
    mov ah, 0x0e
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10

print_variable:
    mov bx, variable
    variable_loop:
        mov al, [bx]
        cmp al, 0
        je end
        int 0x10
        inc bx
        jmp variable_loop

variable:
    times 10 db 0

end:
    mov al, '!'
    int 0x10 

prompt:
    db "What's your name ?"

times 510-($ - $$) db 0
db 0x55, 0xaa