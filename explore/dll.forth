\ Runtime DLL loading

\ The arg1-arg4 primitives read their input from r10b.
\ `rr10` and `lr10` are the new register manipulation words for r10.

\ ( callee signature -- <takes word off of input, creates dictionary entry for word that calls callee with args
\                       marshaled a la signature> )

\ bind signature can be represented by: [vqdufF](\|[ifF]*)?
\ A return code is mandatory; the optional |-suffix lists argument codes, one per
\ argument, in call order.
\ _______________________________________________________________________________________
\ | Code | Meaning                                                     | Valid position |
\ |------|-------------------------------------------------------------|----------------|
\ |  v   | void. No return value. Push nothing.                        | return only    |
\ |  q   | qword. Full 64 bits of rax. Pushed.                         | return only    |
\ |  d   | dword. eax, sign-extended to a cell. Pushed.                | return only    |
\ |  u   | dword. eax, zero-extended to a cell. Pushed.                | return only    |
\ |  i   | integer or pointer, any width. Cell moved whole to the      | argument only  |
\ |      | parameter register; upper bits are the callee's business.   |                |
\ |  f   | 32-bit float. Returned in xmm0, passed in xmmN. Pushed.     | return/arg     |
\ |  F   | 64-bit float. Returned in xmm0, passed in xmmN. Pushed.     | return/arg     |
\ |______|_____________________________________________________________|________________|
\
\ Narrowing, masking, and boolean conversion (Forth true is -1, not 1) are the
\ caller's job, done in Forth before the call.

var numargs
: countargs dup \ need a copy of the pointer to the string later to set the return behavior

;

: bind create here 16 - dp ! find docol @ , 0 ,
    \ Get the number of arguments.
    \ place binder tokens for all args present
    \ place token to move rsp
    \ place tokens to bind extra args, if present
    \ place token for call
    \ place token for pushing return value, if present
    ' exit ,
;