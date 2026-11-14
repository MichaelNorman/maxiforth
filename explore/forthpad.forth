\ h" \nRan forthpad.forth!\n" var excitement excitement ! excitement @ type excitement var-free

\ NOTES:
\ calloc for structs that I pass unless Windows demands otherwise.
\ Virtual* functions only when I need to write executable code or if Windows requires it.

\ static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
\ {
\     switch (msg) {
\     case WM_DESTROY:
\         PostQuitMessage(0);
\         return 0;
\     }
\     return DefWindowProcA(hwnd, msg, wParam, lParam);
\ }
\
\ int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrev, LPSTR cmdLine, int nCmdShow)
\ {
\     (void)hPrev; (void)cmdLine;
\
\     WNDCLASSEXA wc = {0};
\     wc.cbSize        = sizeof wc;
\     wc.lpfnWndProc   = WndProc;
\     wc.hInstance     = hInstance;
\     wc.hCursor       = LoadCursorA(NULL, IDC_ARROW);
\     wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
\     wc.lpszClassName = "BlankWindow";
\
\     if (!RegisterClassExA(&wc))
\         return 1;
\
\     HWND hwnd = CreateWindowExA(
\         0,                      // extended style
\         "BlankWindow",          // class name registered above
\         "Blank",                // title bar text
\         WS_OVERLAPPEDWINDOW,    // standard frame and buttons
\         CW_USEDEFAULT, CW_USEDEFAULT, 640, 480,
\         NULL, NULL, hInstance, NULL);
\     if (!hwnd)
\         return 1;
\
\     ShowWindow(hwnd, nCmdShow);
\
\     MSG msg;
\     while (GetMessageA(&msg, NULL, 0, 0) > 0) {   // returns -1 on error, 0 on WM_QUIT
\         TranslateMessage(&msg);
\         DispatchMessageA(&msg);
\     }
\     return (int)msg.wParam;
\ }
\
\ #define UNICODE is gone. With it defined, IDC_ARROW expands to a wide-string pointer type, which doesn’t match LoadCursorA. ShowWindow and TranslateMessage have no A/W variants.
\
\ WNDCLASSEXA on Win64 has the same 80-byte layout as the W version. The only change is that the two string fields point to null-terminated 8-bit strings instead of UTF-16:
\
\ Offset (dec)	Offset (hex)	Size	Type	Field
\ 0	0x00	4	UINT	cbSize
\ 4	0x04	4	UINT	style
\ 8	0x08	8	WNDPROC	lpfnWndProc
\ 16	0x10	4	int	cbClsExtra
\ 20	0x14	4	int	cbWndExtra
\ 24	0x18	8	HINSTANCE	hInstance
\ 32	0x20	8	HICON	hIcon
\ 40	0x28	8	HCURSOR	hCursor
\ 48	0x30	8	HBRUSH	hbrBackground
\ 56	0x38	8	LPCSTR	lpszMenuName
\ 64	0x40	8	LPCSTR	lpszClassName
\ 72	0x48	8	HICON	hIconSm

var hwnd
var msg
var wparam
var lparam
>hex
: loword ffff and ;
>dec


: hwnd rp 1 cells - @ ;
: msg rp 2 cells - @ ;
: wparam rp 3 cells - @ ;
: lparam rp 4 cells - @ ;
: n-drop cells 1 + sp swap - sp! :
: n-drop-r cells + rp swap - rp! ;

: cb-forthpad
    >r >r >r >r
    msg @ WM_COMMAND = if
        wparam loword IDM_EXIT =
        if
            hwnd destroywnd drop
        then
        0 exit
    then
    msg WM_DESTROY =
    if
        0 postquitmsg
        0 exit
    then

    hwnd msg wparam lparam defwindproc
;

' cb-forthpad cbtramp !