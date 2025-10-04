
; Make case sensitive and disable MASM's auto prologue/epilogue.
OPTION casemap:none
OPTION prologue:none, epilogue:none

INCLUDE string.inc

.code

; =====================
; Copy & Concatenate
; =====================

str_copy PROC dst:QWORD, dst_cap:QWORD, src:QWORD, src_len:QWORD
    SAFE_PROLOGUE
    ; body pending
    RET_ERR ARR_ERR_NULLPTR
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
