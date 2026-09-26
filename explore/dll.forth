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

\ construct a number string from the bits after the pointer, presuming it's a null-terminated string
var numstr 32 allot \ guess that the dictionary is already aligned to 16 bytes

var x
: cstr2numstr
    0 x !
    begin
        x 31 <
        dup x + c@ 0 <>
        and
    while
        dup x @ + c@ \ character at the offset
        1 x @ + x !
        numstr x @ + c!
    repeat
    x @ numstr !
;

\ ( psigspec -- psigspec argcount )
: countargs dup
    @ 2 - \ get the length from "X|xxxxN"
    5 = if
        dup 14 + cstr2numstr >number 4 +
    else
        dup @ 2 -
    then
;

: max dup rot dup rot - 0 < if drop else swap drop then ;
: min dup rot dup rot - 0 < if swap drop else drop then ;

: make-offset dup 2 mod + 3 << 32 max ;

var offset
var stackargs
var regargs

\ ( psigspec -- psigspec < regargs, stackargs, and offset calculated and stored> )
: config-bind
    countargs
    dup 4 <
    if
        dup regargs !
        0 stackargs !
    else
        4 regargs !
        dup 4 - stackargs !
    then
    make-offset offset !
;

\ runtime stack argument copier. Reads the number of argument to copy from the next cell
\ ( arg1 [arg2 [arg3 [arg4] ] ] -- < args loaded onto stack > )
: movsargs
    r>                 \ get the return address, which is the address of the next cell
    dup 8 + >r         \ put the skipped return slot back
    @ dup              \ get the number of bytes to shave off the stack (The number of bytes to copy.)
    sp@ - rsp 32 + rot \ set up the stack for cmove
    cmove
    sp@ swap - dp !    \ finish our "pop" operation
;

\ ( argcount -- < XT(movsargs) and the number of arguments to move laid into bound word > )
\ This is a run-time word and so does not affect `bind`'s stack picture.
: bindsargs
    ' movsargs ,
    3 << ,
;

: rettype 8 + c@ ;

\ ( pfunc psigspec - < binding created for for pfunc with the dictionary entry supplied by the user> )
: bind create here 16 - dp ! find docol @ , 0 ,
    config-bind
    ['] movrsp ,
    offset  @ ,

    stackargs @ 0 >
    if
       stackargs @ bindsargs
    then

    regargs @ 0 >
    if
        regargs @ bindrargs
    then

    ['] rt_call ,
    swap ,

    rettype \ consume psigspec (config-bind is a no-op on the stack)
    118 ne
    if
        rettype
        setret
    then

    ['] movrsp ,
    0 offset @ - ,
    ['] exit ,
    0 regargs !
    0 stackargs !
    0 offset !
;