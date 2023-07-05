/* link.ld */

OUTPUT_FORMAT(elf32-i386)
ENTRY(start)
SECTIONS
{
   . = 0x100000;
   .text : { *(.text) }
   .data : { *(.data) }
   .bss  : { *(.bss)  }

   . = 0x00000800;
   .gdt : { *(.gdt) }

   . = 0x00000850;
   .gdt_ptr : { *(.gdt_ptr) }
}