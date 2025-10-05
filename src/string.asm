
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
;   CF=0, RAX = new length (== src_len)   ; success
;   CF=1, EAX = ARR_ERR_*                 ; error
; Errors:
;   ARR_ERR_NULLPTR    if dst == NULL or src == NULL
;   ARR_ERR_LEN_ZERO   if src_len == 0
;   ARR_ERR_CAPACITY   if src_len > dst_cap
; Notes:
;   - Copies exactly src_len bytes (no terminator added).
;   - Overlap-safe (memmove semantics): direction chosen automatically.
;   - Length units are BYTES.
;________________________________________
str_copy PROC dst:QWORD, dst_cap:QWORD, src:QWORD, src_len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=dst, RDX=dst_cap, R8=src, R9=src_len

    ; required pointers
    CHECK_NULL rcx, ARR_ERR_NULLPTR        ; dst
    CHECK_NULL r8,  ARR_ERR_NULLPTR        ; src

    ; src_len must be > 0
    CHECK_LEN_NONZERO r9, ARR_ERR_LEN_ZERO

    ; capacity: src_len <= dst_cap
    CHECK_CAPACITY r9, rdx, ARR_ERR_CAPACITY

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


str_concat PROC dst:QWORD, dst_len:QWORD, dst_cap:QWORD, src:QWORD, src_len:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_concat ENDP

; =====================
; Length & Compare
; =====================

str_length PROC base:QWORD, max_scan:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
str_length ENDP

str_compare PROC a:QWORD, a_len:QWORD, b:QWORD, b_len:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
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
