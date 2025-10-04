; header guard
IFNDEF MACROS_INC_GUARD
MACROS_INC_GUARD EQU 1

; Make case sensitive
OPTION casemap:none

; Reserve 32 bytes shadow space + 8 for 16-byte alignment at any nested call site
SAFE_PROLOGUE MACRO
    sub rsp, 40
ENDM

SAFE_EPILOGUE MACRO
    lea rsp, [rsp+40]    ; preserves RFLAGS
    ret
ENDM

; On error: CF=1, EAX=code
RET_ERR MACRO code:REQ
    mov eax, code
    stc
    SAFE_EPILOGUE
ENDM

; On success: CF=0
RET_OK MACRO
    clc
    SAFE_EPILOGUE
ENDM

; Null check: if reg==0 return error
CHECK_NULL MACRO reg:REQ, code:REQ
    test reg, reg
    jnz  @F
      RET_ERR code
@@:
ENDM

; Bounds check: if index >= len return error
CHECK_BOUNDS MACRO idxReg:REQ, lenReg:REQ, code:REQ
    cmp idxReg, lenReg
    jb  @F
      RET_ERR code
@@:
ENDM

; Ensure len != 0
CHECK_LEN_NONZERO MACRO lenReg:REQ, code:REQ
    test lenReg, lenReg
    jnz  @F
      RET_ERR code
@@:
ENDM

; Ensure "needed" bytes fit within "cap" bytes; else return code
CHECK_CAPACITY MACRO needReg:REQ, capReg:REQ, code:REQ
    cmp needReg, capReg
    jbe @F
      RET_ERR code
@@:
ENDM


ENDIF ; end header guard