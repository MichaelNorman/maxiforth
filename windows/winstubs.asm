bits 64
default rel
section .data
    hello_dynamic:      db "Hello, Dynamic World!", 10, 0
    align 16
    print_ptr:          dq 0xefbeadde; 0xDEADBEEF
section .text
    ; extern printf
    print_message:
        push rbp
        mov rbp, rsp
        sub rsp, 32
        lea rcx, [hello_dynamic]
        call [print_ptr]
        add rsp, 32
        mov rsp, rbp
        pop rbp
        ret