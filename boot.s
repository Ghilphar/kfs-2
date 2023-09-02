section .multiboot
align 4
dd 0x1BADB002                   ; Multiboot magic number
dd 0x00000003                   ; Flags for memory info and align page
dd -(0x1BADB002 + 0x00000003)   ; Checksum -- magic number and flags should add up to zero

; The multiboot standard does not define the value of the stack pointer register
; (esp) and it is up to the kernel to provide a stack. This allocates room for a
; small stack by creating a symbol at the bottom of it, then allocating 16384
; bytes for it, and finally creating a symbol at the top. The stack grows
; downwards on x86. The stack is in its own section so it can be marked nobits,
; which means the kernel file is smaller because it does not contain an
; uninitialized stack. The stack on x86 must be 16-byte aligned according to the
; System V ABI standard and de-facto extensions. The compiler will assume the
; stack is properly aligned and failure to align the stack will result in
; undefined behavior.

section .data
align 4
gdt_start:
gdt_null:    ; the mandatory null descriptor
    dd 0x0
    dd 0x0

gdt_code:    ; the kernel code segment descriptor
    dw 0xFFFF   ;First 16 bits of the limit
    dw 0x0      ;First 16 bits of the base
    db 0x0      ;+ 8 bits base (24)
    db 0x9A     ;define present, privilege and type property + type flags, 10011010
    ;We call it the access byte.
    ;First 4 bits represent:
    ;Present bits. Allows an entry to refer to a valid segment. Must be set (1) for any valid segment.
    ;DPL: Descriptor privilege level field. Contains the CPU Privilege level of the segment. 0 = highest privilege (kernel), 3 = lowest privilege (user applications).
    ;S: Descriptor type bit. If clear (0) the descriptor defines a system segment (eg. a Task State Segment). If set (1) it defines a code or data segment.

    ;Last 4 bits,the type flags
    ;E: Executable bit. If clear (0) the descriptor defines a data segment. If set (1) it defines a code segment which can be executed from.
    ;DC: Direction bit/Conforming bit
    ;RW: Readable bit/Writable bit.
    ;A: Accessed bit. Best left clear (0), the CPU will set it when the segment is accessed.
    db 0xCF     ;other flags + last 4 bits of limit (1100 + F  (1111) )
    ;G: Granularity flag, indicates the size the Limit value is scaled by. If clear (0), the Limit is in 1 Byte blocks (byte granularity). If set (1), the Limit is in 4 KiB blocks (page granularity).
    ;DB: Size flag. If clear (0), the descriptor defines a 16-bit protected mode segment. If set (1) it defines a 32-bit protected mode segment. A GDT can have both 16-bit and 32-bit selectors at once.
    ;L: Long-mode code flag. If set (1), the descriptor defines a 64-bit code segment. When set, DB should always be clear. For any other type of segment (other code types or any data segment), it should be clear (0).
    ;reserved
    db 0x0      ;Last 8 bits of base

gdt_data:    ; the kernel data segment descriptor
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 0x92     ;present = 1 (if the segment is used); privileges 00(kernel segment) ; type (1  For Code and Data Segment)  10010010
    db 0xCF
    db 0x0

;"stack": kernel stack, used to stored the call stack during kernel execution
gdt_stack:
    dw 0xFFFF      ;First 16 bits of the limit
    dw 0x0      ;First 16 bits of the base
    db 0x0      ;Next 8 bits of the base
    db 0x96     ;Access byte: Present, Accessed, Readable/Writable, Expand Down (This make it a stack), and Privilege Level 0
    db 0x0D     ;Flags: 32-bit segment and 4-KByte granularity
    db 0xF      ;Last 8 bits of the base

gdt_user_code:    ; the user code segment descriptor
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 0xFA        ; So we change privileges so 11110010 ; We can see what we change is the privileges bites set to 3 (11) lowest privileges
    db 0xCF
    db 0x0

gdt_user_data:    ; the user data segment descriptor
    dw 0xFFFF
    dw 0x0
    db 0x0
    db 0xF2       ; In comparaison to kernel data and kernel code we can see the type flags are the same for the type of segment (Code or Data)
    db 0xCF
    db 0x0

; User stack, used to store the call stack during execution in userland ; Ils palent de TSS? Task State Segment ?
gdt_user_stack:
    dw 0xFFFF      ;First 16 bits of the limit
    dw 0x0      ;First 16 bits of the base
    db 0x0      ;Next 8 bits of the base
    db 0xF6     ;Access byte: Present, Accessed, Readable/Writable, Expand Down (This make it a stack), and Privilege Level 0
    db 0x0D     ;Flags: 32-bit segment and 4-KByte granularity
    db 0xF      ;Last 8 bits of the base


gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

section .bss
align 16
stack_bottom:
resb 16384 ; 16 KiB
stack_top:

; The bootloader will search for this symbol to initiate the kernel
section .text
global _start
global stack_bottom
_start:
    lgdt [gdt_descriptor]  ; load the GDT // gdt_descriptor is hard coded less flexible than the solution of WikiOsDev but more readable.
    jmp 0x08:.reload_CS    ; far jump to reload CS
.reload_CS:
    mov ax, 0x10           ; load the data segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ; To set up a stack, we set the esp register to point to the top of the
    ; stack (as it grows downwards on x86 systems). This is necessarily done
    ; in assembly as languages such as C cannot function without a stack.
    mov esp, stack_top
    ; Enter the high-level kernel.
    extern kernel_main
    call kernel_main

    ; If the system has nothing more to do, put the computer into an
    ; infinite loop. This is done by disabling interrupts with cli (clear interrupt
    ; enable in eflags) and then waiting for the next interrupt with hlt
    ; (halt instruction). Since they are disabled, this will lock up the computer.
    ; If the halt instruction ever wakes up due to a non-maskable interrupt occurring
    ; or due to system management mode, we jump back to the halt instruction.

    cli

loop:
    hlt
    jmp loop
