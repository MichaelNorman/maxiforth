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
    error_init_fail_filename_msg   db "Failed to get init.forth filename.", 10, 0
    error_init_bad_filename_msg    db "init.forth path malformed.", 10, 0
    error_init_long_filename_msg   db "init.forth path too long.", 10, 0
    error_init_file_no_exist_msg   db "Could not open init.forth.", 10, 0
    error_fp_stack_overflow_msg    db "File pointer stack overflow: Too many nested includes.", 10, 0
    error_fp_stack_underflow_msg   db "File pointer stack underflow: Too many pops.", 10, 0
    qstr                           db " ?", 10, 0
    okstr                          db " ok", 10, 0
    init_forth_str                 db "init.forth", 0
    file_read_str                  db "rb", 0
    message                        db "It worked!", 10, 0
    align 16
    ; CFAs for manually coded compiled words:
    ;cfa_interpret: dq interpret_body
    cfa_quit:                   dq quit_body

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
    cfa_word:                   dq _word
    cfa_dup:                    dq _dup
    cfa_char_get:               dq _char_get
    cfa_0branch:                dq _0branch
    cfa_comma:                  dq _comma
    cfa_find:                   dq _find_word ; used to be _find
    cfa_0eq:                    dq _0eq
    cfa_swap:                   dq _swap
    cfa_0lt:                    dq _0lt
    cfa_0gt:                    dq _0gt
    cfa_state:                  dq push_state
    cfa_get:                    dq _get
    cfa_store:                  dq _store
    cfa_drop:                   dq _drop
    cfa_here:                   dq push_dp
    cfa_to_number:              dq _to_number
    cfa_run:                    dq _run
    cfa_cmove_desc:             dq _cmove_desc
    cfa_cmove_asc:              dq _cmove_asc
    cfa_wb_to_pad:              dq _wb_to_pad
    cfa_type:                   dq _type
    cfa_ctype:                  dq _ctype
    cfa_pad:                    dq _pad
    cfa_bye:                    dq _bye
    cfa_pause:                  dq _pause
    cfa_ok:                     dq _ok
    cfa_wbuf:                   dq push_wbuf

    align 16
    static_dictionary:
    label_quit:
    dq 0
    db 4 | SMUDGE
    db "quit"
    times 27 db 0
    ; BEGIN QUIT LOOP BODY
    quit_body:
    dq cfa_docol
    dq cfa_rp0
    dq cfa_rp_store
    .begin:             ; ( okstraddr -- < " ok" printed> )
    ; BEGIN
    dq cfa_refill              ; (
    dq cfa_0branch
    dq .fault - $
    dq cfa_interpret
    dq cfa_ok
    ; REPEAT
    dq cfa_branch
    dq quit_body.begin - $
    .fault:
    dq cfa_bye
    ; END QUIT LOOP BODY
    label_interpret:
    dq label_quit
    db 9
    db "interpret"
    times 22 db 0
    cfa_interpret:
        dq _docol
    ; BEGIN INTERPRET BODY
    interpret_body:
        .begin:
            ; >in >= >#tib -> branch exit
            dq cfa_lit          ; (  -- INPUT_BUFFER_SIZE  )
            dq INPUT_BUFFER_SIZE
            dq cfa_input_pos    ; ( INPUT_BUFFER_SIZE -- INPUT_BUFFER_SIZE input_pos )
            dq cfa_gt           ; ( input_pos INPUT_BUFFER_SIZE -- -1 | 0)
            dq cfa_0branch      ; ( -1 -- <continue> ) | ( 0 -- <jmp exit> )
            dq .exit - $
            ; get a word
            dq cfa_wbuf        ; ( -- addr )
            dq cfa_word         ; ( addr -- addr ) {Actually, it's ( -- ) but an address must be present}
            ; exit on 0-length word
            dq cfa_dup          ; ( addr -- addr addr )
            dq cfa_char_get     ; ( addr addr -- addr byte )
            dq cfa_0branch      ; ( addr byte -- addr <continue> | addr <jmp exit> )
            dq .drop_exit - $
            ; find
            dq cfa_find         ; ( addr -- addr 0 | XT ( -1|1 )
            dq cfa_state        ; ( addr 0 | XT (-1|1)  -- (addr 0 | XT (-1|1) )  (0|1) )
            dq cfa_get
            dq cfa_0eq          ; ( addr 0 | XT (-1|1) )  (0|1)  --   ( addr 0 | XT (-1|1) )  (-1|0) )
            dq cfa_0branch      ; ( ( addr 0 | XT (-1|1) )  (-1|0) --( addr 0 | XT (-1|1) <continue> | <jmp compile>) )
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
            dq cfa_drop
            dq cfa_to_number    ; ( addr -- int -1 | addr 0 )
            dq cfa_0branch      ; ( int -1 | addr 0 -- int <continue> | addr <jmp write and abort> )
            dq .write_and_abort - $
            dq cfa_branch
            dq .begin - $
        .write_and_abort:
            ; ( addr -- <printed message> )
            ; minor wart: wb>pad is a convenience primitive that allows for a simpler type primiitive. rather than
            ;             write wb>pad in threaded code, I'm paying the cost of just dropping the address of
            ;             word_buffer.
            dq cfa_drop         ; ( &word_buffer -- )
            ; dq cfa_pause
            dq cfa_wb_to_pad    ; ( -- &pad <pad contains typable string representation of word_buffer> )
            dq cfa_type         ; ( &pad -- <print unknown word> )
            dq cfa_lit
            dq qstr             ; ( -- &qstr )
            dq cfa_ctype        ; ( &qstr -- <print " ?\n"> )
            dq cfa_lit          ; ( -- 0 )
            dq 0
            ; dq cfa_lit          ; ( 0 -- 0 &state )
            dq cfa_state        ; ( 0 -- 0 &state )
            dq cfa_store        ; ( 0 &state -- <state set to interpreting> )
            dq cfa_sp0          ; ( -- &data_stack )
            dq cfa_sp_store     ; ( &data_stack -- <data stack pointer set to base> )
            dq cfa_exit
        .drop_exit:
            dq cfa_drop
        .exit:
            dq cfa_exit
    regular_entry _quit, "next", _next
    regular_entry _next, "refill", _refill
    regular_entry _refill, "docol", _docol
    regular_entry _docol, "exit", _exit
    regular_entry _exit, "branch", _branch
    regular_entry _branch, "0branch", _0branch
    regular_entry _0branch, "lit", _lit
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
    regular_entry _get_rp, "here", push_dp
    regular_entry push_dp, "state", push_state
    regular_entry push_state, "latest", push_latest
    regular_entry push_latest, ">in", _input_pos
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
    regular_entry _gt, "0=", _0eq
    regular_entry _0eq, "u<", _ult
    regular_entry _ult, "base", push_base
    regular_entry push_base, "find", _find_word
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
    regular_entry _0gt, ">number", _to_number
    regular_entry _to_number, "cmove", _cmove_asc
    regular_entry _cmove_asc, "cmove>", _cmove_desc
    regular_entry _cmove_desc, "wb>pad", _wb_to_pad
    regular_entry _wb_to_pad, "pad", _pad
    regular_entry _pad, "type", _type
    regular_entry _type, "bye", _bye
    regular_entry _bye, "msg", _message
    regular_entry _message, "ctype", _ctype
    regular_entry _ctype, "dovar", _dovar
    regular_entry _dovar, "pause", _pause
    regular_entry _pause, "wbuf", push_wbuf
    initial_latest:
    regular_entry push_wbuf, "accept", _accept

section .bss
    alignb 16
    initial_here:
    dynammic_dictionary   resb DYNA_DICT_SIZE
    dyna_dict_end:
    main_rbp              resq 1
    stdin                 resq 1
    word_buffer           resb 32 ; ANS Forth standard 31-byte word with length prefix
    current_char          resb 1
    alignb 16
    data_stack            resb DATA_STACK_SIZE * POINTER_SIZE
    return_stack          resb RETURN_STACK_SIZE * POINTER_SIZE
    file_pointer_stack    resb FILE_POINTER_STACK_SIZE * POINTER_SIZE
    fp_tos                resq 1
    qw_scratch            resq 1

    ; state
    latest                resq 1
    input_buffer          resb INPUT_BUFFER_SIZE ; tib, actually
    pad                   resb PAD_SIZE
    input_pos             resq 1 ; index into input_buffer
    here                  resq 1
    state                 resq 1
    base                  resq 1
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
    extern strrchr
    extern _get_pgmptr
    extern memcpy
    extern strcpy
    extern _errno

main:
    enter_call
    lea DATA_TOS_REG, [rel data_stack]
    lea RETURN_TOS_REG, [rel return_stack]
    lea r8, [rel file_pointer_stack]
    mov [rel fp_tos], r8
    mov [rel main_rbp], rbp
    sub rsp, 32
    lea rax, [rel initial_latest]
    mov [rel latest], rax
    xor rax, rax
    mov rcx, 0
    call __acrt_iob_func
    mov [rel stdin], rax
    mov qword [rel base], 10 ; start out intuitively
    lea rax, [rel initial_here]
    mov qword [rel here], rax
    mov qword [rel state], 0

    ; point input at init.forth, init file adjacent to exe
    call get_init
    mov rcx, rax
    ;call printf
    ;int3
    lea rdx, [rel file_read_str]
    call fopen
    test rax, rax
    jz .init_file_no_exist
    ; file_pointer_stack, fp_tos, qw_scratch
    var_of file_pointer_stack, fp_tos, POINTER_SIZE, 1, FILE_POINTER_STACK_SIZE*POINTER_SIZE, error_fp_stack_overflow
    mov r8, rax
    var_stack_push r8, r9, fp_tos, POINTER_SIZE


    ; jump start quit loop
    lea IP_REG, [rel quit_body + POINTER_SIZE] ; skip cfa_docol
    jmp _next
    
    .fault:
    leave_call ; will never get here. Should do leave_call in bye or its equivalent
    ret
    .init_file_no_exist:
    call _errno
    mov eax, [rax]
    int3
    call error_init_file_no_exist
get_init:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    ; get name of the exe
    lea rcx, [rel qw_scratch]
    call _get_pgmptr
    test rax, rax
    jnz .fail_filename
    ; check the size of the returned path, and bail on 511 or larger
    mov r10, rax
    mov rcx, [rel qw_scratch]
    call strlen
    cmp rax, PAD_SIZE - 1 ; this checks not just for fit inside pad, but fit
    jae .long_filename

    ; copy name of exe into pad
    mov rdx, [rel qw_scratch]
    lea rcx, [rel pad]

    call strcpy
    ; find the last `\\`
    lea rcx, [rel pad]
    mov rdx, '\'
    call strrchr
    test rax, rax
    jz .bad_filename
    ; ensure we can fit `init.forth\0` into pad
    mov rcx, rax
    lea r9, [rel pad]
    add r9, PAD_SIZE - 12 ;    |...<location>|\init.forth0|
                          ; PAD|        <loc>|    PAD_SIZE|
    cmp rcx, r9
    jae .long_filename
    ; copy our file name at that position
    inc rcx ; we write starting one past the `\`
    lea rdx, [rel init_forth_str]
    mov r8, 11
    call memcpy
    lea rax, [rel pad]
    .ret:
    add rsp, 32
    mov rsp, rbp
    pop rbp
    ret
    .fail_filename:
        call error_init_fail_filename
        jmp .ret
    .bad_filename:
        call error_init_bad_filename
        jmp .ret
    .long_filename:
        call error_init_long_filename
        ; jmp .ret FALL THROUGH
; presumes that the address of the word buffer has been loaded into r8
_find:
    push rbp
    mov rbp, rsp
    xor rax, rax
    ; start at latest
    lea rdx, [rel latest]
    mov r11, r8 ; stash word address for later
    ; store comparison limit, noting that we are comparing by words
    mov rcx, r8
    add rcx, 24
    ; treat 32-byte names as four qwords for comparison, bail on mismatch
    .initial_compare: ; first qword in dictionary name could have mask values
    mov r9, rdx
    add r9, POINTER_SIZE ; offset for name start
    ; get ahold of the value at the address in r9
    mov r10, [r8]
    ; mask out flags in first byte (We could grab a byte, but and(X,1) is X, so we can just grab the word)
    test r10, SMUDGE
    ; compare first chunk
    jnz .previous
    and r10, 0xFFFFFFFFFFFFFF1F
    cmp r10, [r9]
    jne .previous
    ; move to next chunk and loop naively
    add r8, POINTER_SIZE
    add r9, POINTER_SIZE
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
        ; reset word pointer
        mov r8, r11
        ; start afresh in a new word
        jmp .initial_compare
    .success:
        lea rax, [rdx + CFA_OFFSET] ; where the XT lives

        ; fill rdx with 1 or -1 depending on the flag
        movzx r8d, byte [rdx + WORD_OFFSET]
        test r8b, IMMEDIATE
        jnz .immediate
        ; .regular:
        mov rdx, -1
        jmp .ret
        .immediate:
            mov rdx, 1
            jmp .ret
    .not_found:
        mov rax, r11
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
    movzx r9d, byte [r8] ; load length byte
    inc r8 ; move to start of string
    xor rax, rax
    mov al, [r8] ; get possible sign bit
    ; handle sign, if present
    mov byte [rel negative], 0
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
        neg rdx
        jmp .ret
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
    xor rdx, rdx
    .loop:
        mov r10b, [r8] ; the digit character to transform into a value
        cmp r10b, '0'
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
    xor rdx, rdx
    .loop:
        mov r10b, [r8] ; the digit character to transform into a value
        cmp r10b, '0'
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
    xor rdx, rdx
    .loop:
        mov r10b, [r8] ; the digit character to transform into a value
        cmp r10b, '0'
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
callable_error error_init_fail_filename, error_init_fail_filename_msg
callable_error error_init_bad_filename,  error_init_bad_filename_msg
callable_error error_init_long_filename, error_init_long_filename_msg
callable_error error_init_file_no_exist, error_init_file_no_exist_msg
callable_error error_fp_stack_overflow, error_fp_stack_overflow_msg
callable_error error_fp_stack_underflow, error_fp_stack_underflow_msg