; tests/arr_sanity.asm  -- pure ASM console tests for array module
; Paste this file and build/run the `tests` project.

OPTION casemap:none

; Umbrella header (brings macros, arr.inc, and WinAPI EXTERNs if declared there)
INCLUDE AsmEase64.inc
INCLUDE win32_console.inc

; Be explicit (safe even if already declared)
EXTERN GetStdHandle:PROC
EXTERN WriteConsoleA:PROC
EXTERN ExitProcess:PROC

.data
; Primary array used by get/set tests
arr            QWORD 10,20,30,40,50
len            QWORD 5

; Secondary array for fill tests (kept separate so prior tests are stable)
arr2           QWORD 1,2,3,4
len2           QWORD 4

stdoutHandle   QWORD 0

msgStart     db "Running array sanity tests...",13,10
msgStart_len EQU ($-msgStart)

msgT1       db "T1: get NULL base -> expect ERR_NULLPTR ... "
msgT1_len   EQU ($-msgT1)

msgT2       db "T2: get arr[2] -> expect RAX=30, CF=0 ... "
msgT2_len   EQU ($-msgT2)

msgT3       db "T3: get index==len -> expect ERR_OUT_OF_RANGE ... "
msgT3_len   EQU ($-msgT3)

; set() tests
msgT4       db "T4: set NULL base -> expect ERR_NULLPTR ... "
msgT4_len   EQU ($-msgT4)

msgT5       db "T5: set arr[3]=99 then get -> expect 99, CF=0 ... "
msgT5_len   EQU ($-msgT5)

msgT6       db "T6: set index==len -> expect ERR_OUT_OF_RANGE ... "
msgT6_len   EQU ($-msgT6)

msgT7       db "T7: set with len==0 -> expect ERR_LEN_ZERO ... "
msgT7_len   EQU ($-msgT7)

; fill() tests
msgT8       db "T8: fill NULL base -> expect ERR_NULLPTR ... "
msgT8_len   EQU ($-msgT8)

msgT9       db "T9: fill with len==0 -> expect ERR_LEN_ZERO ... "
msgT9_len   EQU ($-msgT9)

msgT10      db "T10: fill arr2 with 7 -> expect all 7s ... "
msgT10_len  EQU ($-msgT10)

msgPASS     db "PASS",13,10
msgPASS_len EQU ($-msgPASS)

msgFAIL     db "FAIL",13,10
msgFAIL_len EQU ($-msgFAIL)

; ---- arr_copy test data ----
arr3_src   QWORD 111,222,333,444
arr3_dst   QWORD 0,0,0,0
len3       QWORD 4

arr4       QWORD 1,2,3,4,5,6
len4       QWORD 6

arr5       QWORD 9,8,7,6,5,4
len5       QWORD 6

msgT11     db "T11: copy NULL dst -> expect ERR_NULLPTR ... "
msgT11_len EQU ($-msgT11)

msgT12     db "T12: copy NULL src -> expect ERR_NULLPTR ... "
msgT12_len EQU ($-msgT12)

msgT13     db "T13: copy with len==0 -> expect ERR_LEN_ZERO ... "
msgT13_len EQU ($-msgT13)

msgT14     db "T14: copy arr3_src->arr3_dst (no overlap) -> verify [0]==111,[3]==444 ... "
msgT14_len EQU ($-msgT14)

msgT15     db "T15: copy overlap right (arr4[1..5] <- arr4[0..4]) -> memmove-safe ... "
msgT15_len EQU ($-msgT15)

msgT16     db "T16: copy overlap left  (arr5[0..4] <- arr5[1..5]) -> memmove-safe ... "
msgT16_len EQU ($-msgT16)

; ---- arr_reverse test data ----
arr6_even   QWORD 1,2,3,4,5,6
len6        QWORD 6

arr7_odd    QWORD 10,20,30,40,50
len7        QWORD 5

arr1_single QWORD 12345
len1        QWORD 1

msgT17     db "T17: reverse NULL base -> expect ERR_NULLPTR ... "
msgT17_len EQU ($-msgT17)

msgT18     db "T18: reverse len==0 -> expect ERR_LEN_ZERO ... "
msgT18_len EQU ($-msgT18)

msgT19     db "T19: reverse len==1 -> expect success and unchanged ... "
msgT19_len EQU ($-msgT19)

msgT20     db "T20: reverse even len (1..6) -> expect 6..1 ... "
msgT20_len EQU ($-msgT20)

msgT21     db "T21: reverse odd len (10..50) -> expect 50,40,30,20,10 ... "
msgT21_len EQU ($-msgT21)


; ---- arr_swap test data ----
arr8       QWORD 100,200,300,400
len8       QWORD 4

msgT22     db "T22: swap NULL base -> expect ERR_NULLPTR ... "
msgT22_len EQU ($-msgT22)

msgT23     db "T23: swap with len==0 -> expect ERR_LEN_ZERO ... "
msgT23_len EQU ($-msgT23)

msgT24     db "T24: swap out-of-range (i==len) -> expect ERR_OUT_OF_RANGE ... "
msgT24_len EQU ($-msgT24)

msgT25     db "T25: swap same index (2,2) -> success and unchanged (arr8[2]==300) ... "
msgT25_len EQU ($-msgT25)

msgT26     db "T26: swap indices 0 and 3 -> expect arr8[0]=400, arr8[3]=100 ... "
msgT26_len EQU ($-msgT26)


; ---- arr_max test data ----
arr9        QWORD 5,9,3,12,7
len9        QWORD 5

arr10_one   QWORD 123456789
len10       QWORD 1

arr11_big   QWORD 0, -2, -1          ; as unsigned: 0, 0xFFFFFFFFFFFFFFFE, 0xFFFFFFFFFFFFFFFF
len11       QWORD 3

msgT27     db "T27: max NULL base -> expect ERR_NULLPTR ... "
msgT27_len EQU ($-msgT27)

msgT28     db "T28: max len==0 -> expect ERR_LEN_ZERO ... "
msgT28_len EQU ($-msgT28)

msgT29     db "T29: max len==1 -> expect RAX==123456789, CF=0 ... "
msgT29_len EQU ($-msgT29)

msgT30     db "T30: max of {5,9,3,12,7} -> expect 12 ... "
msgT30_len EQU ($-msgT30)

msgT31     db "T31: max (unsigned) of {0, -2, -1} -> expect 0xFFFFFFFFFFFFFFFF ... "
msgT31_len EQU ($-msgT31)

; ---- arr_index_of_max test data ----
arr16_dups  QWORD 4,9,9,2
len16       QWORD 4

msgT32     db "T32: index_of_max NULL base -> expect ERR_NULLPTR ... "
msgT32_len EQU ($-msgT32)

msgT33     db "T33: index_of_max len==0 -> expect ERR_LEN_ZERO ... "
msgT33_len EQU ($-msgT33)

msgT34     db "T34: index_of_max len==1 -> expect index 0 ... "
msgT34_len EQU ($-msgT34)

msgT35     db "T35: index_of_max {5,9,3,12,7} -> expect 3 ... "
msgT35_len EQU ($-msgT35)

msgT36     db "T36: index_of_max unsigned {0,-2,-1} -> expect 2 ... "
msgT36_len EQU ($-msgT36)

msgT37     db "T37: index_of_max with duplicates {4,9,9,2} -> expect first index 1 ... "
msgT37_len EQU ($-msgT37)

; ---- arr_index_of_min test data ----
arr17_dups_min  QWORD 4,1,1,2
len17           QWORD 4

msgT38     db "T38: index_of_min NULL base -> expect ERR_NULLPTR ... "
msgT38_len EQU ($-msgT38)

msgT39     db "T39: index_of_min len==0 -> expect ERR_LEN_ZERO ... "
msgT39_len EQU ($-msgT39)

msgT40     db "T40: index_of_min len==1 -> expect index 0 ... "
msgT40_len EQU ($-msgT40)

msgT41     db "T41: index_of_min {5,9,3,12,7} -> expect 2 ... "
msgT41_len EQU ($-msgT41)

msgT42     db "T42: index_of_min unsigned {0,-2,-1} -> expect 0 ... "
msgT42_len EQU ($-msgT42)

msgT43     db "T43: index_of_min duplicates {4,1,1,2} -> expect first index 1 ... "
msgT43_len EQU ($-msgT43)

; ---- arr_smax test data ----
arr12_mix     QWORD -10, 5, -3, 2
len12         QWORD 4

arr14_one     QWORD -42
len14         QWORD 1

arr15_edges   QWORD 8000000000000000h, 7FFFFFFFFFFFFFFFh  ; INT64_MIN, INT64_MAX

msgT44     db "T44: smax NULL base -> expect ERR_NULLPTR ... "
msgT44_len EQU ($-msgT44)

msgT45     db "T45: smax len==0 -> expect ERR_LEN_ZERO ... "
msgT45_len EQU ($-msgT45)

msgT46     db "T46: smax len==1 (-42) -> expect -42, CF=0 ... "
msgT46_len EQU ($-msgT46)

msgT47     db "T47: smax signed {0,-2,-1} -> expect 0 ... "
msgT47_len EQU ($-msgT47)

msgT48     db "T48: smax signed {-10,5,-3,2} -> expect 5 ... "
msgT48_len EQU ($-msgT48)

msgT49     db "T49: smax edges {INT64_MIN, INT64_MAX} -> expect 0x7FFFFFFFFFFFFFFF ... "
msgT49_len EQU ($-msgT49)


; ---- arr_smin test data ----
msgT50     db "T50: smin NULL base -> expect ERR_NULLPTR ... "
msgT50_len EQU ($-msgT50)

msgT51     db "T51: smin len==0 -> expect ERR_LEN_ZERO ... "
msgT51_len EQU ($-msgT51)

msgT52     db "T52: smin len==1 (-42) -> expect -42, CF=0 ... "
msgT52_len EQU ($-msgT52)

msgT53     db "T53: smin signed {0,-2,-1} -> expect -2 ... "
msgT53_len EQU ($-msgT53)

msgT54     db "T54: smin signed {-10,5,-3,2} -> expect -10 ... "
msgT54_len EQU ($-msgT54)

msgT55     db "T55: smin edges {INT64_MIN, INT64_MAX} -> expect 0x8000000000000000 ... "
msgT55_len EQU ($-msgT55)

; ---- arr_index_of_smax test data ----
arr18_dups_smax  QWORD -5, 3, 3, -1
len18            QWORD 4

msgT56     db "T56: index_of_smax NULL base -> expect ERR_NULLPTR ... "
msgT56_len EQU ($-msgT56)

msgT57     db "T57: index_of_smax len==0 -> expect ERR_LEN_ZERO ... "
msgT57_len EQU ($-msgT57)

msgT58     db "T58: index_of_smax len==1 (-42) -> expect 0 ... "
msgT58_len EQU ($-msgT58)

msgT59     db "T59: index_of_smax signed {-10,5,-3,2} -> expect 1 ... "
msgT59_len EQU ($-msgT59)

msgT60     db "T60: index_of_smax signed {0,-2,-1} -> expect 0 ... "
msgT60_len EQU ($-msgT60)

msgT61     db "T61: index_of_smax edges {INT64_MIN, INT64_MAX} -> expect 1 ... "
msgT61_len EQU ($-msgT61)

msgT62     db "T62: index_of_smax duplicates {-5,3,3,-1} -> expect first index 1 ... "
msgT62_len EQU ($-msgT62)

; ---- arr_index_of_smin test data ----
arr19_dups_smin  QWORD 2, -7, -7, 0
len19            QWORD 4

msgT63     db "T63: index_of_smin NULL base -> expect ERR_NULLPTR ... "
msgT63_len EQU ($-msgT63)

msgT64     db "T64: index_of_smin len==0 -> expect ERR_LEN_ZERO ... "
msgT64_len EQU ($-msgT64)

msgT65     db "T65: index_of_smin len==1 (-42) -> expect 0 ... "
msgT65_len EQU ($-msgT65)

msgT66     db "T66: index_of_smin signed {-10,5,-3,2} -> expect 0 ... "
msgT66_len EQU ($-msgT66)

msgT67     db "T67: index_of_smin signed {0,-2,-1} -> expect 1 ... "
msgT67_len EQU ($-msgT67)

msgT68     db "T68: index_of_smin edges {INT64_MIN, INT64_MAX} -> expect 0 ... "
msgT68_len EQU ($-msgT68)

msgT69     db "T69: index_of_smin duplicates {2,-7,-7,0} -> expect first index 1 ... "
msgT69_len EQU ($-msgT69)

; ---- arr_min (unsigned) test data ----
; (reuses existing arrays: arr9 {5,9,3,12,7}, arr10_one {123456789},
;  arr11_big {0,-2,-1}, arr15_edges {INT64_MIN, INT64_MAX})

msgT70     db "T70: min NULL base -> expect ERR_NULLPTR ... "
msgT70_len EQU ($-msgT70)

msgT71     db "T71: min len==0 -> expect ERR_LEN_ZERO ... "
msgT71_len EQU ($-msgT71)

msgT72     db "T72: min len==1 (123456789) -> expect 123456789, CF=0 ... "
msgT72_len EQU ($-msgT72)

msgT73     db "T73: min unsigned of {5,9,3,12,7} -> expect 3 ... "
msgT73_len EQU ($-msgT73)

msgT74     db "T74: min unsigned of {0,-2,-1} -> expect 0 ... "
msgT74_len EQU ($-msgT74)

msgT75     db "T75: min unsigned of {INT64_MIN, INT64_MAX} -> expect 0x7FFFFFFFFFFFFFFF ... "
msgT75_len EQU ($-msgT75)



.code
main PROC
    ; Standard Win64 shadow space + alignment
    sub rsp, 40

    ; Get stdout handle
    mov  ecx, -11                 ; STD_OUTPUT_HANDLE
    call GetStdHandle
    mov  [stdoutHandle], rax

    ; print "Running..." line
    mov  rcx, [stdoutHandle]
    lea  rdx, msgStart
    mov  r8d, msgStart_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0   ; 5th arg to WriteConsoleA (lpReserved)
    call WriteConsoleA

    ; ===== T1: get NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT1
    mov  r8d, msgT1_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                  ; base = NULL
    mov  rdx, 5                    ; len
    mov  r8,  2                    ; index
    call arr_get_value
    jnc  t1_fail
    cmp  eax, ERR_NULLPTR
    jne  t1_fail
t1_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t2_begin
t1_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t2_begin:
    ; ===== T2: get arr[2] -> 30 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT2
    mov  r8d, msgT2_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr
    mov  rdx, 5
    mov  r8,  2
    call arr_get_value
    jc   t2_fail
    cmp  rax, 30
    jne  t2_fail
t2_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t3_begin
t2_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t3_begin:
    ; ===== T3: get index==len -> OUT_OF_RANGE =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT3
    mov  r8d, msgT3_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr
    mov  rdx, 5
    mov  r8,  5                    ; index == len
    call arr_get_value
    jnc  t3_fail
    cmp  eax, ERR_OUT_OF_RANGE
    jne  t3_fail
t3_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t4_begin
t3_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t4_begin:
    ; ===== T4: set NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT4
    mov  r8d, msgT4_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                  ; base = NULL
    mov  rdx, 5
    mov  r8,  1
    mov  r9,  77
    call arr_set_value
    jnc  t4_fail
    cmp  eax, ERR_NULLPTR
    jne  t4_fail
t4_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t5_begin
t4_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t5_begin:
    ; ===== T5: set arr[3]=99 then get -> 99 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT5
    mov  r8d, msgT5_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr
    mov  rdx, 5
    mov  r8,  3
    mov  r9,  99
    call arr_set_value
    jc   t5_fail                    ; success expected

    ; read back arr[3]
    lea  rcx, arr
    mov  rdx, 5
    mov  r8,  3
    call arr_get_value
    jc   t5_fail
    cmp  rax, 99
    jne  t5_fail
t5_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t6_begin
t5_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t6_begin:
    ; ===== T6: set index==len -> OUT_OF_RANGE =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT6
    mov  r8d, msgT6_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr
    mov  rdx, 5
    mov  r8,  5                    ; index == len
    mov  r9,  11
    call arr_set_value
    jnc  t6_fail
    cmp  eax, ERR_OUT_OF_RANGE
    jne  t6_fail
t6_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t7_begin
t6_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t7_begin:
    ; ===== T7: set with len==0 -> LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT7
    mov  r8d, msgT7_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    ; len==0 means no valid indices; base value irrelevant
    lea  rcx, arr
    xor  rdx, rdx                  ; len = 0
    xor  r8,  r8                   ; index = 0
    mov  r9,  55
    call arr_set_value
    jnc  t7_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t7_fail
t7_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t8_begin
t7_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t8_begin:
    ; ===== T8: fill NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT8
    mov  r8d, msgT8_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                  ; base = NULL
    mov  rdx, 4                    ; len
    mov  r8,  7                    ; value
    call arr_fill
    jnc  t8_fail
    cmp  eax, ERR_NULLPTR
    jne  t8_fail
t8_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t9_begin
t8_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t9_begin:
    ; ===== T9: fill with len==0 -> LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT9
    mov  r8d, msgT9_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr2
    xor  rdx, rdx                  ; len = 0
    mov  r8,  7
    call arr_fill
    jnc  t9_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t9_fail
t9_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t10_begin
t9_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t10_begin:
    ; ===== T10: fill arr2 with 7 -> verify arr2[0] and arr2[3] == 7 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT10
    mov  r8d, msgT10_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    ; call fill
    lea  rcx, arr2
    mov  rdx, 4
    mov  r8,  7
    call arr_fill
    jc   t10_fail                  ; must succeed

    ; verify arr2[0] == 7
    lea  rcx, arr2
    mov  rdx, 4
    xor  r8,  r8
    call arr_get_value
    jc   t10_fail
    cmp  rax, 7
    jne  t10_fail

    ; verify arr2[3] == 7
    lea  rcx, arr2
    mov  rdx, 4
    mov  r8,  3
    call arr_get_value
    jc   t10_fail
    cmp  rax, 7
    jne  t10_fail

t10_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t11_begin

t10_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    jmp  t11_begin

t11_begin:
    ; ===== T11: copy NULL dst -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT11
    mov  r8d, msgT11_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                 ; dst = NULL
    lea  rdx, arr3_src            ; src
    mov  r8,  4                   ; len
    call arr_copy
    jnc  t11_fail
    cmp  eax, ERR_NULLPTR
    jne  t11_fail
t11_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t12_begin
t11_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t12_begin:
    ; ===== T12: copy NULL src -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT12
    mov  r8d, msgT12_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr3_dst            ; dst
    xor  rdx, rdx                 ; src = NULL
    mov  r8,  4
    call arr_copy
    jnc  t12_fail
    cmp  eax, ERR_NULLPTR
    jne  t12_fail
t12_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t13_begin
t12_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t13_begin:
    ; ===== T13: copy with len==0 -> LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT13
    mov  r8d, msgT13_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr3_dst
    lea  rdx, arr3_src
    xor  r8,  r8                  ; len = 0
    call arr_copy
    jnc  t13_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t13_fail
t13_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t14_begin
t13_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t14_begin:
    ; ===== T14: copy arr3_src -> arr3_dst (no overlap) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT14
    mov  r8d, msgT14_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr3_dst
    lea  rdx, arr3_src
    mov  r8,  4
    call arr_copy
    jc   t14_fail

    ; verify dst[0] == 111
    lea  rcx, arr3_dst
    mov  rdx, 4
    xor  r8,  r8
    call arr_get_value
    jc   t14_fail
    cmp  rax, 111
    jne  t14_fail

    ; verify dst[3] == 444
    lea  rcx, arr3_dst
    mov  rdx, 4
    mov  r8,  3
    call arr_get_value
    jc   t14_fail
    cmp  rax, 444
    jne  t14_fail
t14_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t15_begin
t14_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t15_begin:
    ; ===== T15: overlap right shift (dst = &arr4[1], src = &arr4[0], len=5) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT15
    mov  r8d, msgT15_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr4
    add  rcx, 8                   ; dst = &arr4[1]
    lea  rdx, arr4                ; src = &arr4[0]
    mov  r8,  5
    call arr_copy
    jc   t15_fail

    ; After memmove-right: arr4 -> [1,1,2,3,4,5]
    ; check arr4[1] == 1 and arr4[5] == 5
    lea  rcx, arr4
    mov  rdx, 6
    mov  r8,  1
    call arr_get_value
    jc   t15_fail
    cmp  rax, 1
    jne  t15_fail

    lea  rcx, arr4
    mov  rdx, 6
    mov  r8,  5
    call arr_get_value
    jc   t15_fail
    cmp  rax, 5
    jne  t15_fail
t15_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t16_begin
t15_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t16_begin:
    ; ===== T16: overlap left shift (dst = &arr5[0], src = &arr5[1], len=5) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT16
    mov  r8d, msgT16_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr5                ; dst = &arr5[0]
    lea  rdx, arr5
    add  rdx, 8                   ; src = &arr5[1]
    mov  r8,  5
    call arr_copy
    jc   t16_fail

    ; After memmove-left: arr5 -> [8,7,6,5,4,4]
    ; check arr5[0] == 8 and arr5[4] == 4
    lea  rcx, arr5
    mov  rdx, 6
    xor  r8,  r8
    call arr_get_value
    jc   t16_fail
    cmp  rax, 8
    jne  t16_fail

    lea  rcx, arr5
    mov  rdx, 6
    mov  r8,  4
    call arr_get_value
    jc   t16_fail
    cmp  rax, 4
    jne  t16_fail
t16_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t17_begin
t16_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t17_begin

    t17_begin:
    ; ===== T17: reverse NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT17
    mov  r8d, msgT17_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                 ; base = NULL
    mov  rdx, 4                   ; len
    call arr_reverse
    jnc  t17_fail
    cmp  eax, ERR_NULLPTR
    jne  t17_fail
t17_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t18_begin
t17_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t18_begin:
    ; ===== T18: reverse len==0 -> ERR_LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT18
    mov  r8d, msgT18_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr6_even
    xor  rdx, rdx                 ; len = 0
    call arr_reverse
    jnc  t18_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t18_fail
t18_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t19_begin
t18_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t19_begin:
    ; ===== T19: reverse len==1 -> success and unchanged =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT19
    mov  r8d, msgT19_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr1_single
    mov  rdx, 1
    call arr_reverse
    jc   t19_fail                 ; must succeed

    ; verify unchanged
    lea  rcx, arr1_single
    mov  rdx, 1
    xor  r8,  r8
    call arr_get_value
    jc   t19_fail
    cmp  rax, 12345
    jne  t19_fail
t19_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t20_begin
t19_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t20_begin:
    ; ===== T20: reverse even len (1..6) -> 6..1 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT20
    mov  r8d, msgT20_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr6_even
    mov  rdx, 6
    call arr_reverse
    jc   t20_fail                 ; must succeed

    ; check first, middle, last
    lea  rcx, arr6_even
    mov  rdx, 6
    xor  r8,  r8                  ; index 0
    call arr_get_value
    jc   t20_fail
    cmp  rax, 6
    jne  t20_fail

    lea  rcx, arr6_even
    mov  rdx, 6
    mov  r8,  2                   ; index 2 should be 4
    call arr_get_value
    jc   t20_fail
    cmp  rax, 4
    jne  t20_fail

    lea  rcx, arr6_even
    mov  rdx, 6
    mov  r8,  5                   ; last
    call arr_get_value
    jc   t20_fail
    cmp  rax, 1
    jne  t20_fail
t20_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t21_begin
t20_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t21_begin:
    ; ===== T21: reverse odd len (10..50) -> 50..10, middle stays 30 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT21
    mov  r8d, msgT21_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr7_odd
    mov  rdx, 5
    call arr_reverse
    jc   t21_fail

    ; check first, middle, last
    lea  rcx, arr7_odd
    mov  rdx, 5
    xor  r8,  r8                  ; index 0
    call arr_get_value
    jc   t21_fail
    cmp  rax, 50
    jne  t21_fail

    lea  rcx, arr7_odd
    mov  rdx, 5
    mov  r8,  2                   ; middle should be 30
    call arr_get_value
    jc   t21_fail
    cmp  rax, 30
    jne  t21_fail

    lea  rcx, arr7_odd
    mov  rdx, 5
    mov  r8,  4                   ; last
    call arr_get_value
    jc   t21_fail
    cmp  rax, 10
    jne  t21_fail
t21_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t22_begin
t21_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t22_begin

t22_begin:
    ; ===== T22: swap NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT22
    mov  r8d, msgT22_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                 ; base = NULL
    mov  rdx, 4                   ; len
    xor  r8,  r8                  ; i = 0
    mov  r9,  1                   ; j = 1
    call arr_swap
    jnc  t22_fail
    cmp  eax, ERR_NULLPTR
    jne  t22_fail
t22_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t23_begin
t22_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t23_begin:
    ; ===== T23: swap with len==0 -> ERR_LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT23
    mov  r8d, msgT23_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr8
    xor  rdx, rdx                 ; len = 0
    xor  r8,  r8
    mov  r9,  1
    call arr_swap
    jnc  t23_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t23_fail
t23_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t24_begin
t23_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t24_begin:
    ; ===== T24: swap out-of-range (i==len) -> ERR_OUT_OF_RANGE =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT24
    mov  r8d, msgT24_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr8
    mov  rdx, 4
    mov  r8,  4                   ; i == len -> OOR
    mov  r9,  1
    call arr_swap
    jnc  t24_fail
    cmp  eax, ERR_OUT_OF_RANGE
    jne  t24_fail
t24_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t25_begin
t24_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t25_begin:
    ; ===== T25: swap same index (2,2) -> success and unchanged =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT25
    mov  r8d, msgT25_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    ; perform swap
    lea  rcx, arr8
    mov  rdx, 4
    mov  r8,  2
    mov  r9,  2
    call arr_swap
    jc   t25_fail                 ; must succeed

    ; verify arr8[2] == 300 (unchanged)
    lea  rcx, arr8
    mov  rdx, 4
    mov  r8,  2
    call arr_get_value
    jc   t25_fail
    cmp  rax, 300
    jne  t25_fail
t25_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t26_begin
t25_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t26_begin:
    ; ===== T26: swap indices 0 and 3 -> expect 400 at [0], 100 at [3] =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT26
    mov  r8d, msgT26_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    ; perform swap
    lea  rcx, arr8
    mov  rdx, 4
    xor  r8,  r8                   ; i = 0
    mov  r9,  3                    ; j = 3
    call arr_swap
    jc   t26_fail

    ; verify arr8[0] == 400
    lea  rcx, arr8
    mov  rdx, 4
    xor  r8,  r8
    call arr_get_value
    jc   t26_fail
    cmp  rax, 400
    jne  t26_fail

    ; verify arr8[3] == 100
    lea  rcx, arr8
    mov  rdx, 4
    mov  r8,  3
    call arr_get_value
    jc   t26_fail
    cmp  rax, 100
    jne  t26_fail
t26_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t27_begin
t26_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t27_begin

t27_begin:
    ; ===== T27: max NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT27
    mov  r8d, msgT27_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                ; base = NULL
    mov  rdx, 5
    call arr_max
    jnc  t27_fail
    cmp  eax, ERR_NULLPTR
    jne  t27_fail
t27_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t28_begin
t27_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t28_begin:
    ; ===== T28: max len==0 -> LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT28
    mov  r8d, msgT28_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr9
    xor  rdx, rdx                ; len = 0
    call arr_max
    jnc  t28_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t28_fail
t28_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t29_begin
t28_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t29_begin:
    ; ===== T29: max len==1 -> value itself =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT29
    mov  r8d, msgT29_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr10_one
    mov  rdx, 1
    call arr_max
    jc   t29_fail
    cmp  rax, 123456789
    jne  t29_fail
t29_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t30_begin
t29_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t30_begin:
    ; ===== T30: max of {5,9,3,12,7} -> 12 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT30
    mov  r8d, msgT30_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr9
    mov  rdx, 5
    call arr_max
    jc   t30_fail
    cmp  rax, 12
    jne  t30_fail
t30_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t31_begin
t30_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t31_begin:
    ; ===== T31: max unsigned of {0, -2, -1} -> 0xFFFFFFFFFFFFFFFF =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT31
    mov  r8d, msgT31_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr11_big
    mov  rdx, 3
    call arr_max
    jc   t31_fail
    cmp  rax, -1                 ; -1 == 0xFFFFFFFFFFFFFFFF
    jne  t31_fail
t31_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t32_begin
t31_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t32_begin

    t32_begin:
    ; ===== T32: NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT32
    mov  r8d, msgT32_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                ; base = NULL
    mov  rdx, 5
    call arr_index_of_max
    jnc  t32_fail
    cmp  eax, ERR_NULLPTR
    jne  t32_fail
t32_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t33_begin
t32_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t33_begin:
    ; ===== T33: len==0 -> ERR_LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT33
    mov  r8d, msgT33_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr9
    xor  rdx, rdx                ; len = 0
    call arr_index_of_max
    jnc  t33_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t33_fail
t33_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t34_begin
t33_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t34_begin:
    ; ===== T34: len==1 -> index 0 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT34
    mov  r8d, msgT34_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr10_one
    mov  rdx, 1
    call arr_index_of_max
    jc   t34_fail
    cmp  rax, 0
    jne  t34_fail
t34_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t35_begin
t34_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t35_begin:
    ; ===== T35: typical array -> expect index 3 (value 12) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT35
    mov  r8d, msgT35_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr9               ; {5,9,3,12,7}
    mov  rdx, 5
    call arr_index_of_max
    jc   t35_fail
    cmp  rax, 3
    jne  t35_fail
t35_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t36_begin
t35_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t36_begin:
    ; ===== T36: unsigned semantics -> expect index 2 (-1 is max) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT36
    mov  r8d, msgT36_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr11_big          ; {0, -2, -1} (unsigned: 0, 0x...FE, 0x...FF)
    mov  rdx, 3
    call arr_index_of_max
    jc   t36_fail
    cmp  rax, 2
    jne  t36_fail
t36_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t37_begin
t36_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t37_begin:
    ; ===== T37: duplicates -> expect first max index 1 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT37
    mov  r8d, msgT37_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr16_dups         ; {4,9,9,2}
    mov  rdx, 4
    call arr_index_of_max
    jc   t37_fail
    cmp  rax, 1
    jne  t37_fail
t37_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t38_begin

t37_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t38_begin

    t38_begin:
    ; ===== T38: NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT38
    mov  r8d, msgT38_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                ; base = NULL
    mov  rdx, 5
    call arr_index_of_min
    jnc  t38_fail
    cmp  eax, ERR_NULLPTR
    jne  t38_fail
t38_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t39_begin
t38_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t39_begin:
    ; ===== T39: len==0 -> ERR_LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT39
    mov  r8d, msgT39_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr9
    xor  rdx, rdx                ; len = 0
    call arr_index_of_min
    jnc  t39_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t39_fail
t39_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t40_begin
t39_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t40_begin:
    ; ===== T40: len==1 -> index 0 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT40
    mov  r8d, msgT40_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr10_one
    mov  rdx, 1
    call arr_index_of_min
    jc   t40_fail
    cmp  rax,  0
    jne  t40_fail
t40_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t41_begin
t40_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t41_begin:
    ; ===== T41: typical array -> expect index 2 (value 3) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT41
    mov  r8d, msgT41_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr9               ; {5,9,3,12,7}
    mov  rdx, 5
    call arr_index_of_min
    jc   t41_fail
    cmp  rax, 2
    jne  t41_fail
t41_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t42_begin
t41_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t42_begin:
    ; ===== T42: unsigned semantics -> expect index 0 (0 is min) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT42
    mov  r8d, msgT42_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr11_big          ; {0, -2, -1} (unsigned: 0, 0x...FE, 0x...FF)
    mov  rdx, 3
    call arr_index_of_min
    jc   t42_fail
    cmp  rax, 0
    jne  t42_fail
t42_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t43_begin
t42_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t43_begin:
    ; ===== T43: duplicates -> expect first min index 1 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT43
    mov  r8d, msgT43_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr17_dups_min     ; {4,1,1,2}
    mov  rdx, 4
    call arr_index_of_min
    jc   t43_fail
    cmp  rax, 1
    jne  t43_fail
t43_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t44_begin

t43_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t44_begin


    t44_begin:
    ; ===== T44: smax NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT44
    mov  r8d, msgT44_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                ; base = NULL
    mov  rdx, 3
    call arr_smax
    jnc  t44_fail
    cmp  eax, ERR_NULLPTR
    jne  t44_fail
t44_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t45_begin
t44_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t45_begin:
    ; ===== T45: smax len==0 -> LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT45
    mov  r8d, msgT45_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr12_mix
    xor  rdx, rdx
    call arr_smax
    jnc  t45_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t45_fail
t45_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t46_begin
t45_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t46_begin:
    ; ===== T46: smax len==1 (-42) -> -42 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT46
    mov  r8d, msgT46_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr14_one
    mov  rdx, 1
    call arr_smax
    jc   t46_fail
    cmp  rax, -42
    jne  t46_fail
t46_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t47_begin
t46_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t47_begin:
    ; ===== T47: smax signed {0,-2,-1} -> 0 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT47
    mov  r8d, msgT47_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr11_big          ; {0, -2, -1}
    mov  rdx, 3
    call arr_smax
    jc   t47_fail
    cmp  rax, 0
    jne  t47_fail
t47_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t48_begin
t47_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t48_begin:
    ; ===== T48: smax signed {-10,5,-3,2} -> 5 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT48
    mov  r8d, msgT48_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr12_mix
    mov  rdx, 4
    call arr_smax
    jc   t48_fail
    cmp  rax, 5
    jne  t48_fail
t48_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t49_begin
t48_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t49_begin:
    ; ===== T49: smax edges {INT64_MIN, INT64_MAX} -> 0x7FFFFFFFFFFFFFFF =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT49
    mov  r8d, msgT49_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr15_edges
    mov  rdx, 2
    call arr_smax
    jc   t49_fail
    mov  rdx, 7FFFFFFFFFFFFFFFh   ; load 64-bit immediate
    cmp  rax, rdx
    jne  t49_fail
t49_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t50_begin
t49_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t50_begin

t50_begin:
    ; ===== T50: smin NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT50
    mov  r8d, msgT50_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                ; base = NULL
    mov  rdx, 3
    call arr_smin
    jnc  t50_fail
    cmp  eax, ERR_NULLPTR
    jne  t50_fail
t50_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t51_begin
t50_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t51_begin:
    ; ===== T51: smin len==0 -> LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT51
    mov  r8d, msgT51_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr12_mix
    xor  rdx, rdx
    call arr_smin
    jnc  t51_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t51_fail
t51_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t52_begin
t51_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t52_begin:
    ; ===== T52: smin len==1 (-42) -> -42 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT52
    mov  r8d, msgT52_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr14_one
    mov  rdx, 1
    call arr_smin
    jc   t52_fail
    cmp  rax, -42
    jne  t52_fail
t52_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t53_begin
t52_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t53_begin:
    ; ===== T53: smin signed {0,-2,-1} -> -2 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT53
    mov  r8d, msgT53_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr11_big          ; {0, -2, -1}
    mov  rdx, 3
    call arr_smin
    jc   t53_fail
    cmp  rax, -2
    jne  t53_fail
t53_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t54_begin
t53_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t54_begin:
    ; ===== T54: smin signed {-10,5,-3,2} -> -10 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT54
    mov  r8d, msgT54_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr12_mix
    mov  rdx, 4
    call arr_smin
    jc   t54_fail
    cmp  rax, -10
    jne  t54_fail
t54_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t55_begin
t54_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t55_begin:
    ; ===== T55: smin edges {INT64_MIN, INT64_MAX} -> INT64_MIN =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT55
    mov  r8d, msgT55_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr15_edges
    mov  rdx, 2
    call arr_smin
    jc   t55_fail
    mov  rdx, 8000000000000000h   ; INT64_MIN (load into reg; cmp imm64 isn't encodable)
    cmp  rax, rdx
    jne  t55_fail
t55_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t56_begin
t55_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t56_begin

t56_begin:
    ; ===== T56: NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT56
    mov  r8d, msgT56_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                ; base = NULL
    mov  rdx, 3
    call arr_index_of_smax
    jnc  t56_fail
    cmp  eax, ERR_NULLPTR
    jne  t56_fail
t56_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t57_begin
t56_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t57_begin:
    ; ===== T57: len==0 -> ERR_LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT57
    mov  r8d, msgT57_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr12_mix
    xor  rdx, rdx                ; len = 0
    call arr_index_of_smax
    jnc  t57_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t57_fail
t57_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t58_begin
t57_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t58_begin:
    ; ===== T58: len==1 -> index 0 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT58
    mov  r8d, msgT58_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr14_one          ; {-42}
    mov  rdx, 1
    call arr_index_of_smax
    jc   t58_fail
    cmp  rax, 0
    jne  t58_fail
t58_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t59_begin
t58_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t59_begin:
    ; ===== T59: typical signed array -> expect index 1 (value 5) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT59
    mov  r8d, msgT59_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr12_mix          ; {-10,5,-3,2}
    mov  rdx, 4
    call arr_index_of_smax
    jc   t59_fail
    cmp  rax, 1
    jne  t59_fail
t59_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t60_begin
t59_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t60_begin:
    ; ===== T60: signed semantics -> expect index 0 (0 is max) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT60
    mov  r8d, msgT60_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr11_big          ; {0, -2, -1}
    mov  rdx, 3
    call arr_index_of_smax
    jc   t60_fail
    cmp  rax, 0
    jne  t60_fail
t60_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t61_begin
t60_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t61_begin:
    ; ===== T61: edges -> expect index 1 (INT64_MAX is max) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT61
    mov  r8d, msgT61_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr15_edges        ; {INT64_MIN, INT64_MAX}
    mov  rdx, 2
    call arr_index_of_smax
    jc   t61_fail
    cmp  rax, 1
    jne  t61_fail
t61_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t62_begin
t61_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t62_begin:
    ; ===== T62: duplicates -> expect first max index 1 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT62
    mov  r8d, msgT62_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr18_dups_smax    ; {-5,3,3,-1}
    mov  rdx, 4
    call arr_index_of_smax
    jc   t62_fail
    cmp  rax, 1
    jne  t62_fail
t62_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t63_begin
t62_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t63_begin:
    ; ===== T63: NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT63
    mov  r8d, msgT63_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                ; base = NULL
    mov  rdx, 3
    call arr_index_of_smin
    jnc  t63_fail
    cmp  eax, ERR_NULLPTR
    jne  t63_fail
t63_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t64_begin
t63_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t64_begin:
    ; ===== T64: len==0 -> ERR_LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT64
    mov  r8d, msgT64_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr12_mix
    xor  rdx, rdx                ; len = 0
    call arr_index_of_smin
    jnc  t64_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t64_fail
t64_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t65_begin
t64_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t65_begin:
    ; ===== T65: len==1 -> expect index 0 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT65
    mov  r8d, msgT65_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr14_one          ; {-42}
    mov  rdx, 1
    call arr_index_of_smin
    jc   t65_fail
    cmp  rax, 0
    jne  t65_fail
t65_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t66_begin
t65_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t66_begin:
    ; ===== T66: typical signed array -> expect index 0 (value -10) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT66
    mov  r8d, msgT66_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr12_mix          ; {-10,5,-3,2}
    mov  rdx, 4
    call arr_index_of_smin
    jc   t66_fail
    cmp  rax, 0
    jne  t66_fail
t66_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t67_begin
t66_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t67_begin:
    ; ===== T67: signed semantics -> expect index 1 (-2 is min) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT67
    mov  r8d, msgT67_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr11_big          ; {0, -2, -1}
    mov  rdx, 3
    call arr_index_of_smin
    jc   t67_fail
    cmp  rax, 1
    jne  t67_fail
t67_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t68_begin
t67_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t68_begin:
    ; ===== T68: edges -> expect index 0 (INT64_MIN is min) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT68
    mov  r8d, msgT68_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr15_edges        ; {INT64_MIN, INT64_MAX}
    mov  rdx, 2
    call arr_index_of_smin
    jc   t68_fail
    cmp  rax, 0
    jne  t68_fail
t68_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t69_begin
t68_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t69_begin:
    ; ===== T69: duplicates -> expect first min index 1 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT69
    mov  r8d, msgT69_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr19_dups_smin    ; {2,-7,-7,0}
    mov  rdx, 4
    call arr_index_of_smin
    jc   t69_fail
    cmp  rax, 1
    jne  t69_fail
t69_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t70_begin
t69_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t70_begin


t70_begin:
    ; ===== T70: min NULL base -> ERR_NULLPTR =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT70
    mov  r8d, msgT70_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    xor  rcx, rcx                ; base = NULL
    mov  rdx, 5
    call arr_min
    jnc  t70_fail
    cmp  eax, ERR_NULLPTR
    jne  t70_fail
t70_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t71_begin
t70_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t71_begin:
    ; ===== T71: min len==0 -> LEN_ZERO =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT71
    mov  r8d, msgT71_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr9
    xor  rdx, rdx                ; len = 0
    call arr_min
    jnc  t71_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t71_fail
t71_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t72_begin
t71_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t72_begin:
    ; ===== T72: len==1 -> the element itself =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT72
    mov  r8d, msgT72_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr10_one
    mov  rdx, 1
    call arr_min
    jc   t72_fail
    cmp  rax, 123456789
    jne  t72_fail
t72_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t73_begin
t72_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t73_begin:
    ; ===== T73: typical array -> expect 3 =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT73
    mov  r8d, msgT73_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr9               ; {5,9,3,12,7}
    mov  rdx, 5
    call arr_min
    jc   t73_fail
    cmp  rax, 3
    jne  t73_fail
t73_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t74_begin
t73_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t74_begin:
    ; ===== T74: unsigned semantics -> expect 0 (0 is smallest) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT74
    mov  r8d, msgT74_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr11_big          ; {0, -2, -1}  (unsigned: 0, 0x...FE, 0x...FF)
    mov  rdx, 3
    call arr_min
    jc   t74_fail
    cmp  rax, 0
    jne  t74_fail
t74_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  t75_begin
t74_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

t75_begin:
    ; ===== T75: edges unsigned -> expect 0x7FFFFFFFFFFFFFFF (smaller than 0x8000...) =====
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT75
    mov  r8d, msgT75_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA

    lea  rcx, arr15_edges        ; {INT64_MIN (0x8000...), INT64_MAX (0x7FFF...)}
    mov  rdx, 2
    call arr_min
    jc   t75_fail
    mov  rdx, 7FFFFFFFFFFFFFFFh  ; load 64-bit constant for compare
    cmp  rax, rdx
    jne  t75_fail
t75_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  done
t75_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    jmp  done




done:
    lea rsp, [rsp+40]
    xor ecx, ecx
    call ExitProcess
main ENDP
END
