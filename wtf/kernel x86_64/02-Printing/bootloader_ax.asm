mov ax, 0x0e34
int 0x10

mov ax, 0x0e32
int 0x10

jmp $

times 510-($ - $$) db 0
db 0x55, 0xaa