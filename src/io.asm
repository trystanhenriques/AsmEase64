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

; bit masks / patterns (avoid huge immediates in instructions)
mask_abs      dq 7FFFFFFFFFFFFFFFh   ; clear sign
mask_mant     dq 0000FFFFFFFFFFFFFh   ; mantissa
pat_inf       dq 7FF0000000000000h    ; +INF (abs pattern)

; decimal helpers
const_half    dq 3FE0000000000000h    ; 0.5 as double

; 10^n as double (n = 0..9)
pow10_q       dq 3FF0000000000000h    ; 1
              dq 4024000000000000h    ; 10
              dq 4059000000000000h    ; 100
              dq 408F400000000000h    ; 1e3
              dq 40C3880000000000h    ; 1e4
              dq 40F86A0000000000h    ; 1e5
              dq 412E848000000000h    ; 1e6
              dq 416312D000000000h    ; 1e7
              dq 4197D78400000000h    ; 1e8
              dq 41CDCD6500000000h    ; 1e9

; 10^n as uint64 (n = 0..9)
pow10_u       dq 1,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000

; literals for special cases
lit_inf       db "inf"
lit_neginf    db "-inf"
lit_nan       db "nan"


;---------------------------------------------------------
; .const
;---------------------------------------------------------
.const
inf_str   db 'inf'
inf_len   EQU ($-inf_str)
ninf_str  db '-inf'
ninf_len  EQU ($-ninf_str)
nan_str   db 'nan'
nan_len   EQU ($-nan_str)

.const
inf_bytes     db 'i','n','f'
inf_len       EQU ($-inf_bytes)

neginf_bytes  db '-','i','n','f'
neginf_len    EQU ($-neginf_bytes)

nan_bytes     db 'n','a','n'
nan_len       EQU ($-nan_bytes)



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




;________________________________________
; io_print_hex(value, min_digits)
;________________________________________
; RCX = value (u64)
; RDX = min_digits (0..16, clamped to 16)
; Returns (success):
;   CF=0, RAX = bytes written
; Returns (failure):
;   CF=0, RAX = 0   (best-effort; we don’t CF=1 on write failure)
; Notes:
;   - Uppercase hex (A..F).
;   - No "0x" prefix.
;   - If value==0 and min_digits==0 -> prints "0" (1 digit).
;   - Otherwise prints max(actual_digits, min_digits) with leading zeros as needed.
;   - Uses WriteFile, so it works with console or redirected stdout.
; Stack (after SAFE_PROLOGUE then locals: sub rsp,40h):
;   [rsp+00..+1F]  shadow space
;   [rsp+08]       cached stdout handle (QWORD)
;   [rsp+18]       DWORD bytesWritten
;   [rsp+20]       5th arg (lpOverlapped=NULL)
;   [rsp+30..+5F]  48-byte local buffer; we write digits from the end backward
;________________________________________
io_print_hex PROC value:QWORD, min_digits:QWORD
    SAFE_PROLOGUE
    sub   rsp, 40h

    ; cache stdout handle
    call  _io_get_stdout
    mov   [rsp+08h], rax

    ; snapshot args
    mov   r11, rcx               ; r11 = value (u64)
    mov   r10d, edx              ; r10d = min_digits (lower 32b enough)

    ; clamp min_digits to [0..16]
    cmp   r10d, 16
    jbe   ihx_md_ok
      mov   r10d, 16
ihx_md_ok:

    ; write pointer at end of local buffer
    lea   r9,  [rsp+5Fh]         ; r9 = write ptr for last digit
    xor   eax, eax
    mov   ecx, eax               ; ecx = digit count

    ; zero fast path
    test  r11, r11
    jnz   ihx_build
      mov   byte ptr [r9], '0'
      mov   ecx, 1
      jmp   ihx_pad

ihx_build:
    ; produce digits by nibbles (LSB first, written backward)
ihx_loop:
    mov   rax, r11
    and   eax, 0Fh               ; nibble in AL (0..15)
    cmp   al, 9
    jbe   ihx_digit_09
      add   al, ('A' - 10)
      jmp   ihx_store
ihx_digit_09:
      add   al, '0'
ihx_store:
    mov   byte ptr [r9], al
    inc   ecx                    ; digit count++
    dec   r9
    shr   r11, 4                 ; value >>= 4
    test  r11, r11
    jnz   ihx_loop

    ; need to advance r9 back to the last stored digit position
    inc   r9                     ; r9 now points to first digit

ihx_pad:
    ; ensure at least min_digits (leading zeros)
    ; while (count < min_digits) { *--start = '0'; ++count; }
    cmp   ecx, r10d
    jae   ihx_len_ready
ihx_pad_loop:
    dec   r9
    mov   byte ptr [r9], '0'
    inc   ecx
    cmp   ecx, r10d
    jb    ihx_pad_loop

ihx_len_ready:
    ; start = r9, len = ecx
    mov   eax, ecx               ; len -> EAX (DWORD)

    ; WriteFile(handle, start, len, &written, NULL)
    mov   rcx, [rsp+08h]         ; hFile
    mov   rdx, r9                ; lpBuffer
    mov   r8d, eax               ; nBytes (DWORD)
    lea   r9,  [rsp+18h]         ; &written (DWORD in shadow)
    mov   qword ptr [rsp+20h], 0 ; lpOverlapped = NULL
    mov   dword ptr [rsp+18h], 0
    call  WriteFile

    test  eax, eax
    jz    ihx_done_zero
    mov   eax, dword ptr [rsp+18h] ; bytes written

ihx_done_zero:
    lea   rsp, [rsp+40h]
    RET_OK
io_print_hex ENDP



;===============================================================================
; io_print_float
;-------------------------------------------------------------------------------
; Print an IEEE-754 double as a decimal string.
;
; Prototype:
;   io_print_float PROC value:QWORD, precision:QWORD, flags:QWORD
;
; Arguments (Win64):
;   RCX = value
;         Raw 64-bit IEEE-754 double *bit pattern* (not a pointer).
;   RDX = precision
;         Requested number of digits after the decimal point. Clamped to [0..9].
;   R8  = flags
;         Reserved (must be 0). Currently ignored.
;
; Returns:
;   CF = 0 on return.
;   RAX = number of bytes written to stdout (0 if the underlying write fails).
;
; Behavior:
;   • Handles special values first:
;       - NaN  -> prints "nan"
;       - +Inf -> prints "inf"
;       - -Inf -> prints "-inf"
;   • For normal numbers:
;       - Prints a minus only if value < 0 and value is not -0.0
;       - Integer part is trunc(|value|)
;       - Fraction is rounded to the requested precision using
;         round(frac * 10^p + 0.5). A carry into the integer part is handled.
;       - Exactly ‘precision’ fractional digits are emitted (no trimming).
;   • Uses io_print_string to write the final buffer (no direct WriteFile here).
;
; Notes:
;   • RCX must contain the *bits* of the double. If you have a test constant,
;     move the 64-bit pattern into RCX (e.g., mov rcx, [dbl_bits]).
;   • Precision is clamped to 9 to limit table sizes and keep code small.
;   • -0.0 prints as "0" (no minus sign).
;   • This routine allocates 0xC0 bytes of local scratch space and builds the
;     decimal text backward in that buffer, then calls io_print_string(ptr,len).
;   • io_print_string already reserves its own shadow space; do NOT add any
;     extra shadow space before calling it.
;
; Dependencies:
;   • io_print_string (writes the final buffer to stdout)
;   • pow10_q : table of doubles  {1.0, 10.0, 100.0, ...}
;   • pow10_u : table of u64      {1,   10,   100,   ...}
;   • const_half : qword 3FE0000000000000h  ; 0.5 as double
;
; Clobbers:
;   GPRs:  RAX, RCX, RDX, R8, R9, R10, R11, R12, R13, R14, R15
;   XMMs:  XMM0..XMM3
;   (RBX is preserved by SAFE_PROLOGUE/SAFE_EPILOGUE.)
;
; Calling convention / alignment:
;   • Win64 System Vectors, 16-byte stack alignment preserved by SAFE_PROLOGUE.
;   • No additional stack adjustment is required around io_print_string.
;===============================================================================

io_print_float PROC value:QWORD, precision:QWORD, flags:QWORD
    SAFE_PROLOGUE
    sub   rsp, 0C0h                        ; local scratch [..0BFh]

    ; snapshot args
    mov   rbx, rcx                         ; rbx = raw bits
    mov   r10d, edx                        ; precision (clamp below)

    ; clamp precision to [0..9]
    cmp   r10d, 9
    jbe   ipf_prec_ok
    mov   r10d, 9
ipf_prec_ok:

    ; ---------- SPECIALS FIRST ----------
    ; xmm0 = original double
    movq  xmm0, rcx

    ; NaN? (ucomisd sets PF=1 if NaN)
    ucomisd xmm0, xmm0
    jp    ipf_emit_nan

    ; |bits| == 0x7FF0000000000000 ?  => INF
    mov   rax, rcx
    mov   rdx, 7FFFFFFFFFFFFFFFh         ; ABS mask -> rdx
    and   rax, rdx
    mov   rdx, 7FF0000000000000h
    cmp   rax, rdx
    jne   ipf_normal                      ; not INF -> go normal

    ; sign bit tells +INF vs -INF
    bt    rbx, 63
    jc    ipf_emit_neginf

ipf_emit_inf:
    ; stack literal "inf"
    lea   rdi, [rsp+100h]
    mov   byte ptr [rdi+0], 'i'
    mov   byte ptr [rdi+1], 'n'
    mov   byte ptr [rdi+2], 'f'
    mov   rcx, rdi                         ; ptr
    mov   rdx, 3                           ; len
    call  io_print_string                  ; no extra shadow space
    add   rsp, 0C0h
    RET_OK

ipf_emit_neginf:
    ; stack literal "-inf"
    lea   rdi, [rsp+100h]
    mov   byte ptr [rdi+0], '-'
    mov   byte ptr [rdi+1], 'i'
    mov   byte ptr [rdi+2], 'n'
    mov   byte ptr [rdi+3], 'f'
    mov   rcx, rdi
    mov   rdx, 4
    call  io_print_string
    add   rsp, 0C0h
    RET_OK

ipf_emit_nan:
    ; stack literal "nan"
    lea   rdi, [rsp+100h]
    mov   byte ptr [rdi+0], 'n'
    mov   byte ptr [rdi+1], 'a'
    mov   byte ptr [rdi+2], 'n'
    mov   rcx, rdi
    mov   rdx, 3
    call  io_print_string
    add   rsp, 0C0h
    RET_OK

; ---------- NORMAL NUMERIC PATH ----------
ipf_normal:
    ; sign handling (avoid '-' for -0.0)
    mov   r11, rbx
    shr   r11, 63                          ; r11 = sign
    mov   r15b, 0
    test  r11, r11
    jz    ipf_sign_done
      mov   rax, rbx
      shl   rax, 1                         ; zero if exp|mant == 0  (i.e., -0.0)
      jz    ipf_sign_done
      mov   r15b, 1
ipf_sign_done:

    ; |value| into xmm0
    mov   rax, rbx
    mov   rdx, 7FFFFFFFFFFFFFFFh
    and   rax, rdx
    movq  xmm0, rax

    ; integer part = trunc(|value|)
    cvttsd2si r12, xmm0                    ; r12 = int64 trunc(|x|)
    cvtsi2sd xmm1, r12
    subsd   xmm0, xmm1                     ; xmm0 = frac in [0,1)

    ; pow10 tables: doubles (pow10_q) and u64 (pow10_u)
    lea   rsi, pow10_q
    lea   rdi, pow10_u

    ; scale fractional to integer with rounding: round(frac * 10^p)
    mov   eax, r10d
    movzx rax, ax
    shl   rax, 3
    movsd xmm2, qword ptr [rsi+rax]        ; scale (double)
    mulsd xmm0, xmm2
    movsd xmm3, qword ptr [const_half]     ; +0.5
    addsd xmm0, xmm3
    cvttsd2si r13, xmm0                    ; r13 = rounded fractional integer

    ; get 10^p (u64) to detect carry
    mov   eax, r10d
    movzx rax, ax
    shl   rax, 3
    mov   r8,  qword ptr [rdi+rax]         ; r8 = 10^p (u64)

    cmp   r13, r8
    jne   ipf_no_carry
      xor   r13, r13
      add   r12, 1
ipf_no_carry:

    ; build decimal in [rsp+30h..+0AFh] backwards
    lea   rbx, [rsp+0B0h]                  ; end+1
    lea   r14, [rsp+0AFh]                  ; write cursor

    ; fractional digits (exactly 'precision')
    test  r10d, r10d
    jz    ipf_after_frac
    mov   ecx, r10d
    mov   rax, r13
ipf_frac_loop:
    xor   rdx, rdx
    mov   r9d, 10
    div   r9                                ; rax=quot, rdx=rem
    add   dl, '0'
    mov   byte ptr [r14], dl
    dec   r14
    dec   ecx
    mov   rax, rax
    jnz   ipf_frac_loop

    ; decimal point
    mov   byte ptr [r14], '.'
    dec   r14
ipf_after_frac:

    ; integer digits (at least one)
    mov   rax, r12
    test  rax, rax
    jnz   ipf_int_loop
      mov   byte ptr [r14], '0'
      dec   r14
      jmp   ipf_after_int
ipf_int_loop:
    xor   rdx, rdx
    mov   r9d, 10
    div   r9
    add   dl, '0'
    mov   byte ptr [r14], dl
    dec   r14
    test  rax, rax
    jnz   ipf_int_loop
ipf_after_int:

    ; minus sign if needed (not for -0.0)
    cmp   r15b, 0
    je    ipf_set_start
      mov   byte ptr [r14], '-'
      dec   r14

ipf_set_start:
    lea   rdx, [r14+1]                     ; start ptr
    mov   rax, rbx
    sub   rax, rdx                         ; len = end - start (rbx = end+1)
    ; call io_print_string(start,len)
    mov   rcx, rdx
    mov   rdx, rax
    call  io_print_string

    add   rsp, 0C0h
    RET_OK
io_print_float ENDP





;________________________________________
; io_print_binary(value, min_bits)
;________________________________________
; RCX = value (u64)
; RDX = min_bits (0..64, will be clamped to 64)
; Returns (success):
;   CF=0, RAX = bytes written
; Returns (failure):
;   CF=0, RAX = 0   (best-effort; we don’t CF=1 on write failure)
; Notes:
;   - Prints uppercase '0'/'1', MSB-first.
;   - No "0b" prefix.
;   - Width rule: max(actual_bits, min_bits); if value==0 and min_bits==0 => "0".
;   - Uses WriteFile (works with console or redirected stdout).
; Stack (SAFE_PROLOGUE sub rsp,28h; locals sub rsp,80h):
;   [rsp+00..+1F]  shadow space
;   [rsp+08]       cached stdout handle (QWORD)
;   [rsp+18]       DWORD bytesWritten
;   [rsp+20]       5th arg (lpOverlapped=NULL)
;   [rsp+30..+9F]  112-byte local buffer; we use end at +9F so up to 64 bits fit
;________________________________________
io_print_binary PROC value:QWORD, min_bits:QWORD
    SAFE_PROLOGUE
    sub   rsp, 80h                         ; bigger local to hold up to 64 chars

    ; cache stdout handle
    call  _io_get_stdout
    mov   [rsp+08h], rax

    ; snapshot args
    mov   r11, rcx                         ; r11 = value (u64)
    mov   r10d, edx                        ; r10d = min_bits (32b is enough)

    ; clamp min_bits to [0..64]
    cmp   r10d, 64
    jbe   ib_min_ok
      mov   r10d, 64
ib_min_ok:

    ; actual_bits = (r11==0 ? 1 : (bsr(r11)+1))
    test  r11, r11
    jnz   ib_have_bits
      mov   ecx, 1                         ; actual_bits = 1
      jmp   ib_width
ib_have_bits:
    bsr   rax, r11                          ; rax = index of highest set bit [0..63]
    lea   ecx, [rax+1]                      ; actual_bits = index+1

ib_width:
    ; required = max(actual_bits, min_bits)
    mov   eax, r10d
    cmp   ecx, eax
    cmovg eax, ecx                          ; EAX = required bits (<=64)
    mov   esi, eax                          ; save required for later (len)

    ; Build digits from LSB upward, writing backward so output is MSB-first.
    lea   r9,  [rsp+9Fh]                   ; end of local buffer
    mov   ecx, esi                          ; remaining = required

ib_loop:
    test  ecx, ecx
    jz    ib_finish

    mov   eax, r11d
    and   eax, 1
    add   al, '0'                           ; 0->'0', 1->'1'
    mov   byte ptr [r9], al
    dec   r9

    shr   r11, 1                            ; next bit
    dec   ecx
    jmp   ib_loop

ib_finish:
    ; start = r9+1, len = ESI
    lea   rdx, [r9+1]                       ; lpBuffer
    mov   eax, esi                          ; len (DWORD)

    ; WriteFile(handle, start, len, &written, NULL)
    mov   rcx, [rsp+08h]                    ; hFile
    mov   r8d, eax                          ; nBytes
    lea   r9,  [rsp+18h]                    ; &written
    mov   qword ptr [rsp+20h], 0            ; lpOverlapped = NULL
    mov   dword ptr [rsp+18h], 0
    call  WriteFile

    test  eax, eax
    jz    ib_done_zero
    mov   eax, dword ptr [rsp+18h]          ; bytes written

ib_done_zero:
    lea   rsp, [rsp+80h]                    ; release locals (preserve flags)
    RET_OK
io_print_binary ENDP




;io_print_mem PROC buf:QWORD, len:QWORD
    ;SAFE_PROLOGUE
    ;test rdx, rdx
    ;jz   ipm_ok
    ;CHECK_NULL rcx, ERR_NULLPTR        ; rcx == buf
;ipm_ok:
    ;xor  rax, rax
    ;RET_OK
;io_print_mem ENDP


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
