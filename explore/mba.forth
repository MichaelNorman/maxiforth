var u32
var h_u32
var mba
var ptr_mba
var mba_sigstr
var mba_caption
var mba_message

h" user32.dll" u32 !

\ Get the handle for user32.dll, but remember that the outside world wants C strings
u32 @ cstr lla

\ Store the handle to user32.dll
h_u32 !

\ The first word we're going to bind
h" MessageBoxA" mba !

\ Again, remembering that the outside world wants C strings, get the process address for MessageBoxA from user32.dll
h_u32 @ mba @ cstr gpa

\ Test for it in production code, but this works!
ptr_mba !

h" d|iiii" mba_sigstr !

ptr_mba @ mba_sigstr @ cstr bind MBOX

h" Forth message" mba_caption !
h" Hello, Windows!" mba_messaage !

0 mba_message @ cstr mba_caption @ cstr 0 MBOX

