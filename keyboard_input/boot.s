bits 32
section .text
        align 4
        dd 0x1BADB002
        dd 0x00
        dd - (0x1BADB002 + 0x00)

global start
global keyboard_handler
global read_port
global write_port
global load_idt
global gdt_flush

extern kmain
extern keyboard_handler_main


gdt_flush:
	lgdt [esp + 4]	; Load the GDT
	jmp	 0x18:kmain	; Use a Far jump to reload the CS register

.flush:
	mov ax, 0x18	;Load the data segment selector into Ax
	mov ds, ax		; Load The data segment
	mov es, ax		; Load the extra segment
	mov fs, ax		; Load the FS Segment 
	mov gs, ax		; Load the GS Segment
	mov ss, ax		; Load the stack segment
	ret

read_port:
	mov edx, [esp + 4]
	in al, dx
	ret

write_port:
	mov   edx, [esp + 4]    
	mov   al, [esp + 4 + 4]  
	out   dx, al  
	ret

load_idt:
	mov edx, [esp + 4]
	lidt [edx]
	sti
	ret

keyboard_handler:                 
	call    keyboard_handler_main
	iretd

start:
	cli
	mov eax, cr0
    or eax, 0x1
    mov cr0, eax
	mov esp, stack_space
	call kmain
	hlt 

section .bss
resb 8192
stack_space: