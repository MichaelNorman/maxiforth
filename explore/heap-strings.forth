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

\ `escaping` defaults to zero. This is a state variable that gets turned on when `\` is encountered. Backspace
\ clears it if the user has pressed ENTER immediately after typing `\`.
var escaping
\ Safely get a character from the input, regardless of whether the buffer has run out
: safe-read ;

: resolve-escape
    dup 110 = if drop 10 exit then
    dup 114 = if drop 13 exit then
    dup 116 = if drop 9 exit then
    dup  34 = if exit then
    dup  92 = if exit then
    0 escaping !
;

\ Safely write a character to the string, calling realloc if necessary
: safe-write ;

: handle-buffer-start escaping @ invert if exit then safe-read dup 8 = if 0 escaping ! else safe-write then ;
