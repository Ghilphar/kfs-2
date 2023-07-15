[org 0x7c00]

mov ax, 0x0003
int 0x10            ; Clear screen 

mov ax, 0xB800
mov es, ax          ; ES points to video memory
mov di, 0           ; DI points to the cursor
mov cl, 0x07        ; Initial color

get_input:
    xor ax, ax       ; Clear ax
    int 0x16         ; Wait for a keypress

    push ax          ; Preserve ax
    call print_dec   ; Print the value of AH
    pop ax           ; Restore ax

    cmp al, 0xE0     ; Check if AL contains 0xE0 (special key)
    jne get_input    ; If not, wait for another keypress

    xor ax, ax       ; Clear ax again
    int 0x16         ; Get the actual special key

    cmp ah, 0x4B     ; Check if AH contains 0x4B (left arrow key)
    jne get_input    ; If not, wait for another keypress

    mov al, 'A'      ; If yes, prepare to print 'A' to the screen
    mov [es:di], al
    mov [es:di+1], cl
    add di, 2        ; Move to the next character cell

    jmp get_input    ; Jump back to the input loop

print_dec:  ; Prints the value in AH as decimal
    mov cx, 10
    mov bx, 0
div_loop:
    xor dx, dx
    div cx
    push dx
    inc bx
    test ax, ax
    jnz div_loop
print_loop:
    pop ax
    add al, '0'
    mov [es:di], al
    mov [es:di+1], cl
    add di, 2
    dec bx
    jnz print_loop
    ret

times 510-($ - $$) db 0
db 0x55, 0xaa
