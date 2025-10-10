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


;________________________________________
; io_print_char(byteVal)
;________________________________________
; RCX = byteVal (low 8 bits used)
; Returns:
;   CF=0, RAX = bytes written (1 on success, 0 on failure)
; Errors:
;   (none for now; best-effort write)
; Notes:
;   - Binary-safe: will attempt to write any byte (0x00..0xFF).
;   - Uses WriteFile so it works with console *or* redirected stdout.
;   - Does not require io_init(); stdout fetched lazily.
;________________________________________
io_print_char PROC byteVal:QWORD
    SAFE_PROLOGUE

    ; snapshot 'ch' before calling helpers (RCX will be clobbered by calls)
    mov   r10, rcx                  ; r10b = character to write

    ; fetch stdout handle (works for console or pipe)
    call  _io_get_stdout            ; RAX = handle

    ; store the one byte on our shadow space to pass a pointer to WriteFile
    mov   byte ptr [rsp+10h], r10b  ; 1-byte temp inside our 32B shadow

    ; WriteFile(h, &byte, 1, &written, NULL)
    mov   rcx, rax                  ; hFile
    lea   rdx, [rsp+10h]            ; lpBuffer -> our 1-byte temp
    mov   r8d, 1                    ; nNumberOfBytesToWrite
    lea   r9,  [rsp+18h]            ; lpNumberOfBytesWritten (DWORD in shadow)
    mov   qword ptr [rsp+20h], 0    ; lpOverlapped = NULL (5th arg)
    mov   dword ptr [rsp+18h], 0
    call  WriteFile

    test  eax, eax
    jz    ipc_fail
    mov   eax, dword ptr [rsp+18h]  ; should be 1
    RET_OK
ipc_fail:
    xor   eax, eax
    RET_OK
io_print_char ENDP



;________________________________________
; io_print_string(buf, len)
;________________________________________
; RCX = buf (pointer to bytes)
; RDX = len (number of bytes to write)
; Returns (success):
;   CF=0, RAX = bytes written (may be 0 if len==0)
; Returns (error):
;   CF=1, EAX = ERR_NULLPTR   if len>0 and buf == NULL
; Notes:
;   - Binary-safe: writes exactly 'len' bytes (no terminator).
;   - Uses WriteFile so it works with console or redirected stdout.
;   - Fast path for len <= 0xFFFFFFFF (single WriteFile), slow path otherwise.
;________________________________________
io_print_string PROC buf:QWORD, len:QWORD
    SAFE_PROLOGUE

    ; snapshot args immediately (param symbols are invalid after prologue)
    mov   r10, rcx                 ; r10 = buf
    mov   r11, rdx                 ; r11 = len

    ; len == 0 -> success, 0 bytes
    test  r11, r11
    jnz   ips_nonzero
    xor   eax, eax
    RET_OK

ips_nonzero:
    ; if we need to write, buf must be non-NULL
    CHECK_NULL r10, ERR_NULLPTR

    ; fetch stdout handle, stash in our shadow space
    call  _io_get_stdout           ; RAX = handle
    mov   [rsp+08h], rax           ; save handle (8 bytes inside shadow)

    ; ---- fast path: one call if len <= 0xFFFFFFFF ----
    mov   rax, 0FFFFFFFFh
    cmp   r11, rax
    ja    ips_slow_path

    mov   rcx, [rsp+08h]           ; hFile
    mov   rdx, r10                 ; lpBuffer
    mov   r8d, r11d                ; nBytes (DWORD)
    lea   r9,  [rsp+18h]           ; &written (DWORD in shadow)
    mov   qword ptr [rsp+20h], 0   ; lpOverlapped = NULL
    mov   dword ptr [rsp+18h], 0
    call  WriteFile

    test  eax, eax
    jz    ips_fast_zero
    mov   eax, dword ptr [rsp+18h] ; bytes written
    RET_OK
ips_fast_zero:
    xor   eax, eax
    RET_OK

    ; ---- slow path: chunking for >4GiB ----
ips_slow_path:
    xor   rax, rax                 ; total = 0
ips_loop:
    test  r11, r11
    jz    ips_done

    ; chunk = min(remaining=r11, 0xFFFFFFFF)
    mov   ecx, 0FFFFFFFFh          ; ECX = max DWORD
    cmp   r11, rcx
    cmovbe rcx, r11                ; ECX = (r11 <= max) ? r11 : max

    mov   rcx, [rsp+08h]           ; hFile
    mov   rdx, r10                 ; lpBuffer
    mov   r8d, ecx                 ; nBytes (DWORD)
    lea   r9,  [rsp+18h]           ; &written
    mov   qword ptr [rsp+20h], 0
    mov   dword ptr [rsp+18h], 0
    call  WriteFile

    test  eax, eax
    jz    ips_done                 ; treat failure as short write

    mov   edx, dword ptr [rsp+18h] ; written (zero-extends to RDX)
    test  edx, edx
    jz    ips_done

    add   rax, rdx                 ; total += written
    add   r10, rdx                 ; buf   += written
    sub   r11, rdx                 ; remaining -= written
    jmp   ips_loop

ips_done:
    RET_OK
io_print_string ENDP



;________________________________________
; io_print_int(value)
;________________________________________
; RCX = value (signed 64-bit)
; Returns (success):
;   CF=0, RAX = bytes written
; Returns (failure):
;   CF=0, RAX = 0   (best-effort; no ERR_* on write failure)
; Notes:
;   - Minimal decimal; 0 prints "0".
;   - Negative numbers get a leading '-' (handles INT64_MIN).
;   - Uses WriteFile; works with console or redirected stdout.
; Stack layout with SAFE_PROLOGUE (sub rsp,28h), then locals (sub rsp,40h):
;   [rsp+00..+1F]  shadow space
;   [rsp+08]       cached stdout handle (QWORD)
;   [rsp+10]       sign flag (BYTE 0/1)
;   [rsp+18]       DWORD bytesWritten
;   [rsp+20]       5th arg (lpOverlapped=NULL)
;   [rsp+30..+5F]  48-byte local digit buffer (we write from the end)
;________________________________________
io_print_int PROC value:QWORD
    SAFE_PROLOGUE
    sub   rsp, 40h

    ; fetch stdout handle once
    call  _io_get_stdout
    mov   [rsp+08h], rax

    ; snapshot value, detect sign, compute magnitude in r11 (u64)
    mov   r11, rcx                   ; signed input
    xor   eax, eax
    mov   byte ptr [rsp+10h], al     ; sign = 0
    test  r11, r11
    jge   ipi_mag_ready
      mov   byte ptr [rsp+10h], 1    ; sign = 1
      mov   rax, r11
      neg   rax                      ; |value| (INT64_MIN -> 0x8000..)
      mov   r11, rax
ipi_mag_ready:

    ; digit buffer end
    lea   r10, [rsp+5Fh]

    ; zero special-case: set start=r10 and len=1 directly
    test  r11, r11
    jnz   ipi_build
      mov   byte ptr [r10], '0'
      mov   r9,  r10                 ; start = r10
      mov   eax, 1                   ; len   = 1
      jmp   ipi_write

ipi_build:
    mov   r8d, 10                    ; r8 = 10
ipi_loop:
    xor   rdx, rdx                   ; 128/64 div
    mov   rax, r11
    div   r8                          ; RAX = quotient, RDX = remainder (0..9)
    add   dl, '0'
    mov   byte ptr [r10], dl
    dec   r10
    mov   r11, rax
    test  r11, r11
    jnz   ipi_loop

    ; start = r10+1
    lea   r9,  [r10+1]

    ; prepend '-' if negative: start-- ; *start = '-'
    cmp   byte ptr [rsp+10h], 0
    je    ipi_len
      dec   r9
      mov   byte ptr [r9], '-'

ipi_len:
    ; len = (end+1) - start  (64-bit safe)
    lea   rax, [rsp+60h]
    sub   rax, r9                    ; RAX = length

ipi_write:
    ; WriteFile(handle, start, len, &written, NULL)
    mov   rcx, [rsp+08h]             ; hFile
    mov   rdx, r9                    ; lpBuffer
    mov   r8d, eax                   ; nBytes (DWORD)
    lea   r9,  [rsp+18h]             ; &written
    mov   qword ptr [rsp+20h], 0     ; lpOverlapped = NULL
    mov   dword ptr [rsp+18h], 0
    call  WriteFile

    test  eax, eax
    jz    ipi_done_zero
    mov   eax, dword ptr [rsp+18h]   ; bytes written

ipi_done_zero:
    lea   rsp, [rsp+40h]             ; release locals, preserve flags
    RET_OK
io_print_int ENDP




;________________________________________
; io_print_uint(value)
;________________________________________
; RCX = value (unsigned 64-bit)
; Returns (success):
;   CF=0, RAX = bytes written (digit count)
; Returns (failure):
;   CF=0, RAX = 0 (best-effort; no ERR_* for write issues)
; Notes:
;   - Minimal decimal, no leading zeros; zero prints "0".
;   - Uses WriteFile (works with console or redirected stdout).
;   - Stack layout with SAFE_PROLOGUE (sub rsp,28h), then locals (sub rsp,40h):
;       [rsp+00..+1F]  shadow space for calls
;       [rsp+08]       (we stash stdout handle here)
;       [rsp+18]       DWORD bytesWritten
;       [rsp+20]       5th arg (lpOverlapped=NULL)
;       [rsp+30..+5F]  48-byte local digit buffer (we use end at +5F)
;________________________________________
io_print_uint PROC value:QWORD
    SAFE_PROLOGUE

    ; reserve 64 bytes for locals (keeps 16B alignment)
    sub   rsp, 40h

    ; fetch stdout handle once
    call  _io_get_stdout               ; RAX = handle
    mov   [rsp+08h], rax               ; stash handle in shadow space

    ; set up reverse-digit builder using the local buffer above shadow:
    ; buffer = [rsp+30 .. rsp+5F], we start from the very end (rsp+5F)
    mov   r11, rcx                     ; r11 = value (u64)
    lea   r10, [rsp+5Fh]               ; r10 = write ptr (last byte in buffer)

    ; zero special-case -> "0"
    test  r11, r11
    jnz   ipu_build
    mov   byte ptr [r10], '0'
    mov   r9,  r10                     ; start
    mov   eax, 1                       ; len
    jmp   ipu_write

ipu_build:
    mov   r8d, 10                      ; r8 = 10 (64-bit reg)
ipu_loop:
    xor   rdx, rdx                     ; RDX:RAX / 10  (128/64 div uses full RAX)
    mov   rax, r11                     ; RAX = value (u64)
    div   r8                            ; quotient -> RAX (u64), remainder -> RDX (u64)
    mov   dl, dl                       ; (no-op; just to make it clear we use DL)
    add   dl, '0'                      ; remainder -> ASCII
    mov   byte ptr [r10], dl
    dec   r10
    mov   r11, rax                     ; value = quotient
    test  r11, r11
    jnz   ipu_loop


    ; compute start (r10+1) and len using 64-bit pointer arithmetic
    lea   r9,  [r10+1]                 ; start
    lea   rax, [rsp+60h]               ; one past end of buffer
    sub   rax, r9                      ; len = end - start  (64-bit safe)

ipu_write:
    ; WriteFile(h, start, len, &written, NULL)
    mov   rcx, [rsp+08h]               ; hFile
    mov   rdx, r9                      ; lpBuffer
    mov   r8d, eax                     ; nBytes (DWORD)
    lea   r9,  [rsp+18h]               ; &written (DWORD in shadow)
    mov   qword ptr [rsp+20h], 0       ; lpOverlapped = NULL
    mov   dword ptr [rsp+18h], 0
    call  WriteFile

    test  eax, eax
    jz    ipu_done_zero
    mov   eax, dword ptr [rsp+18h]     ; bytes written

ipu_done_zero:
    lea   rsp, [rsp+40h]               ; release locals, preserve flags
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
