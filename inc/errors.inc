IFNDEF ERRORS_INC_GUARD ; header guard
ERRORS_INC_GUARD EQU 1

; make case sensitive
OPTION casemap:none

; --- common error codes (used by ALL modules; returned in EAX when CF=1)
ERR_OK               EQU 0
ERR_NULLPTR          EQU 1
ERR_OUT_OF_RANGE     EQU 2
ERR_LEN_ZERO         EQU 3
ERR_CAPACITY         EQU 4
ERR_OVERFLOW         EQU 5    ; arithmetic overflow (result does not fit)


; Back-compat aliases (so existing code keeps building)
ARR_OK                EQU 0    ; success (no error); operation completed, CF will be clear.
ARR_ERR_NULLPTR       EQU 1    ; a required pointer argument (ex. base/src/dst) was NULL (0).
ARR_ERR_OUTOFRANGE    EQU 2    ; index/offset was out of bounds (not in [0, len).
ARR_ERR_LEN_ZERO      EQU 3    ; length was zero where a non-empty array is required.
ARR_ERR_CAPACITY      EQU 4    ; insufficient capacity for the operation (ex. insert/append/shift).

; Random Errors
ERR_BADARG		  EQU 3	 ; bad argument (e.g., rand_range: max == 0)


ENDIF ; ERRORS_INC_GUARD
