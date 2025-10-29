; header guard
IFNDEF MACROS_INC_GUARD
MACROS_INC_GUARD EQU 1

; Make case sensitive
OPTION casemap:none

; 32 bytes shadow + 8 for alignment = 40 bytes (0x28)
SAFE_PROLOGUE MACRO
    sub rsp, 28h
ENDM

; Preserve RFLAGS
SAFE_EPILOGUE MACRO
    lea rsp, [rsp+28h]   ; LEA does not modify flags
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

; Ensure a <= b; else return code (e.g., clamp requires min <= max)
CHECK_ORDER MACRO aReg:REQ, bReg:REQ, code:REQ
    cmp aReg, bReg
    jle @F
      RET_ERR code
@@:
ENDM


ENDIF ; end header guard