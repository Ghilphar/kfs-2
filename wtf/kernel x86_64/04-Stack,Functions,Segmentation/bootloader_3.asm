[org 0x7c00]

mov ax, 0x0003
int 0x10            ; Clear screen 

mov ax, 0xB800
mov es, ax          ; ES points to video memory 

mov di, 0           ; DI points to the cursor
mov si, 0           ; SI points to the buffer 
mov bp, 0           ; CX points to the buffer size
mov cl, 0x07        ; Initial color

get_input:
    call move_cursor

    xor ah, ah
    int 0x16  ; Get the input from the keyboard

    ; Change color if Tab is pressed
    cmp al, 0x09
    je change_color

    ; Handle backspace
    cmp al, 0x08
    je backspace

    cmp al, 0x0D
    je enter_input

    cmp ah, 0x4B
    je left_arrow_input

    cmp ah, 0x4D
    je right_arrow_input

    mov [es:di], al
    mov [es:di+1], cl
    mov [buffer+si], al  ; Save the character to the buffer
    inc si  ; Increment the buffer pointer
    mov [buffer+si], cl  ; Save the color to the buffer
    inc si  ; Increment the buffer pointer
    add di, 2
    cmp si, bp
    jg inc_buffer
    jmp get_input

inc_buffer:
    add bp, 2
    jmp get_input

change_color:
    cmp cl, 0x07
    je reset_color
    inc cl  ; Change to the next color
    jmp get_input

reset_color:
    mov cl, 0x01  ; Reset cl to 0
    jmp get_input  ; Jump to get_input

backspace:
    cmp si, 00
    jle get_input
    sub di, 2  ; Move back in the buffer
    mov word [es:di], 0x0720  ; Clear the character on screen
    xor bx, bx
    mov [buffer + si], bx
    dec si
    mov [buffer + si], bx
    dec si
    jmp get_input

right_arrow_input:
    add di, 2
    add si, 2
    jmp get_input

left_arrow_input:
    sub di, 2
    sub si, 2
    jmp get_input

enter_input:
    call new_line ; Create a new line
    xor bx, bx    ; Clear bx

    print_loop:   ; Print out    buffer
        cmp bx, bp ; Compare bx with the current pointer position in the buffer
        je reset_buffer ; If we've reached the end of the buffer, reset it
        mov al, [buffer + bx] ; Otherwise, get the next character from the buffer
        mov [es:di], al
        inc bx
        mov al, [buffer + bx]
        mov [es:di+1], al
        add di, 2
        inc bx
        jmp print_loop

    reset_buffer: ; Reset the buffer and the buffer pointer
        xor si, si
        xor bp, bp ;
        call new_line ; Create a new line
        jmp get_input

new_line:
    mov ax, di
    add ax, 160
    xor dx, dx
    mov bx, 160
    div bx
    mul bx
    mov di, ax
    cmp di, 4000
    jl skip_reset
    mov di, 0
skip_reset:
    ret

move_cursor:
    mov ax, di
    shr ax, 1  ; Convert byte offset to cell offset
    mov bl, 80  ; Number of cells per row
    div bl  ; AX = AX / BX, AH = remainder
    xchg ah, al  ; Swap AH and AL
    mov dx, ax  ; DX = X in row (AH) and Y in column (AL)
    
    mov ah, 0x02  ; Set cursor position function
    mov bh, 0x00  ; Page number
    int 0x10  ; Call BIOS Video Services
    ret

times 510-($ - $$) db 0
db 0x55, 0xaa

buffer times 510 db 0
