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
    error_input_buffer_overrun_msg db "Last character of input buffer was not white space.", 10, 0
    error_ib_overrun_hard_msg      db "Hard overrun of input buffer. Interpreter corrupted. Exit and restart.", 10, 0
    error_ib_underrun_hard_msg     db "Hard underrun of input buffer. Interpreter corrupted. Exit and restart.", 10, 0
    qstr                           db " ?", 10, 0
    okstr                          db " ok", 10, 0

    ; CFAs for manually coded compiled words:
    cfa_interpret: dq interpret_body
    cfa_quit:      dq quit_body

    ; CFAs for primitives:
    cfa_sub:                    dq _sub
    cfa_emit:                   dq _emit
    cfa_lit:                    dq _lit
    cfa_exit:                   dq _exit
    cfa_docol:                  dq _docol
    cfa_refill:                 dq _refill
    cfa_branch:                 dq _branch
    cfa_rp0:                    dq _rp0
    cfa_rp_store:               dq _rp_store
    cfa_sp0:                    dq _sp0
    cfa_sp_store:               dq _sp_store
    cfa_input_buffer:           dq _input_buffer
    cfa_tib:                    dq _tib
    cfa_input_pos:              dq _input_pos
    cfa_gt:                     dq _gt
    cfa_gte:                    dq _gte
    cfa_0branch:                dq _0branch
    cfa_word:                   dq _word
    cfa_dup:                    dq _dup
    cfa_char_get:               dq _char_get
    cfa_0branch:                dq _0branch
    cfa_find:                   dq _find
    cfa_0eq:                    dq _0eq
    cfa_swap:                   dq _swap
    cfa_lt0:                    dq _lt0
    cfa_gt0:                    dq _gt0
    cfa_state:                  dq _state
    cfa_drop:                   dq _drop
    cfa_here:                   dq _here
    cfa_to_number:              dq _to_number
    cfa_run:                    dq _run
    cfa_cmove_desc:             dq _cmove_desc
    cfa_cmove_asc:              dq _cmove_asc
    cfa_wb_to_pad:              dq _wb_to_pad
    cfa_type:                   dq _type
    cfa_pad:                    dq _pad

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
    dq cfa_lit
    dq okstr
    dq cfa_type
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
            dq cfa_lit          ; (  -- INPUT_BUFFER_SIZE  )
            dq INPUT_BUFFER_SIZE
            dq cfa_lit          ; ( INPUT_BUFFER_SIZE -- INPUT_BUFFER_SIZE input_pos )
            dq cfa_input_pos
            dq cfa_gt           ; ( input_pos INPUT_BUFFER_SIZE -- -1 | 0)
            dq cfa_0branch
            dq .exit - $
            ; get a word
            dq cfa_word
            ; exit on 0-length word
            dq cfa_dup ; address of word_buffer
            dq cfa_char_get ; length byte of word
            dq cfa_0branch
            dq .exit - $
            ; find
            dq cfa_find         ; ( -- addr|XT -1|0|1)
            dq cfa_state        ; ( addr|XT -1|0|1-- addr|XT -1|0|1 0|-1 )
            dq cfa_0eq          ; ( addr|XT -1|0|1 0|-1--  addr|XT -1|0|1 -1|0)
            dq cfa_0branch      ; ( addr|XT -1|0|1 -1|0 -- addr|XT -1|0|1 <continue>) |
                                                          ; addr|XT -1|0|1 <jmp compile>)
            dq .compile - $     ; --
            ; in "running" state
            dq cfa_dup          ; (addr|XT -1|0|1 -- addr|XT -1|0|1  -1|0|1)
            dq cfa_0branch      ; (addr|XT -1|0|1  -1|0|1 -- XT -1|1 <continue> |
                                                           ; addr 0 <jmp run_number)
            dq .run_number - $  ; .run_number label must start with dq cfa_drop
            ; whether regular or immediate, run the word:
            dq cfa_drop         ; (XT -1|1 -- XT)
            dq cfa_branch       ; (XT -- <jmp run_it)
            dq .run_it - $
        .compile:
            ; TOS is still the flag. STATE is definitely 1. TOS is -1, 0, or 1
            dq cfa_dup          ; ( addr|XT -1|0|1 -- addr|XT -1|0|1 -1|0|1)
            dq cfa_0branch      ; ( addr|XT -1|0|1 -1|0|1 -- addr 0 <jmp compile_number> | XT -1|1 <continue>)
            dq .compile_number - $
            dq cfa_0lt          ; ( XT -1|1 -- XT -1|0)
            dq cfa_0branch      ; ( XT -1|0 -- XT <continue> | XT <jmp compile_number)
            ; jump ot run_it on immediate
            dq .run_it - $
            ; compile step!
            dq cfa_comma        ; ( XT -- <compile word> )
            ; dq cfa_branch
            ;dq .compile_number - $ ; FALL THROUGH AS LONG AS .compile_number IS NEXT
            .compile_number:
            dq cfa_to_number    ; ( addr -- int -1 | addr 0)
            dq cfa_0branch
            dq .write_and_abort - $
            dq cfa_lit          ; ( int -- int cfa_lit)
            dq cfa_lit          ; ^
            dq cfa_comma        ; ( int cfa_lit -- int <compiile cfa_lit> )
            dq cfa_comma        ; (int -- <compile int> )
            dq cfa_comma        ; (int -- <compile the number>)
            ; branch .begin
            dq cfa_branch
            dq .begin - $
        .run_it:
            dq cfa_run          ; ( XT -- <execute XT> )
            dq cfa_branch
            dq .begin - $
        .run_number:
            dq cfa_to_number        ; ( addr -- int -1 | addr 0 )
            dq cfa_0branch          ; ( int -1 | addr 0 -- int <continue> | addr <jmp write and abort> )
            dq .write_and_abort - $
            dq cfa_branch
            dq .begin - $
        .write_and_abort:
            ; ( addr -- <printed message> )
            ; minor wart: wb>pad is a convenience primitive that allows for a simpler type primiitive. rather than
            ;             write wb>pad in threaded code, I'm paying the cost of just dropping the address of
            ;             word_buffer.
            dq cfa_drop             ; ( &word_buffer -- )
            dq cfa_wb_to_pad        ; ( -- &pad <pad contains typable string representation of word_buffer> )
            dq cfa_type             ; ( &pad -- <print unknown word> )
            dq qstr                 ; ( -- &qstr )
            dq cfa_type             ; ( &qstr -- <print " ?\n"> )
            dq cfa_sp0              ; ( -- &data_stack )
            dq cfa_sp_store         ; ( &data_stack -- <data stack pointer set to base> )
            dq cfa_lit              ; ( -- 0 )
            dq 0
            dq cfa_lit              ; ( 0 -- 0 &state )
            dq cfa_state            ; ( 0 -- <state set to interpreting> )
            dq cfa_store
        .exit:
            dq cfa_exit
    regular_entry _quit, "next", _next
    regular_entry _next, "refill", _refill
    regular_entry _refill, "docol", _docol
    regular_entry _docol, "exit", _exit
    regular_enrty _exit, "branch", _branch
    regular_entry _branch, "0branch", _0branch
    regular_entry _0branch, "lit", _lit
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
    regular_entry _to_number, "cmove", _cmove_asc
    regular_entry _cmove_asc, "cmove>", _cmove_desc
    regular_entry _cmove_des, "wb>pad", _wb_to_pad
    regular_entry _wb_to_pad, "pad",
    regular_entry _pad, "type", _type
    initial_latest:
    regular_entry _type, "accept", _accept

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
    pad                   resb PAD_SIZE
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
        je .not_found
        ; follow the previous pointer
        mov rdx, [rdx]
        lea r8, [rel word_buffer]
        ; start afresh in a new word
        jmp .initial_compare
    .success:
        lea rax, [rdx + CFA_OFFSET] ; where the XT lives

        ; fill rdx with 1 or -1 depending on the flag
        movzx r8d, byte [rdx + WORD_OFFSET]
        test r8b, IMMEDIATE_MASK
        jnz .immediate
        mov rdx, -1
        jmp .ret
        .immediate:
            mov rdx, 1
            jmp .ret
    .not_found:
        lea rax, [rel word_buffer]
        mov rdx, 0
    .ret:
        mov rsp, rbp
        pop rbp
        ret

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
        jmp .error_check
    .dec:
        xor r10, r10
        sub rsp, 32
        call dec_convert
        add rsp, 32
        jmp .error_check
    .oct:
        xor r10, r10
        sub rsp, 32
        call oct_convert
        add rsp, 32
        jmp .error_check
    .error_check:
        cmp rax, -1
        jne .handle_failure
        cmp byte [rel negative], 1
        jne .ret
        neg qword [rel working_number]
        mov rdx, [rel working_number]
    .handle_failure:
        lea rdx, [rel word_buffer]
    .ret:
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
        jmp .error_result
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
            jmp .error_result

        .fifteen_check:
            cmp r10b, 'f'
            jbe .got_hex
            jmp .error_result

        .got_hex:
        sub r10b, 0x57 ; magic number to leave 10-15 in r10b
        ; jmp .acc fall through
        .acc:
        imul rdx, rdx, 16 ; I know, I know. Not using base saves a load and reduces register pressure
        add rdx, r10
        dec r9b
        cmp r9b, 0
        je .success_result
        inc r8
    jmp .loop
    .error_result:
    mov rax, 0
    ret
    .success_result:
    mov rax, -1
    ret

dec_convert:
    mov r11, [rel working_number]
    .loop:
        mov r10b, [r8] ; the digit character to transform into a value
        cmp r10b, '0''
        jae .nine_check
        jmp .error_result
        .nine_check:
            cmp r10b, '9'
            jbe .valid_digit
            ;out of 0-9 range
            jmp .error_result
        .valid_digit:
        sub r10b, '0' ; subtract off ASCII `0` (0x30) to get a value
        imul rdx, rdx, 10 ; I know, I know. Not using base saves a load and reduces register pressure
        add rdx, r10
        dec r9b
        cmp r9b, 0
        je .success_result
        inc r8
    jmp .loop
    .error_result:
    mov rax, 0
    ret
    .success_result:
    mov rax, -1
    ret

oct_convert:
    mov r11, [rel working_number]
    .loop:
        mov r10b, [r8] ; the digit character to transform into a value
        cmp r10b, '0''
        jae .seven_check
        jmp .error_result
        .seven_check:
            cmp r10b, '7'
            jbe .valid_digit
            ;out of 0-9 range
            jmp .error_result
        .valid_digit:
        sub r10b, '0' ; subtract off ASCII `0` (0x30) to get a value
        imul rdx, rdx, 8 ; I know, I know. Not using base saves a load and reduces register pressure
        add rdx, r10
        dec r9b
        cmp r9b, 0
        je .success_result
        inc r8
    jmp .loop
    .error_result:
    mov rax, 0
    ret
    .success_result:
    mov rax, -1
    ret

callable_error error_return_overflow, error_return_overflow_msg
callable_error error_return_underflow, error_return_underflow_msg
callable_error error_data_underflow, error_data_underflow_msg
callable_error error_data_overflow, error_data_overflow_msg
callable_error error_bad_numeric_lieral, error_bad_numeric_lieral_msg
callable_error error_bad_base, error_bad_base_msg
callable_error error_input_buffer_overrun, error_input_buffer_overrun_msg
callable_error error_ib_overrun_hard, error_ib_overrun_hard_msg
callable_error error_ib_underrun_hard, error_ib_underrun_hard_msg