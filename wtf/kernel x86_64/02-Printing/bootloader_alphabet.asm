mov bl, 0x41
int 0x10

label: 
    mov ah, 0x0e
    mov al, bl
    add bl, 1
    int 0x10
    cmp bl, 91
    jl label

jmp $
times 510-($ - $$) db 0
db 0x55, 0xaa