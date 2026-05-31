%include "macros.ninc"
%include "primitives.ninc"

section .rodata

section .data
    echo_fmt                   db "I found: %s", 10, 0
    test_str                   db 10, "Ran this from the dictionary!", 10, 0
    not_found_msg              db 10, "Word does not exist in dictionary.", 10, 0
    quit_msg                   db 10, "I'm the quit label!", 10, 0
    goof_msg                   db 10, "In test and done goofed!", 10, 0
    error_return_overflow_msg  db "Return stack overflow.", 10, 0
    error_return_underflow_msg db "Return stack underflow.", 10, 0
    error_data_underflow_msg   db "Data stack underflow.", 10, 0
    error_data_overflow_msg    db "Data stack overflow.", 10, 0
    ; CFAs for manually coded compiled words:
    cfa_interpret: dq interpret_body
    cfa_quit:      dq quit_body

    ; CFAs for primitives:
    cfa_emit:                   dq _emit
    cfa_lit:                    dq _lit
    cfa_exit:                   dq _exit
    cfa_docol:                  dq _docol
    cfa_refill:                 dq _refill
    cfa_branch:                 dq _branch
    cfa_rp0:                    dq _rp0
    cfa_rp_store:               dq _rp_store
    cfa_input_buffer:           dq _input_buffer
    cfa_ib_fill:                dq _ib_fill
    cfa_input_pos:              dq _input_pos
    cfa_gt:                     dq _gt
    cfa_0branch:                dq _0branch
    cfa_word:                   dq _word

    static_dictionary:
    label_quit:
    dq 0
    db 4
    db "quit"
    times 27 db 0
    dq cfa_docol
    ; begin quit loop body
    quit_body:
    dq cfa_docol
    dq cfa_rp0
    dq cfa_rp_store
    .begin:
    ; BEGIN
    dq cfa_refill
    dq cfa_interpret
    ; REPEAT
    dq cfa_branch
    dq quit_body.begin - $
    ; end quit loop body
    label_interpret:
    dq label_quit
    db 9
    db "interpret"
    times 22 db 0
    interpret_body:
    dq cfa_docol
    .begin:
    ; >in >= >#tib => branch exit
    dq cfa_ib_fill
    dq cfa_input_pos
    dq cfa_gt
    cfa_0branch
    dq .exit - $
    ; get a word
    dq cfa_fill_word
    ; if no word, branch to .begin
    ; find
    ; if found, branch to .dispatch
    ; >number
    ; if number, branch .number
    ; if state == 0, branch .run_num_error
    ; set state to 0
    ; unwind here
    .run_num_error:
    ; reset and error
    .number:
    ; if state == 0, branch .push_lit
    ; compiling, so:
    ; write LIT to here
    ; write value to here
    ; branch .begin
    .push_lit:
    ; push value onto stack
    ; branch .begin
    .dispatch:
    ; if state == 0, branch .run_it
    ; if IMMEDIATE, branch .run_it
    ; compiling, so
    ; write xt and advance here
    ; branch .begin
    .run_it:
    ; run
    ; branch .begin
    .exit:
    dq cfa_exit
    regular_entry _quit, "next", _next
    regular_entry _next, "docol", _docol
    regular_entry _docol, "exit", _exit
    regular_enrty _exit, "branch", _branch
    regular_entry _branch, "0branch", _0branch
    masked_dict_entry _0branch, "lit", _lit, IMMEDIATE
    regular_entry _lit, "key", _key
    regular_entry _key, "emit", _emit
    regular_entry _emit, "dup", _dup
    regular_entry _dup, "2dup", _2dup
    regular_entry _2dup, "drop", _drop
    regular_entry _drop, "swap", _swap
    regular_entry _swap, "over", _over
    regular_entry _over, "rot", _rot
    regular_entry _rot, ">r", _to_return
    regular_entry _to_return, "r>", _to_data
    regular_entry _to_data, "sp@", _get_sp
    regular_entry _get_sp, "rp@", _get_rp
    regular_entry _get_rp, "here", _dp
    regular_entry _dp, "state", _state
    regular_entry _state, "latest", _latest
    regular_entry _latest, ">in", _input_pos
    regular_entry _input_pos, "source", _input_buffer
    regular_entry _input_buffer, "@", _get
    regular_entry _get, "!", _store
    regular_entry _store, "c@", _char_get
    regular_entry _char_get, "c!", _char_store
    regular_entry _char_store, "+", _add
    regular_entry _add, "-", _sub
    regular_entry _sub, "and", _and
    regular_entry _and, "invert", _invert
    regular_entry _invert, "*", _mul
    regular_entry _mul, "xor", _xor
    regular_entry _xor, "or", _or
    regular_entry _or, "/", _div
    regular_entry _div, "/mod", _divmod
    regular_entry _divmod, "mod", _mod
    regular_entry _mod, "+!", _plus_store
    regular_entry _plus_store, "-!", _sub_store
    regular_entry _sub_store, "<<", _lshift
    regular_entry _lshift, ">>", _rshift
    regular_entry _rshift, "<", _lt
    regular_entry _lt, "<=", _lte
    regular_entry _lte, "=", _eq
    regular_entry _eq, ">=", _gte
    regular_entry _gte, ">", _gt
    regular_entry _gt, "0=", _0=
    regular_entry _0=, "u<", _ult
    regular_entry _ult, "here", _here
    regular_entry _here, "state", _state
    regular_entry _state, "latest", _latest
    regular_entry _latest, "base', _base
    regular_entry _base, "create", _create
    regular_entry _create, "find", _find_word
    regular_entry _find_word, ",", _comma
    regular_entry _comma, "run", _run
    regular_entry _run, "rp0", _rp0
    regular_entry _rp0, "sp0", _sp0
    regular_entry _sp0, "rp!", _rp_store
    regular_entry _rp_store, "sp!", _sp_store
    regular_entry _sp_store, "#tib", _ib_fill
    regular_entry _ib_fill, "word", _word
    initial_latest:
    regular_entry _ib_fill, "accept", _accept

section .bss
    main_rbp              resq 1
    stdin                 resq 1
    lookup_buffer         resb 32 ; ANS Forth standard 31-byte word with length prefix
    current_char          resb 1
    data_stack            resb DATA_STACK_SIZE * POINTER_SIZE
    return_stack          resb RETURN_STACK_SIZE * POINTER_SIZE
    file_pointer_stack    resb FILE_POINTER_STACK_SIZE * POINTER_SIZE

    ; state
    latest                resq 1
    input_buffer          resb INPUT_BUFFER_SIZE
    input_pos             resq 1
    here                  resq 1
    state                 resb 1

section .text
    global main
    extern __acrt_iob_func
    extern getch
    extern putch
    extern printf
main:
    enter_call
    lea DATA_TOS_REG, [rel data_stack]
    lea RETURN_TOS_REG, [rel return_stack]
    mov [rel main_rbp], rbp
    sub rsp, 32
    lea rax, [rel latest_label]
    mov [rel latest], rax
    xor rax, rax
    mov rcx, 0
    call __acrt_iob_func
    mov [rel stdin], rax
    ; jump start quit loop
    ret

skip_space:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    .skip_loop:
        call getch
        mov r14, rax
        cmp r14b, ' '
        je .skip_loop
        cmp r14b, 13
        je .skip_loop
        cmp r14b, 10
        je .skip_loop
        cmp r14b, 9
        je .skip_loop
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret

_fill:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    call skip_space
    lea r13, [rel lookup_buffer + 31]
    lea rdi, [rel lookup_buffer]
    mov rcx, 4
    mov rax, 0
    rep stosq

    lea r12, [rel lookup_buffer + 1]
    mov byte [r13], 0
    jmp .word_start
    .char_loop:
        call getch
        mov r14, rax
        .word_start:
            ;check for baill\ing
            cmp r14b, 0x03
            je .bail
            ; check for word boundaries
            cmp r14b, ' '
            je .ret
            cmp r14b, 13
            je .ret
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
            lea r10, [rel lookup_buffer + 1]
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
            ; move to next slot
            inc r12
            ; keep the length current
            inc byte [rel lookup_buffer]
            cmp r13, r12
            je .ret
            jmp .char_loop
    .ret:
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
    .bail: ; TODO: FIX!!! implement handling that the quit loop will understand, or properly throw.
    mov rbp, [rel main_rbp]
    jmp main.end

_find:
    ; start at latest
    push rbp
    mov rbp, rsp
    xor rax, rax
    lea r8, [rel lookup_buffer]
    ; store comparison limit
    mov rcx, r8
    add rcx, 24
    lea rdx, [rel latest]
    ; treat 32-byte names as four qwords for comparison, bail on mismatch
    .initial_compare: ; first qword in dictionary name could have mask values
    mov r9, rdx
    add r9, 8 ; offset for name start
    ; get ahold of the value at the address in r9
    mov r10, [r9]
    ; mask out flags in first byte
    and r10, 0xFFFFFFFFFFFFFF1F
    ; compare first chunk
    cmp r10, [r8]
    jne .previous
    ; move to next chunk and loop naively
    add r8, 8
    add r9, 8
    .cmp_loop:
        ; move on to previous entry if we miss
        mov r10, [r8]
        cmp r10, [r9]
        jne .previous

        ; move to next qword pair and start over
        add r8, 8
        add r9, 8
        ; see if we've already compared the four qwords that comprise the word
        cmp r8, rcx
        ja .success
        jmp .cmp_loop
        .previous:
        ; eventually, this will load return normally
        cmp qword [rdx], 0
        je .bail
        ; follow the previous pointer
        mov rdx, [rdx]
        lea r8, [rel lookup_buffer]
        ; start afresh in a new word
        jmp .initial_compare
    .success:
    mov rsp, rbp
    pop rbp
    lea rax, [rdx + CFA_OFFSET] ; where the XT lives
    ret
    ; if not found, print friendly message, for now
    .bail:
        lea rcx, [rel not_found_msg]
        sub rsp, 32
        call printf
        add rsp, 32
        mov rax, 0
        mov rbp, [rel main_rbp]
        jmp main.quit

callable_error error_return_overflow, error_return_overflow_msg
callable_error error_return_underflow, error_return_underflow_msg
callable_error error_data_underflow, error_data_underflow_msg
callable_error error_data_overflow, error_data_overflow_msg