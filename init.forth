latest @ , here 8 - latest ! here word ' 32 + dp !
here word docol find drop @ , 0 ,
here word wbuf find drop ,
here word word find drop ,
here word find find drop ,
here word drop find drop ,
here word exit find drop ,

latest @ , here 8 - latest ! here word create 32 + dp !
' docol @ , 0 ,
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
' here ,
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

: var create 0 , ;
: const create , does> @ ;
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
    dup here swap - swap !
; immediate

\ begin/until/while/repeat

: begin here ; immediate

: until ['] 0branch , here - , ; immediate

: while
    ['] 0branch ,
    here
    0 ,
; immediate

: repeat              \ ( &begin &while_hole )
    ['] branch ,
    swap here - ,
    here over - swap !
; immediate

\ strings

\ >in  index into tib
\ tib  top of input buffer
\ tib| number of bytes read

-1 const true
0 const false

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
        dup 34 = if        \ hit the bare quote
            drop 0 c,      \ null terminator
            dup 1 cells +  \ point at start of string
            here 1 -       \ point to end of string and don't count the trailing null
            swap - swap !  \ write length to start cell
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

: nl 10 emit ;

\ ./.s/u./.r

\ .

var num-str 24 allot \  var reserves 8. 24 allot allows for [length (8 bytes)][chars (23 bytes)][0 (1 byte)]
var rev-ptr

\ ( -- addr <next addr will be `addr 1 -` >)
: pnext-digit rev-ptr dup @ swap dup @ 1 - swap ! ;

\ ( -- addr < of last valid character position > )
: end-digit num-str 30 + ; \ `num-str end-digit` gives a pointer to the last digit

var neg
\ ( val -- val { neg is true if val 0 <, otherwise false} )
: set-neg dup 0< neg ! ;

\ ( -- base_val )
: get-base base @ ;
: >hex 16 base ! ;
: >dec 10 base ! ;
: >oct 8 base ! ;

\ digit-string gives you the address of the string directly
var digit-string
here 1 cells - dp !
i" 0123456789abcdef"
sp@ 1 cells - sp! \ we already know where this lives.

\ fetch the ASCII for the digit, regardless of base (up to 16)
: digit-for digit-string 1 cells + + c@ ;

\ Design: The core algorithm takes an integer and divides by base, stacking the ASCII for the remainder
\         into the number string until the quotient is 0, writes the sign if present, writes the count, and
\         copies the string down into the start slot of the number.
\ ( num -- )
: fill-num
    dup
    end-digit rev-ptr !                       \ ( num -- <rev-ptr now points to the last valid digit slot> )
    rev-ptr @ 1 + 0 swap c!                   \ ( num -- <write 0 beyond last valid digit spot> )
    set-neg                                   \ ( num -- num <neg is set> )

    dup 0 = if
        digit-for pnext-digit c!              \ ( num -- <character for digit stored> )
    else
        begin
            dup 0 <>                          \ ( num -- quotient <while quotient isn't 0...> )
        while                                 \ num is quotient, trivially so before the first division
            get-base /mod swap                \ ( quotient -- quotient remainder )
            neg @ if -1 * then                \ ( quotient remainder -- quotient |remainder| )
            digit-for pnext-digit c!          \ ( quotient remainder -- quotient <ascii for digit written> )
        repeat
        drop                                  \ ( quotient -- <leftover quotient dropped> )
    then

    neg @ if
        pnext-digit dup 45 swap c!            \ ( -- start-ptr <`-` written> )
    else
        rev-ptr @ 1 +                         \ ( -- start-ptr <no `-` written> )
    then
    end-digit swap - 1 + dup num-str !        \ ( start-ptr -- num-chars <num-chars stored in num-str> )
    1 +                                       \ ( num-chars -- str-len)
    \ going for ( src dest count -- )
    dup end-digit 2 + swap - swap             \ ( str-len -- src str-len )
    num-str 1 cells +                         \ ( src str-len -- src str-len dest )
    swap                                      \ ( src str-len dest -- src dest str-len )
    cmove                                     \ ( src dest str-len -- <string representation copied down> )
;

: . fill-num drop num-str nl type ;
: ._ fill-num drop num-str type ;

\ .s
: sp 32 emit ;
: .sp fill-num drop num-str type sp ;

var stackp

: .s sp0 stackp !
    nl
    60 emit
    sp@ sp0 - 3 >> ._
    62 emit
    sp
    sp@
    begin
        dup stackp @ swap <
    while
        stackp @ @ .sp stackp @ 1 cells + stackp !
    repeat
    drop
;

\ files

: cell+ 1 cells + ;
: mode: cell+ const ;
i" rt" mode: m_rt
i" rb" mode: m_rb

\ include

i" \nFile pointer stack overflow.\n" const fpov-msg

: on-space >in @ c@ 32 = ;
: inc-in >in @ 1 + >in ! ;
: skip-space begin on-space while inc-in repeat ;
: not-null >in @ c@ 0 <> ;
: find-null begin not-null while inc-in repeat >in ;

: write-0-char dup 0 swap c! ;
\ ( end-addr -- <trailing CR LF, if present, removed, null-terminated> )
: trim-end
    begin
        dup c@ 0=
    while
        1 -
    repeat
    dup c@ 10 = if write-0-char 1 - then
    dup c@ 13 = if write-0-char 1 - then
    drop
;

: prepare-name skip-space dup find-null trim-end ;

: open-include m_rb fopen ;
: ?fps-full fptos @ fps @ szfps + >= if fpov-msg type abort then ;

: push-handle ?fps-full fptos @ ! fptos @ 1 cells + fptos ! ;
: include prepare-name open-include push-handle ;

