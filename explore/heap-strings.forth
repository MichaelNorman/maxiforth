i" Double-free detected! Aborting..." const dbl-free-err
: cr 10 emit ;

: var-free
    dup @ dup             \ ( ptr-var -- ptr-var ptr ptr)
    0= if                 \ ( ptr-var -- ptr-var ptr )
        cr dbl-free-err type abort
    then
    free                  \ ( ptr-var ptr -- ptr-var )
    0 swap !              \ ( ptr-var -- <0 stored in ptr-var> )
;

var test-var
\ var creates a thing that puts the address of the cell after it on the stack
\ calloc returns an address that's been assigned to the requested memory size.

14 1 calloc test-var !
test-var var-free

\ Design: Heap strings will be allocated on the heap, support a limited set of escape sequences.

\ Safely get a character from the input, regardless of whether the buffer has run out
: safe-read valid-refill pib c@ 1 >in +! ;

92 const backslash

i" \nUnknown escape sequence encountered. Aborting...\n" const bad-esc-msg

: free-str
    drop \ character on the stack above the pointer
    var-free
;

: safe-read
    \ check if we're at the end or we've encountered a newline character
    \ if so, refill
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

var hstr-buff-sz
var hstr-ptr
var hstr-start-ptr
var hstr-index

i" Memory allocation failure in heap string." const hstr-mem-alloc-fail

: safe-write
    hstr-index @ 0 =
    if
        hstr-mem-alloc-fail type abort
    then

    hstr-index @ hstr-buff-sz @ >=
    if
        hstr-ptr @ realloc
        0 =
        if

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

: check-quote dup 34 = if true else false then ;

: check-escape dup backslash = if resolve-escape ;

: f"
    h-str-ptr !
    h-str-buff-sz !
    h-str-ptr @ 1 cells + h-str-start-ptr !

    swap

    begin
        safe-read
        check-quote  if finish-string  exit then

        check-escape if resolve-escape      else
                        safe-write          then
    repeat
;