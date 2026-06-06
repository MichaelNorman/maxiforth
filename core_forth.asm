%include "macros.ninc"
%include "primitives.ninc"

section .rodata

section .data
    echo_fmt                       db "I found: %s", 10, 0
    test_str                       db 10, "Ran this from the dictionary!", 10, 0
    not_found_msg                  db 10, "Word does not exist in dictionary.", 10, 0
    quit_msg                       db 10, "I'm the quit label!", 10, 0
    goof_msg                       db 10, "In test and done goofed!", 10, 0
    error_return_overflow_msg      db "Return stack overflow.", 10, 0
    error_return_underflow_msg     db "Return stack underflow.", 10, 0
    error_data_underflow_msg       db "Data stack underflow.", 10, 0
    error_data_overflow_msg        db "Data stack overflow.", 10, 0
    error_bad_numeric_lieral_msg   db "No word found, and invalid literal for any base.", 10, 0
    error_bad_base_msg             db "Bad base. This error should not occur.", 10, 0
    error_low_digit_msg            db "Low digit for any base.", 10, 0
    error_bad_hex_digit_msg        db "Invalid hex digit.", 10, 0
    error_high_hex_digit_msg       db "Invalid hex digit: too high.", 10, 0
    error_high_dec_digit_msg       db "Invalid decimal digit: too high", 10, 0
    error_input_buffer_overrun_msg db "Last character of input buffer was not white space.", 10, 0
    error_ib_overrun_hard_msg      db "Hard overrun of input buffer. Interpreter corrupted. Exit and restart.", 10, 0
    error_ib_underrun_hard_msg     db "Hard underrun of input buffer. Interpreter corrupted. Exit and restart.", 10, 0

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
    cfa_tib:                    dq _tib
    cfa_input_pos:              dq _input_pos
    cfa_gt:                     dq _gt
    cfa_0branch:                dq _0branch
    cfa_word:                   dq _word
    cfa_dup:                    dq _dup
    cfa_char_get:               dq _char_get
    cfa_0branch:                dq _0branch
    cfa_find:                   dq _find
    cfa_rt_lit:                 dq _rt_lit
    cfa_0eq:                    dq _0eq
    cfa_swap:                   dq _swap
    cfa_lt0:                    dq _lt0
    cfa_gt0:                    dq _gt0
    cfa_state:                  dq _state
    cfa_drop:                   dq _drop
    cfa_here:                   dq _here

    static_dictionary:
    label_quit:
    dq 0
    db 4
    db "quit"
    times 27 db 0
    dq cfa_docol
    ; BEGIN QUIT LOOP BODY
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
    ; END QUIT LOOP BODY
    label_interpret:
    dq label_quit
    db 9
    db "interpret"
    times 22 db 0
    ; BEGIN INTERPRET BODY
    interpret_body:
        dq cfa_docol
        .begin:
            ; >in >= >#tib -> branch exit
            dq cfa_input_pos
            dq cfa_dup
            dq cfa_rt_lit
            dq INPUT_BUFFER_SIZE
            dq cfa_gte
            dq cfa_0branch
            dq .exit - $
            ; get a word
            dq cfa_fill_word
            ; if no word, branch to .exit
            dq cfa_dup ; address of word_buffer
            dq cfa_char_get ; length byte of word
            dq cfa_0branch
            dq .exit - $
            ; find
            dq cfa_find
            dq cfa_state
            dq cfa_0eq
            dq cfa_0branch
            dq .compile - $
            ; in "running" state
            dq cfa_dup
            dq cfa_0branch
            dq .run_number - $
            ; whether regular or immediate, run the word:
            dq cfa_branch
            dq .run_it - $
        .compile:
            ; TOS is still the flag. STATE is definitely 1. TOS is -1, 0, or 1
            dq cfa_dup
            dq cfa_0branch
            dq .compile_number
            ; if not found, branch to .number
            dq cfa_dup
            dq cfa_0branch
            dq .number - $
            ; consume the flag dq cfa_dup ; flag
            dq cfa_lt0
            ; jump ot run_it on immediate
            dq cfa_0branch
            dq .run_it - $
            ; compile in anger:
            dq cfa_comma
            .compile_number:

        ; if IMMEDIATE, branch .run_it

        ; compiling, so
        ; write xt and advance here
        ; branch .begin
        .run_it:
        ; run
        ; branch .begin; >number
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

        .exit:
            dq cfa_exit
    regular_entry _quit, "next", _next
    regular_entry _next, "refill", _refill
    regular_entry _refill, "docol", _docol
    regular_entry _docol, "exit", _exit
    regular_enrty _exit, "branch", _branch
    regular_entry _branch, "0branch", _0branch
    regular_entry _0branch, "lit", _rt_lit
    regular_entry _rt_lit, "key", _key
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
    regular_entry _sp_store, "#tib", _tib
    regular_entry _tib, "word", _word
    regular_entry _word, "0<", _0lt
    regular_entry _0lt, "0>", _0gt
    regular_enrty _0gt, ">number", _to_number
    initial_latest:
    regular_entry _to_number, "accept", _accept

section .bss
    main_rbp              resq 1
    stdin                 resq 1
    word_buffer           resb 32 ; ANS Forth standard 31-byte word with length prefix
    current_char          resb 1
    data_stack            resb DATA_STACK_SIZE * POINTER_SIZE
    return_stack          resb RETURN_STACK_SIZE * POINTER_SIZE
    file_pointer_stack    resb FILE_POINTER_STACK_SIZE * POINTER_SIZE
    fp_tos                resq 1

    ; state
    latest                resq 1
    input_buffer          resb INPUT_BUFFER_SIZE ; tib, actually
    input_pos             resq 1 ; index into input_buffer
    here                  resq 1
    state                 resb 1
    working_number        resq 1
    negative              resb 1

section .text
    global main
    extern __acrt_iob_func
    extern _getch
    extern _putch
    extern fopen
    extern fclose
    extern ferr
    extern feof
    extern fread
    extern fgets
    extern strlen
    extern printf
main:
    enter_call
    lea DATA_TOS_REG, [rel data_stack]
    lea RETURN_TOS_REG, [rel return_stack]
    lea r8, [rel file_pointer_stack]
    mov [rel fp_tos], r8
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

; skip_space and fill are currently stupid. They were from an unbuffered input model that just filled the word,
; or from some transitional state.

; skip_space operates on input_buffer and input_pos, and consideres INPUT_BUFFER_SIZE
; The gist is, while input_pos < input_buffer + IBS and character is space-like, advance input_pos
skip_space:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    .skip_loop:
        call _getch
        mov r10, rax
        cmp r14b, ' '
        je .skip_loop
        cmp r10b, 13
        je .skip_loop
        cmp r10b, 10
        je .skip_loop
        cmp r10b, 9
        je .skip_loop
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret



_find:
    ; start at latest
    push rbp
    mov rbp, rsp
    xor rax, rax
    lea r8, [rel word_buffer]
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
        lea r8, [rel word_buffer]
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

to_number:
    push rbp
    mov rbp, rsp
    ; presume the address to a 32-byte array is in r8
    ; it is a length-prefixed 31-byte max value (32 bytes total).
    mov qword [rel working_number], 0 ; initialize positive accumulator
    movzx r9d, byte [r8] ; load length byte
    inc r8 ; move to start of string
    xor rax, rax
    mov al, [r8] ; get possible sign bit
    ; handle sign, if present
    cmp al, '-'
    jne .check_plus
    mov byte [rel negative], 1
    inc r8 ; move past sign
    dec r9b ; one "digit" was the sign
    jmp .sign_done
    .check_plus:
    cmp al, '+'
    jne .sign_done
    mov byte [rel negative], 0
    inc r8 ; move past sign
    dec r9b ; one 'digit" was the sign
    ; r9b contains the (possibly adjusted) nummber of bytes to check.
    ; r8 contains the (possibly adjusted) address of the first actual digit
    .sign_done:
        mov r10, [rel base]
        cmp r10, 16
        je .hex
        cmp r10, 10
        je .dec
        cmp r10, 8
        je .oct
        call error_bad_base
    .hex:
        xor r10, r10
        sub rsp, 32
        call hex_convert
        add rsp, 32
        jmp .handle_sign
    .dec:
        xor r10, r10
        sub rsp, 32
        call dec_convert
        add rsp, 32
        jmp .handle_sign
    .oct:
        xor r10, r10
        sub rsp, 32
        call oct_convert
        add rsp, 32
        jmp .handle_sign
    .handle_sign:
        cmp byte [rel negative], 1
        jne .sign_handled
        neg qword [rel working_number]
    .sign_handled:
    mov rsp, rbp
    pop rbp
    ret

; r8 has the address of the starting byte of the positive portion of the number
;    the number ends with `0` if it is shorter than 31 chars with sign or
;    has its last digit at most 31 bytes above &word_buffer
; r9b contains the number of digits to process
; word_buffer + 1 or +2 is the start of the number, coresponding to [r8]
; working_number is initialized to 0
; r10 is all balls

hex_convert:
    mov r11, [rel working_number]
    .loop:
        mov r10b, [r8] ; the digit character to transform into a value
        cmp r10b, '0''
        jae .nine_check
        call error_low_digit
        .nine_check:
        cmp r10b, '9'
        ja .hex_check ;out of 0-9 range, so let's hope it's a-f
        sub r10b, '0' ; subtract off ASCII `0` (0x30) to get a value
        jmp .acc
        .hex_check:
            ; the next line leaves ASCII digits untouched, but pushes characters to lowercase.
            ; a | 0x61 | 0110 0001
            ; f | 0x66 | 0110 0110
            ; A | 0x41 | 0100 0001
            ; F | 0x46 | 0100 0110
            ;   | 0x20 | 0010 0000
            ; In the chart above, ORing the final row with the capital row produces the lowrcase row.
            or r10b, 0x20

            cmp r10b, 'a'
            jae .fifteen_check
            call error_low_hex_digit

        .fifteen_check:
            cmp r10b, 'f'
            jbe .got_hex
            call error_high_hex_digit

        .got_hex:
        sub r10b, 0x57 ; magic number to leave 10-15 in r10b
        ; jmp .acc fall through
        .acc:
        imul r11, r11, 16 ; I know, I know. Not using base saves a load and reduces register pressure
        add r11, r10
        dec r9b
        cmp r9b, 0
        je .ret
        inc r8
    jmp .loop
    .ret:
    mov [rel working_number], r11
    ret

dec_convert:
    mov r11, [rel working_number]
    .loop:
        mov r10b, [r8] ; the digit character to transform into a value
        cmp r10b, '0''
        jae .nine_check
        call error_low_digit
        .nine_check:
            cmp r10b, '9'
            jbe .valid_digit
            ;out of 0-9 range
            call error_high_dec_digit
        .valid_digit:
        sub r10b, '0' ; subtract off ASCII `0` (0x30) to get a value
        imul r11, r11, 10 ; I know, I know. Not using base saves a load and reduces register pressure
        add r11, r10
        dec r9b
        cmp r9b, 0
        je .ret
        inc r8
    jmp .loop
    .ret:
    mov [rel working_number], r11
    ret

oct_convert:
    mov r11, [rel working_number]
    .loop:
        mov r10b, [r8] ; the digit character to transform into a value
        cmp r10b, '0''
        jae .seven_check
        call error_low_digit
        .seven_check:
            cmp r10b, '7'
            jbe .valid_digit
            ;out of 0-9 range
            call error_high_oct_digit
        .valid_digit:
        sub r10b, '0' ; subtract off ASCII `0` (0x30) to get a value
        imul r11, r11, 8 ; I know, I know. Not using base saves a load and reduces register pressure
        add r11, r10
        dec r9b
        cmp r9b, 0
        je .ret
        inc r8
    jmp .loop
    .ret:
    mov [rel working_number], r11
    ret

callable_error error_return_overflow, error_return_overflow_msg
callable_error error_return_underflow, error_return_underflow_msg
callable_error error_data_underflow, error_data_underflow_msg
callable_error error_data_overflow, error_data_overflow_msg
callable_error error_bad_numeric_lieral, error_bad_numeric_lieral_msg
callable_error error_bad_base, error_bad_base_msg
callable_error error_low_digit, error_low_digit_msg
callable_error error_bad_hex_digit, error_bad_hex_digit_msg
callable_error error_high_hex_digit, error_high_hex_digit_msg
callable_error error_high_dec_digit, error_high_dec_digit_msg
callable_error error_input_buffer_overrun, error_input_buffer_overrun_msg
callable_error error_ib_overrun_hard, error_ib_overrun_hard_msg
callable_error error_ib_underrun_hard, error_ib_underrun_hard_msg