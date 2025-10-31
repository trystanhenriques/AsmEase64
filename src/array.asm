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
;   CF=1, EAX = ERR_*            ; error
; Errors:
;   ERR_NULLPTR     if base == NULL
;   ERR_LEN_ZERO    if len  == 0
;   ERR_OUT_OF_RANGE if index >= len
;________________________________________
arr_get_value PROC base:QWORD, len:QWORD, index:QWORD
    SAFE_PROLOGUE
    ; RCX=base, RDX=len, R8=index  (Win64)

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
_len_ok:

    ; 0 <= index < len
    cmp  r8, rdx
    jb   _in_range
      RET_ERR ERR_OUT_OF_RANGE
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
;   CF=1, EAX = ERR_*        ; error
; Errors:
;   ERR_NULLPTR     if base == NULL
;   ERR_LEN_ZERO    if len  == 0
;   ERR_OUT_OF_RANGE  if index >= len
;_______________________________________
arr_set_value PROC base:QWORD, len:QWORD, index:QWORD, value:QWORD
    SAFE_PROLOGUE
    ; Win64 regs:
    ;    RCX=base, RDX=len, R8=index, R9=value

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
_len_ok:

    ; bounds: index < len
    cmp  r8, rdx
    jb   _in_range
      RET_ERR ERR_OUT_OF_RANGE
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
;   CF=1, EAX = ERR_*        ; error
; Errors:
;   ERR_NULLPTR     if base == NULL
;   ERR_LEN_ZERO    if len  == 0
;__________________________________________________________
arr_fill PROC base:QWORD, len:QWORD, value:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len, R8=value

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
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
;   CF=1, EAX = ERR_*         ; error
; Errors:
;   ERR_NULLPTR     if dst == NULL or src == NULL
;   ERR_LEN_ZERO    if len  == 0
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
    RET_ERR ERR_NULLPTR

_len_zero:
    RET_ERR ERR_LEN_ZERO
arr_copy ENDP

;____________________________________________
; arr_reverse(base,len)
;____________________________________________
; Returns:
;   CF=0                      ; success
;   CF=1, EAX = ERR_*         ; error
; Errors:
;   ERR_NULLPTR     if base == NULL
;   ERR_LEN_ZERO    if len  == 0
;____________________________________________
arr_reverse PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
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

;__________________________________________________________
; arr_swap(base,len,i,j)
;__________________________________________________________
; Returns:
;   CF=0                      ; success
;   CF=1, EAX = ERR_*         ; error
; Errors:
;   ERR_NULLPTR     if base == NULL
;   ERR_LEN_ZERO    if len  == 0
;   ERR_OUT_OF_RANGE  if i >= len or j >= len
; Notes:
;   No-op if i == j.
;__________________________________________________________
arr_swap PROC base:QWORD, len:QWORD, i:QWORD, j:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len, R8=i, R9=j

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
_len_ok:

    ; bounds: i < len, j < len
    cmp  r8, rdx
    jb   _i_ok
      RET_ERR ERR_OUT_OF_RANGE
_i_ok:
    cmp  r9, rdx
    jb   _j_ok
      RET_ERR ERR_OUT_OF_RANGE
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
;   CF=1, EAX = ERR_*
; Errors:
;   ERR_NULLPTR   if base == NULL
;   ERR_LEN_ZERO  if len  == 0
; Notes:
;   Unsigned comparison (cmova). Works fine for nonnegative data.
; _____________________________________________________
arr_max PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
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

;__________________________________________
; arr_min(base,len)
;__________________________________________
; Returns:
;   CF=0, RAX = min (unsigned compare)
;   CF=1, EAX = ERR_*    ; error
; Errors:
;   ERR_NULLPTR  if base == NULL
;   ERR_LEN_ZERO if len  == 0
; Notes:
;   Compares as UNSIGNED (use cmovb). For signed variant, use arr_smin.
;__________________________________________
arr_min PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
_len_ok:

    ; Initialize min with first element
    mov  rax, [rcx]          ; current min in RAX

    ; If only one element, we’re done
    cmp  rdx, 1
    je   _ok

    ; Walk the rest: pointer in R9, count in RDX (len-1), temp in R10
    lea  r9,  [rcx+8]        ; next element
    dec  rdx                  ; remaining count
_min_loop:
    mov  r10, [r9]
    cmp  r10, rax
    cmovb rax, r10            ; unsigned: take if r10 < rax
    add  r9, 8
    dec  rdx
    jnz  _min_loop

_ok:
    RET_OK
arr_min ENDP



;_________________________________________
; arr_index_of_max(base,len)
;_________________________________________
; Returns:
;   CF=0, RAX = index of maximum element (unsigned compare; first occurrence on ties)
;   CF=1, EAX = ERR_*    ; error
; Errors:
;   ERR_NULLPTR  if base == NULL
;   ERR_LEN_ZERO if len  == 0
;_________________________________________
arr_index_of_max PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
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
;   CF=1, EAX = ERR_*    ; error
; Errors:
;   ERR_NULLPTR  if base == NULL
;   ERR_LEN_ZERO if len  == 0
;_____________________________________________________________
arr_index_of_min PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
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

;________________________________________________________________
; arr_smax(base,len)
;________________________________________________________________
; Returns:
;   CF=0, RAX = signed maximum (two's-complement, first occurrence on ties)
;   CF=1, EAX = ERR_*        ; error
; Errors:
;   ERR_NULLPTR  if base == NULL
;   ERR_LEN_ZERO if len  == 0
;________________________________________________________________
arr_smax PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
_len_ok:

    ; initialize with first element
    mov  rax, [rcx]          ; current signed max

    ; if only one element, done
    cmp  rdx, 1
    je   _ok

    ; scan remaining elements using signed compare
    lea  r9,  [rcx+8]        ; ptr to next element
    dec  rdx                 ; remaining count
_smax_loop:
    mov  r10, [r9]
    cmp  r10, rax
    cmovg rax, r10           ; signed: take if r10 > rax
    add  r9, 8
    dec  rdx
    jnz  _smax_loop

_ok:
    RET_OK
arr_smax ENDP

;________________________________________________
; arr_smin(base,len)
;________________________________________________
; Returns:
;   CF=0, RAX = signed minimum (two's-complement)
;   CF=1, EAX = ERR_*        ; error
; Errors:
;   ERR_NULLPTR  if base == NULL
;   ERR_LEN_ZERO if len  == 0
;________________________________________________
arr_smin PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
_len_ok:

    ; initialize with first element
    mov  rax, [rcx]          ; current signed min

    ; if only one element, done
    cmp  rdx, 1
    je   _ok

    ; scan remaining elements using signed compare
    lea  r9,  [rcx+8]        ; ptr to next element
    dec  rdx                 ; remaining count
_smin_loop:
    mov  r10, [r9]
    cmp  r10, rax
    cmovl rax, r10           ; signed: take if r10 < rax
    add  r9, 8
    dec  rdx
    jnz  _smin_loop

_ok:
    RET_OK
arr_smin ENDP

;_______________________________________________________
; arr_index_of_smax(base,len)
;_______________________________________________________
; Returns:
;   CF=0, RAX = index of signed max (two's-complement; first occurrence on ties)
;   CF=1, EAX = ERR_*        ; error
; Errors:
;   ERR_NULLPTR  if base == NULL
;   ERR_LEN_ZERO if len  == 0
;_______________________________________________________
arr_index_of_smax PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
_len_ok:

    ; current max value in R8 (signed), index in R10
    mov  r8,  [rcx]          ; max value
    xor  r10, r10            ; max index = 0

    cmp  rdx, 1
    je   _ret_ok             ; len==1 -> index 0

    lea  r9,  [rcx+8]        ; ptr to next element
    mov  r11, 1              ; loop index i = 1
    mov  rax, rdx
    dec  rax                 ; remaining = len-1

_loop:
    mov  rdx, [r9]           ; candidate
    cmp  rdx, r8
    jle  _skip               ; signed: update only if candidate > current max
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
arr_index_of_smax ENDP

;_______________________________________
; arr_index_of_smin(base,len)
;_______________________________________
; Returns:
;   CF=0, RAX = index of signed min (two's-complement; first occurrence on ties)
;   CF=1, EAX = ERR_*        ; error
; Errors:
;   ERR_NULLPTR  if base == NULL
;   ERR_LEN_ZERO if len  == 0
;_______________________________________
arr_index_of_smin PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    ; Win64: RCX=base, RDX=len

    ; base must be non-NULL
    test rcx, rcx
    jnz  _base_ok
      RET_ERR ERR_NULLPTR
_base_ok:

    ; len must be > 0
    test rdx, rdx
    jnz  _len_ok
      RET_ERR ERR_LEN_ZERO
_len_ok:

    ; current min value in R8 (signed), index in R10
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
    jge  _skip               ; signed: update only if candidate < current min
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
arr_index_of_smin ENDP



END
