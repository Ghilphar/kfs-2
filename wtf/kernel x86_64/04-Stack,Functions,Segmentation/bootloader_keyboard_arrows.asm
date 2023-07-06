[org 0x7c00]

mov ax, 0x0003
int 0x10            ; Clear screen 

mov ax, 0xB800
mov es, ax          ; ES points to video memory
mov di, 0           ; DI points to the cursor
mov cl, 0x07        ; Initial color

get_input:
    mov ah, 0x00
    int 0x16  ; Wait for a keypress

    mov [es:di], al
    mov [es:di+1], cl
    jmp get_input  ; Jump back to the input loop

times 510-($ - $$) db 0
db 0x55, 0xaa
