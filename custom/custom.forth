\ This file is for custom Forth code that represents the program state that you want at startup,
\ beyond the base language. It's just a Forth file. You can implement your customizations directly
\ in this file, `include` them, or both.

include @MAXIFORTH_ROOT@\custom\heap-strings.forth
include @MAXIFORTH_ROOT@\explore\dll.forth