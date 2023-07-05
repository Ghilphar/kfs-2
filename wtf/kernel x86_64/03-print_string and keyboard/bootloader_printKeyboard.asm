[org 0x7c00]

mov ax, 0x0003
int 0x10            ; Clear screen 

mov ah, 0x0e

get_input:
    mov ah, 0
    int 0x16  ; Here we get the input of the keyboard
    cmp al, 0x0D
    je end
    mov ah, 0x0e 
    int 0x10  ; writing mode
    jmp get_input

end:
    cli ; Disable interrupts
    hlt ; Halt CPU

times 510-($ - $$) db 0
db 0x55, 0xaa