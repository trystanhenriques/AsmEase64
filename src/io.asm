;=========================================================
; io.asm — I/O module (Windows console) — SKELETON
;=========================================================
OPTION casemap:none
OPTION prologue:none, epilogue:none

INCLUDE io.inc                ; public API (prototypes, ERR_*, macros)
INCLUDE win32_console.inc     ; private: EXTERN/INCLUDELIB for Win32 console

;---------------------------------------------------------
; Private state (cached handles), optional init
;---------------------------------------------------------
.data
g_io_inited     dd 0
align 8
g_stdout        dq 0
g_stdin         dq 0

.const
crlf_bytes      db 13,10        ; "\r\n"
crlf_len        EQU ($-crlf_bytes)

;---------------------------------------------------------
; .code
;---------------------------------------------------------
.code

;________________________________________
; io_init()
;________________________________________
; Initializes cached console handles.
; Returns:
;   CF=0, RAX = 0 (reserved)
; Errors:
;   (none for now; later we may return ERR_* if handles fail)
;________________________________________
io_init PROC
    SAFE_PROLOGUE

    mov   ecx, STD_OUTPUT_HANDLE
    call  GetStdHandle
    mov   [g_stdout], rax

    mov   ecx, STD_INPUT_HANDLE
    call  GetStdHandle
    mov   [g_stdin], rax

    mov   dword ptr [g_io_inited], 1
    xor   rax, rax
    RET_OK
io_init ENDP



;=========================================================
; Helpers (private)
;=========================================================

; Ensure stdout handle available in RAX (lazy)
_io_get_stdout PROC
    SAFE_PROLOGUE
    mov     rax, [g_stdout]
    test    rax, rax
    jnz     @done
    mov     ecx, STD_OUTPUT_HANDLE
    call    GetStdHandle
    mov     [g_stdout], rax
@done:
    SAFE_EPILOGUE
_io_get_stdout ENDP

; Ensure stdin handle available in RAX (lazy)
_io_get_stdin PROC
    SAFE_PROLOGUE
    mov     rax, [g_stdin]
    test    rax, rax
    jnz     @done
    mov     ecx, STD_INPUT_HANDLE
    call    GetStdHandle
    mov     [g_stdin], rax
@done:
    SAFE_EPILOGUE
_io_get_stdin ENDP



;=========================================================
; Printing (placeholders)
;=========================================================


io_print_char PROC byteval:QWORD
    SAFE_PROLOGUE
    xor rax, rax
    RET_OK
io_print_char ENDP


io_print_string PROC buf:QWORD, len:QWORD
    SAFE_PROLOGUE
    test rdx, rdx
    jz   ips_ok
    CHECK_NULL rcx, ERR_NULLPTR        ; rcx == buf
ips_ok:
    xor  rax, rax
    RET_OK
io_print_string ENDP



io_print_int PROC value:QWORD
    SAFE_PROLOGUE
    xor rax, rax
    RET_OK
io_print_int ENDP


io_print_uint PROC value:QWORD
    SAFE_PROLOGUE
    xor rax, rax
    RET_OK
io_print_uint ENDP


io_print_hex PROC value:QWORD, min_digits:QWORD
    SAFE_PROLOGUE
    xor rax, rax
    RET_OK
io_print_hex ENDP


io_print_float PROC value:QWORD, precision:QWORD, flags:QWORD
    SAFE_PROLOGUE
    xor rax, rax
    RET_OK
io_print_float ENDP


io_print_binary PROC value:QWORD, min_bits:QWORD
    SAFE_PROLOGUE
    xor rax, rax
    RET_OK
io_print_binary ENDP


io_print_mem PROC buf:QWORD, len:QWORD
    SAFE_PROLOGUE
    test rdx, rdx
    jz   ipm_ok
    CHECK_NULL rcx, ERR_NULLPTR        ; rcx == buf
ipm_ok:
    xor  rax, rax
    RET_OK
io_print_mem ENDP


io_print_reg PROC value:QWORD, flags:QWORD
    SAFE_PROLOGUE
    xor rax, rax
    RET_OK
io_print_reg ENDP


;________________________________________
; io_print_newline()
;________________________________________
; Returns:
;   CF=0, RAX = bytes written (2 for CRLF); best-effort (0 on failure)
; Notes:
;   - Uses WriteFile so it works with console or redirected stdout (pipes/files).
;   - No need to call io_init(); stdout fetched lazily.
;________________________________________
io_print_newline PROC
    SAFE_PROLOGUE
    call  _io_get_stdout            ; RAX = handle

    ; WriteFile(h, "\r\n", 2, &written, NULL)
    mov   rcx, rax                  ; hFile
    lea   rdx, crlf_bytes           ; lpBuffer
    mov   r8d, 2                    ; nNumberOfBytesToWrite
    lea   r9,  [rsp+18h]            ; LPDWORD lpNumberOfBytesWritten  (use shadow space!)
    mov   qword ptr [rsp+20h], 0    ; LPOVERLAPPED = NULL (5th arg)
    mov   dword ptr [rsp+18h], 0
    call  WriteFile

    test  eax, eax
    jz    @fail
    mov   eax, dword ptr [rsp+18h]  ; bytes written (should be 2)
    RET_OK
@fail:
    xor   eax, eax
    RET_OK
io_print_newline ENDP




;=========================================================
; Reading (placeholders)
;=========================================================


io_read_char PROC out_ptr:QWORD
    SAFE_PROLOGUE
    CHECK_NULL rcx, ERR_NULLPTR
    xor rax, rax
    RET_OK
io_read_char ENDP


io_read_string PROC dst:QWORD, dst_cap:QWORD
    SAFE_PROLOGUE
    test rdx, rdx
    jz   irs_ok
    CHECK_NULL rcx, ERR_NULLPTR
irs_ok:
    xor  rax, rax
    RET_OK
io_read_string ENDP


io_read_int PROC out_ptr_qword:QWORD
    SAFE_PROLOGUE
    CHECK_NULL rcx, ERR_NULLPTR
    xor rax, rax
    RET_OK
io_read_int ENDP


io_read_uint PROC out_ptr_qword:QWORD
    SAFE_PROLOGUE
    CHECK_NULL rcx, ERR_NULLPTR
    xor rax, rax
    RET_OK
io_read_uint ENDP


io_read_hex PROC out_ptr_qword:QWORD
    SAFE_PROLOGUE
    CHECK_NULL rcx, ERR_NULLPTR
    xor rax, rax
    RET_OK
io_read_hex ENDP


io_read_binary PROC out_ptr_qword:QWORD
    SAFE_PROLOGUE
    CHECK_NULL rcx, ERR_NULLPTR
    xor rax, rax
    RET_OK
io_read_binary ENDP


END
