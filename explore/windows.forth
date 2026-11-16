var sigstr
var fstr
var errstr
var hlib
d" Could not find " const nf-msg

\ If h_u32 isn't present, find mba.forth and copy the code here, or use lla to get it.

\ Model for calling gpa: h_u32 @ mba @ cstr gpa
    h_u32 @ const cu32

\ ATOM is a 16-bit unsigned value. BOOL is a 32-bit signed int.
\ HMODULE, HWND, HMENU, HINSTANCE, LPCSTR, LPVOID, LPMSG, WPARAM, LPARAM, and LRESULT are all 64 bits wide.


\ Convenience word for binding with sigstr
    : sigbind sigstr @ bind ;

\ ( p -- p ) abort, naming fstr, if the lookup returned null
    : ?found dup 0= if nf-msg type fstr @ type lf abort then ;

\ ( -- ) fstr holds a DLL name. lla returns the existing handle if the DLL is already loaded.
    : uselib fstr @ cstr lla ?found hlib ! fstr var-free ;

\ ( -- <name> ) bind fstr's function from hlib using sigstr\ frees both strings
    : frezbind hlib @ fstr @ cstr gpa ?found fstr var-free sigbind sigstr var-free ;


\ GetModuleHandleA	kernel32	HMODULE GetModuleHandleA(LPCSTR lpModuleName);
\ use `gmha`


\ ================================ user32.dll ================================ \
    h" user32.dll" fstr !  uselib

\ CreateWindowExA	user32	HWND CreateWindowExA(DWORD dwExStyle, LPCSTR lpClassName, LPCSTR lpWindowName, DWORD dwStyle, int X, int Y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam);
    h" q|iiii8" sigstr !  h" CreateWindowExA" fstr !  frezbind createwndex

\ RegisterClassA	user32	ATOM RegisterClassA(const WNDCLASSA *lpWndClass);
\ ATOM is 16 bits\ `2` zero-extends ax.
    h" 2|i" sigstr !  h" RegisterClassA" fstr !  frezbind registerclass

\ GetMessageA	user32	BOOL GetMessageA(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
\ Signed: returns -1 on error.
    h" d|iiii" sigstr !  h" GetMessageA" fstr !  frezbind getmsg

\ TranslateMessage	user32	BOOL TranslateMessage(const MSG *lpMsg);
    h" d|i" sigstr !  h" TranslateMessage" fstr !  frezbind translatemsg

\ DispatchMessageA	user32	LRESULT DispatchMessageA(const MSG *lpMsg);
    h" q|i" sigstr !  h" DispatchMessageA" fstr !  frezbind dispatchmsg

\ PostQuitMessage	user32	void PostQuitMessage(int nExitCode);
    h" v|i" sigstr !  h" PostQuitMessage" fstr !  frezbind postquitmsg

\ DefWindowProcA	user32	LRESULT DefWindowProcA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    h" q|iiii" sigstr !  h" DefWindowProcA" fstr !  frezbind defwndproc

\ SetWindowPos	user32	BOOL SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
    h" d|iiii3" sigstr !  h" SetWindowPos" fstr !  frezbind setwndpos

\ SetWindowTextA	user32	BOOL SetWindowTextA(HWND hWnd, LPCSTR lpString);
    h" d|ii" sigstr !  h" SetWindowTextA" fstr !  frezbind setwndtext

\ GetSystemMenu	user32	HMENU GetSystemMenu(HWND hWnd, BOOL bRevert);
    h" q|ii" sigstr !  h" GetSystemMenu" fstr !  frezbind getsysmenu

\ AppendMenuA	user32	BOOL AppendMenuA(HMENU hMenu, UINT uFlags, UINT_PTR uIDNewItem, LPCSTR lpNewItem);
    h" d|iiii" sigstr !  h" AppendMenuA" fstr !  frezbind appendmenu

\ CreateMenu	user32	HMENU CreateMenu(void);
    h" q|" sigstr !  h" CreateMenu" fstr !  frezbind createmenu

\ CreatePopupMenu	user32	HMENU CreatePopupMenu(void);
    h" q|" sigstr !  h" CreatePopupMenu" fstr !  frezbind createpopupmenu

\ SetMenu	user32	BOOL SetMenu(HWND hWnd, HMENU hMenu);
    h" d|ii" sigstr !  h" SetMenu" fstr !  frezbind setmenu

\ DestroyWindow	user32	BOOL DestroyWindow(HWND hWnd);
    h" d|i" sigstr !  h" DestroyWindow" fstr !  frezbind destroywnd

\ MessageBoxA	user32	int MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, UINT uType);
    h" d|iiii" sigstr !  h" MessageBoxA" fstr !  frezbind msgbox

\ TrackPopupMenu	user32	BOOL TrackPopupMenu(HMENU hMenu, UINT uFlags, int x, int y, int nReserved, HWND hWnd, const RECT *prcRect);
    h" d|iiii3" sigstr !  h" TrackPopupMenu" fstr !  frezbind trackpopupmenu

\ DestroyMenu	user32	BOOL DestroyMenu(HMENU hMenu);
    h" d|i" sigstr !  h" DestroyMenu" fstr !  frezbind destroymenu

\ GetMessagePos	user32	DWORD GetMessagePos(void);
\ x in the low word, y in the high word, each a signed 16-bit value.
    h" u|" sigstr !  h" GetMessagePos" fstr !  frezbind getmsgpos

\ GetKeyState	user32	SHORT GetKeyState(int nVirtKey);
\ `2` zero-extends ax\ the key is down when bit 15 is set.
    h" 2|i" sigstr !  h" GetKeyState" fstr !  frezbind getkeystate

\ SendMessageA	user32	LRESULT SendMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
    h" q|iiii" sigstr !  h" SendMessageA" fstr !  frezbind sendmsg

\ RegisterWindowMessageA	user32	UINT RegisterWindowMessageA(LPCSTR lpString);
    h" u|i" sigstr !  h" RegisterWindowMessageA" fstr !  frezbind registerwndmsg

\ IsDialogMessageA	user32	BOOL IsDialogMessageA(HWND hDlg, LPMSG lpMsg);
    h" d|ii" sigstr !  h" IsDialogMessageA" fstr !  frezbind isdialogmsg

\ ShowWindow	user32	BOOL ShowWindow(HWND hWnd, int nCmdShow);
    h" d|ii" sigstr !  h" ShowWindow" fstr !  frezbind showwindow

\ GetClientRect	user32	BOOL GetClientRect(HWND hWnd, LPRECT lpRect);
    h" d|ii" sigstr !  h" GetClientRect" fstr !  frezbind getclientrect

\ wsprintfA	user32	int wsprintfA(LPSTR unnamedParam1, LPCSTR unnamedParam2, ...);
\ Variadic, bound at fixed arity 4: ( buf fmt n1 n2 -- len ), enough for "Ln %d, Col %d".
\ wsprintfA has no float conversions, so the Win64 varargs rule (floats mirrored into
\ integer registers) never applies\ an all-integer fixed-arity call is the same call.
    h" d|iiii" sigstr !  h" wsprintfA" fstr !  frezbind wsprintf4

\ DialogBoxIndirectParamA	user32	INT_PTR DialogBoxIndirectParamA(HINSTANCE hInstance, LPCDLGTEMPLATEA hDialogTemplate, HWND hWndParent, DLGPROC lpDialogFunc, LPARAM dwInitParam);
    h" q|iiii1" sigstr !  h" DialogBoxIndirectParamA" fstr !  frezbind dialogboxindirectparam

\ GetDlgItemInt	user32	UINT GetDlgItemInt(HWND hDlg, int nIDDlgItem, BOOL *lpTranslated, BOOL bSigned);
    h" u|iiii" sigstr !  h" GetDlgItemInt" fstr !  frezbind getdlgitemint

\ EndDialog	user32	BOOL EndDialog(HWND hDlg, INT_PTR nResult);
    h" d|ii" sigstr !  h" EndDialog" fstr !  frezbind enddialog

\ SetFocus	user32	HWND SetFocus(HWND hWnd);
    h" q|i" sigstr !  h" SetFocus" fstr !  frezbind setfocus


\ =============================== kernel32.dll =============================== \
    h" kernel32.dll" fstr !  uselib

\ GetModuleHandleA	kernel32	HMODULE GetModuleHandleA(LPCSTR lpModuleName);
    h" q|i" sigstr !  h" GetModuleHandleA" fstr !  frezbind getmodulehandle

\ LoadLibraryA	kernel32	HMODULE LoadLibraryA(LPCSTR lpLibFileName);
    h" q|i" sigstr !  h" LoadLibraryA" fstr !  frezbind loadlibrary

\ GetCommandLineA	kernel32	LPSTR GetCommandLineA(void);
    h" q|" sigstr !  h" GetCommandLineA" fstr !  frezbind getcommandline

\ CreateFileA	kernel32	HANDLE CreateFileA(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
    h" q|iiii3" sigstr !  h" CreateFileA" fstr !  frezbind createfile

\ GetFileSize	kernel32	DWORD GetFileSize(HANDLE hFile, LPDWORD lpFileSizeHigh);
    h" u|ii" sigstr !  h" GetFileSize" fstr !  frezbind getfilesize

\ GlobalAlloc	kernel32	HGLOBAL GlobalAlloc(UINT uFlags, SIZE_T dwBytes);
    h" q|ii" sigstr !  h" GlobalAlloc" fstr !  frezbind globalalloc

\ GlobalFree	kernel32	HGLOBAL GlobalFree(HGLOBAL hMem);
    h" q|i" sigstr !  h" GlobalFree" fstr !  frezbind globalfree

\ ReadFile	kernel32	BOOL ReadFile(HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped);
    h" d|iiii1" sigstr !  h" ReadFile" fstr !  frezbind readfile

\ WriteFile	kernel32	BOOL WriteFile(HANDLE hFile, LPCVOID lpBuffer, DWORD nNumberOfBytesToWrite, LPDWORD lpNumberOfBytesWritten, LPOVERLAPPED lpOverlapped);
    h" d|iiii1" sigstr !  h" WriteFile" fstr !  frezbind writefile

\ CloseHandle	kernel32	BOOL CloseHandle(HANDLE hObject);
    h" d|i" sigstr !  h" CloseHandle" fstr !  frezbind closehandle

\ GetLocalTime	kernel32	void GetLocalTime(LPSYSTEMTIME lpSystemTime);
    h" v|i" sigstr !  h" GetLocalTime" fstr !  frezbind getlocaltime

\ GetDateFormatA	kernel32	int GetDateFormatA(LCID Locale, DWORD dwFlags, const SYSTEMTIME *lpDate, LPCSTR lpFormat, LPSTR lpDateStr, int cchDate);
    h" d|iiii2" sigstr !  h" GetDateFormatA" fstr !  frezbind getdateformat

\ GetTimeFormatA	kernel32	int GetTimeFormatA(LCID Locale, DWORD dwFlags, const SYSTEMTIME *lpTime, LPCSTR lpFormat, LPSTR lpTimeStr, int cchTime);
    h" d|iiii2" sigstr !  h" GetTimeFormatA" fstr !  frezbind gettimeformat

\ ExitProcess	kernel32	void ExitProcess(UINT uExitCode);
    h" v|i" sigstr !  h" ExitProcess" fstr !  frezbind exitprocess


\ =============================== comdlg32.dll =============================== \
    h" comdlg32.dll" fstr !  uselib

\ GetOpenFileNameA	comdlg32	BOOL GetOpenFileNameA(LPOPENFILENAMEA unnamedParam1);
    h" d|i" sigstr !  h" GetOpenFileNameA" fstr !  frezbind getopenfilename

\ GetSaveFileNameA	comdlg32	BOOL GetSaveFileNameA(LPOPENFILENAMEA unnamedParam1);
    h" d|i" sigstr !  h" GetSaveFileNameA" fstr !  frezbind getsavefilename

\ ChooseFontW	comdlg32	BOOL ChooseFontW(LPCHOOSEFONTW unnamedParam1);
    h" d|i" sigstr !  h" ChooseFontW" fstr !  frezbind choosefontw

\ FindTextA	comdlg32	HWND FindTextA(LPFINDREPLACEA unnamedParam1);
    h" q|i" sigstr !  h" FindTextA" fstr !  frezbind findtext

\ ReplaceTextA	comdlg32	HWND ReplaceTextA(LPFINDREPLACEA unnamedParam1);
    h" q|i" sigstr !  h" ReplaceTextA" fstr !  frezbind replacetext

\ PrintDlgA	comdlg32	BOOL PrintDlgA(LPPRINTDLGA pPD);
    h" d|i" sigstr !  h" PrintDlgA" fstr !  frezbind printdlg

\ PageSetupDlgA	comdlg32	BOOL PageSetupDlgA(LPPAGESETUPDLGA unnamedParam1);
    h" d|i" sigstr !  h" PageSetupDlgA" fstr !  frezbind pagesetupdlg


\ ================================ gdi32.dll ================================= \
    h" gdi32.dll" fstr !  uselib

\ StartDocA	gdi32	int StartDocA(HDC hdc, const DOCINFOA *lpdi);
    h" d|ii" sigstr !  h" StartDocA" fstr !  frezbind startdoc

\ StartPage	gdi32	int StartPage(HDC hdc);
    h" d|i" sigstr !  h" StartPage" fstr !  frezbind startpage

\ EndPage	gdi32	int EndPage(HDC hdc);
    h" d|i" sigstr !  h" EndPage" fstr !  frezbind endpage

\ EndDoc	gdi32	int EndDoc(HDC hdc);
    h" d|i" sigstr !  h" EndDoc" fstr !  frezbind enddoc

\ GetDeviceCaps	gdi32	int GetDeviceCaps(HDC hdc, int index);
    h" d|ii" sigstr !  h" GetDeviceCaps" fstr !  frezbind getdevicecaps

\ DeleteDC	gdi32	BOOL DeleteDC(HDC hdc);
    h" d|i" sigstr !  h" DeleteDC" fstr !  frezbind deletedc


\ =============================== shell32.dll ================================ \
    h" shell32.dll" fstr !  uselib

\ ShellExecuteA	shell32	HINSTANCE ShellExecuteA(HWND hwnd, LPCSTR lpOperation, LPCSTR lpFile, LPCSTR lpParameters, LPCSTR lpDirectory, INT nShowCmd);
\ Returns a value greater than 32 on success.
    h" q|iiii2" sigstr !  h" ShellExecuteA" fstr !  frezbind shellexecute

\ =============================== Windows constants  ================================ \

\ comments in this section adopted from TinyRetroPad source
>dec
800        const WindowWidth         \ window startup size
640        const WindowHeight
1001       const IDC_EDIT            \ WinAPI EDIT control from WinAPI
>hex
400 const WM_USER
>dec
WM_USER 53 + const EM_EXLIMITTEXT      \ Rich Edit: raise user editing text limit
WM_USER 68 + const EM_SETCHARFORMAT    \ Rich Edit: set text format
WM_USER 69 + const EM_SETEVENTMASK     \ Rich Edit: choose which notifications parent gets
WM_USER 72 + const EM_SETTARGETDEVICE  \ Rich Edit: wrapping target width

>hex
4  const SCF_ALL             \ Rich Edit: apply format to all text
1  const ENM_CHANGE          \ Rich Edit: send EN_CHANGE notifications
20000000  const CFM_FACE            \ Rich Edit: use font face name

>dec
128        const MAX_CMD_PATH        \ holds startup file path from dropped file
128        const MAX_TITLE           \ holds window title text (file name and if dirty * )

>hex
0E100     const IDM_SAVE            \ Save menu ID (WM_SYSCOMMAND)
0E200     const IDM_FILE_NEW
0E201     const IDM_FILE_EXIT
0E202     const IDM_FILE_OPEN
0E203     const IDM_FILE_SAVEAS
0E204     const IDM_FILE_PRINT
0E205     const IDM_FILE_PAGESETUP
0E210     const IDM_EDIT_UNDO
0E211     const IDM_EDIT_CUT
0E212     const IDM_EDIT_COPY
0E213     const IDM_EDIT_PASTE
0E214     const IDM_EDIT_DELETE
0E215     const IDM_EDIT_SELALL
0E216     const IDM_EDIT_TIME
0E217     const IDM_EDIT_FIND
0E218     const IDM_EDIT_FINDNEXT
0E219     const IDM_EDIT_REPLACE
0E21A     const IDM_EDIT_GOTO
0E220     const IDM_FMT_WRAP
0E221     const IDM_FMT_FONT
0E230     const IDM_VIEW_STATUS
0E240     const IDM_HELP_ABOUT
0E241     const IDM_HELP_VIEWHELP

>dec
1000         const IDC_GOEDIT          \ Go To dialog edit field id
WM_USER 57 + const EM_FORMATRANGE      \ Rich Edit: render text to a DC (printing)
20           const SBHEIGHT

\ ====================== application constants ======================= \
>hex
0001 const WM_CREATE
0002 const WM_DESTROY
0005 const WM_SIZE
000D const WM_GETTEXT
000E const WM_GETTEXTLENGTH
004E const WM_NOTIFY
0100 const WM_KEYDOWN
0110 const WM_INITDIALOG
0111 const WM_COMMAND
0112 const WM_SYSCOMMAND
0300 const WM_CUT
0301 const WM_COPY
0302 const WM_PASTE
0303 const WM_CLEAR
0304 const WM_UNDO
0400 const WM_USER
00B1 const EM_SETSEL
00B7 const EM_SCROLLCARET
00BB const EM_LINEINDEX
00C2 const EM_REPLACESEL
0434 const EM_EXGETSEL
0436 const EM_EXLINEFROMCHAR
0437 const EM_EXSETSEL
044F const EM_FINDTEXTEXA
0300 const EN_CHANGE
0702 const EN_SELCHANGE
00020000 const ENM_MOUSEEVENTS
00080000 const ENM_SELCHANGE
00000001 const CFM_BOLD
00000002 const CFM_ITALIC
80000000 const CFM_SIZE
00000001 const CFE_BOLD
00000002 const CFE_ITALIC
00CF0000 const WS_OVERLAPPEDWINDOW
80000000 const WS_POPUP
40000000 const WS_CHILD
10000000 const WS_VISIBLE
00C00000 const WS_CAPTION
00800000 const WS_BORDER
00200000 const WS_VSCROLL
00080000 const WS_SYSMENU
00010000 const WS_TABSTOP
00020000 const WS_EX_STATICEDGE
0000 const ES_LEFT
0004 const ES_MULTILINE
0040 const ES_AUTOVSCROLL
2000 const ES_NUMBER
00000001 const BS_DEFPUSHBUTTON
80 const DS_MODALFRAME
80000000 const CW_USEDEFAULT
0000 const MF_STRING
0001 const MF_GRAYED
0010 const MF_POPUP
0800 const MF_SEPARATOR
0000 const MB_OK
0003 const MB_YESNOCANCEL
0020 const MB_ICONQUESTION
0040 const MB_ICONINFORMATION
0004 const SWP_NOZORDER
10 const VK_SHIFT
11 const VK_CONTROL
72 const VK_F3
74 const VK_F5
80000000 const GENERIC_READ
40000000 const GENERIC_WRITE
00000001 const FILE_SHARE_READ
00000080 const FILE_ATTRIBUTE_NORMAL
0000 const GMEM_FIXED
0400 const LOCALE_USER_DEFAULT
00000001 const DATE_SHORTDATE
0002 const OFN_OVERWRITEPROMPT
0004 const OFN_HIDEREADONLY
0800 const OFN_PATHMUSTEXIST
1000 const OFN_FILEMUSTEXIST
0001 const CF_SCREENFONTS
0100 const CF_EFFECTS
0001 const FR_DOWN
0004 const FR_MATCHCASE
0010 const FR_REPLACE
0020 const FR_REPLACEALL
0040 const FR_DIALOGTERM
0004 const PD_NOSELECTION
0008 const PD_NOPAGENUMS
0100 const PD_RETURNDC
>dec
1 const IDOK
2 const IDCANCEL
7 const IDNO
0 const SW_HIDE
1 const SW_SHOWNORMAL
5 const SW_SHOW
2 const CREATE_ALWAYS
3 const OPEN_EXISTING
-1 const INVALID_HANDLE_VALUE
32 const LF_FACESIZE
8 const HORZRES
10 const VERTRES
88 const LOGPIXELSX
90 const LOGPIXELSY
0 const NULL
0 const FALSE
1 const TRUE

h" CreateWindowExA" const CreateWindowExA                 \ create main window \ EDIT control
h" GetModuleHandleA" const GetModuleHandleA               \ get HINSTANCE
h" LoadLibraryA" const LoadLibraryA                       \ load modern Rich Edit DLL
h" RegisterClassA" const RegisterClassA                   \ rgstr wndw class (was RegisterClassExA@4)
h" GetMessageA" const GetMessageA                         \ message loop get
h" TranslateMessage" const TranslateMessage               \ translate keys
h" DispatchMessageA" const DispatchMessageA               \ dispatch to WndProc
h" PostQuitMessage" const PostQuitMessage                 \ exit message loop
h" DefWindowProcA" const DefWindowProcA                   \ default window handling
h" SetWindowPos" const SetWindowPos                       \ resize EDIT control
h" GetCommandLineA" const GetCommandLineA                 \ get startup file path
h" CreateFileA" const CreateFileA                         \ open file (read/write)
h" GetFileSize" const GetFileSize                         \ get file size
h" GlobalAlloc" const GlobalAlloc                         \ allocate buffer
h" GlobalFree" const GlobalFree                           \ free buffer
h" ReadFile" const ReadFile                               \ read file into EDIT
h" WriteFile" const WriteFile                             \ save EDIT to file
h" CloseHandle" const CloseHandle                         \ close file handle
h" SetWindowTextA" const SetWindowTextA                   \ set title / EDIT text
h" GetSystemMenu" const GetSystemMenu                     \ get system menu
h" AppendMenuA" const AppendMenuA                         \ add Save menu item
h" CreateMenu" const CreateMenu                           \ create main menu bar
h" CreatePopupMenu" const CreatePopupMenu                 \ create each drop-down menu
h" SetMenu" const SetMenu                                 \ attach menu bar to main window
h" DestroyWindow" const DestroyWindow                     \ close main window
h" GetOpenFileNameA" const GetOpenFileNameA               \ common file open dialog
h" GetSaveFileNameA" const GetSaveFileNameA               \ common file save dialog
h" GetLocalTime" const GetLocalTime                       \ current local time
h" GetDateFormatA" const GetDateFormatA                   \ date formatting
h" GetTimeFormatA" const GetTimeFormatA                   \ time formatting
h" MessageBoxA" const MessageBoxA                         \ simple About dialog
h" TrackPopupMenu" const TrackPopupMenu                   \ show context popup menu
h" DestroyMenu" const DestroyMenu                         \ free a menu handle
h" GetMessagePos" const GetMessagePos                     \ screen coords of last msg
h" GetKeyState" const GetKeyState                         \ shortcut modifier state
h" SendMessageA" const SendMessageA                       \ talk to EDIT control
h" ChooseFontW" const ChooseFontW                         \ common font picker dialog
h" FindTextA" const FindTextA                             \ common Find dialog
h" ReplaceTextA" const ReplaceTextA                       \ common Replace dialog
h" RegisterWindowMessageA" const RegisterWindowMessageA   \ FINDMSGSTRING message id
h" IsDialogMessageA" const IsDialogMessageA               \ route keys to find dialog
h" PrintDlgA" const PrintDlgA                             \ common Print dialog (returns DC)
h" StartDocA" const StartDocA                             \ begin print job
h" StartPage" const StartPage                             \ begin a printed page
h" EndPage" const EndPage                                 \ finish a printed page
h" EndDoc" const EndDoc                                   \ finish print job
h" GetDeviceCaps" const GetDeviceCaps                     \ printer resolution/size
h" DeleteDC" const DeleteDC                               \ release printer DC
h" ShowWindow" const ShowWindow                           \ show/hide status bar
h" GetClientRect" const GetClientRect                     \ client size for relayout
h" wsprintfA" const wsprintfA                             \ format Ln/Col string
h" ShellExecuteA" const ShellExecuteA                     \ open help URL in browser
h" PageSetupDlgA" const PageSetupDlgA                     \ common Page Setup dialog
h" DialogBoxIndirectParamA" const DialogBoxIndirectParamA \ in-memory Go To dialog
h" GetDlgItemInt" const GetDlgItemInt                     \ read Go To line number
h" EndDialog" const EndDialog                             \ close Go To dialog
h" SetFocus" const SetFocus                               \ focus edit control after commands
h" ExitProcess" const ExitProcess                         \ terminate process cleanly

\ ============= proof of concept for "Hello, dynamic world!" ================= \

\ =============================== kernel32.dll =============================== \
    h" kernel32.dll" fstr !  uselib
\
\ LPVOID VirtualAlloc(
\     LPVOID lpAddress,          // NULL = let the system choose
\     SIZE_T dwSize,
\     DWORD  flAllocationType,   // MEM_COMMIT | MEM_RESERVE = 0x3000
\     DWORD  flProtect           // PAGE_READWRITE = 0x04, PAGE_EXECUTE_READWRITE = 0x40
\ );
     h" q|iiii" sigstr ! h" GetModuleHandleA" fstr ! frezbind virtualalloc

\
\ BOOL VirtualProtect(
\     LPVOID lpAddress,
\     SIZE_T dwSize,
\     DWORD  flNewProtect,       // PAGE_EXECUTE_READ = 0x20
\     PDWORD lpflOldProtect      // must be non-NULL, points to a writable DWORD
\ );
    h" d|iiii" sigstr ! h" GetModuleHandleA" fstr ! frezbind virtualprotect

\ BOOL FlushInstructionCache(
\     HANDLE  hProcess,          // GetCurrentProcess() = (HANDLE)-1
\     LPCVOID lpBaseAddress,
\     SIZE_T  dwSize
\ );
    h" d|iii" sigstr ! h" GetModuleHandleA" fstr ! frezbind flushicache

\ BOOL VirtualFree(
\     LPVOID lpAddress,
\     SIZE_T dwSize,             // must be 0 with MEM_RELEASE
\     DWORD  dwFreeType          // MEM_RELEASE = 0x8000
\ );
    h" d|iii" sigstr ! h" GetModuleHandleA" fstr ! frezbind virtualfree

\ HANDLE CreateThread(
\     LPSECURITY_ATTRIBUTES  lpThreadAttributes,  // NULL
\     SIZE_T                 dwStackSize,         // 0 = default
\     LPTHREAD_START_ROUTINE lpStartAddress,      // DWORD WINAPI fn(LPVOID)
\     LPVOID                 lpParameter,
\     DWORD                  dwCreationFlags,     // 0 = run immediately
\     LPDWORD                lpThreadId           // may be NULL
\ );

    h" q|iiii2" sigstr ! h" GetModuleHandleA" fstr ! frezbind createthread \ maxiForth is single-threaded!

\ get-cb-mem ( size -- address)
\ This will pass the correct protection and allocation type
\ Getting the memory twice will return the same address (unless you futz with cb-mem)
var old-protect
var cb-mem
: get-cb-mem
    cb-mem @ 0 =
    if
        \  lpAddress,  dwSize, flNewProtect, lpflOldProtect
        0 1 12 << >hex 4 >dec virtualalloc
        dup cb-mem !
    else
        cb-mem @
    then
;
var cb-loaded 0 cb-loaded !

\ load-test-callback ( -- [true|false] <memory variables stored, callbacks loaded>)
\ 0. if already loaded, bail (true)
\ 1. true cb-loaded !
\ 2. open the binary with fopen
\ 3. get its length, store it in `len-stubs` and rewind it
\ 4. virtualalloc 4kb with get-cb-mem (fills cb-mem)
\ 5. bail if cb-mem is 0 (false)
\ 6. store `cb-mem` in `vahere`
\ 7. read `len-stubs` bytes from the binary into `vahere`
\ 8. patch the address of `printf` into `callback-mem + 0x40`
\ 8. `vahere @ len-stubs @ + vahere !`
\ 9. protect the memory

var len-stubs
var vahere
var winstubs-bin h" C:\\Users\\mknor\\CLionProjects\\core_forth\\windows\\winstubs.bin" winstubs-bin !
var mode-read-binary h" rb" mode-read-binary !

\ ( file-handle -- file-handle length )
: get-file-length
    dup 0 2 fseek
    0 <>
    if
        -1 exit
    then
    dup dup ftell
    swap rewind
;
\ ( -- [true|false] )
: load-test-callback
    cb-loaded @
    if
        true
    else
        true cb-loaded !
        winstubs-bin @ mode-read-binary @ fopen
        dup 0 =

        if
            exit \ false already on stack
        then

        get-file-length
        dup -1 =
        if
            drop false exit \ WRONG!: remember to close the file
        then

;