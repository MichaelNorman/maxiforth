\ store the format string
var q|4i
h" q|iiii" q|4i !

\ put test function into trampoline
: 4add + + + ;
' 4add cbtramp !

\ bind the callback directly
wndproc q|4i @ bind cbtest

\ clean up memory (sorta)
q|4i var-free

\ run the test with a marker on the stack. ( 500 1 2 3 5 -- 500 10 )
500 1 2 3 4 cbtest drop drop \ .s drop drop

var count-recurse 4 count-recurse !

: 4add-recurse
    4add
    count-recurse @ 0=
    if
        exit
    then
    count-recurse @ 1 - count-recurse !
    1 0 0 cbtest
;

' 4add-recurse cbtramp !

600 1 2 3 4 cbtest drop drop \ .s drop drop

