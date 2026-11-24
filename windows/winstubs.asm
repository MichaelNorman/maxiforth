bits 64
default rel
section .text
%include "defines.ninc"
%include "macros.ninc"

handler_template: ; NOTE: This is a likely place to push the pointer to the win_throw handler
    mov rax, rsp
    mov r10, qword 0
    jmp cb_handler

win_throw:
    ret

cb_handler:
; enter_call. It leaves rcx, rdx, r8, and r9 untouched.
; push_vm_state, push in_callback, then subtract 8 more bytes for the pad. rsp is 16-aligned again.
; Load DATA_TOS_REG from vm_state+8 and RETURN_TOS_REG from vm_state+0.
; Store 1 in in_callback.
; Point IP_REG at thread cell 0.
; _NEXT.
    push rbx
    push rbp
    push rdi
    push rsi
    push r12
    push r13
    push r14
    push r15
    mov rbp, rsp
    sub rsp, 8  ; TODO: push address to callback throw handler onto the stack.
    push_vm_state ; push vm state ; TODO: This value can no longer line in a variable, it must be put onto the stack
    push qword [rel in_callback]  ; TODO: This will be handled by having stack-dependent error handlers
    add rax, 8 ; move to address of first argument
    push rax ; Needs a word to latch this pushed value
    ; load DATA_TOS_REG and RETURN_TOS_REG
    mov DATA_TOS_REG, [rel vm_state +  POINTER_SIZE]
    mov RETURN_TOS_REG, [rel vm_state]
    ; note that we're in a callback
    mov qword [rel in_callback], 1 ; TODO: This might not be necessary if we put pointers to `throw` on the stack
    ; set IP_REG and _NEXT
    mov IP_REG, r10
    _NEXT

; private word for callback return

cfa_cb_ret:                 dq _cb_ret

_cb_ret:
    push rcx
    push rdx
    ds_underflow 1
    pop rdx
    pop rcx
    stack_popq rax, DATA_TOS_REG
    add rsp, 8
    pop qword [rel in_callback]
    pop_vm_state
    mov rsp, rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbp
    pop rbx
    ret

section .data
wp_thread:              dq 0, cfa_cb_ret
cb_thread_template:     dq 0, cfa_cb_ret

section .text

; words for pushing the addresses of WndProc and cb_thread

_wp_thunk_addr:
    ds_overflow 1
    lea r8, [rel wp_thunk]
    stack_pushq r8, DATA_TOS_REG
    _NEXT

wp_thunk:
    mov rax, rsp
    lea r10, [rel _wp_thunk_addr]
    jmp WndProc

_cb_thread:
    ds_overflow 1
    lea r8, [rel cb_thread]
    stack_pushq r8, DATA_TOS_REG
    _NEXT

_test_thunk_addr:
    ds_overflow 1
    lea r8, [rel test_thunk]
    stack_pushq r8, DATA_TOS_REG
    _NEXT

test_thunk:
    mov rax, rsp
    lea r10, [rel cb_testthread]
    jmp WndProc

WndProc:
    mov rax, rsp
    mov r10, qword wp_thread
    jmp cb_handler

; ************************ Museum ***************************** ;

; section .data
;     hello_dynamic:      db "Hello, Dynamic World!", 10, 0
;     align 16
;     printf_ptr:          dq 0xefbeadde; 0xDEADBEEF
; section .text
;     ; extern printf
;     print_message:
;         push rbp
;         mov rbp, rsp
;         sub rsp, 32
;         lea rcx, [hello_dynamic]
;         call [printf_ptr]
;         add rsp, 32
;         mov rsp, rbp
;         pop rbp
;         ret
;