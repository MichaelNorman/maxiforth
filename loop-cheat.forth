\ ============================================================
\ Counted loops:  do  loop  +loop  leave   ( i / j )
\
\ Design: single leave-head variable, no nested do/loop in one
\ definition. Factor inner loops into their own words.
\ Runtime lives in primitives (see bottom); the words below
\ only stitch threaded code and patch offsets.
\ ============================================================

variable leave-head

\ Walk the leave chain, patching each slot with a self-relative
\ forward offset to here (the cleanup point, just before unloop).
\ Resets leave-head to 0 so the next loop starts with a clean chain.
: resolve-leaves
   leave-head @
   begin dup while            \ slot on stack, nonzero
      dup @                   \ read next link before clobbering
      swap here over - swap ! \ store (here - slot) into slot
   repeat
   drop
   0 leave-head ! ;

\ Compile the runtime frame-push, leave &do for the back-branch.
: do
   ['] swap , ['] >r , ['] >r ,
   here ; immediate

\ Step by one.
: loop
   ['] (loop) ,
   ['] 0branch , here - ,     \ back-branch to &do while flag = 0
   resolve-leaves             \ leaves land here
   ['] unloop , ; immediate

\ Step by a value taken from the data stack at runtime.
: +loop
   ['] (+loop) ,
   ['] 0branch , here - ,
   resolve-leaves
   ['] unloop , ; immediate

\ Early exit: compile a forward branch, thread its offset cell
\ onto the leave chain. resolve-leaves patches it later.
: leave
   ['] branch ,
   here leave-head @ , leave-head ! ; immediate


\ ============================================================
\ Remaining primitives to hand-write in assembly.
\ Return-stack layout inside a running loop:
\   [RTOS - CELL_SIZE]    = index
\   [RTOS - 2*CELL_SIZE]  = limit
\
\ (loop)   ( -- flag )
\   Add 1 to index in place. Push crossing flag: nonzero when the
\   signed index+step crosses the limit boundary, else 0.
\   (Or: hardwire step 1 and share (+loop)'s body.)
\
\ (+loop)  ( step -- flag )
\   Pop step from data stack, add to index in place. Same signed
\   crossing test as (loop):  (i-limit) xor (i-limit+step), sign
\   bit set => crossed => flag nonzero.
\   On no-cross: 0branch takes the back-branch to &do.
\   On cross:    fall through; next word is unloop.
\
\ unloop   ( -- )   ( R: limit index -- )
\   Drop the two loop-control cells from the return stack.
\   Runtime destination shared by normal exit and every leave.
\
\ Must be primitives: they read/drop the return-stack control
\ cells by fixed offset. A colon word can't — its own return
\ frame would sit on top of index/limit and throw every offset
\ off by a cell. Same reason i/j are primitives.
\ ============================================================

\ i   ( -- index )   push [RTOS - CELL_SIZE]
\ j   ( -- index )   push [RTOS - 3*CELL_SIZE]  (outer loop, one
\                    frame deeper: limit/index pair of the outer do)