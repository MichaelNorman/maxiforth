
i" Double-free detected! Aborting..." const dbl-free-err
: cr 10 emit ;

: pvar-free
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
test-var pvar-free

