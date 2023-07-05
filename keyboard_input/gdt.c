#include "gdt.h"

//Declare an array of gdt_entry structs. The GDT actually has 6 entries
__attribute__((section(".gdt")))
struct gdt_entry    gdt[6];
//A pointer to the GDT
__attribute__((section(".gdt_ptr")))
struct gdt_ptr      gdt_ptr;

//The function in boot.s that will load our GDT
extern void gdt_flush();

// This function will setup each entry in the GDT
void gdt_set_gate(int num, unsigned long base, unsigned long limit, unsigned char access, unsigned char gran)
{
    gdt[num].base_low = (base & 0xFFFF);
    gdt[num].base_middle = (base >> 16) & 0xFF;
    gdt[num].base_high = (base >> 24) & 0xFF;

    gdt[num].limit_low = (limit & 0xFFFF);
    gdt[num].granularity = ((limit >> 16) & 0x0F);

    gdt[num].granularity |= (gran & 0xF0);
    gdt[num].access = access;
}

//The function that will initiate the GDT pointer
void gdt_install()
{
    //Set up the GDT pointer
    gdt_ptr.limit = (sizeof(struct gdt_entry) * 6) - 1;
    gdt_ptr.base = (unsigned int)gdt;

    //Null descriptor
    gdt_set_gate(0, 0, 0, 0, 0);

    //Code segment
    gdt_set_gate(1, 0, 0xFFFFFFFF, 0x9A, 0xCF);

    //Data Segment
    gdt_set_gate(2, 0, 0xFFFFFFFF, 0x92, 0xCF);

    //User mode code Segment
    gdt_set_gate(3, 0, 0xFFFFFFFF, 0xFA, 0xCF);

    //User mode data segment
    gdt_set_gate(4, 0, 0xFFFFFFFF, 0xF2, 0xCF);

    //gdt_flush();
}

