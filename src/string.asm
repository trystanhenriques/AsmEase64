
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

;________________________________________
; str_trim(base, len)
;________________________________________
; RCX = base  (pointer to bytes, modified in-place)
; RDX = len   (number of bytes to examine)
;
; Returns (success):
;   CF=0, RAX = new_len after removing leading/trailing ASCII whitespace:
;               bytes in {0x20, 0x09..0x0D} at both ends are removed.
;               Middle whitespace is preserved. Data is left-shifted if needed.
;
; Returns (error):
;   CF=1, EAX = ERR_* 
; Errors:
;   ERR_NULLPTR  if base == NULL
;
; Notes:
;   - Binary-safe; does NOT append a terminator.
;   - Overlap-safe by construction (dst < src -> forward copy).
;   - len == 0 is allowed and returns 0 (success).
;________________________________________
str_trim PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE

    ; validate pointer
    CHECK_NULL rcx, ERR_NULLPTR          ; base

    ; quick exit: empty input -> length 0
    test    rdx, rdx
    jnz     st_nonempty
    xor     rax, rax                     ; new_len = 0
    RET_OK

st_nonempty:
    ; r10 = i (leading index), r11 = j (trailing end = len)
    xor     r10, r10                     ; i = 0
    mov     r11, rdx                     ; j = len

    ; ---- trim leading ----
st_lead_loop:
    cmp     r10, r11
    jae     st_all_trimmed               ; all whitespace -> length 0
    mov     al, [rcx + r10]              ; AL = base[i]
    ; is_whitespace := (AL == 0x20) || (0x09 <= AL <= 0x0D)
    cmp     al, 20h
    je      st_lead_inc
    cmp     al, 09h
    jb      st_lead_done
    cmp     al, 0Dh
    jbe     st_lead_inc
    jmp     st_lead_done

st_lead_inc:
    inc     r10
    jmp     st_lead_loop

st_lead_done:
    ; ---- trim trailing ----
st_trail_loop:
    cmp     r11, r10
    jbe     st_all_trimmed               ; nothing but whitespace
    mov     al, [rcx + r11 - 1]          ; AL = base[j-1]
    cmp     al, 20h
    je      st_trail_dec
    cmp     al, 09h
    jb      st_trail_done
    cmp     al, 0Dh
    jbe     st_trail_dec
    jmp     st_trail_done

st_trail_dec:
    dec     r11
    jmp     st_trail_loop

st_trail_done:
    ; new_len = j - i
    mov     rax, r11
    sub     rax, r10
    ; if i==0 or new_len==0, no move needed
    test    rax, rax
    jz      st_ret_ok
    test    r10, r10
    jz      st_ret_ok

    ; shift left: dst = base, src = base + i, count = new_len
    mov     rdi, rcx                     ; dst
    lea     rsi, [rcx + r10]             ; src
    mov     rcx, rax                     ; count
    cld
    rep movsb                            ; forward copy safe (dst < src)

st_ret_ok:
    RET_OK

st_all_trimmed:
    xor     rax, rax                     ; 0
    RET_OK
str_trim ENDP


;________________________________________
; str_to_upper(base, len)
;________________________________________
; RCX = base  (pointer to bytes; modified in-place)
; RDX = len   (bytes to process)
;
; Returns (success):
;   CF=0, RAX = len processed (== len)
;
; Returns (error):
;   CF=1, EAX = ERR_* 
; Errors:
;   ERR_NULLPTR  if base == NULL
;
; Notes:
;   - ASCII-only transform: bytes in ['a'(0x61) .. 'z'(0x7A)] are mapped to
;     uppercase by subtracting 0x20. All other bytes are left unchanged.
;   - Binary-safe (no terminator added/required).
;   - len==0 is allowed and returns 0 (success).
;________________________________________
str_to_upper PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE

    ; validate pointer
    CHECK_NULL rcx, ERR_NULLPTR      ; base

    ; quick return for empty spans
    test    rdx, rdx
    jnz     stu_nonempty
    xor     rax, rax
    RET_OK

stu_nonempty:
    mov     rdi, rcx                 ; rdi = write/read ptr
    mov     rcx, rdx                 ; rcx = count
    mov     rax, rdx                 ; rax = return value (len)

stu_loop:
    movzx   r8d, byte ptr [rdi]      ; r8b = current byte
    cmp     r8b, 'a'                 ; < 'a' ?
    jb      stu_next
    cmp     r8b, 'z'                 ; > 'z' ?
    ja      stu_next
    sub     r8b, 20h                 ; 'a'..'z' -> 'A'..'Z'
    mov     byte ptr [rdi], r8b
stu_next:
    inc     rdi
    dec     rcx
    jnz     stu_loop

    RET_OK
str_to_upper ENDP


;________________________________________
; str_to_lower(base, len)
;________________________________________
; RCX = base  (pointer to bytes; modified in-place)
; RDX = len   (bytes to process)
;
; Returns (success):
;   CF=0, RAX = len processed (== len)
;
; Returns (error):
;   CF=1, EAX = ERR_* 
; Errors:
;   ERR_NULLPTR  if base == NULL
;
; Notes:
;   - ASCII-only transform: bytes in ['A'(0x41) .. 'Z'(0x5A)] are mapped to
;     lowercase by adding 0x20. All other bytes are left unchanged.
;   - Binary-safe (no terminator added/required).
;   - len==0 is allowed and returns 0 (success).
;________________________________________
str_to_lower PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE

    ; validate pointer
    CHECK_NULL rcx, ERR_NULLPTR      ; base

    ; quick return for empty spans
    test    rdx, rdx
    jnz     stl_nonempty
    xor     rax, rax
    RET_OK

stl_nonempty:
    mov     rdi, rcx                 ; rdi = write/read ptr
    mov     rcx, rdx                 ; rcx = count
    mov     rax, rdx                 ; rax = return value (len)

stl_loop:
    movzx   r8d, byte ptr [rdi]      ; r8b = current byte
    cmp     r8b, 'A'                 ; < 'A' ?
    jb      stl_next
    cmp     r8b, 'Z'                 ; > 'Z' ?
    ja      stl_next
    add     r8b, 20h                 ; 'A'..'Z' -> 'a'..'z'
    mov     byte ptr [rdi], r8b
stl_next:
    inc     rdi
    dec     rcx
    jnz     stl_loop

    RET_OK
str_to_lower ENDP


;________________________________________
; str_reverse(base, len)
;________________________________________
; RCX = base  (pointer to bytes; modified in-place)
; RDX = len   (bytes to reverse)
;
; Returns (success):
;   CF=0, RAX = len
;
; Returns (error):
;   CF=1, EAX = ERR_*
; Errors:
;   ERR_NULLPTR  if base == NULL
;
; Notes:
;   - Binary-safe: treats bytes as raw; no terminator required/added.
;   - len==0 or len==1 => no-op with success.
;   - Uses two-pointer swap from ends; O(len), in-place.
;________________________________________
str_reverse PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE

    ; validate pointer
    CHECK_NULL rcx, ERR_NULLPTR          ; base

    ; quick outs
    mov     rax, rdx                     ; return = len
    test    rdx, rdx
    jz      sr_done_ok                   ; len==0
    cmp     rdx, 1
    je      sr_done_ok                   ; len==1

    ; rdi -> front, rsi -> back, rcx = swaps = len/2
    mov     rdi, rcx                     ; rdi = base
    lea     rsi, [rcx + rdx - 1]         ; rsi = base + len - 1
    mov     rcx, rdx
    shr     rcx, 1                       ; number of swaps

sr_loop:
    mov     r8b,  [rdi]
    mov     r9b,  [rsi]
    mov     [rdi], r9b
    mov     [rsi], r8b
    inc     rdi
    dec     rsi
    dec     rcx
    jnz     sr_loop

sr_done_ok:
    RET_OK
str_reverse ENDP


;________________________________________
; str_fill(base, len, ch)
;________________________________________
; RCX = base  (pointer to bytes; modified in-place)
; RDX = len   (bytes to write)
; R8  = byteval    (byte value to store; low 8 bits used)
;
; Returns (success):
;   CF=0, RAX = len
;
; Returns (error):
;   CF=1, EAX = ERR_*
; Errors:
;   ERR_NULLPTR  if base == NULL
;
; Notes:
;   - Binary-safe: writes exactly 'len' bytes of value (R8B).
;   - len==0 is allowed (no writes), returns 0 with success.
;________________________________________
str_fill PROC base:QWORD, len:QWORD, byteval:QWORD
    SAFE_PROLOGUE

    ; validate
    CHECK_NULL rcx, ERR_NULLPTR          ; base

    ; return value = len
    mov     rax, rdx
    test    rdx, rdx
    jz      sf_done_ok                   ; nothing to write

    ; rdi = dst, rcx = count, r9b = byte to write
    mov     rdi, rcx
    mov     rcx, rdx
    mov     r9b, r8b

sf_loop:
    mov     byte ptr [rdi], r9b
    inc     rdi
    dec     rcx
    jnz     sf_loop

sf_done_ok:
    RET_OK
str_fill ENDP


; =====================
; Search & Replace
; =====================

;________________________________________
; str_find_char(base, len, byteval)
;________________________________________
; RCX = base     (pointer to bytes; read-only)
; RDX = len      (bytes to scan)
; R8  = byteval  (target byte; low 8 bits used)
;
; Returns (success):
;   CF=0, RAX = index (0..len-1) of first occurrence, or STR_NPOS if not found
;
; Returns (error):
;   CF=1, EAX = ERR_*
; Errors:
;   ERR_NULLPTR  if base == NULL
;
; Notes:
;   - Binary-safe; scans raw bytes (NUL is just a byte).
;   - len==0 is allowed and returns STR_NPOS (success).
;   - No over-read: only examines 'len' bytes.
;________________________________________
str_find_char PROC base:QWORD, len:QWORD, byteval:QWORD
    SAFE_PROLOGUE

    ; validate pointer
    CHECK_NULL rcx, ERR_NULLPTR          ; base

    ; quick out for empty spans
    test    rdx, rdx
    jnz     sfc_scan
    mov     rax, STR_NPOS
    RET_OK

sfc_scan:
    mov     rsi, rcx                     ; keep base for index math
    mov     rdi, rcx                     ; scan pointer
    mov     rcx, rdx                     ; count = len
    mov     al,  r8b                     ; AL = target byte
    cld
    repne   scasb                        ; stop if found (ZF=1) or rcx==0

    jnz     sfc_notfound                 ; ZF=0 => not found within 'len'

    ; found: rdi points just past the matched byte
    lea     rax, [rdi-1]                 ; address of match
    sub     rax, rsi                     ; index = (rdi-1) - base
    RET_OK

sfc_notfound:
    mov     rax, STR_NPOS
    RET_OK
str_find_char ENDP


;________________________________________
; str_replace_char(base, len, oldch, newch)
;________________________________________
; RCX = base   (pointer to bytes; modified in-place)
; RDX = len    (bytes to scan)
; R8  = oldch  (target byte; low 8 bits used)
; R9  = newch  (replacement byte; low 8 bits used)
;
; Returns (success):
;   CF=0, RAX = number of bytes replaced (0..len)
;
; Returns (error):
;   CF=1, EAX = ERR_*
; Errors:
;   ERR_NULLPTR  if base == NULL
;
; Notes:
;   - Binary-safe (NUL is just a byte).
;   - len==0 is allowed and returns 0 (success).
;   - If oldch == newch, buffer is left unchanged; RAX = count of occurrences.
;________________________________________
str_replace_char PROC base:QWORD, len:QWORD, oldch:QWORD, newch:QWORD
    SAFE_PROLOGUE

    ; validate
    CHECK_NULL rcx, ERR_NULLPTR          ; base

    ; fast path for empty span
    xor     rax, rax                     ; rax = replacement count
    test    rdx, rdx
    jz      src_done_ok

    ; setup
    mov     rdi, rcx                     ; rdi = p
    mov     rcx, rdx                     ; rcx = remaining
    mov     r10b, r8b                    ; r10b = oldch
    mov     r11b, r9b                    ; r11b = newch

    ; loop
src_loop:
    mov     r8b, [rdi]
    cmp     r8b, r10b
    jne     src_next
    ; match
    cmp     r10b, r11b
    je      src_count_only               ; old==new: don't write, just count
    mov     [rdi], r11b
src_count_only:
    inc     rax
src_next:
    inc     rdi
    dec     rcx
    jnz     src_loop

src_done_ok:
    RET_OK
str_replace_char ENDP


END
