
; Make case sensitive
OPTION casemap:none
INCLUDE x64AsmLib.inc

; -------------------------
; arr_get_value(base,len,i)
; Success: CF=0, RAX=value
; Errors:  CF=1, EAX=MYLIB_ERR_*
arr_get_value PROC
    SAFE_PROLOGUE
    ; body pending
    RET_ERR MYLIB_ERR_NULL_PTR   ; placeholder so file assembles; remove when implemented
arr_get_value ENDP

arr_set_value PROC
    SAFE_PROLOGUE
    RET_ERR MYLIB_ERR_NULL_PTR
arr_set_value ENDP

arr_fill PROC
    SAFE_PROLOGUE
    RET_ERR MYLIB_ERR_NULL_PTR
arr_fill ENDP

arr_copy PROC
    SAFE_PROLOGUE
    RET_ERR MYLIB_ERR_NULL_PTR
arr_copy ENDP

arr_reverse PROC
    SAFE_PROLOGUE
    RET_ERR MYLIB_ERR_NULL_PTR
arr_reverse ENDP

arr_swap PROC
    SAFE_PROLOGUE
    RET_ERR MYLIB_ERR_NULL_PTR
arr_swap ENDP

arr_max PROC
    SAFE_PROLOGUE
    RET_ERR MYLIB_ERR_LEN_ZERO
arr_max ENDP

arr_index_of_max PROC
    SAFE_PROLOGUE
    RET_ERR MYLIB_ERR_LEN_ZERO
arr_index_of_max ENDP

arr_index_of_min PROC
    SAFE_PROLOGUE
    RET_ERR MYLIB_ERR_LEN_ZERO
arr_index_of_min ENDP

END
