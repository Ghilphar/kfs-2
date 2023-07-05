[org 0x7c00]

mov ax, 0x0003
int 0x10            ; Clear screen 

mov ax, 0xB800
mov es, ax          ; ES points to video memory 

mov byte [es:0], '4' ; Character to display
mov byte [es:1], 0x04 ; Color code (4 is red)

mov byte [es:2], '2' ; Next character
mov byte [es:3], 0x04 ; Color code 

jmp $ ; Halt the CPU

times 510-($ - $$) db 0
db 0x55, 0xaa
