IFNDEF IO_INC_GUARD ; header guard
IO_INC_GUARD EQU 1

; make case sensitive
OPTION casemap:none

INCLUDE macros.inc
INCLUDE errors.inc

; _______________________________________________________
; I/O API (Windows x64, console)
; Conventions for ALL io_*:
;   - Uses Windows console APIs under the hood (WriteConsoleA / ReadConsoleA).
;   - Each proc is safe to call without prior init; however, calling io_init
;     once lets the implementation cache handles internally (optional).
; Calling convention (Win64):
;   RCX, RDX, R8, R9 = first four arguments; additional go on stack.
; Returns:
;   Success: CF=0, RAX = bytes produced/consumed or a value as documented.
;   Error:  CF=1, EAX = ERR_*
; Clobbers:
;   RAX, RCX, RDX, R8, R9, R10, R11 (volatile)
; _______________________________________________________

; ---- public constants (console handles) ----
STD_INPUT_HANDLE   EQU -10       ; GetStdHandle(STD_INPUT_HANDLE)
STD_OUTPUT_HANDLE  EQU -11       ; GetStdHandle(STD_OUTPUT_HANDLE)

; ---- optional initialization ----
; Initializes/caches console handles (stdin/stdout). Safe to call multiple times.
io_init            PROTO

; ---- printing (write to stdout) ----
; Simple character (low 8 bits used)
io_print_char      PROTO :QWORD                               ; (ch) -> RAX=1

; Raw string (binary-safe): writes exactly 'len' bytes from ptr
io_print_string    PROTO :QWORD, :QWORD                       ; (ptr, len) -> RAX=bytes written

; Signed/unsigned 64-bit integers in decimal
io_print_int       PROTO :QWORD                               ; (s64 value) -> RAX=bytes written
io_print_uint      PROTO :QWORD                               ; (u64 value) -> RAX=bytes written

; Hexadecimal printing: 'value' as hex, at least 'min_digits' (pad with '0')
io_print_hex       PROTO :QWORD, :QWORD                       ; (u64 value, min_digits[0..16]) -> RAX=bytes

; Binary printing: 'value' as bits, at least 'min_bits' (pad with '0')
io_print_binary    PROTO :QWORD, :QWORD                       ; (u64 value, min_bits[0..64]) -> RAX=bytes

; Float printing (IEEE-754 double): precision = digits after decimal (0..?),
; flags reserved for future (e.g., scientific)
io_print_float     PROTO :QWORD, :QWORD, :QWORD               ; (double value, precision, flags) -> RAX=bytes

;WILL IMPLEMENT LATER
; Memory dump (binary-safe): prints len bytes from ptr in a canonical format
; Format is TBA; initially may be a simple hex stream or hex+ASCII per line
;io_print_mem       PROTO :QWORD, :QWORD                       ; (ptr, len) -> RAX=bytes

; Register/value printing helper (format flags TBA; e.g., hex/dec/pfx width)
io_print_reg       PROTO :QWORD, :QWORD                       ; (u64 value, flags) -> RAX=bytes

; CRLF convenience
io_print_newline   PROTO                                       ; () -> RAX=bytes (2 for "\r\n")

; ---- reading (from stdin) ----
; Reads exactly one byte; stores at [out_ptr]; RAX=1 on success
io_read_char       PROTO :QWORD                               ; (out_ptr) -> RAX=1

; Reads a (possibly binary) sequence up to dst_cap or newline; returns length via RAX
; Stops on '\n' (consumes it) or when dst_cap is reached. Does NOT append NUL.
io_read_string     PROTO :QWORD, :QWORD                       ; (dst, dst_cap) -> RAX=len read

; Parse signed/unsigned integer from input (decimal); RAX = value on success
; Whitespace skipped; stops at first non-digit (or sign+digits for signed).
io_read_int        PROTO :QWORD                               ; (out_ptr_qword) -> RAX=chars consumed
io_read_uint       PROTO :QWORD                               ; (out_ptr_qword) -> RAX=chars consumed

; Parse hex/binary strings into a u64; RAX = chars consumed
io_read_hex        PROTO :QWORD                               ; (out_ptr_qword) -> RAX=chars consumed
io_read_binary     PROTO :QWORD                               ; (out_ptr_qword) -> RAX=chars consumed

ENDIF ; IO_INC_GUARD
