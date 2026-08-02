i" Double-free detected! Aborting..." const dbl-free-err
: lf 10 emit ;

: var-free
    dup @ dup             \ ( ptr-var -- ptr-var ptr ptr)
    0= if                 \ ( ptr-var -- ptr-var ptr )
        lf dbl-free-err type abort
    then
    free                  \ ( ptr-var ptr -- ptr-var )
    0 swap !              \ ( ptr-var -- <0 stored in ptr-var> )
;

\ Safely get a character from the input, regardless of whether the buffer has run out
: safe-read valid-refill pib c@ 1 >in +! ;

92 const backslash

i" \nUnknown escape sequence encountered. Aborting...\n" const bad-esc-msg

: free-str
    drop \ character on the stack above the pointer
    var-free
;

: safe-read
    begin
        at-end      if true  else
        pib c@ 10 = if true  else
        pib c@ 13 = if true  else
                       false then then then
    while
        refill
    repeat
    \ safe to get a character now
    pib c@ 1 >in !
;

var hstr-ptr
var hstr-start-ptr
var hstr-buff-sz
var hstr-index
32 const hstr-init-size \ starter size for string allocation

: reset-str
    0 hstr-ptr @ <>
    if
        hstr-ptr free
    then
    0 hstr-ptr !
    hstr-init-size hstr-buff-sz !
    0 hstr-start-ptr !
    0 hstr-index !
;

i" Memory allocation failure in heap string. Aborting..." const hstr-mem-alloc-fail

: init-str
    reset-str
    hstr-buff-sz @ malloc hstr-ptr !
    hstr-ptr @ 0 =
    if
        hstr-mem-alloc-fail type reset-str abort
    then
    hstr-ptr @ 1 cells + hstr-start-ptr !
;

: update-str
    hstr-ptr @ 1 cells +
    hstr-start-ptr !
    hstr-buff-sz @ << 1 hstr-buff-sz !
;

: safe-write
    hstr-index @ hstr-buff-sz @ 1 - >=
    if
        hstr-ptr @
        hstr-buff-sz @ << 1
        realloc
        hstr-ptr !
        hstr-ptr @ 0 =
        if
            hstr-mem-alloc-fail type reset-str abort
        then
    then
    update-str
    hstr-start-ptr @ hstr-index @ + c!
    1 hstr-index +!
;

: resolve-escape
    dup  97 = if drop    exit then             \ \a
    dup 110 = if drop 10 safe-write exit then  \ \n
    dup 114 = if drop 13 safe-write exit then  \ \r
    dup 116 = if drop  9 safe-write exit then  \ \t
    dup  34 = if         safe-write exit then  \ \"
    dup  92 = if         safe-write exit then  \ \\
    cleanup-str bad-esc-msg type abort
;

: finish-str
    0 hstr-start-ptr @ hstr-index @ + c!
    hstr-index @ hstr-ptr @ !
    hstr-ptr @
    reset-str
;

: check-quote dup 34 = if true else false then ;

: check-escape dup backslash = if resolve-escape ;

: f"
    init-str
    begin
        safe-read
        check-quote  if finish-string  exit then
        check-escape if resolve-escape      else
                        safe-write          then
    repeat
;