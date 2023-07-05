[org 0x7c00]

; Init Stack
mov bp, 0x8000
mov sp, bp

; Prints number
mov ax, 0x1A4 ; 420
call print_num
call print_nl

; Prints number
mov ax, 0x18 ; 24
call print_num
call print_nl

; Prints number
mov ax, 0x1E ; 30
call print_num
call print_nl

; Prints number
mov ax, 0x5 ; 5
call print_num
call print_nl

; Prints number
mov ax, 0x1D ; 29
call print_num
call print_nl

; Forever Loop
jmp $

print_num: ; Print a number given in ax
  pusha ; Stores all registers in the stack
  mov cx, 0 ; Counter for the digits
  mov bx, 0x0a ; Divisor set to 10
pn_loop:
  mov dx, 0
  div bx    ; Division -> ax / bx -> ax ; ax % bx -> dx
  push dx
  inc cx
  cmp ax, 0 ; jmps out of the loop if the quotient is zero
  je pn_print
  jmp pn_loop
pn_print: ; Print setup
  mov al, 0x0
  mov ah, 0x0e
pn_print_loop:  ; Prints numbers
  dec cx
  pop bx
  add bx, '0'   ; Converts the Digit to a Assci number digit
  mov al, bl
  int 0x10
  cmp cx, 0     ; jumps out of the loop if the digit counter is zero
  je pn_exit
  jmp pn_print_loop
pn_exit:
  popa        ; Pops the stored registers from the stack
  ret         ; Returns to the point in the program where this function was called

print_nl: ; Jumps int the next line on screen
  pusha
  mov ah, 0x0e
  mov al, 0xd
  int 0x10
  mov al, 0xa
  int 0x10
  popa
  ret

; Magic
times 510 - ($ - $$) db 0
db 0x55, 0xaa