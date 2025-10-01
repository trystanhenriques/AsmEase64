
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

arr_set_value PROC base:QWORD, len:QWORD, index:QWORD, value:QWORD
    SAFE_PROLOGUE
    RET_ERR ARR_ERR_NULLPTR
arr_set_value ENDP

arr_fill PROC base:QWORD, len:QWORD, value:QWORD
    SAFE_PROLOGUE
    RET_ERR ARR_ERR_NULLPTR
arr_fill ENDP

arr_copy PROC dst:QWORD, src:QWORD, len:QWORD
    SAFE_PROLOGUE
    RET_ERR ARR_ERR_NULLPTR
arr_copy ENDP

arr_reverse PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    RET_ERR ARR_ERR_NULLPTR
arr_reverse ENDP

arr_swap PROC base:QWORD, len:QWORD, i:QWORD, j:QWORD
    SAFE_PROLOGUE
    RET_ERR ARR_ERR_NULLPTR
arr_swap ENDP

arr_max PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    RET_ERR ARR_ERR_LEN_ZERO
arr_max ENDP

arr_index_of_max PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    RET_ERR ARR_ERR_LEN_ZERO 
arr_index_of_max ENDP

arr_index_of_min PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    RET_ERR ARR_ERR_LEN_ZERO
arr_index_of_min ENDP


END
