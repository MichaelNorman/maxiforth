\ Runtime DLL loading
\ The arg1-arg4 primitives read their input from r10b.
\ `rr10` and `lr10` are the new register manipulation words for r10.

\ ( callee signature -- <takes word off of input, creates dictionary entry for word that calls callee with args
\                       marshaled a la signature> )

\ bind signature strings can be represented with the following regex: [qduv](\|[if]*)?
\ In other words, they have to specify a return type, and each input argument is specified as an integer or float.
\ The table below shows the meanings of the different spedifiers
\ ___________________________________________________________________________________________
\ | Code | Meaning                                                         | Valid position |
\ |------|-----------------------------------------------------------------|----------------|
\ |  v   | void. No return value. Push nothing onto the stack.             | return only    |
\ |  q   | qword. Full-width integer value from rax. Pushed.               | return only    |
\ |  d   | dword. 32-bit signed integer value from eax. Pushed.            | return only    |
\ |  u   | unsigned dword. 32-bit unsigned integer value from eax. Pushed. | return only    |
\ |  f   | 32-bit float. Returned in xmm0. Accepted in xmmN. Pushed.       | return/arg     |
\ |  F   | 64-bit float. Returned in xmm0. Accepted in xmmN. Pushed.       | return/arg     |
\ |  i   | integer, any size. Returned in rax. Pushed.                     | argument only  |
\ |______|_________________________________________________________________|________________|

: bind create here 16 - dp ! find docol @ , 0 ,
    \ Get the size of the string, which is implicitly the size of the argument list. (It's two less than the length.)
    \
    ' exit ,
;