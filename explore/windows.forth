var sigstr
var fstr
var errstr

\ If h_u32 isn't present, find mba.forth and copy the code here, or use lla to get it.

\ Model for calling gpa: h_u32 @ mba @ cstr gpa
    h_u32 @ const cu32

\ ATOM is a 16-bit unsigned value. BOOL is a 32-bit signed int.
\ HMODULE, HWND, HMENU, HINSTANCE, LPCSTR, LPVOID, LPMSG, WPARAM, LPARAM, and LRESULT are all 64 bits wide.

\ Check to ensure our lookup succeeded. If not, simply abort:
    : ?gpa
        dup 0= if
            errstr @ type
            errstr var-free
            sigstr var-free
            pause
            abort
        then
    ;

\ Convenience word for calling gpa
    : u32gpa cu32 fstr @ gpa fstr var-free ;

\ Convenience word for binding with sigstr
    : sigbind sigstr @ bind ;

\ Convenience word for binding.
    : ezbind u32gpa ?gpa sigbind ;

\ Signature string for things that take ints and return 64-bit ints.
    h" q|i" sigstr !

\ GetModuleHandleA	kernel32	HMODULE GetModuleHandleA(LPCSTR lpModuleName);
    h" GetModuleHandleA" fstr !
    h" Could not find GetModuleHandleA. Aborting.\n" errstr !
    ezbind getmodulehandle


\ TranslateMessage	user32	BOOL TranslateMessage(const MSG *lpMsg);
    h" TranslateMessage" fstr !
    h" Could not find TranslateMessage. Aborting.\n" errstr !
    ezbind translatemsg

\ ShowWindow	user32	BOOL ShowWindow(HWND hWnd, int nCmdShow);
    h" ShowWindow" fstr !
    h" Could not find ShowWindow. Aborting.\n" errstr !
    ezbind showwindow
    
\ DispatchMessageA	user32	LRESULT DispatchMessageA(const MSG *lpMsg);
    h" DispatchMessageA" fstr !
    h" Could not find DispatchMessageA. Aborting.\n" errstr !
    ezbind dispatchmsg

    sigstr var-free

\ ---------- custom sigstr items ------------------ \
: frezbind ezbind sigstr var-free ;

\ PostQuitMessage	user32	void PostQuitMessage(int nExitCode);
    h" u|i" sigstr !
    h" PostQuitMessage" fstr !
    h" Could not find PostQuitMessage. Aborting.\n" errstr !
    frezbind postquitmsg

\ DefWindowProcA	user32	LRESULT DefWindowProcA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    h" q|iiii" sigstr !
    h" DefWindowProcA" fstr !
    h" Could not find DefWindowProcA. Aborting.\n" errstr !
    frezbind defwndproc

\ RegisterClassA	user32	ATOM RegisterClassA(const WNDCLASSA *lpWndClass);
    h" u|i" sigstr !
    h" RegisterClassA" fstr !
    h" Could not find RegisterClassA. Aborting.\n" errstr !
    frezbind registerclass

\ GetMessageA	user32	BOOL GetMessageA(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
    h" q|iiii" sigstr !
    h" GetMessageA" fstr !
    h" Could not find GetMessageA. Aborting.\n" errstr !
    frezbind getmsg

\ CreateWindowExA	user32	HWND CreateWindowExA(
\                                   DWORD dwExStyle,
\                                   LPCSTR lpClassName,
\                                   LPCSTR lpWindowName,
\                                   DWORD dwStyle,
\                                   int X,
\                                   int Y,
\                                   int nWidth,
\                                   int nHeight,
\                                   HWND hWndParent,
\                                   HMENU hMenu,
\                                   HINSTANCE hInstance,
\                                   LPVOID lpParam
\                               );
    h" q|iiii8" sigstr !
    h" CreateWindowExA" fstr !
    h" Could not find CreateWindowExA. Aborting.\n" errstr !
    frezbind createwndex
