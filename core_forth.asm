%include "macros.ninc"

section .rodata

section .data
    echo_fmt db "I found: %s", 10, 0
section .bss
    stdin        resq 1
    current_word resb 32 ; ANS Forth standard 31-byte word with length prefix
    current_char resb 1

section .text
    global main
    extern __acrt_iob_func
    extern getch
    extern putch
    extern printf
main:
    enter_call
    sub rsp, 32
    mov rcx, 0
    call __acrt_iob_func
    mov [rel stdin], rax

    .word_loop:
        lea r12, [rel current_word + 1]
        lea r13, [rel current_word + 31]
        .char_loop:
            call getch
            mov r14, rax
            ;check for bailling
            cmp r14b, 0x03
            je .end
            ; check for word boundaries
            cmp r14b, ' '
            je .print_word
            cmp r14b, 13
            je .print_word
            ; check for line editing
            cmp r14b, 8
            je .handle_bsp
            cmp r14b, 127
            je .handle_bsp
            ; check for control codes
            cmp r14b, 0
            je .consume_and_loop
            cmp r14b, 0xE0
            je .check_del
            jmp .no_bsp
            .consume_and_loop:
            call getch
            jmp .char_loop
            .check_del:
            call getch
            cmp al, 0x53
            jne .char_loop
            .handle_bsp:
                ; skip if at start of buffer
                lea r10, [rel current_word + 1]
                cmp r12, r10
                jle .char_loop
                ; fix input
                mov ecx, 8
                call putch
                mov ecx, 32
                call putch
                mov ecx, 8
                call putch
                dec r12
                jmp .char_loop
            .no_bsp:
            ; echo to user
            mov rcx, r14
            call putch
            ; mov al into the current location
            mov byte [r12], r14b
            inc r12
            cmp r13, r12
            je .print_word
            jmp .char_loop
        .print_word:
        mov rcx, 10
        call putch

        inc r8
        mov byte [r12], 0
        lea rcx, [rel echo_fmt]
        lea rdx, [rel current_word + 1]
        call printf
        jmp .word_loop
        .end:
    add rsp, 32
    leave_call
    xor rax, rax
    ret