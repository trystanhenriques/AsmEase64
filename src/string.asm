
; Make case sensitive and disable MASM's auto prologue/epilogue.
OPTION casemap:none
OPTION prologue:none, epilogue:none

INCLUDE string.inc

.code

; =====================
; Copy & Concatenate
; =====================

;________________________________________
; str_copy(dst, dst_cap, src, src_len)
;________________________________________
; Returns:
;   CF=0, RAX = new length (== src_len)     ; success
;   CF=1, EAX = ERR_*                       ; error
; Errors:
;   ERR_NULLPTR    if dst == NULL or src == NULL
;   ERR_LEN_ZERO   if src_len == 0
;   ERR_CAPACITY   if src_len > dst_cap
; Notes:
;   - Copies exactly src_len bytes (no terminator added).
;   - Overlap-safe (memmove semantics): direction chosen automatically.
;   - Length units are BYTES.
;________________________________________
str_copy PROC dst:QWORD, dst_cap:QWORD, src:QWORD, src_len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=dst, RDX=dst_cap, R8=src, R9=src_len

    ; required pointers
    CHECK_NULL rcx, ERR_NULLPTR        ; dst
    CHECK_NULL r8,  ERR_NULLPTR        ; src

    ; src_len must be > 0
    CHECK_LEN_NONZERO r9, ERR_LEN_ZERO

    ; capacity: src_len <= dst_cap
    CHECK_CAPACITY r9, rdx, ERR_CAPACITY

    ; keep return value in r11, free RAX for byte moves
    mov  r11, r9            ; r11 = src_len (return)

    ; if dst == src, nothing to do (but still "success")
    cmp  rcx, r8
    jne  sc_check_overlap
      mov  rax, r11
      RET_OK

sc_check_overlap:
    ; if dst >= src && dst < src+len  -> backward copy
    ; else forward copy
    mov  r10, r8
    add  r10, r11           ; r10 = src + len
    cmp  rcx, r8
    jb   sc_forward         ; dst < src  => forward is safe
    cmp  rcx, r10
    jb   sc_backward        ; dst in (src .. src+len) => backward
    ; else: dst >= src+len  => no overlap, forward is fine

sc_forward:
    ; r9 = dst ptr, r10 = src ptr, rcx = count
    mov  r9,  rcx           ; r9  = dst
    mov  r10, r8            ; r10 = src
    mov  rcx, r11           ; rcx = count
sc_fw_loop:
    mov  al,  [r10]
    mov  [r9], al
    inc  r10
    inc  r9
    dec  rcx
    jnz  sc_fw_loop
    mov  rax, r11
    RET_OK

sc_backward:
    ; r9 = dst+len, r10 = src+len, copy from end
    mov  r9,  rcx           ; r9  = dst
    mov  r10, r8            ; r10 = src
    mov  rcx, r11           ; rcx = count
    add  r9,  rcx
    add  r10, rcx
sc_bw_loop:
    dec  r9
    dec  r10
    mov  al,  [r10]
    mov  [r9], al
    dec  rcx
    jnz  sc_bw_loop
    mov  rax, r11
    RET_OK
str_copy ENDP


; WIll implement this later!!!!!! 5 arg mess!
;str_concat PROC dst:QWORD, dst_len:QWORD, dst_cap:QWORD, src:QWORD, src_len:QWORD
    ;SAFE_PROLOGUE
    ; body pending
    ;RET_ERR ARR_ERR_NULLPTR
;str_concat ENDP

; =====================
; Length & Compare
; =====================

;________________________________________
; str_length(src, max_len)
;________________________________________
; RCX = src (pointer to bytes)
; RDX = max_len (scan limit, in bytes)
; Returns:
;   CF=0, RAX = number of bytes before first 0x00, up to max_len
;   CF=1, EAX = ERR_*                ; error
; Errors:
;   ERR_NULLPTR   if src == NULL
;   ERR_LEN_ZERO  if max_len == 0
; Notes:
;   - Binary-safe 'strnlen': if no NUL within max_len, returns max_len.
;   - Does NOT read past max_len.
;________________________________________
str_length PROC src:QWORD, max_len:QWORD
    SAFE_PROLOGUE

    ; validate
    CHECK_NULL        rcx, ERR_NULLPTR      ; src
    CHECK_LEN_NONZERO rdx, ERR_LEN_ZERO     ; max_len > 0

    ; scan for NUL up to max_len
    mov   rsi, rcx            ; keep base
    mov   rdi, rcx            ; scan ptr
    mov   rcx, rdx            ; count = max_len
    xor   eax, eax            ; AL = 0
    cld
    repne scasb               ; stops if ZF==1 (found) or RCX==0 (not found)

    jnz   sl_not_found        ; ZF==0 => no NUL within max_len

    ; found: RDI points just past matched NUL
    mov   rax, rdi
    sub   rax, rsi            ; bytes including the NUL
    dec   rax                 ; exclude the NUL itself
    RET_OK

sl_not_found:
    ; no NUL in window -> length == max_len (RDX unchanged)
    mov   rax, rdx
    RET_OK
str_length ENDP


;________________________________________
; str_compare(a, a_len, b, b_len)
;________________________________________
; RCX = a       (pointer to bytes)
; RDX = a_len   (bytes to compare from a)
; R8  = b       (pointer to bytes)
; R9  = b_len   (bytes to compare from b)
;
; Returns (success):
;   CF=0, RAX =  0  if a == b (same bytes and same length)
;   CF=0, RAX = -1  if a  < b (first differing byte in a is smaller, unsigned compare;
;                              or a is a proper prefix of b)
;   CF=0, RAX =  1  if a  > b (first differing byte in a is larger, unsigned compare;
;                              or b is a proper prefix of a)
;
; Returns (error):
;   CF=1, EAX = ERR_* 
; Errors:
;   ERR_NULLPTR  if a == NULL or b == NULL
;
; Notes:
;   - Binary-safe: compares raw bytes (unsigned 0..255). NULs are treated like any byte.
;   - No length restrictions: a_len and/or b_len may be zero.
;   - Reading only (no writes); overlap between a and b is harmless.
;________________________________________
;________________________________________
; str_compare(a, a_len, b, b_len)
; See earlier comment block for full contract.
;________________________________________
str_compare PROC a:QWORD, a_len:QWORD, b:QWORD, b_len:QWORD
    SAFE_PROLOGUE

    ; ---- validate pointers ----
    CHECK_NULL rcx, ERR_NULLPTR      ; a
    CHECK_NULL r8,  ERR_NULLPTR      ; b

    ; ---- set up ----
    mov     rsi, rcx                 ; rsi = a
    mov     rdi, r8                  ; rdi = b

    ; rcx = min(a_len, b_len)  [**FIXED INIT**]
    mov     r10, rdx                 ; r10 = a_len
    mov     r11, r9                  ; r11 = b_len
    mov     rcx, r10                 ; rcx = a_len (init)
    cmp     r10, r11
    cmova   rcx, r11                 ; if a_len > b_len -> rcx = b_len

    ; If min len is zero, skip byte compare and decide by lengths
    test    rcx, rcx
    jz      sc_len_only

    ; ---- byte-wise compare, unsigned ----
    cld
    repe    cmpsb                    ; stop on mismatch (ZF=0) or rcx==0 (prefix equal)
    jne     sc_mismatch              ; ZF=0 => differing byte

    ; Prefix equal up to min length -> decide by lengths
sc_len_only:
    cmp     r10, r11
    je      sc_equal
    jb      sc_a_lt_b                ; a shorter prefix -> a<b
    jmp     sc_a_gt_b                ; a longer        -> a>b

sc_mismatch:
    ; rsi/rdi advanced past the differing byte; compare previous bytes unsigned
    movzx   eax, byte ptr [rsi-1]    ; A byte (0..255)
    movzx   edx, byte ptr [rdi-1]    ; B byte (0..255)
    cmp     eax, edx
    jb      sc_a_lt_b
    ja      sc_a_gt_b
    ; (defensive)
    jmp     sc_equal

sc_equal:
    xor     eax, eax                 ; 0
    RET_OK

sc_a_lt_b:
    mov     rax, -1                  ; **64-bit -1**
    RET_OK

sc_a_gt_b:
    mov     rax, 1                   ; **64-bit +1**
    RET_OK

str_compare ENDP



; =====================
; In-place transforms
; =====================

str_trim PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_trim ENDP

str_to_upper PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_to_upper ENDP

str_to_lower PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_to_lower ENDP

str_reverse PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_reverse ENDP

str_fill PROC base:QWORD, len:QWORD, ch8:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_fill ENDP

; =====================
; Search & Replace
; =====================

str_find_char PROC base:QWORD, len:QWORD, ch8:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_find_char ENDP

str_replace_char PROC base:QWORD, len:QWORD, from:QWORD, to:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_replace_char ENDP

END
