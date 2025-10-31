; ------------------------------------------------------------
; str_sanity.asm — ONLY str_copy tests (using general ERR_* codes)
; Build: Console App (x64). Link against AsmEase64.lib.
; Requires MASM Include Path -> C:\VSProj\AsmEase64\inc
; ------------------------------------------------------------

OPTION casemap:none
OPTION prologue:none, epilogue:none

INCLUDE AsmEase64.inc
INCLUDE win32_console.inc

.data
stdoutHandle    QWORD 0

msgPASS   db "PASS",13,10
msgPASS_len EQU ($-msgPASS)
msgFAIL   db "FAIL",13,10
msgFAIL_len EQU ($-msgFAIL)

msgT1    db "T1: str_copy dst=NULL -> expect ERR_NULLPTR ... "
msgT1_len EQU ($-msgT1)
msgT2    db "T2: str_copy src=NULL -> expect ERR_NULLPTR ... "
msgT2_len EQU ($-msgT2)
msgT3    db "T3: str_copy src_len==0 -> expect ERR_LEN_ZERO ... "
msgT3_len EQU ($-msgT3)
msgT4    db "T4: str_copy capacity too small -> expect ERR_CAPACITY ... "
msgT4_len EQU ($-msgT4)
msgT5    db "T5: str_copy normal copy (no overlap) -> len=5 & exact bytes ... "
msgT5_len EQU ($-msgT5)
msgT6    db "T6: str_copy exact fit (src_len==dst_cap) -> CF=0 ... "
msgT6_len EQU ($-msgT6)
msgT7    db "T7: str_copy overlap forward (dst<src) memmove-safe ... "
msgT7_len EQU ($-msgT7)
msgT8    db "T8: str_copy overlap backward (dst>src) memmove-safe ... "
msgT8_len EQU ($-msgT8)
msgT9    db "T9: str_copy capacity=0 but src_len>0 -> ERR_CAPACITY ... "
msgT9_len EQU ($-msgT9)
msgT10   db "T10: str_copy binary with NULs -> copies all bytes, no terminator ... "
msgT10_len EQU ($-msgT10)
msgT11   db "T11: str_copy dst==src -> no-op, len preserved ... "
msgT11_len EQU ($-msgT11)

src_hello      db "hello"                ; 5 bytes
dst_small      db 16 dup(0CCh)
dst_cap16      QWORD 16

dst_fit        db 5 dup(0CCh)
dst_fit_cap    QWORD 5

ovl_buf1       db "ABCDE",0             ; 6 bytes storage
ovl_cap1       QWORD 6
ovl_buf2       db "ABCDE",0
ovl_cap2       QWORD 6

cap0_buf       db 4 dup(0)
cap0_cap       QWORD 0

src_bin        db 041h, 000h, 042h, 000h
dst_bin        db 8 dup(055h)
dst_bin_cap    QWORD 8

self_buf       db "xyz",0
self_cap       QWORD 4

; ---- str_length test banners ----
msgT12     db "T12: length NULL src -> expect ERR_NULLPTR ... "
msgT12_len EQU ($-msgT12)

msgT13     db "T13: length max_len==0 -> expect ERR_LEN_ZERO ... "
msgT13_len EQU ($-msgT13)

msgT14     db "T14: length 'hello\\0' with max=10 -> expect 5 ... "
msgT14_len EQU ($-msgT14)

msgT15     db "T15: no NUL within max_len -> returns max_len ... "
msgT15_len EQU ($-msgT15)

msgT16     db "T16: first byte is NUL -> returns 0 ... "
msgT16_len EQU ($-msgT16)

msgT17     db "T17: embedded NUL at index 2 -> returns 2 ... "
msgT17_len EQU ($-msgT17)

msgT18     db "T18: NUL at boundary-1 -> returns boundary-1 ... "
msgT18_len EQU ($-msgT18)

msgT19     db "T19: NUL after boundary -> returns boundary (no overread) ... "
msgT19_len EQU ($-msgT19)

; ---- str_length test data ----
len_hello      db "hello", 0
no_nul_16      db 16 dup('A')          ; no zero in first 16 bytes
nul_first      db 0, 'x','y','z'
embed_nul db 'A','B',0,'C','D'   ; NUL at index 2
boundary_buf   db 'a','b','c','d','e','f','g','h','i',0,'X','Y'  ; NUL at index 9


; ---- str_compare test banners ----
msgT20     db "T20: compare NULL a -> expect ERR_NULLPTR ... "
msgT20_len EQU ($-msgT20)

msgT21     db "T21: compare NULL b -> expect ERR_NULLPTR ... "
msgT21_len EQU ($-msgT21)

msgT22     db "T22: equal buffers & equal lengths -> expect 0 ... "
msgT22_len EQU ($-msgT22)

msgT23     db "T23: differ at first byte -> expect -1 ... "
msgT23_len EQU ($-msgT23)

msgT24     db "T24: differ at later byte -> expect 1 ... "
msgT24_len EQU ($-msgT24)

msgT25     db "T25: a is proper prefix of b -> expect -1 ... "
msgT25_len EQU ($-msgT25)

msgT26     db "T26: b is proper prefix of a -> expect 1 ... "
msgT26_len EQU ($-msgT26)

msgT27     db "T27: either length can be zero (0 vs nonzero) -> expect -1 ... "
msgT27_len EQU ($-msgT27)

msgT28     db "T28: both zero length -> expect 0 ... "
msgT28_len EQU ($-msgT28)

msgT29     db "T29: binary data with NULs, mismatch on 0x00 vs 0xFF -> expect -1 ... "
msgT29_len EQU ($-msgT29)

; ---- str_compare test data ----
cmp_eq_a     db 'k','i','t','e'          ; 4
cmp_eq_b     db 'k','i','t','e'          ; 4

cmp_fst_a    db 'A','x','x'              ; 3
cmp_fst_b    db 'B','x','x'              ; 3

cmp_mid_a    db 'h','e','y'              ; 3
cmp_mid_b    db 'h','o','y'              ; 3

cmp_pref_a   db 'c','a','t'              ; 3
cmp_pref_b   db 'c','a','t','s'          ; 4

cmp_pref2_a  db 'b','e','a','r','s'      ; 5
cmp_pref2_b  db 'b','e','a','r'          ; 4

cmp_zero_b   db 'z','e','r','o'          ; 4

cmp_bin_a    db 0FFh, 000h, 07Fh         ; 3
cmp_bin_b    db 0FFh, 0FFh, 07Fh         ; 3


; ---- str_trim test banners ----
msgT30     db "T30: trim NULL base -> expect ERR_NULLPTR ... "
msgT30_len EQU ($-msgT30)

msgT31     db "T31: trim len==0 -> expect 0 and no crash ... "
msgT31_len EQU ($-msgT31)

msgT32     db "T32: all whitespace -> expect new_len=0 ... "
msgT32_len EQU ($-msgT32)

msgT33     db "T33: leading spaces only -> shift left to 'abc' (len=3) ... "
msgT33_len EQU ($-msgT33)

msgT34     db "T34: trailing spaces only -> keep 'abc' (len=3) ... "
msgT34_len EQU ($-msgT34)

msgT35     db "T35: both sides (tab/space/CR/LF) -> 'abc' (len=3) ... "
msgT35_len EQU ($-msgT35)

msgT36     db "T36: no trim needed -> 'abc' (len=3) ... "
msgT36_len EQU ($-msgT36)

msgT37     db "T37: tabs-only around -> 'abc' (len=3) ... "
msgT37_len EQU ($-msgT37)

msgT38     db "T38: internal spaces preserved -> 'a b' (len=3) ... "
msgT38_len EQU ($-msgT38)

; ---- str_trim test data ----
tw_all_ws      db 9, 9, 20h, 0Ah, 0Dh, 20h, 9, 9       ; mix of ASCII ws
tw_leading     db 20h,20h,20h,'a','b','c'              ; "   abc"
tw_trailing    db 'a','b','c',20h,20h,20h              ; "abc   "
tw_both        db 9,20h,'a','b','c',20h,0Dh,0Ah        ; "\t abc \r\n"
tw_no_ws       db 'a','b','c'
tw_tabs        db 9,9,'a','b','c',9
tw_internal    db 20h,'a',20h,'b',20h                  ; " a b " -> expect "a b"

; scratch copies so multiple tests are independent
buf_all_ws     db 8 dup(0)
buf_lead       db 6 dup(0)
buf_trail      db 6 dup(0)
buf_both       db 8 dup(0)
buf_now        db 3 dup(0)
buf_tabs       db 6 dup(0)
buf_internal   db 5 dup(0)


; ---- str_to_upper test banners (explicit proc name) ----
msgT39     db "T39 (str_to_upper): base=NULL -> expect ERR_NULLPTR ... "
msgT39_len EQU ($-msgT39)

msgT40     db "T40 (str_to_upper): len==0 -> expect CF=0, RAX=0, no change ... "
msgT40_len EQU ($-msgT40)

msgT41     db "T41 (str_to_upper): all lowercase -> ALL UPPER, RAX=len ... "
msgT41_len EQU ($-msgT41)

msgT42     db "T42 (str_to_upper): mixed case + digits/punct unaffected ... "
msgT42_len EQU ($-msgT42)

msgT43     db "T43 (str_to_upper): already uppercase -> unchanged ... "
msgT43_len EQU ($-msgT43)

msgT44     db "T44 (str_to_upper): non-ASCII bytes (>=0x80) unchanged ... "
msgT44_len EQU ($-msgT44)

msgT45     db "T45 (str_to_upper): edges 'a'/'z' map to 'A'/'Z' ... "
msgT45_len EQU ($-msgT45)

; ---- str_to_upper test data ----
tu_src_low    db 'abcdefghijklmnopqrstuvwxyz'            ; 26
tu_src_mix    db 'a','B','c','1','!','z'                 ; 6
tu_src_up     db 'ABCXYZ'                                 ; 6
tu_src_bin    db 080h,0FFh,07Fh,061h,07Ah                 ; 5   (note: includes 'a','z' at end)
tu_src_edges  db 'a','z'                                  ; 2

; separate scratch buffers (so tests don't interfere)
tu_buf_low    db 26 dup(0)
tu_buf_mix    db 6  dup(0)
tu_buf_up     db 6  dup(0)
tu_buf_bin    db 5  dup(0)
tu_buf_edges  db 2  dup(0)

; ---- str_to_lower test banners (explicit proc name) ----
msgT46     db "T46 (str_to_lower): base=NULL -> expect ERR_NULLPTR ... "
msgT46_len EQU ($-msgT46)

msgT47     db "T47 (str_to_lower): len==0 -> expect CF=0, RAX=0, no change ... "
msgT47_len EQU ($-msgT47)

msgT48     db "T48 (str_to_lower): all UPPERCASE -> all lowercase, RAX=len ... "
msgT48_len EQU ($-msgT48)

msgT49     db "T49 (str_to_lower): mixed case + digits/punct unaffected ... "
msgT49_len EQU ($-msgT49)

msgT50     db "T50 (str_to_lower): already lowercase -> unchanged ... "
msgT50_len EQU ($-msgT50)

msgT51     db "T51 (str_to_lower): non-ASCII bytes (>=0x80) unchanged; A/Z convert ... "
msgT51_len EQU ($-msgT51)

msgT52     db "T52 (str_to_lower): edges 'A'/'Z' map to 'a'/'z' ... "
msgT52_len EQU ($-msgT52)

; ---- str_to_lower test data ----
tl_src_up     db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'            ; 26
tl_src_mix    db 'a','B','c','1','!','Z'                 ; 6
tl_src_low    db 'abcxyz'                                 ; 6
tl_src_bin    db 080h,0FFh,07Fh,041h,05Ah                 ; 5   (includes 'A','Z' at end)
tl_src_edges  db 'A','Z'                                  ; 2

; scratch buffers (independent per test)
tl_buf_up     db 26 dup(0)
tl_buf_mix    db 6  dup(0)
tl_buf_low    db 6  dup(0)
tl_buf_bin    db 5  dup(0)
tl_buf_edges  db 2  dup(0)

; ---- str_reverse test banners (explicit proc name) ----
msgT53     db "T53 (str_reverse): base=NULL -> expect ERR_NULLPTR ... "
msgT53_len EQU ($-msgT53)

msgT54     db "T54 (str_reverse): len==0 -> expect CF=0, RAX=0, no change ... "
msgT54_len EQU ($-msgT54)

msgT55     db "T55 (str_reverse): len==1 -> expect CF=0, RAX=1, unchanged ... "
msgT55_len EQU ($-msgT55)

msgT56     db "T56 (str_reverse): even length 'abcd' -> 'dcba' ... "
msgT56_len EQU ($-msgT56)

msgT57     db "T57 (str_reverse): odd length 'abcde' -> 'edcba' ... "
msgT57_len EQU ($-msgT57)

msgT58     db "T58 (str_reverse): palindrome 'racecar' unchanged ... "
msgT58_len EQU ($-msgT58)

msgT59     db "T59 (str_reverse): binary with NULs reverses correctly ... "
msgT59_len EQU ($-msgT59)

msgT60     db "T60 (str_reverse): 0..15 -> 15..0 ... "
msgT60_len EQU ($-msgT60)

; ---- str_reverse test data ----
rv_src_even    db 'a','b','c','d'                     ; 4
rv_src_odd     db 'a','b','c','d','e'                 ; 5
rv_src_pal     db 'r','a','c','e','c','a','r'         ; 7
rv_src_bin     db 1,0,2,0,3,0,4,0                      ; 8
rv_src_0_15    db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 ; 16
rv_one         db 'X'                                  ; 1
rv_zero_scratch db 55h                                 ; any byte, will not be touched for len==0

; scratch buffers (so tests do not interfere)
rv_buf_even    db 4  dup(0)
rv_buf_odd     db 5  dup(0)
rv_buf_pal     db 7  dup(0)
rv_buf_bin     db 8  dup(0)
rv_buf_0_15    db 16 dup(0)
rv_buf_one     db 1  dup(0)


; ---- str_fill test banners (explicit proc name) ----
msgT61     db "T61 (str_fill): base=NULL -> expect ERR_NULLPTR ... "
msgT61_len EQU ($-msgT61)

msgT62     db "T62 (str_fill): len==0 -> expect CF=0, RAX=0, no change ... "
msgT62_len EQU ($-msgT62)

msgT63     db "T63 (str_fill): fill 8 bytes with 'x' ... "
msgT63_len EQU ($-msgT63)

msgT64     db "T64 (str_fill): fill with 0xFF (non-ASCII) ... "
msgT64_len EQU ($-msgT64)

msgT65     db "T65 (str_fill): partial fill preserves guard bytes ... "
msgT65_len EQU ($-msgT65)

msgT66     db "T66 (str_fill): overwrite subset after prior fill ... "
msgT66_len EQU ($-msgT66)

msgT67     db "T67 (str_fill): larger count (32 bytes) smoke test ... "
msgT67_len EQU ($-msgT67)

; ---- str_fill test data ----
sf_buf8        db 8  dup(0)
sf_buf8_b      db 8  dup(0)
sf_buf16       db 16 dup(0)
sf_buf32       db 32 dup(0)

; guard-buffer: [0xAA][ 10 bytes payload ][0xBB]
sf_guarded     db 0AAh, 10 dup(0), 0BBh


; ---- str_find_char test banners (explicit proc name) ----
msgT68     db "T68 (str_find_char): base=NULL -> expect ERR_NULLPTR ... "
msgT68_len EQU ($-msgT68)

msgT69     db "T69 (str_find_char): len==0 -> expect STR_NPOS ... "
msgT69_len EQU ($-msgT69)

msgT70     db "T70 (str_find_char): hit at head -> index 0 ... "
msgT70_len EQU ($-msgT70)

msgT71     db "T71 (str_find_char): hit in middle -> index 1 ... "
msgT71_len EQU ($-msgT71)

msgT72     db "T72 (str_find_char): hit at tail -> index 2 ... "
msgT72_len EQU ($-msgT72)

msgT73     db "T73 (str_find_char): not found -> STR_NPOS ... "
msgT73_len EQU ($-msgT73)

msgT74     db "T74 (str_find_char): binary data; find NUL -> index 1 ... "
msgT74_len EQU ($-msgT74)

msgT75     db "T75 (str_find_char): repeated hits; returns first -> index 1 ... "
msgT75_len EQU ($-msgT75)

msgT76     db "T76 (str_find_char): boundary guard; target past len -> STR_NPOS ... "
msgT76_len EQU ($-msgT76)

msgT77     db "T77 (str_find_char): high-bit byte 0x80 -> index 0 ... "
msgT77_len EQU ($-msgT77)

; ---- str_find_char test data ----
sfc_head      db 'a','b','c'                 ; len=3
sfc_mid       db 'a','b','c'                 ; len=3
sfc_tail      db 'a','b','c'                 ; len=3
sfc_nf        db 'a','b','c'                 ; len=3
sfc_bin       db 1,0,2,0                     ; len=4
sfc_repeats   db 'b','a','n','a','n','a'     ; "banana", len=6
sfc_guard     db 'h','e','l','l','o'         ; len=5 (but we will pass len=4)
sfc_hi        db 080h,07Fh                   ; len=2

; ---- str_replace_char test banners (explicit proc name) ----
msgT78     db "T78 (str_replace_char): base=NULL -> expect ERR_NULLPTR ... "
msgT78_len EQU ($-msgT78)

msgT79     db "T79 (str_replace_char): len==0 -> CF=0, RAX=0, no change ... "
msgT79_len EQU ($-msgT79)

msgT80     db "T80 (str_replace_char): no matches -> count=0, buffer unchanged ... "
msgT80_len EQU ($-msgT80)

msgT81     db "T81 (str_replace_char): replace some ('banana', 'a'->'o') -> 'bonono', count=3 ... "
msgT81_len EQU ($-msgT81)

msgT82     db "T82 (str_replace_char): replace all ('aaaa'->'zzzz') -> count=4 ... "
msgT82_len EQU ($-msgT82)

msgT83     db "T83 (str_replace_char): old==new ('a'->'a') -> unchanged, count of 'a' ... "
msgT83_len EQU ($-msgT83)

msgT84     db "T84 (str_replace_char): binary: 1,0,2,0 ; 0->FF -> 1,FF,2,FF ; count=2 ... "
msgT84_len EQU ($-msgT84)

msgT85     db "T85 (str_replace_char): high-bit 0x80->0x7F in [80,7F] -> [7F,7F], count=1 ... "
msgT85_len EQU ($-msgT85)

; ---- str_replace_char test data ----
rr_src_none     db 'h','e','l','l','o'           ; len=5
rr_src_banana   db 'b','a','n','a','n','a'       ; "banana", len=6
rr_src_all      db 'a','a','a','a'               ; len=4
rr_src_same     db 'a','b','c','a','b','c'       ; len=6
rr_src_bin      db 1,0,2,0                       ; len=4
rr_src_hi       db 080h,07Fh                     ; len=2

; scratch buffers
rr_buf_none     db 5 dup(0)
rr_buf_banana   db 6 dup(0)
rr_buf_all      db 4 dup(0)
rr_buf_same     db 6 dup(0)
rr_buf_bin      db 4 dup(0)
rr_buf_hi       db 2 dup(0)

.code

.code
main PROC
    sub rsp, 40
    mov ecx, -11
    call GetStdHandle
    mov [stdoutHandle], rax

; ---- T1 ----
t1_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT1
    mov  r8d, msgT1_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 16
    lea  r8,  src_hello
    mov  r9,  5
    call str_copy
    jnc  t1_fail
    cmp  eax, ERR_NULLPTR
    jne  t1_fail
t1_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t2_begin
t1_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T2 ----
t2_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT2
    mov  r8d, msgT2_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, dst_small
    mov  rdx, 16
    xor  r8,  r8                  ; src=NULL
    mov  r9,  5
    call str_copy
    jnc  t2_fail
    cmp  eax, ERR_NULLPTR
    jne  t2_fail
t2_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t3_begin
t2_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T3 ----
t3_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT3
    mov  r8d, msgT3_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, dst_small
    mov  rdx, 16
    lea  r8,  src_hello
    xor  r9,  r9                 ; src_len=0
    call str_copy
    jnc  t3_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t3_fail
t3_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t4_begin
t3_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T4 ----
t4_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT4
    mov  r8d, msgT4_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, dst_small
    mov  rdx, 4                  ; capacity too small
    lea  r8,  src_hello
    mov  r9,  5
    call str_copy
    jnc  t4_fail
    cmp  eax, ERR_CAPACITY
    jne  t4_fail
t4_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t5_begin
t4_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T5 ----
t5_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT5
    mov  r8d, msgT5_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    mov  rax, 16
    lea  rdi, dst_small
    mov  bl, 0CCh
t5_wipe:
    mov  [rdi], bl
    inc  rdi
    dec  rax
    jnz  t5_wipe

    lea  rcx, dst_small
    mov  rdx, 16
    lea  r8,  src_hello
    mov  r9,  5
    call str_copy
    jc   t5_fail
    cmp  rax, 5
    jne  t5_fail
    lea  rsi, src_hello
    lea  rdi, dst_small
    mov  rcx, 5
t5_cmp:
    mov  al, [rsi]
    cmp  al, [rdi]
    jne  t5_fail
    inc  rsi
    inc  rdi
    dec  rcx
    jnz  t5_cmp
t5_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t6_begin
t5_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T6 ----
t6_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT6
    mov  r8d, msgT6_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, dst_fit
    mov  rdx, 5
    lea  r8,  src_hello
    mov  r9,  5
    call str_copy
    jc   t6_fail
t6_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t7_begin
t6_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T7 ----
t7_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT7
    mov  r8d, msgT7_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, ovl_buf1            ; dst = &buf[0]
    mov  rdx, 6
    lea  r8,  ovl_buf1+1          ; src = &buf[1]
    mov  r9,  4                    ; copy "BCDE" -> expect "BCDEE",0
    call str_copy
    jc   t7_fail
    lea  rsi, ovl_buf1
    mov  al, 'B'  ;0
    cmp  [rsi+0], al
    jne  t7_fail
    mov  al, 'C'  ;1
    cmp  [rsi+1], al
    jne  t7_fail
    mov  al, 'D'  ;2
    cmp  [rsi+2], al
    jne  t7_fail
    mov  al, 'E'  ;3
    cmp  [rsi+3], al
    jne  t7_fail
    mov  al, 'E'  ;4
    cmp  [rsi+4], al
    jne  t7_fail
t7_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t8_begin
t7_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T8 ----
t8_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT8
    mov  r8d, msgT8_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, ovl_buf2+1          ; dst = &buf[1]
    mov  rdx, 6
    lea  r8,  ovl_buf2            ; src = &buf[0]
    mov  r9,  4                    ; copy "ABCD" -> expect "AABCD",0
    call str_copy
    jc   t8_fail
    lea  rsi, ovl_buf2
    mov  al,'A'
    cmp  [rsi+0], al
    jne  t8_fail
    mov  al,'A'
    cmp  [rsi+1], al
    jne  t8_fail
    mov  al,'B'
    cmp  [rsi+2], al
    jne  t8_fail
    mov  al,'C'
    cmp  [rsi+3], al
    jne  t8_fail
    mov  al,'D'
    cmp  [rsi+4], al
    jne  t8_fail
t8_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t9_begin
t8_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T9 ----
t9_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT9
    mov  r8d, msgT9_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, cap0_buf
    xor  rdx, rdx                 ; dst_cap=0
    lea  r8,  src_hello
    mov  r9,  1
    call str_copy
    jnc  t9_fail
    cmp  eax, ERR_CAPACITY
    jne  t9_fail
t9_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t10_begin
t9_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T10 ----
t10_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT10
    mov  r8d, msgT10_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, dst_bin
    mov  rdx, 8
    lea  r8,  src_bin
    mov  r9,  4
    call str_copy
    jc   t10_fail
    lea  rdi, dst_bin
    mov  al, 041h
    cmp  [rdi+0], al
    jne  t10_fail
    mov  al, 000h
    cmp  [rdi+1], al
    jne  t10_fail
    mov  al, 042h
    cmp  [rdi+2], al
    jne  t10_fail
    mov  al, 000h
    cmp  [rdi+3], al
    jne  t10_fail
    mov  al, 055h
    cmp  [rdi+4], al
    jne  t10_fail
t10_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t11_begin
t10_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

; ---- T11 ----
t11_begin:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT11
    mov  r8d, msgT11_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, self_buf
    mov  rdx, 4
    lea  r8,  self_buf
    mov  r9,  3
    call str_copy
    jc   t11_fail
    cmp  rax, 3
    jne  t11_fail
    lea  rsi, self_buf
    mov  al, 'x'
    cmp  [rsi+0], al
    jne  t11_fail
    mov  al, 'y'
    cmp  [rsi+1], al
    jne  t11_fail
    mov  al, 'z'
    cmp  [rsi+2], al
    jne  t11_fail
t11_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t12_begin

t11_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t12_begin

    ; ==================== str_length tests (T12–T19) ====================
t12_begin:
    ; ----- T12: src=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT12
    mov  r8d, msgT12_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 10
    call str_length
    jnc  t12_fail
    cmp  eax, ERR_NULLPTR
    jne  t12_fail
t12_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t13_begin
t12_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t13_begin:
    ; ----- T13: max_len==0 -> ERR_LEN_ZERO -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT13
    mov  r8d, msgT13_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, len_hello
    xor  rdx, rdx
    call str_length
    jnc  t13_fail
    cmp  eax, ERR_LEN_ZERO
    jne  t13_fail
t13_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t14_begin
t13_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t14_begin:
    ; ----- T14: "hello\0", max=10 -> 5 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT14
    mov  r8d, msgT14_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, len_hello
    mov  rdx, 10
    call str_length
    jc   t14_fail
    cmp  rax, 5
    jne  t14_fail
t14_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t15_begin
t14_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t15_begin:
    ; ----- T15: no NUL within max -> returns max_len -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT15
    mov  r8d, msgT15_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, no_nul_16
    mov  rdx, 16
    call str_length
    jc   t15_fail
    cmp  rax, 16
    jne  t15_fail
t15_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t16_begin
t15_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t16_begin:
    ; ----- T16: first byte NUL -> 0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT16
    mov  r8d, msgT16_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, nul_first
    mov  rdx, 4
    call str_length
    jc   t16_fail
    cmp  rax, 0
    jne  t16_fail
t16_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t17_begin
t16_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t17_begin:
    ; ----- T17: embedded NUL at index 2 -> 2 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT17
    mov  r8d, msgT17_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, embed_nul
    mov  rdx, 5
    call str_length
    jc   t17_fail
    cmp  rax, 2
    jne  t17_fail
t17_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t18_begin
t17_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t18_begin:
    ; ----- T18: NUL at boundary-1 -> boundary-1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT18
    mov  r8d, msgT18_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, boundary_buf          ; NUL at 9
    mov  rdx, 12
    call str_length
    jc   t18_fail
    cmp  rax, 9
    jne  t18_fail
t18_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t19_begin
t18_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t19_begin:
    ; ----- T19: NUL after boundary -> boundary (no overread) -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT19
    mov  r8d, msgT19_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, boundary_buf          ; NUL at 9, but cap at 5
    mov  rdx, 5
    call str_length
    jc   t19_fail
    cmp  rax, 5
    jne  t19_fail
t19_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t20_begin

t19_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t20_begin

    ; ==================== str_compare tests (T20–T29) ====================
t20_begin:
    ; ----- T20: a=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT20
    mov  r8d, msgT20_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx                    ; a=NULL
    mov  rdx, 1
    lea  r8,  cmp_eq_b
    mov  r9,  1
    call str_compare
    jnc  t20_fail
    cmp  eax, ERR_NULLPTR
    jne  t20_fail
t20_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t21_begin
t20_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t21_begin:
    ; ----- T21: b=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT21
    mov  r8d, msgT21_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, cmp_eq_a
    mov  rdx, 1
    xor  r8,  r8                     ; b=NULL
    mov  r9,  1
    call str_compare
    jnc  t21_fail
    cmp  eax, ERR_NULLPTR
    jne  t21_fail
t21_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t22_begin
t21_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t22_begin:
    ; ----- T22: equal bytes & lengths -> 0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT22
    mov  r8d, msgT22_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, cmp_eq_a
    mov  rdx, 4
    lea  r8,  cmp_eq_b
    mov  r9,  4
    call str_compare
    jc   t22_fail
    cmp  rax, 0
    jne  t22_fail
t22_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t23_begin
t22_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t23_begin:
    ; ----- T23: differ at first byte -> -1 ('A' < 'B') -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT23
    mov  r8d, msgT23_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, cmp_fst_a
    mov  rdx, 3
    lea  r8,  cmp_fst_b
    mov  r9,  3
    call str_compare
    jc   t23_fail
    cmp  rax, -1
    jne  t23_fail
t23_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t24_begin
t23_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t24_begin:
    ; ----- T24: differ later -> 1 ('o' > 'e') -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT24
    mov  r8d, msgT24_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, cmp_mid_b      ; a = "hoy"
    mov  rdx, 3
    lea  r8,  cmp_mid_a      ; b = "hey"
    mov  r9,  3
    call str_compare
    jc   t24_fail
    cmp  rax, 1
    jne  t24_fail
t24_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t25_begin
t24_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t25_begin:
    ; ----- T25: a is proper prefix of b -> -1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT25
    mov  r8d, msgT25_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, cmp_pref_a
    mov  rdx, 3
    lea  r8,  cmp_pref_b
    mov  r9,  4
    call str_compare
    jc   t25_fail
    cmp  rax, -1
    jne  t25_fail
t25_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t26_begin
t25_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t26_begin:
    ; ----- T26: b is proper prefix of a -> 1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT26
    mov  r8d, msgT26_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, cmp_pref2_a
    mov  rdx, 5
    lea  r8,  cmp_pref2_b
    mov  r9,  4
    call str_compare
    jc   t26_fail
    cmp  rax, 1
    jne  t26_fail
t26_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t27_begin
t26_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t27_begin:
    ; ----- T27: (0 vs nonzero) -> -1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT27
    mov  r8d, msgT27_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; a_len=0, b="zero"(4) -> a<b
    lea  rcx, cmp_zero_b           ; pointer valid, but we pass 0 len for a
    xor  rdx, rdx                  ; a_len=0
    lea  r8,  cmp_zero_b
    mov  r9,  4
    call str_compare
    jc   t27_fail
    cmp  rax, -1
    jne  t27_fail
t27_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t28_begin
t27_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t28_begin:
    ; ----- T28: (0 vs 0) -> 0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT28
    mov  r8d, msgT28_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; both zero-length at same address is fine
    lea  rcx, cmp_zero_b
    xor  rdx, rdx
    lea  r8,  cmp_zero_b
    xor  r9,  r9
    call str_compare
    jc   t28_fail
    cmp  rax, 0
    jne  t28_fail
t28_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t29_begin
t28_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t29_begin:
    ; ----- T29: binary with NULs: 0x00 vs 0xFF -> -1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT29
    mov  r8d, msgT29_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; cmp_bin_a = FF 00 7F, cmp_bin_b = FF FF 7F
    lea  rcx, cmp_bin_a
    mov  rdx, 3
    lea  r8,  cmp_bin_b
    mov  r9,  3
    call str_compare
    jc   t29_fail
    cmp  rax, -1
    jne  t29_fail
t29_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t30_begin

t29_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t30_begin


    ; ==================== str_trim tests (T30–T38) ====================
t30_begin:
    ; ----- T30: base=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT30
    mov  r8d, msgT30_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 5
    call str_trim
    jnc  t30_fail
    cmp  eax, ERR_NULLPTR
    jne  t30_fail
t30_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t31_begin
t30_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t31_begin:
    ; ----- T31: len==0 -> success, return 0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT31
    mov  r8d, msgT31_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, buf_now
    lea  rsi, tw_no_ws
    mov  rcx, 3
    rep movsb

    lea  rcx, buf_now
    xor  rdx, rdx
    call str_trim
    jc   t31_fail
    cmp  rax, 0
    jne  t31_fail
t31_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t32_begin
t31_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t32_begin:
    ; ----- T32: all whitespace -> new_len=0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT32
    mov  r8d, msgT32_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, buf_all_ws
    lea  rsi, tw_all_ws
    mov  rcx, 8
    rep  movsb

    lea  rcx, buf_all_ws
    mov  rdx, 8
    call str_trim
    jc   t32_fail
    cmp  rax, 0
    jne  t32_fail
t32_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t33_begin
t32_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t33_begin:
    ; ----- T33: leading spaces only -> "abc" -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT33
    mov  r8d, msgT33_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, buf_lead
    lea  rsi, tw_leading
    mov  rcx, 6
    rep  movsb

    lea  rcx, buf_lead
    mov  rdx, 6
    call str_trim
    jc   t33_fail
    cmp  rax, 3
    jne  t33_fail
    lea  rsi, buf_lead
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t33_fail
    mov  al,'b'
    cmp  [rsi+1], al
    jne  t33_fail
    mov  al,'c'
    cmp  [rsi+2], al
    jne  t33_fail
t33_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t34_begin
t33_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t34_begin:
    ; ----- T34: trailing spaces only -> "abc" -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT34
    mov  r8d, msgT34_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, buf_trail
    lea  rsi, tw_trailing
    mov  rcx, 6
    rep  movsb

    lea  rcx, buf_trail
    mov  rdx, 6
    call str_trim
    jc   t34_fail
    cmp  rax, 3
    jne  t34_fail
    lea  rsi, buf_trail
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t34_fail
    mov  al,'b'
    cmp  [rsi+1], al
    jne  t34_fail
    mov  al,'c'
    cmp  [rsi+2], al
    jne  t34_fail
t34_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t35_begin
t34_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t35_begin:
    ; ----- T35: both sides mixed ws -> "abc" -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT35
    mov  r8d, msgT35_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, buf_both
    lea  rsi, tw_both
    mov  rcx, 8
    rep  movsb

    lea  rcx, buf_both
    mov  rdx, 8
    call str_trim
    jc   t35_fail
    cmp  rax, 3
    jne  t35_fail
    lea  rsi, buf_both
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t35_fail
    mov  al,'b'
    cmp  [rsi+1], al
    jne  t35_fail
    mov  al,'c'
    cmp  [rsi+2], al
    jne  t35_fail
t35_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t36_begin
t35_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t36_begin:
    ; ----- T36: no trim -> "abc" -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT36
    mov  r8d, msgT36_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, buf_now
    lea  rsi, tw_no_ws
    mov  rcx, 3
    rep  movsb

    lea  rcx, buf_now
    mov  rdx, 3
    call str_trim
    jc   t36_fail
    cmp  rax, 3
    jne  t36_fail
    lea  rsi, buf_now
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t36_fail
    mov  al,'b'
    cmp  [rsi+1], al
    jne  t36_fail
    mov  al,'c'
    cmp  [rsi+2], al
    jne  t36_fail
t36_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t37_begin
t36_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t37_begin:
    ; ----- T37: tabs-around -> "abc" -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT37
    mov  r8d, msgT37_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, buf_tabs
    lea  rsi, tw_tabs
    mov  rcx, 6
    rep  movsb

    lea  rcx, buf_tabs
    mov  rdx, 6
    call str_trim
    jc   t37_fail
    cmp  rax, 3
    jne  t37_fail
    lea  rsi, buf_tabs
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t37_fail
    mov  al,'b'
    cmp  [rsi+1], al
    jne  t37_fail
    mov  al,'c'
    cmp  [rsi+2], al
    jne  t37_fail
t37_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t38_begin
t37_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t38_begin:
    ; ----- T38: internal spaces preserved -> "a b" -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT38
    mov  r8d, msgT38_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, buf_internal
    lea  rsi, tw_internal
    mov  rcx, 5
    rep  movsb

    lea  rcx, buf_internal
    mov  rdx, 5
    call str_trim
    jc   t38_fail
    cmp  rax, 3
    jne  t38_fail
    lea  rsi, buf_internal
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t38_fail
    mov  al,' '
    cmp  [rsi+1], al
    jne  t38_fail
    mov  al,'b'
    cmp  [rsi+2], al
    jne  t38_fail
t38_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t39_begin

t38_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t39_begin

; ==================== str_to_upper tests (T39–T45) ====================
t39_begin:
    ; ----- T39: base=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT39
    mov  r8d, msgT39_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 5
    call str_to_upper
    jnc  t39_fail
    cmp  eax, ERR_NULLPTR
    jne  t39_fail
t39_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t40_begin
t39_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t40_begin:
    ; ----- T40: len==0 -> success, RAX=0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT40
    mov  r8d, msgT40_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, tu_buf_up
    xor  rdx, rdx
    call str_to_upper
    jc   t40_fail
    cmp  rax, 0
    jne  t40_fail
t40_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t41_begin
t40_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t41_begin:
    ; ----- T41: all lowercase -> all uppercase -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT41
    mov  r8d, msgT41_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; copy source into scratch
    lea  rdi, tu_buf_low
    lea  rsi, tu_src_low
    mov  rcx, 26
    rep  movsb

    lea  rcx, tu_buf_low
    mov  rdx, 26
    call str_to_upper
    jc   t41_fail
    cmp  rax, 26
    jne  t41_fail
    ; verify "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    lea  rsi, tu_buf_low
    mov  rcx, 26
    mov  rbx, 'A'
t41_check:
    mov  al, [rsi]
    cmp  al, bl
    jne  t41_fail
    inc  rsi
    inc  bl
    dec  rcx
    jnz  t41_check
t41_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t42_begin
t41_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t42_begin:
    ; ----- T42: mixed case + digits/punct unaffected -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT42
    mov  r8d, msgT42_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, tu_buf_mix
    lea  rsi, tu_src_mix
    mov  rcx, 6
    rep  movsb

    lea  rcx, tu_buf_mix
    mov  rdx, 6
    call str_to_upper
    jc   t42_fail
    cmp  rax, 6
    jne  t42_fail
    ; expected: 'A','B','C','1','!','Z'
    lea  rsi, tu_buf_mix
    mov  al,'A'  ;0
    cmp  [rsi+0], al
    jne  t42_fail
    mov  al,'B'  ;1
    cmp  [rsi+1], al
    jne  t42_fail
    mov  al,'C'  ;2
    cmp  [rsi+2], al
    jne  t42_fail
    mov  al,'1'  ;3
    cmp  [rsi+3], al
    jne  t42_fail
    mov  al,'!'  ;4
    cmp  [rsi+4], al
    jne  t42_fail
    mov  al,'Z'  ;5
    cmp  [rsi+5], al
    jne  t42_fail
t42_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t43_begin
t42_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t43_begin:
    ; ----- T43: already uppercase -> unchanged -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT43
    mov  r8d, msgT43_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, tu_buf_up
    lea  rsi, tu_src_up
    mov  rcx, 6
    rep  movsb

    lea  rcx, tu_buf_up
    mov  rdx, 6
    call str_to_upper
    jc   t43_fail
    cmp  rax, 6
    jne  t43_fail
    ; verify still "ABCXYZ"
    lea  rsi, tu_buf_up
    mov  al,'A'
    cmp  [rsi+0], al
    jne  t43_fail
    mov  al,'B'
    cmp  [rsi+1], al
    jne  t43_fail
    mov  al,'C'
    cmp  [rsi+2], al
    jne  t43_fail
    mov  al,'X'
    cmp  [rsi+3], al
    jne  t43_fail
    mov  al,'Y'
    cmp  [rsi+4], al
    jne  t43_fail
    mov  al,'Z'
    cmp  [rsi+5], al
    jne  t43_fail
t43_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t44_begin
t43_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t44_begin:
    ; ----- T44: non-ASCII bytes unchanged; 'a'/'z' still convert -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT44
    mov  r8d, msgT44_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, tu_buf_bin
    lea  rsi, tu_src_bin
    mov  rcx, 5
    rep  movsb

    lea  rcx, tu_buf_bin
    mov  rdx, 5
    call str_to_upper
    jc   t44_fail
    cmp  rax, 5
    jne  t44_fail
    ; expect: 80 FF 7F 41 5A
    lea  rsi, tu_buf_bin
    mov  al,080h
    cmp  [rsi+0], al
    jne  t44_fail
    mov  al,0FFh
    cmp  [rsi+1], al
    jne  t44_fail
    mov  al,07Fh
    cmp  [rsi+2], al
    jne  t44_fail
    mov  al,'A'
    cmp  [rsi+3], al
    jne  t44_fail
    mov  al,'Z'
    cmp  [rsi+4], al
    jne  t44_fail
t44_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t45_begin
t44_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t45_begin:
    ; ----- T45: edges 'a'->'A', 'z'->'Z' -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT45
    mov  r8d, msgT45_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, tu_buf_edges
    lea  rsi, tu_src_edges
    mov  rcx, 2
    rep  movsb

    lea  rcx, tu_buf_edges
    mov  rdx, 2
    call str_to_upper
    jc   t45_fail
    cmp  rax, 2
    jne  t45_fail
    ; expect "AZ"
    lea  rsi, tu_buf_edges
    mov  al,'A'
    cmp  [rsi+0], al
    jne  t45_fail
    mov  al,'Z'
    cmp  [rsi+1], al
    jne  t45_fail
t45_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t46_begin

t45_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t46_begin


; ==================== str_to_lower tests (T46–T52) ====================
t46_begin:
    ; ----- T46: base=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT46
    mov  r8d, msgT46_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 5
    call str_to_lower
    jnc  t46_fail
    cmp  eax, ERR_NULLPTR
    jne  t46_fail
t46_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t47_begin
t46_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t47_begin:
    ; ----- T47: len==0 -> success, RAX=0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT47
    mov  r8d, msgT47_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, tl_buf_low
    xor  rdx, rdx
    call str_to_lower
    jc   t47_fail
    cmp  rax, 0
    jne  t47_fail
t47_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t48_begin
t47_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t48_begin:
    ; ----- T48: all UPPERCASE -> all lowercase -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT48
    mov  r8d, msgT48_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; copy source into scratch
    lea  rdi, tl_buf_up
    lea  rsi, tl_src_up
    mov  rcx, 26
    rep  movsb

    lea  rcx, tl_buf_up
    mov  rdx, 26
    call str_to_lower
    jc   t48_fail
    cmp  rax, 26
    jne  t48_fail
    ; verify "abcdefghijklmnopqrstuvwxyz"
    lea  rsi, tl_buf_up
    mov  rcx, 26
    mov  rbx, 'a'
t48_check:
    mov  al, [rsi]
    cmp  al, bl
    jne  t48_fail
    inc  rsi
    inc  bl
    dec  rcx
    jnz  t48_check
t48_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t49_begin
t48_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t49_begin:
    ; ----- T49: mixed case + digits/punct unaffected -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT49
    mov  r8d, msgT49_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, tl_buf_mix
    lea  rsi, tl_src_mix
    mov  rcx, 6
    rep  movsb

    lea  rcx, tl_buf_mix
    mov  rdx, 6
    call str_to_lower
    jc   t49_fail
    cmp  rax, 6
    jne  t49_fail
    ; expected: 'a','b','c','1','!','z'
    lea  rsi, tl_buf_mix
    mov  al,'a'  ;0
    cmp  [rsi+0], al
    jne  t49_fail
    mov  al,'b'  ;1
    cmp  [rsi+1], al
    jne  t49_fail
    mov  al,'c'  ;2
    cmp  [rsi+2], al
    jne  t49_fail
    mov  al,'1'  ;3
    cmp  [rsi+3], al
    jne  t49_fail
    mov  al,'!'  ;4
    cmp  [rsi+4], al
    jne  t49_fail
    mov  al,'z'  ;5
    cmp  [rsi+5], al
    jne  t49_fail
t49_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t50_begin
t49_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t50_begin:
    ; ----- T50: already lowercase -> unchanged -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT50
    mov  r8d, msgT50_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, tl_buf_low
    lea  rsi, tl_src_low
    mov  rcx, 6
    rep  movsb

    lea  rcx, tl_buf_low
    mov  rdx, 6
    call str_to_lower
    jc   t50_fail
    cmp  rax, 6
    jne  t50_fail
    ; verify still "abcxyz"
    lea  rsi, tl_buf_low
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t50_fail
    mov  al,'b'
    cmp  [rsi+1], al
    jne  t50_fail
    mov  al,'c'
    cmp  [rsi+2], al
    jne  t50_fail
    mov  al,'x'
    cmp  [rsi+3], al
    jne  t50_fail
    mov  al,'y'
    cmp  [rsi+4], al
    jne  t50_fail
    mov  al,'z'
    cmp  [rsi+5], al
    jne  t50_fail
t50_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t51_begin
t50_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t51_begin:
    ; ----- T51: non-ASCII unchanged; 'A','Z' -> 'a','z' -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT51
    mov  r8d, msgT51_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, tl_buf_bin
    lea  rsi, tl_src_bin
    mov  rcx, 5
    rep  movsb

    lea  rcx, tl_buf_bin
    mov  rdx, 5
    call str_to_lower
    jc   t51_fail
    cmp  rax, 5
    jne  t51_fail
    ; expect: 80 FF 7F 61 7A
    lea  rsi, tl_buf_bin
    mov  al,080h
    cmp  [rsi+0], al
    jne  t51_fail
    mov  al,0FFh
    cmp  [rsi+1], al
    jne  t51_fail
    mov  al,07Fh
    cmp  [rsi+2], al
    jne  t51_fail
    mov  al,'a'
    cmp  [rsi+3], al
    jne  t51_fail
    mov  al,'z'
    cmp  [rsi+4], al
    jne  t51_fail
t51_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t52_begin
t51_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t52_begin:
    ; ----- T52: edges 'A'->'a', 'Z'->'z' -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT52
    mov  r8d, msgT52_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, tl_buf_edges
    lea  rsi, tl_src_edges
    mov  rcx, 2
    rep  movsb

    lea  rcx, tl_buf_edges
    mov  rdx, 2
    call str_to_lower
    jc   t52_fail
    cmp  rax, 2
    jne  t52_fail
    ; expect "az"
    lea  rsi, tl_buf_edges
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t52_fail
    mov  al,'z'
    cmp  [rsi+1], al
    jne  t52_fail
t52_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t53_begin

t52_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t53_begin

; ==================== str_reverse tests (T53–T60) ====================
t53_begin:
    ; ----- T53: base=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT53
    mov  r8d, msgT53_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 4
    call str_reverse
    jnc  t53_fail
    cmp  eax, ERR_NULLPTR
    jne  t53_fail
t53_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t54_begin
t53_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t54_begin:
    ; ----- T54: len==0 -> CF=0, RAX=0, no changes -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT54
    mov  r8d, msgT54_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, rv_zero_scratch
    xor  rdx, rdx
    call str_reverse
    jc   t54_fail
    cmp  rax, 0
    jne  t54_fail
t54_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t55_begin
t54_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t55_begin:
    ; ----- T55: len==1 -> unchanged -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT55
    mov  r8d, msgT55_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rv_buf_one
    lea  rsi, rv_one
    mov  rcx, 1
    rep  movsb

    lea  rcx, rv_buf_one
    mov  rdx, 1
    call str_reverse
    jc   t55_fail
    cmp  rax, 1
    jne  t55_fail
    mov  al,'X'
    cmp  byte ptr [rv_buf_one], al
    jne  t55_fail
t55_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t56_begin
t55_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t56_begin:
    ; ----- T56: even 'abcd' -> 'dcba' -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT56
    mov  r8d, msgT56_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rv_buf_even
    lea  rsi, rv_src_even
    mov  rcx, 4
    rep  movsb

    lea  rcx, rv_buf_even
    mov  rdx, 4
    call str_reverse
    jc   t56_fail
    cmp  rax, 4
    jne  t56_fail
    ; expect "dcba"
    lea  rsi, rv_buf_even
    mov  al,'d'
    cmp  [rsi+0], al
    jne  t56_fail
    mov  al,'c'
    cmp  [rsi+1], al
    jne  t56_fail
    mov  al,'b'
    cmp  [rsi+2], al
    jne  t56_fail
    mov  al,'a'
    cmp  [rsi+3], al
    jne  t56_fail
t56_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t57_begin
t56_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t57_begin:
    ; ----- T57: odd 'abcde' -> 'edcba' -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT57
    mov  r8d, msgT57_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rv_buf_odd
    lea  rsi, rv_src_odd
    mov  rcx, 5
    rep  movsb

    lea  rcx, rv_buf_odd
    mov  rdx, 5
    call str_reverse
    jc   t57_fail
    cmp  rax, 5
    jne  t57_fail
    ; expect "edcba"
    lea  rsi, rv_buf_odd
    mov  al,'e'
    cmp  [rsi+0], al
    jne  t57_fail
    mov  al,'d'
    cmp  [rsi+1], al
    jne  t57_fail
    mov  al,'c'
    cmp  [rsi+2], al
    jne  t57_fail
    mov  al,'b'
    cmp  [rsi+3], al
    jne  t57_fail
    mov  al,'a'
    cmp  [rsi+4], al
    jne  t57_fail
t57_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t58_begin
t57_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t58_begin:
    ; ----- T58: palindrome 'racecar' -> unchanged -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT58
    mov  r8d, msgT58_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rv_buf_pal
    lea  rsi, rv_src_pal
    mov  rcx, 7
    rep  movsb

    lea  rcx, rv_buf_pal
    mov  rdx, 7
    call str_reverse
    jc   t58_fail
    cmp  rax, 7
    jne  t58_fail
    ; verify still "racecar"
    lea  rsi, rv_buf_pal
    mov  al,'r'
    cmp  [rsi+0], al
    jne  t58_fail
    mov  al,'a'
    cmp  [rsi+1], al
    jne  t58_fail
    mov  al,'c'
    cmp  [rsi+2], al
    jne  t58_fail
    mov  al,'e'
    cmp  [rsi+3], al
    jne  t58_fail
    mov  al,'c'
    cmp  [rsi+4], al
    jne  t58_fail
    mov  al,'a'
    cmp  [rsi+5], al
    jne  t58_fail
    mov  al,'r'
    cmp  [rsi+6], al
    jne  t58_fail
t58_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t59_begin
t58_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t59_begin:
    ; ----- T59: binary with NULs -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT59
    mov  r8d, msgT59_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rv_buf_bin
    lea  rsi, rv_src_bin
    mov  rcx, 8
    rep  movsb

    lea  rcx, rv_buf_bin
    mov  rdx, 8
    call str_reverse
    jc   t59_fail
    cmp  rax, 8
    jne  t59_fail
    ; expect reverse of 1,0,2,0,3,0,4,0 -> 0,4,0,3,0,2,0,1
    lea  rsi, rv_buf_bin
    mov  al,0
    cmp  [rsi+0], al
    jne  t59_fail
    mov  al,4
    cmp  [rsi+1], al
    jne  t59_fail
    mov  al,0
    cmp  [rsi+2], al
    jne  t59_fail
    mov  al,3
    cmp  [rsi+3], al
    jne  t59_fail
    mov  al,0
    cmp  [rsi+4], al
    jne  t59_fail
    mov  al,2
    cmp  [rsi+5], al
    jne  t59_fail
    mov  al,0
    cmp  [rsi+6], al
    jne  t59_fail
    mov  al,1
    cmp  [rsi+7], al
    jne  t59_fail
t59_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t60_begin
t59_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t60_begin:
    ; ----- T60: 0..15 -> 15..0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT60
    mov  r8d, msgT60_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rv_buf_0_15
    lea  rsi, rv_src_0_15
    mov  rcx, 16
    rep  movsb

    lea  rcx, rv_buf_0_15
    mov  rdx, 16
    call str_reverse
    jc   t60_fail
    cmp  rax, 16
    jne  t60_fail
    ; verify 15..0
    lea  rsi, rv_buf_0_15
    mov  rcx, 16
    mov  rbx, 15
t60_check:
    mov  al, [rsi]
    cmp  al, bl
    jne  t60_fail
    inc  rsi
    dec  bl
    dec  rcx
    jnz  t60_check
t60_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t61_begin

t60_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t61_begin

; ==================== str_fill tests (T61–T67) ====================
t61_begin:
    ; ----- T61: base=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT61
    mov  r8d, msgT61_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 4
    mov  r8,  'A'
    call str_fill
    jnc  t61_fail
    cmp  eax, ERR_NULLPTR
    jne  t61_fail
t61_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t62_begin
t61_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t62_begin:
    ; ----- T62: len==0 -> success, no change -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT62
    mov  r8d, msgT62_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; snapshot first byte
    lea  rax, sf_buf8
    mov  bl, [rax]
    lea  rcx, sf_buf8
    xor  rdx, rdx
    mov  r8,  'Z'
    call str_fill
    jc   t62_fail
    cmp  rax, 0
    jne  t62_fail
    ; unchanged?
    lea  rax, sf_buf8
    cmp  bl, [rax]
    jne  t62_fail
t62_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t63_begin
t62_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t63_begin:
    ; ----- T63: fill 8 bytes with 'x' -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT63
    mov  r8d, msgT63_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; zero buffer first
    lea  rdi, sf_buf8
    xor  eax, eax
    mov  rcx, 8
    rep  stosb

    lea  rcx, sf_buf8
    mov  rdx, 8
    mov  r8,  'x'
    call str_fill
    jc   t63_fail
    cmp  rax, 8
    jne  t63_fail
    ; verify all 'x'
    lea  rsi, sf_buf8
    mov  rcx, 8
t63_chk:
    mov  al, [rsi]
    cmp  al, 'x'
    jne  t63_fail
    inc  rsi
    dec  rcx
    jnz  t63_chk
t63_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t64_begin
t63_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t64_begin:
    ; ----- T64: fill with 0xFF -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT64
    mov  r8d, msgT64_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; zero then fill
    lea  rdi, sf_buf8_b
    xor  eax, eax
    mov  rcx, 8
    rep  stosb

    lea  rcx, sf_buf8_b
    mov  rdx, 8
    mov  r8,  0FFh
    call str_fill
    jc   t64_fail
    cmp  rax, 8
    jne  t64_fail
    ; verify 0xFF
    lea  rsi, sf_buf8_b
    mov  rcx, 8
t64_chk:
    cmp  byte ptr [rsi], 0FFh
    jne  t64_fail
    inc  rsi
    dec  rcx
    jnz  t64_chk
t64_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t65_begin
t64_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t65_begin:
    ; ----- T65: partial fill preserves guards -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT65
    mov  r8d, msgT65_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; reset payload region to 0
    lea  rdi, sf_guarded+1             ; skip leading guard
    mov  rcx, 10
    xor  eax, eax
    rep  stosb

    lea  rcx, sf_guarded+1             ; base = payload
    mov  rdx, 6                         ; fill only first 6 of 10
    mov  r8,  'Q'
    call str_fill
    jc   t65_fail
    cmp  rax, 6
    jne  t65_fail

    ; guards intact?
    cmp  byte ptr [sf_guarded+0], 0AAh
    jne  t65_fail
    cmp  byte ptr [sf_guarded+11], 0BBh
    jne  t65_fail

    ; first 6 are 'Q'
    lea  rsi, sf_guarded+1
    mov  rcx, 6
t65_qchk:
    cmp  byte ptr [rsi], 'Q'
    jne  t65_fail
    inc  rsi
    dec  rcx
    jnz  t65_qchk

    ; remaining 4 are still 0
    mov  rcx, 4
t65_zchk:
    cmp  byte ptr [rsi], 0
    jne  t65_fail
    inc  rsi
    dec  rcx
    jnz  t65_zchk
t65_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t66_begin
t65_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t66_begin:
    ; ----- T66: overwrite subset after prior fill -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT66
    mov  r8d, msgT66_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; start from 16 'A's
    lea  rdi, sf_buf16
    mov  al, 'A'
    mov  rcx, 16
    rep  stosb

    ; overwrite first 5 with 'B'
    lea  rcx, sf_buf16
    mov  rdx, 5
    mov  r8,  'B'
    call str_fill
    jc   t66_fail
    cmp  rax, 5
    jne  t66_fail

    ; check 0..4 = 'B', 5..15 = 'A'
    lea  rsi, sf_buf16
    mov  rcx, 5
t66_bchk:
    cmp  byte ptr [rsi], 'B'
    jne  t66_fail
    inc  rsi
    dec  rcx
    jnz  t66_bchk

    mov  rcx, 11
t66_achk:
    cmp  byte ptr [rsi], 'A'
    jne  t66_fail
    inc  rsi
    dec  rcx
    jnz  t66_achk
t66_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t67_begin
t66_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t67_begin:
    ; ----- T67: big(ger) fill: 32 bytes -> 'Z' -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT67
    mov  r8d, msgT67_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; clear first
    lea  rdi, sf_buf32
    xor  eax, eax
    mov  rcx, 32
    rep  stosb

    lea  rcx, sf_buf32
    mov  rdx, 32
    mov  r8,  'Z'
    call str_fill
    jc   t67_fail
    cmp  rax, 32
    jne  t67_fail

    ; verify all 'Z'
    lea  rsi, sf_buf32
    mov  rcx, 32
t67_chk:
    cmp  byte ptr [rsi], 'Z'
    jne  t67_fail
    inc  rsi
    dec  rcx
    jnz  t67_chk
t67_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t68_begin

t67_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t68_begin

; ==================== str_find_char tests (T68–T77) ====================
t68_begin:
    ; ----- T68: base=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT68
    mov  r8d, msgT68_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 3
    mov  r8,  'a'
    call str_find_char
    jnc  t68_fail
    cmp  eax, ERR_NULLPTR
    jne  t68_fail
t68_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t69_begin
t68_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t69_begin:
    ; ----- T69: len==0 -> STR_NPOS -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT69
    mov  r8d, msgT69_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, sfc_head
    xor  rdx, rdx
    mov  r8,  'a'
    call str_find_char
    jc   t69_fail
    cmp  rax, STR_NPOS
    jne  t69_fail
t69_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t70_begin
t69_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t70_begin:
    ; ----- T70: hit at head -> index 0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT70
    mov  r8d, msgT70_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, sfc_head
    mov  rdx, 3
    mov  r8,  'a'
    call str_find_char
    jc   t70_fail
    cmp  rax, 0
    jne  t70_fail
t70_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t71_begin
t70_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t71_begin:
    ; ----- T71: hit in middle -> index 1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT71
    mov  r8d, msgT71_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, sfc_mid
    mov  rdx, 3
    mov  r8,  'b'
    call str_find_char
    jc   t71_fail
    cmp  rax, 1
    jne  t71_fail
t71_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t72_begin
t71_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t72_begin:
    ; ----- T72: hit at tail -> index 2 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT72
    mov  r8d, msgT72_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, sfc_tail
    mov  rdx, 3
    mov  r8,  'c'
    call str_find_char
    jc   t72_fail
    cmp  rax, 2
    jne  t72_fail
t72_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t73_begin
t72_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t73_begin:
    ; ----- T73: not found -> STR_NPOS -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT73
    mov  r8d, msgT73_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, sfc_nf
    mov  rdx, 3
    mov  r8,  'x'
    call str_find_char
    jc   t73_fail
    cmp  rax, STR_NPOS
    jne  t73_fail
t73_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t74_begin
t73_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t74_begin:
    ; ----- T74: binary; find NUL -> index 1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT74
    mov  r8d, msgT74_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, sfc_bin
    mov  rdx, 4
    xor  r8,  r8                     ; search 0x00
    call str_find_char
    jc   t74_fail
    cmp  rax, 1
    jne  t74_fail
t74_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t75_begin
t74_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t75_begin:
    ; ----- T75: repeated hits; return first -> index 1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT75
    mov  r8d, msgT75_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, sfc_repeats
    mov  rdx, 6
    mov  r8,  'a'
    call str_find_char
    jc   t75_fail
    cmp  rax, 1
    jne  t75_fail
t75_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t76_begin
t75_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t76_begin:
    ; ----- T76: boundary guard; 'o' past len -> STR_NPOS -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT76
    mov  r8d, msgT76_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    ; sfc_guard = "hello"; search only first 4 bytes ("hell")
    lea  rcx, sfc_guard
    mov  rdx, 4
    mov  r8,  'o'
    call str_find_char
    jc   t76_fail
    cmp  rax, STR_NPOS
    jne  t76_fail
t76_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t77_begin
t76_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t77_begin:
    ; ----- T77: high-bit byte 0x80 -> index 0 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT77
    mov  r8d, msgT77_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rcx, sfc_hi
    mov  rdx, 2
    mov  r8,  080h
    call str_find_char
    jc   t77_fail
    cmp  rax, 0
    jne  t77_fail
t77_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t78_begin

t77_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t78_begin

; ==================== str_replace_char tests (T78–T85) ====================
t78_begin:
    ; ----- T78: base=NULL -> ERR_NULLPTR -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT78
    mov  r8d, msgT78_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    xor  rcx, rcx
    mov  rdx, 3
    mov  r8,  'x'
    mov  r9,  'y'
    call str_replace_char
    jnc  t78_fail
    cmp  eax, ERR_NULLPTR
    jne  t78_fail
t78_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t79_begin
t78_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t79_begin:
    ; ----- T79: len==0 -> success, RAX=0, no change -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT79
    mov  r8d, msgT79_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rr_buf_none
    lea  rsi, rr_src_none
    mov  rcx, 5
    rep  movsb

    lea  rcx, rr_buf_none
    xor  rdx, rdx
    mov  r8,  'x'
    mov  r9,  'y'
    call str_replace_char
    jc   t79_fail
    cmp  rax, 0
    jne  t79_fail
    ; unchanged first 5 bytes?
    lea  rsi, rr_buf_none
    mov  al,'h'
    cmp  [rsi+0], al
    jne  t79_fail
t79_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t80_begin
t79_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t80_begin:
    ; ----- T80: no matches -> count=0, unchanged -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT80
    mov  r8d, msgT80_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rr_buf_none
    lea  rsi, rr_src_none
    mov  rcx, 5
    rep  movsb

    lea  rcx, rr_buf_none
    mov  rdx, 5
    mov  r8,  'x'
    mov  r9,  'y'
    call str_replace_char
    jc   t80_fail
    cmp  rax, 0
    jne  t80_fail
    ; verify still "hello"
    lea  rsi, rr_buf_none
    mov  al,'h'
    cmp  [rsi+0], al
    jne  t80_fail
    mov  al,'e'
    cmp  [rsi+1], al
    jne  t80_fail
t80_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t81_begin
t80_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t81_begin:
    ; ----- T81: replace some: "banana", 'a'->'o' -> "bonono", count=3 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT81
    mov  r8d, msgT81_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rr_buf_banana
    lea  rsi, rr_src_banana
    mov  rcx, 6
    rep  movsb

    lea  rcx, rr_buf_banana
    mov  rdx, 6
    mov  r8,  'a'
    mov  r9,  'o'
    call str_replace_char
    jc   t81_fail
    cmp  rax, 3
    jne  t81_fail
    ; "bonono"
    lea  rsi, rr_buf_banana
    mov  al,'b'
    cmp  [rsi+0], al
    jne  t81_fail
    mov  al,'o'
    cmp  [rsi+1], al
    jne  t81_fail
    mov  al,'n'
    cmp  [rsi+2], al
    jne  t81_fail
    mov  al,'o'
    cmp  [rsi+3], al
    jne  t81_fail
    mov  al,'n'
    cmp  [rsi+4], al
    jne  t81_fail
    mov  al,'o'
    cmp  [rsi+5], al
    jne  t81_fail
t81_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t82_begin
t81_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t82_begin:
    ; ----- T82: replace all: "aaaa" -> "zzzz"; count=4 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT82
    mov  r8d, msgT82_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rr_buf_all
    lea  rsi, rr_src_all
    mov  rcx, 4
    rep  movsb

    lea  rcx, rr_buf_all
    mov  rdx, 4
    mov  r8,  'a'
    mov  r9,  'z'
    call str_replace_char
    jc   t82_fail
    cmp  rax, 4
    jne  t82_fail
    ; "zzzz"
    lea  rsi, rr_buf_all
    mov  rcx, 4
t82_chk:
    cmp  byte ptr [rsi], 'z'
    jne  t82_fail
    inc  rsi
    dec  rcx
    jnz  t82_chk
t82_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t83_begin
t82_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t83_begin:
    ; ----- T83: old==new: count occurrences of 'a'; buffer unchanged -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT83
    mov  r8d, msgT83_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rr_buf_same
    lea  rsi, rr_src_same
    mov  rcx, 6
    rep  movsb

    lea  rcx, rr_buf_same
    mov  rdx, 6
    mov  r8,  'a'
    mov  r9,  'a'
    call str_replace_char
    jc   t83_fail
    cmp  rax, 2                       ; two 'a' in "abcabc"
    jne  t83_fail
    ; verify unchanged
    lea  rsi, rr_buf_same
    mov  al,'a'
    cmp  [rsi+0], al
    jne  t83_fail
    mov  al,'b'
    cmp  [rsi+1], al
    jne  t83_fail
t83_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t84_begin
t83_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t84_begin:
    ; ----- T84: binary: replace 0x00->0xFF; count=2 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT84
    mov  r8d, msgT84_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rr_buf_bin
    lea  rsi, rr_src_bin
    mov  rcx, 4
    rep  movsb

    lea  rcx, rr_buf_bin
    mov  rdx, 4
    xor  r8,  r8           ; old = 0x00
    mov  r9,  0FFh         ; new = 0xFF
    call str_replace_char
    jc   t84_fail
    cmp  rax, 2
    jne  t84_fail
    ; expect 1,FF,2,FF
    lea  rsi, rr_buf_bin
    mov  al,1
    cmp  [rsi+0], al
    jne  t84_fail
    cmp  byte ptr [rsi+1], 0FFh
    jne  t84_fail
    mov  al,2
    cmp  [rsi+2], al
    jne  t84_fail
    cmp  byte ptr [rsi+3], 0FFh
    jne  t84_fail
t84_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  t85_begin
t84_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

t85_begin:
    ; ----- T85: high-bit 0x80->0x7F in [80,7F] -> [7F,7F], count=1 -----
    mov  rcx, [stdoutHandle]
    lea  rdx, msgT85
    mov  r8d, msgT85_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h

    lea  rdi, rr_buf_hi
    lea  rsi, rr_src_hi
    mov  rcx, 2
    rep  movsb

    lea  rcx, rr_buf_hi
    mov  rdx, 2
    mov  r8,  080h
    mov  r9,  07Fh
    call str_replace_char
    jc   t85_fail
    cmp  rax, 1
    jne  t85_fail
    ; expect [7F, 7F]
    lea  rsi, rr_buf_hi
    cmp  byte ptr [rsi+0], 07Fh
    jne  t85_fail
    cmp  byte ptr [rsi+1], 07Fh
    jne  t85_fail
t85_pass:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgPASS
    mov  r8d, msgPASS_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  done
t85_fail:
    mov  rcx, [stdoutHandle]
    lea  rdx, msgFAIL
    mov  r8d, msgFAIL_len
    xor  r9d, r9d
    sub  rsp, 20h
    mov  qword ptr [rsp+20h], 0
    call WriteConsoleA
    add  rsp, 20h
    jmp  done



done:
    xor  ecx, ecx
    call ExitProcess
main ENDP
END
