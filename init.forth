latest @ , here 8 - latest ! here word ' 32 + dp !
here word docol find drop @ , 0 ,
here word wbuf find drop ,
here word word find drop ,
here word find find drop ,
here word drop find drop ,
here word exit find drop ,

latest @ , here 8 - latest ! here word create 32 + dp ! ' docol @ , 0 ,
' latest ,
' @ ,
' , ,
' dp ,
' @ ,
' lit ,
8 ,
' - ,
' latest ,
' ! ,
' dp ,
' @ ,
' word ,
' lit ,
32 ,
' + ,
' dp ,
' ! ,
' lit ,
' dovar ,
' @ ,
' , ,
' lit ,
0 ,
' , ,
' exit ,

create smudge here 16 - dp ! ' docol @ , 0 ,
' latest ,
' @ ,
' lit ,
8 ,
' + ,
' dup ,
' @ ,
' lit ,
64 ,
' or ,
' swap ,
' ! ,
' exit ,

create unsmudge here 16 - dp ! ' docol @ , 0 ,
' latest ,
' @ ,
' lit ,
8 ,
' + ,
' dup ,
' @ ,
' lit ,
64 ,
' invert ,
' and ,
' swap ,
' ! ,
' exit ,

create : here 16 - dp ! ' docol @ , 0 ,
' create ,
' smudge ,
' dp ,
' @ ,
' lit ,
16 ,
' - ,
' dp ,
' ! ,
' lit ,
' docol ,
' @ ,
' , ,
' dp ,
' @ ,
' lit ,
8 ,
' + ,
' dp ,
' ! ,
' lit ,
1 ,
' state ,
' ! ,
' exit ,

create immediate here 16 - dp ! ' docol @ , 0 ,
' latest ,
' @ ,
' lit ,
8 ,
' + ,
' dup ,
' c@ ,
' lit ,
32 ,
' or ,
' swap ,
' c! ,
' exit ,

create ; here 16 - dp ! ' docol @ , 0 ,
' lit ,
0 ,
' state ,
' ! ,
' lit ,
' exit ,
' , ,
' unsmudge ,
' exit ,
immediate

: \ tib tib| + >in ! ; immediate
\ Now we can comment!

: [ 0 state ! ; immediate
: ] 1 state ! ; immediate

create 'lit ' lit , \ put lit into the dictionary
: literal 'lit @ , , ; immediate  \ bakes in [xt_lit][tos]
: ['] ' 'lit @ , , ; immediate \ bake a word literal in: [xt_lit][xt_ticked_word]

: (does>)  latest @ 40 + dup ['] dodoes @ swap ! 8 + r> swap ! ;
: does> ['] (does>) , ; immediate

: variable create 0 , ;
: constant create , does> @ ;
: allot here + dp ! ;

: cells 8 * ;
: cell 8 ;

\ if/else/then
: if ['] 0branch , here 0 , ; immediate

: -rot rot rot ;

: else \ H_if is on the stack
    dup \ -> H_if H_if
    ['] branch ,
    here -rot \ -> H_hole_else H_if H_if
    0 ,
    here \ -> H_hole_else H_if H_if H_else_code
    swap - swap ! \ H_hole_else < delta stored in H_if >
; immediate

: then \ H_hole_else is on the stack
    dup here swap - swap ! ; immediate

\ begin/until/while/repeat

: begin here ; immediate

: until ['] 0branch , here - , ; immediate

: while
    ['] 0branch ,
    here
    0 , ; immediate

: repeat              \ ( &begin &while_hole )
    ['] branch ,
    swap here - ,
    here over - swap ! ; immediate

\ strings

\ >in  index into tib
\ tib  top of input buffer
\ tib| number of bytes read

-1 constant true
0 constant false

: pib tib >in @ + ;
: ib-end tib tib| + 1 - ; \ pointer to end of buffer
: at-end pib ib-end >= ;

: valid-refill begin at-end while refill repeat ; \ skip empty lines from input

: next-rchar
    valid-refill \ Either we were okay to start with or we are at the start of a new buffer
    pib c@  1 >in +!
;

: resolve-char
    next-rchar
    dup 110 = if drop 10 exit then
    dup 116 = if drop 9  exit then
    dup 34  = if exit then
    dup 92  = if exit then
;

: i" \ runtime string, as opposed to a compile-time string
    here dup 0 ,
    begin next-rchar dup 32 = while drop repeat \ skip leading spaces
    begin
        dup 34 = if \ hit the bare quote
            drop 0 c, \ null terminator
            dup 1 cells + here swap - swap ! \ write length to start cell
            false
        else
            true
        then
    while
        dup 92 = if drop resolve-char then \ ensures room for escapee
        c,
        next-rchar
    repeat
;

\ ./.s/u./.r
\ .
\ Design: The core algorithm takes an integer and divides by base, stacking the ASCII for the remainder
\         into a reversed buffer, ensuring that each value is positive before converting.


\ files, include

\ heap

\ C interop

\ other words
: allot dp +! ;