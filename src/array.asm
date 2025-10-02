
; Make case sensitive
OPTION casemap:none
OPTION prologue:none, epilogue:none     ; we use SAFE_PROLOGUE/SAFE_EPILOGUE

INCLUDE array.inc

.code

;________________________________________
; arr_get_value(base,len,index)
;________________________________________
; Returns:
;   CF=0, RAX = value            ; success
;   CF=1, EAX = ARR_ERR_*        ; error
; Errors:
;   ARR_ERR_NULLPTR   if base == NULL
;   ARR_ERR_LEN_ZERO  if len  == 0
;   ARR_ERR_OUTOFRANGE if index >= len
;________________________________________
arr_get_value PROC base:QWORD, len:QWORD, index:QWORD
    SAFE_PROLOGUE
    ; RCX=base, RDX=len, R8=index  (Win64)

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ARR_ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ARR_ERR_LEN_ZERO
_len_ok:

    ; 0 <= index < len
    cmp  r8, rdx
    jb   _in_range
      RET_ERR ARR_ERR_OUTOFRANGE
_in_range:

    ; load QWORD element
    mov  rax, [rcx + r8*8]
    RET_OK
arr_get_value ENDP

;_______________________________________
; arr_set_value(base,len,index,value)
;_______________________________________
; Returns:
;   CF=0                     ; success
;   CF=1, EAX = ARR_ERR_*    ; error
; Errors:
;   ARR_ERR_NULLPTR     if base == NULL
;   ARR_ERR_LEN_ZERO    if len  == 0
;   ARR_ERR_OUTOFRANGE  if index >= len
;_______________________________________
arr_set_value PROC base:QWORD, len:QWORD, index:QWORD, value:QWORD
    SAFE_PROLOGUE
    ; Win64 regs:
    ;    RCX=base, RDX=len, R8=index, R9=value

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ARR_ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ARR_ERR_LEN_ZERO
_len_ok:

    ; bounds: index < len
    cmp  r8, rdx
    jb   _in_range
      RET_ERR ARR_ERR_OUTOFRANGE
_in_range:

    ; store the QWORD
    mov  [rcx + r8*8], r9

    RET_OK
arr_set_value ENDP

;__________________________________________________________
; arr_fill(base,len,value)
;__________________________________________________________
; Returns:
;   CF=0                     ; success
;   CF=1, EAX = ARR_ERR_*    ; error
; Errors:
;   ARR_ERR_NULLPTR     if base == NULL
;   ARR_ERR_LEN_ZERO    if len  == 0
;__________________________________________________________
arr_fill PROC base:QWORD, len:QWORD, value:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len, R8=value

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ARR_ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ARR_ERR_LEN_ZERO
_len_ok:

    ; Fast fill: rep stosq (writes RAX to [RDI], RCX times)
    ; RDI is non-volatile on Win64 -> preserve it.
    push rdi
    mov  rdi, rcx        ; dest = base
    mov  rax, r8         ; value to store
    mov  rcx, rdx        ; count = len (elements)
    cld                  ; forward direction
    rep stosq
    pop  rdi

    RET_OK
arr_fill ENDP

;__________________________________________________________
; arr_copy(dst, src, len)
;__________________________________________________________
; Returns:
;   CF=0                      ; success
;   CF=1, EAX = ARR_ERR_*     ; error
; Errors:
;   ARR_ERR_NULLPTR     if dst == NULL or src == NULL
;   ARR_ERR_LEN_ZERO    if len  == 0
; Behavior:
;   QWORD-wise copy of len elements (8 bytes each).
;   Overlap-safe (memmove semantics): chooses direction automatically.
;__________________________________________________________
arr_copy PROC dst:QWORD, src:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=dst, RDX=src, R8=len

    ; dst and src must be non-NULL
    test rcx, rcx
    jz   _null_err
    test rdx, rdx
    jz   _null_err

    ; len must be > 0
    test r8, r8
    jz   _len_zero

    ; dst == src -> no-op
    cmp  rcx, rdx
    je   _ok

    ; size in bytes = len * 8
    lea  r9, [r8*8]          ; r9 = byteCount

    ; Overlap check:
    ; If dst < src           -> forward copy
    ; If dst >= src+size     -> forward copy (no overlap)
    ; Else (dst in [src,src+size)) -> backward copy
    mov  r10, rcx            ; r10 = dst
    cmp  r10, rdx
    jb   _forward            ; dst < src

    lea  r11, [rdx + r9]     ; r11 = src_end
    cmp  r10, r11
    jae  _forward            ; dst >= src_end -> no overlap

    ; ---- backward copy (overlap with dst > src) ----
    push rdi                 ; preserve non-volatiles
    push rsi
    lea  rdi, [rcx + r9 - 8] ; dest = dst + (len-1)*8
    lea  rsi, [rdx + r9 - 8] ; src  = src + (len-1)*8
    mov  rcx, r8             ; count = len (elements)
    std
    rep movsq
    cld
    pop  rsi
    pop  rdi
    jmp  _ok

_forward:
    ; ---- forward copy ----
    push rdi
    push rsi
    mov  rdi, rcx            ; dest = dst
    mov  rsi, rdx            ; src  = src
    mov  rcx, r8             ; count = len
    cld
    rep movsq
    pop  rsi
    pop  rdi

_ok:
    RET_OK

_null_err:
    RET_ERR ARR_ERR_NULLPTR

_len_zero:
    RET_ERR ARR_ERR_LEN_ZERO
arr_copy ENDP

;____________________________________________
; arr_reverse(base,len)
;____________________________________________
; Returns:
;   CF=0                      ; success
;   CF=1, EAX = ARR_ERR_*     ; error
; Errors:
;   ARR_ERR_NULLPTR     if base == NULL
;   ARR_ERR_LEN_ZERO    if len  == 0
;____________________________________________
arr_reverse PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ARR_ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ARR_ERR_LEN_ZERO
_len_ok:

    ; Preserve non-volatiles we will use (RDI, RSI)
    push rdi
    push rsi

    ; Pointers to the ends
    mov  rdi, rcx                    ; left  = base
    lea  rsi, [rcx + rdx*8 - 8]      ; right = base + (len-1)*8

    ; Number of swaps = len / 2
    mov  rcx, rdx
    shr  rcx, 1
    jz   _done_pop_ok                ; len==1 (or 0, but zero handled above)

_rev_loop:
    ; swap *rdi and *rsi (QWORD)
    mov  rax, [rdi]
    mov  r10, [rsi]
    mov  [rdi], r10
    mov  [rsi], rax

    add  rdi, 8
    sub  rsi, 8
    dec  rcx
    jnz  _rev_loop

_done_pop_ok:
    pop  rsi
    pop  rdi
    RET_OK
arr_reverse ENDP

;_____________________________________________________
; arr_swap(base,len,i,j)
;_____________________________________________________
; Returns:
;   CF=0                      ; success
;   CF=1, EAX = ARR_ERR_*     ; error
; Errors:
;   ARR_ERR_NULLPTR     if base == NULL
;   ARR_ERR_LEN_ZERO    if len  == 0
;   ARR_ERR_OUTOFRANGE  if i >= len or j >= len
; Notes:
;   No-op if i == j.
;_____________________________________________________
arr_swap PROC base:QWORD, len:QWORD, i:QWORD, j:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len, R8=i, R9=j

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ARR_ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ARR_ERR_LEN_ZERO
_len_ok:

    ; bounds: i < len, j < len
    cmp  r8, rdx
    jb   _i_ok
      RET_ERR ARR_ERR_OUTOFRANGE
_i_ok:
    cmp  r9, rdx
    jb   _j_ok
      RET_ERR ARR_ERR_OUTOFRANGE
_j_ok:

    ; same index -> nothing to do
    cmp  r8, r9
    je   _ok

    ; swap QWORDs at indices i and j
    lea  r10, [rcx + r8*8]      ; &base[i]
    lea  r11, [rcx + r9*8]      ; &base[j]
    mov  rax, [r10]
    mov  rdx, [r11]
    mov  [r10], rdx
    mov  [r11], rax

_ok:
    RET_OK
arr_swap ENDP

; _____________________________________________________
; arr_max(base,len)
; _____________________________________________________
; Returns:
;   CF=0, RAX = maximum QWORD value (unsigned compare)
;   CF=1, EAX = ARR_ERR_*
; Errors:
;   ARR_ERR_NULLPTR   if base == NULL
;   ARR_ERR_LEN_ZERO  if len  == 0
; Notes:
;   Unsigned comparison (cmova). Works fine for nonnegative data.
; _____________________________________________________
arr_max PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ARR_ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ARR_ERR_LEN_ZERO
_len_ok:

    ; RAX := first element
    mov  rax, [rcx]
    cmp  rdx, 1
    je   _ok                      ; single element

    ; scan remaining len-1 elements
    lea  r10, [rcx+8]             ; ptr to second element
    mov  r11, rdx
    dec  r11                      ; remaining count

_max_loop:
    mov  r9, [r10]
    cmp  r9, rax
    cmova rax, r9                  ; unsigned: if r9 > rax, rax = r9
    add  r10, 8
    dec  r11
    jnz  _max_loop

_ok:
    RET_OK
arr_max ENDP

;_________________________________________
; arr_index_of_max(base,len)
;_________________________________________
; Returns:
;   CF=0, RAX = index of maximum element (unsigned compare; first occurrence on ties)
;   CF=1, EAX = ARR_ERR_*    ; error
; Errors:
;   ARR_ERR_NULLPTR  if base == NULL
;   ARR_ERR_LEN_ZERO if len  == 0
;_________________________________________
arr_index_of_max PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ARR_ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ARR_ERR_LEN_ZERO
_len_ok:

    ; Track current max value in R8, index in R10
    mov  r8,  [rcx]          ; current max value
    xor  r10, r10            ; current max index = 0

    cmp  rdx, 1
    je   _ret_ok             ; len==1 -> index 0

    lea  r9,  [rcx+8]        ; ptr to next element
    mov  r11, 1              ; loop index i = 1
    mov  rax, rdx
    dec  rax                 ; remaining = len-1

_loop:
    mov  rdx, [r9]           ; candidate
    cmp  rdx, r8
    jbe  _skip               ; unsigned: only update if candidate > current max
    mov  r8,  rdx
    mov  r10, r11
_skip:
    add  r9, 8
    inc  r11
    dec  rax
    jnz  _loop

_ret_ok:
    mov  rax, r10            ; return index
    RET_OK
arr_index_of_max ENDP

;_____________________________________________________________
; arr_index_of_min(base,len)
;_____________________________________________________________
; Returns:
;   CF=0, RAX = index of minimum element (unsigned compare; first occurrence on ties)
;   CF=1, EAX = ARR_ERR_*    ; error
; Errors:
;   ARR_ERR_NULLPTR  if base == NULL
;   ARR_ERR_LEN_ZERO if len  == 0
;_____________________________________________________________
arr_index_of_min PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ARR_ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ARR_ERR_LEN_ZERO
_len_ok:

    ; current min value in R8, index in R10
    mov  r8,  [rcx]          ; min value
    xor  r10, r10            ; min index = 0

    cmp  rdx, 1
    je   _ret_ok             ; len==1 -> index 0

    lea  r9,  [rcx+8]        ; ptr to next element
    mov  r11, 1              ; loop index i = 1
    mov  rax, rdx
    dec  rax                 ; remaining = len-1

_loop:
    mov  rdx, [r9]           ; candidate
    cmp  rdx, r8
    jae  _skip               ; unsigned: update only if candidate < min
    mov  r8,  rdx
    mov  r10, r11
_skip:
    add  r9, 8
    inc  r11
    dec  rax
    jnz  _loop

_ret_ok:
    mov  rax, r10            ; return index
    RET_OK
arr_index_of_min ENDP



END
