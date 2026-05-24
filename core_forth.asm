section .rodata

section .data
    hello db "Hello, World!", 10, 0
section .bss
    stdin        resq 1
    input_buffer resb 256

section .text
    global main
    extern __acrt_iob_func
    extern fgets
    extern printf
main:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    mov rcx, 0
    call __acrt_iob_func
    mov [rel stdin], rax

    .loop:
        lea rcx, [rel input_buffer]
        mov rdx, 256
        mov r8, [rel stdin]
        call fgets
        lea rcx, [rel input_buffer]
        call printf
        jmp .loop
    add rsp, 32
    mov rsp, rbp
    pop rbp
    xor rax, rax