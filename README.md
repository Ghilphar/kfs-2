# Kernel From Scratch-1 for 42

A basic Kernel to Boot from with GRUB.

## Add env variables

```shell-session
export PREFIX="$HOME/mycross_cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"
```

## Build GRUB

It's possible that you don't have a compatible version of GRUB on your machine.
To make sure you do run the following command:

```shell-session
$ sh cross_compiled.sh
```

## Build kernel and run qemu 

Run the following command:

```shell-session
$ make run
```

Most `.s` files come in-full or partly from [OSDEV](https://wiki.osdev.org/Bare_Bones_with_NASM) 

## Explanations

You will find a kernel files in the repo:

- `kernel.c`

The `Makefile` will do all necessary

## Authors

- [fgaribot](https://github.com/Ghilphar?tab=repositories)
- [dapinto](https://github.com/RadioPotin?tab=repositories)

## Ressources
    
### KFS1

- [OSDEV BIBLE](https://wiki.osdev.org/Main_Page)
- [lets write a kernel](https://arjunsreedharan.org/post/82710718100/kernels-101-lets-write-a-kernel)
- [Bare Bones](https://wiki.osdev.org/Bare_Bones)
- [Bare Bones with NASM](https://wiki.osdev.org/Bare_Bones_with_NASM)

### KFS2

- [FELIXCLOUTIER - LGDT ET LIDT INSTRUCTIONS](https://www.felixcloutier.com/x86/lgdt:lidt)
- [Global Descriptor Table](https://wiki.osdev.org/Global_Descriptor_Table)
- [GDT Tutorial](https://wiki.osdev.org/GDT_Tutorial)
- [Memory Management](https://wiki.osdev.org/Memory_management)
- [Program Memory allocation types](https://wiki.osdev.org/Program_Memory_Allocation_Types)
- [This video](https://www.youtube.com/watch?v=Wh5nPn2U_1w&list=PLm3B56ql_akNcvH8vvJRYOc7TbYhRs19M&index=7)


