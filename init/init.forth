latest @ , here 8 - latest ! here word ' 32 + dp !
here word docol find drop @ , 0 ,
here word wbuf find drop ,
here word word find drop ,
here word find find drop ,
here word 0branch find drop ,
16 ,
here word exit find drop ,
here word drop find drop ,
here word lit find drop ,
0 ,
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
' dovar @ ,
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
' c@ ,
' lit ,
64 ,
' or ,
' swap ,
' c! ,
' exit ,

create unsmudge here 16 - dp ! ' docol @ , 0 ,
' latest ,
' @ ,
' lit ,
8 ,
' + ,
' dup ,
' c@ ,
' lit ,
64 ,
' invert ,
' and ,
' swap ,
' c! ,
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
' lit ,
0 ,
' , ,
' lit ,
1 ,
' state ,
' ! ,
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

: \ tib mib + >in ! ; immediate
\ Now we can comment!

: [ 0 state ! ; immediate
: ] 1 state ! ; immediate

\ put lit into the dictionary [ prev*(8) ][ mask(0.3) ][ length(0.5) ][ &dovar(8) ][ 0(8) ][ XT(lit) ]
create 'lit
' lit ,

\ bake in [xt_lit][tos]
: literal 'lit @ , , ; immediate

\ bake in next input word at definition time of compiled word: [xt_lit][xt_parsed]
: [']
    'lit @ ,  \ comma in the code address of 'lit
    ' ,       \ comma in xt of next word from input
; immediate

\ if/else/then
: if ['] 0branch , here 0 , ; immediate
\ equivalent to: `: if [ ' 0branch ] literal , here 0 , ; immediate`

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

\ variables and constants
: (does>)  latest @ 40 + dup ['] dodoes @ swap ! 8 + r> swap ! ;
: does> ['] (does>) , ; immediate
: var create 0 , ;
: const create , does> @ ;

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

\ switch/case/break/end-switch
var break-chain
var fall-chain

\ Writes offset to here into hole_addr
: resolve \ ( hole_addr -- )
    here  \ ( hole_addr -- hole_addr here )
    over  \ ( hole_addr here -- hole_addr here hole_addr )
    -     \ ( hole_addr here hole_addr -- hole_addr offset )
    swap  \ ( hole_addr offset -- offset hole_addr )
    !     \ ( offset hole_addr -- <offset written to hole> )
;

: resolve-chain \ ( head -- )
     begin
        dup     \ ( head -- head head )
    while
        dup @   \ ( head -- head previous )
        swap    \ ( head previous -- previous head )
        resolve \ ( previous head -- previous < offset written into hole> )
    repeat
    drop        \ ( previous{0} -- <exited cleanly> )
;

\ Writes previous thread node into dictionary. Stores current location in brkorfll
: thread \ ( brkorfll -- )
    here        \ ( brkorfll -- brkorfll here )
    over        \ ( brkorfll here -- brkorfll here brkorfll )
    @           \ ( brkorfll here brkorfll -- brkorfll here [previous brkorfll] )
    ,           \ ( brkorfll here [previous brkorfll] -- brkorfll here < previous brkorfll put into dictionary> )
    swap        \ ( brkorfll here -- here brkorfll )
    !           \ ( here brkorfll -- <here stored in brkorfll> )
;

: switch \ ( -- old-break old-fall )
    break-chain @ fall-chain @       \ ( -- break fall )
    0 break-chain !  0 fall-chain !  \ ( break fall -- <break-chain and fall-chain zeroed> )
; immediate

: case \ ( -- fail-hole )
    ['] over ,      \ compile xt(over)   into the word definition in which `case` appears
    ['] = ,         \ compile xt(=)       "    "   ...
    ['] 0branch ,   \ compile xt(0branch) " ...
    here            \ record here
    0 ,             \ compile hole (at the `here` location just recorded)
    ['] drop ,      \ compile xt(drop)  into the word def....
    fall-chain @    \ store hole location in fall-chain
    resolve-chain   \ resolve the fall chain
    0 fall-chain !  \ zero out fall-chain
; immediate

: break \ ( fail-hole -- )
    ['] branch ,        \ Compile xt(branch) into the word definition in which `break` appears.
                        \ This is what gets assigned to the current break-chain variable inside thread.
    break-chain thread  \ thread this entry into the break chain
    resolve             \ write offset to here into fail-hole
; immediate

: fall \ ( fail-hole -- )
    ['] branch ,        \ Compile xt(branch) into the word definition in which `fall` appears.
    fall-chain thread   \ This is what gets assigned to the current fall-chain variable inside thread.
    resolve             \ thread this entry into the fall chain
; immediate             \ write offset to here into fail-hole


: end-switch \ ( old-break old-fall -- )
    ['] drop ,                      \ drop the test value from the stack
    break-chain @ resolve-chain     \ resolve the last break chain
    fall-chain @ resolve-chain      \ resolve the last fall chain
    fall-chain !  break-chain !     \ left on the stack by `switch` for nesting
; immediate

\ strings

: allot here + dp ! ;

: cell 8 ;
: cells cell * ; \ readable way to talk about memory cells, such as: my_ptr 5 cells +


\ >in  index into tib
\ tib  top of input buffer
\ mib number of bytes read

-1 const true
0 const false

: pib tib >in @ + ;
: ib-end tib mib + 1 - ; \ pointer to end of buffer
: at-end pib ib-end >= ;

: valid-refill
    begin
        at-end
    while \ skip empty lines from input
        refill
        drop
    repeat
;

: next-rchar
    valid-refill \ Either we were okay to start with or we are at the start of a new buffer
    pib c@  1 >in +!
;

: resolve-char
    next-rchar
    dup 110 = if drop 10 exit then
    dup 114 = if drop 13 exit then
    dup 116 = if drop  9 exit then
    dup 34  = if         exit then
    dup 92  = if         exit then
;

\ dictionary string, as opposed to a heap string.
: d"
    here dup 0 ,                                \ skip length word to first character byte and
                                                \ leave a copy of the start address
    begin next-rchar dup 32 = while drop repeat \ skip leading spaces
    begin
        dup 34 =
        if                 \ hit the bare quote
            drop           \ drop `"`
            0 c,           \ null terminator
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

\ get the offset from a Forth string to the start of the embedded C string
: cstr 8 + ;

: nl 10 emit ;

\ ./.s/u./.r

\ fill-num, .

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
: >hex 16 base ! ; immediate
: >dec 10 base ! ; immediate
: >oct 8 base ! ;  immediate

\ digit-string gives you the address of the string directly
var digit-string
here 1 cells - dp !
 d" 0123456789abcdef"
drop \ we already know where this lives.

\ fetch the ASCII for the digit, regardless of base (up to 16)
: digit-for digit-string 1 cells + + c@ ;

\ Design: The core algorithm takes an integer and divides by base, stacking the ASCII for the remainder
\         into the number string until the quotient is 0, writes the sign if present, writes the count, and
\         copies the string down into the start slot of the number.
\ ( num -- )

: prep-buffer dup end-digit rev-ptr ! rev-ptr @ 1 + 0 swap c! set-neg ;

: acc-digits
    dup 0 =
    if
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
;

: handle-sign
    neg @
    if
        pnext-digit dup 45 swap c!            \ ( -- start-ptr <`-` written> )
    else
        rev-ptr @ 1 +                         \ ( -- start-ptr <no `-` written> )
    then
;

: write-len end-digit swap - 1 + dup num-str ! ;      \ ( start-ptr -- num-chars <num-chars stored in num-str> )

: copy-down
    dup end-digit 2 + swap - swap             \ ( str-len -- src str-len )
    num-str 1 cells +                         \ ( src str-len -- src str-len dest )
    swap                                      \ ( src str-len dest -- src dest str-len )
    cmove                                     \ ( src dest str-len -- <string representation copied down> )
;

: fill-num prep-buffer acc-digits handle-sign write-len 1 + copy-down ;

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

\ mode strings are passed to C, so skip the count word
: cell+ 1 cells + ;
: mode: cell+ const ;
 d" rt" mode: m_rt
 d" rb" mode: m_rb

\ include

 d" \nFile pointer stack overflow.\n" const fpov-msg

: on-space pib c@ 32 = ;
: inc-in 1 >in +! ;
: skip-space begin on-space while inc-in repeat ;
: dpib tib >in @ + ; \ debug pib
: not-null dpib c@ 0 <> ;
: find-null begin not-null while inc-in repeat pib ;

: write-0-char dup 0 swap c! ;
\ ( end-addr -- <trailing CR LF, if present, removed, null-terminated> )

: find-end
    begin
        dup c@
        0=
    while
       1 -
    repeat
;

: trim-end
    find-end
    dup c@ 10 = if write-0-char 1 - then
    dup c@ 13 = if write-0-char 1 - then
    drop
;

: prepare-name skip-space pib find-null trim-end ;

: open-include m_rb fopen ;

: ?fps-full fptos @ fps szfps + >= if fpov-msg type abort then ;
: push-handle ?fps-full fptos @ ! 1 cells fptos +! ;

: include prepare-name open-include push-handle ;

: lf 10 emit ;
 d" Double-free detected! Aborting..." const dbl-free-err
: var-free
    dup @ dup             \ ( ptr-var -- ptr-var ptr ptr)
    0=
    if                    \ ( ptr-var -- ptr-var ptr )
        lf dbl-free-err type abort
    then
    \ [ ' pause , ]
    free                  \ ( ptr-var ptr -- ptr-var )
    0 swap !              \ ( ptr-var -- <0 stored in ptr-var> )
;

\ List out the words in the dictionary.
var current-word
var done-last
create words-buffer 40 allot

: >wordlen c@ 96 invert and ; \ IMMEDIATE | SMUDGE = 96
\ ( -- <dictword is converted and stored in pbuffer> )
: fill-ws-buffer
    words-buffer current-word @
    9 + swap cell + 31 cmove
    0 words-buffer 39 + c!
    current-word @ cell + >wordlen words-buffer !
;

: words
    \ Walk through the dictionary until we hit the null pointer, converting words into Forth strings (with a space after
    \ each) and typing them.

    latest @ current-word !
    false done-last !
    lf \ A nice visual break.
    begin
        done-last @ false =
    while
        current-word @ cell + c@
        64 and 0=
        if
            fill-ws-buffer
            words-buffer type
            sp
        then

        current-word @ @

        dup 0=
        if
            true done-last ! drop
        else
            current-word !
        then
    repeat
;

\ Give the programmer a chance by showing the base in base 10:
: show-base
    10 emit
    get-base 8 =
    if
        56 emit exit
    then
    get-base 10 =
    if
        49 emit 48 emit exit
    then
    49 emit 54 emit
;

\ switch test. Comment out if you want.
d" \nOne!" const one-str
d" \nTwo or three!" const two-three-str
d" \nThree is the biggest number." const argue-str
: announce
    switch
        1 case
            one-str type
            break
        2 case
            fall
        3 case
            two-three-str type
          \ ^ fall goes here
            break
        argue-str type
    end-switch
    \ all breaks go here
;

d" We're running the new init.forth!" 10 emit type

\ This is the hook into additional user-specified bootup code.
include @MAXIFORTH_ROOT@\init\custom.forth


