section .rodata

section .data
    hello db "Hello, World!", 10, 0
section .bss

section .text
    global main
    extern printf
main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov rcx, hello
    call printf
    add rsp, 32
    mov rsp, rbp
    pop rbp
    xor rax, rax