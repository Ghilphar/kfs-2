[org 0x7c00]

mov ax, 0x0003
int 0x10            ; Clear screen 

mov ax, 0xB800
mov es, ax          ; ES points to video memory
mov di, 0            ; DI points to the cursor
mov cl, 0x07        ; Initial color

get_input:
    xor ah, ah
    int 0x16  ; Get the input from the keyboard

    cmp al, 0xE0            ; When you press a special key like an arrow key, the BIOS generates a two-byte scancode. The first byte for these keys is always 0xE0
    jne get_input

    xor ah, ah
    int 0x16  ; Get the second byte of the scan code

    cmp ah, 0x4B  ; Left arrow key
    jne get_input

    sub di, 2  ; Move the cursor two positions to the left
    mov al, 'C'
    mov [es:di], al
    mov [es:di+1], cl
    jmp get_input  ; Jump back to the input loop

times 510-($ - $$) db 0
db 0x55, 0xaa
