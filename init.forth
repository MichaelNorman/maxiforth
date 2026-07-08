latest @ , here @ 8 - latest ! here @ word ' 32 + here !
here @ word docol find drop @ , 0 ,
here @ word wbuf find drop ,
here @ word word find drop ,
here @ word find find drop ,
here @ word drop find drop ,
here @ word exit find drop ,

latest @ , here @ 8 - latest ! here @ word create 32 + here ! ' docol @ , 0 ,
' latest ,
' @ ,
' , ,
' here ,
' @ ,
' lit ,
8 ,
' - ,
' latest ,
' ! ,
' here ,
' @ ,
' word ,
' lit ,
32 ,
' + ,
' here ,
' ! ,
' lit ,
' dovar ,
' @ ,
' , ,
' lit ,
0 ,
' , ,
' exit ,

create smudge here @ 16 - here ! ' docol @ , 0 ,
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

create unsmudge here @ 16 - here ! ' docol @ , 0 ,
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

create : here @ 16 - here ! ' docol @ , 0 ,
' create ,
' smudge ,
' here ,
' @ ,
' lit ,
16 ,
' - ,
' here ,
' ! ,
' lit ,
' docol ,
' @ ,
' , ,
' here ,
' @ ,
' lit ,
8 ,
' + ,
' here ,
' ! ,
' lit ,
1 ,
' state ,
' ! ,
' exit ,

create immediate here @ 16 - here ! ' docol @ , 0 ,
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

create ; here @ 16 - here ! ' docol @ , 0 ,
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
: allot here @ + here ! ;

: cells 8 * ;
: cell 8 ;

\ if/else/then
: if ['] 0branch , here @ 0 , ; immediate

: -rot rot rot ;

: else \ H_if is on the stack
    dup \ -> H_if H_if
    ['] branch ,
    here @ -rot \ -> H_hole_else H_if H_if
    0 ,
    here @ \ -> H_hole_else H_if H_if H_else_code
    swap - swap ! \ H_hole_else < delta stored in H_if >
    ; immediate

: then \ H_hole_else is on the stack
    dup here @ swap - swap ! ; immediate

\ begin/until/while/repeat

: begin here @ ; immediate

: until ['] 0branch , here @ - , ; immediate

: while
    ['] 0branch ,
    here @
    0 , ; immediate

: repeat              \ ( &begin &while_hole )
    ['] branch ,
    swap here @ - ,
    here @ over - swap ! ; immediate


\ do/loop/+loop/leave/i/j

\ do
\ limit index do .... loop/+loop
: do swap  >r >r here @; immediate

\ +loop (&do step)
\ d_old = index - limit        : i rp@ cell 2 * - @ -
\ d_new = index - limit + step : i + rp@ cell 2 * - @ -
\ xor(d_old, d_new)            : xor
\ result < 0                   : 0<

: limit rp@ cell 2 * - @ ;
: iaddr rp@ cell - ;
: +loop                  \ ( &do step )
    dup                  \ ( &do step -- &do step step )
    limit i swap -       \ ( &do step step -- &do step step signed_delta1)
    dup rot +            \ ( &do step step -- &do step signed_delta1 signed_delta 2)
    xor                  \ ( &do step signed_delta1 signed_delta 2 -- &do step pos_or_neg )
    0<                   \ ( &do step pos_or_neg -- &do step <jmp &do or continue> )
    swap here @ swap -   \ ( &do step -- step do_offset )
    ['] 0branch ,        \ ( -- )
    ,                    \ ( step do_offset -- step <do_offset compiled> )
    i + iaddr ! ;        \ ( step -- <i incremented> )
    immediate

\ loop
: loop 1 +loop ;

\ leave


\ ./.s/u./.r

\ strings

\ files, include

\ heap

\ C interop