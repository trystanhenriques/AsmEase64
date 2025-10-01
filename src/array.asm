
; Make case sensitive
OPTION casemap:none
OPTION prologue:none, epilogue:none     ; we use SAFE_PROLOGUE/SAFE_EPILOGUE

INCLUDE array.inc

.code
; -------------------------
; arr_get_value(base,len,i)
; Success: CF=0, RAX=value
; Errors:  CF=1, EAX=MYLIB_ERR_*
arr_get_value PROC base:QWORD, len:QWORD, index:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR   ; placeholder so file assembles; remove when implemented
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
