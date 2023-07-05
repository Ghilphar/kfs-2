[org 0x7c00]

mov ax, 0x0003
int 0x10            ; Clear screen 

mov ax, 0xB800
mov es, ax          ; ES points to video memory 

mov di, 0
mov cl, 0x07        ; Initial color

get_input:
    xor ah, ah
    int 0x16  ; Get the input from the keyboard

    ; Change color if Tab is pressed
    cmp al, 0x09
    je change_color

    ; Handle backspace
    cmp al, 0x08
    je backspace

    cmp al, 0x0D
    je new_line
    mov [es:di], al
    mov [es:di+1], cl
    add di, 2
    jmp get_input

change_color:
    inc cl  ; Change to the next color
    jmp get_input

backspace:
    sub di, 2  ; Move back in the buffer
    mov word [es:di], 0x0720  ; Clear the character on screen
    jmp get_input

new_line:
    mov ax, 160 ; 160 bytes per line
    sub ax, di
    add di, ax ; Move to new line
    jmp get_input

times 510-($ - $$) db 0
db 0x55, 0xaa
