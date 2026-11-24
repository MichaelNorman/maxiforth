\ This file is for custom Forth code that represents the program state that you want at startup,
\ beyond the base language. It's just a Forth file. You can implement your customizations directly
\ in this file, `include` them, or both.

include @MAXIFORTH_ROOT@\init\heap-strings.forth

include @MAXIFORTH_ROOT@\init\dll.forth

include @MAXIFORTH_ROOT@\explore\mba.forth

\ d" We're running the new custom.forth!" 10 emit type

\ include @MAXIFORTH_ROOT@\explore\cbtest.forth
include @MAXIFORTH_ROOT@\windows\windows.forth

\ include @MAXIFORTH_ROOT@\explore\forthpad.forth

