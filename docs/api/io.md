# I/O Module API Reference

The I/O module (`io_*`) provides console input/output procedures for Windows x64.

All procedures use **best-effort semantics** — they attempt to write to stdout but do not set `CF=1` on write failures (except for `io_print_string` which returns `ERR_NULLPTR` for NULL pointers).

---

## Table of Contents

### Initialization
- [io_init](#io_init) — Initialize/cache console handles (optional)

### Character & String Output
- [io_print_char](#io_print_char) — Print single character
- [io_print_string](#io_print_string) — Print NUL-terminated string
- [io_print_newline](#io_print_newline) — Print CRLF (`\r\n`)

### Numeric Output
- [io_print_int](#io_print_int) — Print signed 64-bit integer (decimal)
- [io_print_uint](#io_print_uint) — Print unsigned 64-bit integer (decimal)
- [io_print_hex](#io_print_hex) — Print unsigned 64-bit integer (hexadecimal)
- [io_print_binary](#io_print_binary) — Print unsigned 64-bit integer (binary)

### Floating-Point Output
- [io_print_float](#io_print_float) — Print IEEE-754 double (decimal)

---

## Module Overview

The I/O module uses Windows console APIs (`WriteFile`, `GetStdHandle`) to provide output functionality.

### Key Features
- ✅ **No manual linking required** — `kernel32.lib` is linked automatically via `win32_console.inc`
- ✅ **Works with redirection** — Output works with console, pipes, and file redirection
- ✅ **Binary-safe** — Can write any byte value (including `0x00`)
- ✅ **Lazy initialization** — Stdout handle is fetched automatically on first use
- ✅ **Thread-safe handles** — Console handles are cached in module-private state

### Windows APIs Used
| API | Purpose |
|-----|---------|
| `GetStdHandle` | Fetch stdout/stdin handles (called lazily) |
| `WriteFile` | Write bytes to stdout (works with console and pipes) |

> **Note:** All procedures follow the Windows x64 calling convention and preserve non-volatile registers (`RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15`).

---

## Initialization

### io_init

Initializes and caches console handles (stdin/stdout). **Optional** — handles are fetched lazily if not initialized.

#### Signature
```nasm
io_init()
```

#### Parameters
None

#### Returns
- **Success:** `CF=0`, `RAX=0`
- **Error:** None (may be added in future versions)

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`) — May be modified (per Windows x64 ABI)

#### Notes
- Safe to call multiple times (no-op if already initialized)
- Not required — other `io_*` procedures fetch handles lazily
- May improve performance if called once at startup (avoids repeated `GetStdHandle` calls)
- Caches handles in module-private global state

#### Example
```nasm
.code
main PROC
    call io_init              ; Optional: cache handles once
    
    ; ... rest of program ...
    
    ret
main ENDP
END main
```

---

## Character & String Output

### io_print_char

Prints a single character to stdout (binary-safe).

#### Signature
```nasm
io_print_char(byteVal)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `byteVal` | `RCX` | `QWORD` | Character to print (low 8 bits used) |

#### Returns
- **Success:** `CF=0`, `RAX=1` (1 byte written)
- **Failure:** `CF=0`, `RAX=0` (write failed, best-effort)

#### Errors
None (best-effort write; does not return `ERR_*`)

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Binary-safe:** Will write any byte value (0x00..0xFF)
- Works with console or redirected stdout (pipes, files)
- Does not require `io_init()` — stdout handle fetched lazily
- No error flag on failure — check `RAX==0` if you need to detect write failure
- Uses `WriteFile` internally (works with redirection)

#### Example
```nasm
mov  rcx, 'A'
call io_print_char       ; Prints: A

mov  rcx, 0x0A
call io_print_char       ; Prints: newline (LF)

mov  rcx, 0x41
call io_print_char       ; Prints: A (same as 'A')

; Binary-safe: write NULL byte
mov  rcx, 0x00
call io_print_char       ; Writes: 0x00 (won't terminate string)
```

---

### io_print_string

Prints a NUL-terminated string to stdout.

#### Signature
```nasm
io_print_string(strz)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `strz` | `RCX` | `PTR BYTE` | Pointer to NUL-terminated string |

#### Returns
- **Success:** `CF=0`, `RAX` = bytes written
- **Error:** `CF=1`, `EAX=ERR_NULLPTR` if `strz == NULL`

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `strz == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Computes string length internally (stops at first NUL byte)
- Empty strings (`""`) return `CF=0`, `RAX=0` (success, 0 bytes written)
- Uses `WriteFile` — works with console or redirected stdout
- **NULL check is the only error** — write failure returns `RAX=0` but `CF=0`
- Only I/O procedure that sets `CF=1` on error (NULL pointer)

#### Example
```nasm
.data
msg db "Hello, World!", 0
empty db 0

.code
; Print normal string
lea  rcx, msg
call io_print_string     ; Prints: Hello, World!
                         ; CF=0, RAX = 13 (bytes written)

; Print empty string
lea  rcx, empty
call io_print_string     ; Prints: (nothing)
                         ; CF=0, RAX=0 (success, 0 bytes)

; Error: NULL pointer
xor  rcx, rcx
call io_print_string
jc   error               ; CF=1, EAX=ERR_NULLPTR

; Continue...
jmp  continue

error:
    ; Handle NULL pointer error
    cmp  eax, ERR_NULLPTR
    je   handle_null

continue:
```

---

### io_print_newline

Prints a CRLF sequence (`\r\n`) to stdout.

#### Signature
```nasm
io_print_newline()
```

#### Parameters
None

#### Returns
- **Success:** `CF=0`, `RAX=2` (2 bytes written)
- **Failure:** `CF=0`, `RAX=0` (write failed, best-effort)

#### Errors
None (best-effort write; does not return `ERR_*`)

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Prints Windows-style newline (`\r\n` = CR+LF = 0x0D 0x0A)
- Works with console or redirected stdout
- Does not require `io_init()` — stdout handle fetched lazily
- Always writes 2 bytes (or 0 on failure)

#### Example
```nasm
.data
msg1 db "Line 1", 0
msg2 db "Line 2", 0

.code
lea  rcx, msg1
call io_print_string
call io_print_newline

lea  rcx, msg2
call io_print_string
call io_print_newline

; Output:
; Line 1
; Line 2
```

---

## Numeric Output

### io_print_int

Prints a signed 64-bit integer in decimal format.

#### Signature
```nasm
io_print_int(value)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `SQWORD` | Signed 64-bit integer |

#### Returns
- **Success:** `CF=0`, `RAX` = bytes written (digit count + minus sign if negative)
- **Failure:** `CF=0`, `RAX=0` (write failed, best-effort)

#### Errors
None (best-effort write; does not return `ERR_*`)

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Handles full signed 64-bit range: `-9223372036854775808` to `9223372036854775807`
- Zero prints as `"0"` (1 byte)
- Negative numbers include leading `-` sign
- No thousands separators or padding
- Correctly handles `INT64_MIN` (`-9223372036854775808`)

#### Example
```nasm
mov  rcx, 42
call io_print_int        ; Prints: 42
                         ; RAX = 2

mov  rcx, -100
call io_print_int        ; Prints: -100
                         ; RAX = 4

mov  rcx, 0
call io_print_int        ; Prints: 0
                         ; RAX = 1

mov  rcx, 8000000000000000h  ; INT64_MIN
call io_print_int        ; Prints: -9223372036854775808
                         ; RAX = 20
```

---

### io_print_uint

Prints an unsigned 64-bit integer in decimal format.

#### Signature
```nasm
io_print_uint(value)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `QWORD` | Unsigned 64-bit integer |

#### Returns
- **Success:** `CF=0`, `RAX` = bytes written (digit count)
- **Failure:** `CF=0`, `RAX=0` (write failed, best-effort)

#### Errors
None (best-effort write; does not return `ERR_*`)

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Handles full unsigned 64-bit range: `0` to `18446744073709551615`
- Zero prints as `"0"` (1 byte)
- No leading zeros, no thousands separators
- For negative bit patterns, interprets as large unsigned values

#### Example
```nasm
mov  rcx, 0
call io_print_uint       ; Prints: 0
                         ; RAX = 1

mov  rcx, 42
call io_print_uint       ; Prints: 42
                         ; RAX = 2

mov  rcx, 1234567890
call io_print_uint       ; Prints: 1234567890
                         ; RAX = 10

mov  rcx, -1             ; 0xFFFFFFFFFFFFFFFF
call io_print_uint       ; Prints: 18446744073709551615
                         ; RAX = 20
```

---

### io_print_hex

Prints an unsigned 64-bit integer in hexadecimal format (uppercase, no `0x` prefix).

#### Signature
```nasm
io_print_hex(value, min_digits)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `QWORD` | Unsigned 64-bit integer |
| `min_digits` | `RDX` | `QWORD` | Minimum digits to print (0..16, clamped to 16) |

#### Returns
- **Success:** `CF=0`, `RAX` = bytes written
- **Failure:** `CF=0`, `RAX=0` (write failed, best-effort)

#### Errors
None (best-effort write; does not return `ERR_*`)

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Uppercase hex digits (`A`..`F`)
- No `0x` prefix (add manually if needed)
- If `value==0` and `min_digits==0`, prints `"0"` (1 digit)
- Output width = `max(actual_digits, min_digits)`
- Leading zeros added to meet `min_digits` requirement
- `min_digits > 16` is clamped to 16

#### Example
```nasm
mov  rcx, 0
mov  rdx, 0
call io_print_hex        ; Prints: 0
                         ; RAX = 1

mov  rcx, 0
mov  rdx, 8
call io_print_hex        ; Prints: 00000000
                         ; RAX = 8

mov  rcx, 0xA
mov  rdx, 0
call io_print_hex        ; Prints: A
                         ; RAX = 1

mov  rcx, 0xA
mov  rdx, 2
call io_print_hex        ; Prints: 0A
                         ; RAX = 2

mov  rcx, 0x1234ABCD
mov  rdx, 0
call io_print_hex        ; Prints: 1234ABCD
                         ; RAX = 8

mov  rcx, -1             ; 0xFFFFFFFFFFFFFFFF
mov  rdx, 0
call io_print_hex        ; Prints: FFFFFFFFFFFFFFFF
                         ; RAX = 16
```

---

### io_print_binary

Prints an unsigned 64-bit integer in binary format (no `0b` prefix).

#### Signature
```nasm
io_print_binary(value, min_bits)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `QWORD` | Unsigned 64-bit integer |
| `min_bits` | `RDX` | `QWORD` | Minimum bits to print (0..64, clamped to 64) |

#### Returns
- **Success:** `CF=0`, `RAX` = bytes written
- **Failure:** `CF=0`, `RAX=0` (write failed, best-effort)

#### Errors
None (best-effort write; does not return `ERR_*`)

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Prints `'0'` and `'1'` characters, MSB-first
- No `0b` prefix (add manually if needed)
- If `value==0` and `min_bits==0`, prints `"0"` (1 bit)
- Output width = `max(actual_bits, min_bits)`
- Leading zeros added to meet `min_bits` requirement
- `min_bits > 64` is clamped to 64

#### Example
```nasm
mov  rcx, 0
mov  rdx, 0
call io_print_binary     ; Prints: 0
                         ; RAX = 1

mov  rcx, 0
mov  rdx, 8
call io_print_binary     ; Prints: 00000000
                         ; RAX = 8

mov  rcx, 5
mov  rdx, 0
call io_print_binary     ; Prints: 101
                         ; RAX = 3

mov  rcx, 5
mov  rdx, 8
call io_print_binary     ; Prints: 00000101
                         ; RAX = 8

mov  rcx, 8000000000000000h  ; 1 << 63
mov  rdx, 0
call io_print_binary     ; Prints: 1000000000000000000000000000000000000000000000000000000000000000
                         ; RAX = 64

mov  rcx, -1             ; 0xFFFFFFFFFFFFFFFF
mov  rdx, 0
call io_print_binary     ; Prints: 1111111111111111111111111111111111111111111111111111111111111111
                         ; RAX = 64
```

---

## Floating-Point Output

### io_print_float

Prints an IEEE-754 double-precision floating-point value in decimal format.

#### Signature
```nasm
io_print_float(value, precision, flags)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `QWORD` | IEEE-754 double (raw 64-bit representation) |
| `precision` | `RDX` | `QWORD` | Digits after decimal point (0..9, clamped to 9) |
| `flags` | `R8` | `QWORD` | Reserved (must be 0) |

#### Returns
- **Success:** `CF=0`, `RAX` = bytes written
- **Failure:** `CF=0`, `RAX=0` (write failed, best-effort)

#### Errors
None (best-effort write; does not return `ERR_*`)

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)  
**Non-volatile registers preserved** (`RBX`, `RSI`, `RDI`, `RBP`, `R12`-`R15`)

#### Notes
- **Special values:**
  - `NaN` prints as `"nan"`
  - `+Infinity` prints as `"inf"`
  - `-Infinity` prints as `"-inf"`
- **Normal values:** Decimal format with rounding
- **Precision:**
  - `precision=0` prints integer part only (e.g., `"3"` for `3.14`)
  - `precision=n` prints n digits after decimal point
  - `precision > 9` is clamped to 9
- **Negative zero (`-0.0`)** prints as `"0"` (no minus sign)
- **Rounding:** Uses "round half up" (e.g., `1.999` with `precision=2` → `"2.00"`)
- Pass value as **raw bits** (use `QWORD` representation, not `XMM` register)
- Preserves all non-volatile registers internally

#### Example
```nasm
.data
d_zero   real8 0.0
d_one    real8 1.0
d_neg    real8 -1.25
d_pi     real8 3.14159265358979323846

.code
; Zero with precision 0
mov  rcx, qword ptr [d_zero]
xor  rdx, rdx
xor  r8,  r8
call io_print_float      ; Prints: 0
                         ; RAX = 1

; Zero with precision 3
mov  rcx, qword ptr [d_zero]
mov  rdx, 3
xor  r8,  r8
call io_print_float      ; Prints: 0.000
                         ; RAX = 5

; One with precision 0
mov  rcx, qword ptr [d_one]
xor  rdx, rdx
xor  r8,  r8
call io_print_float      ; Prints: 1
                         ; RAX = 1

; Negative with precision 2
mov  rcx, qword ptr [d_neg]
mov  rdx, 2
xor  r8,  r8
call io_print_float      ; Prints: -1.25
                         ; RAX = 5

; Pi with precision 2
mov  rcx, qword ptr [d_pi]
mov  rdx, 2
xor  r8,  r8
call io_print_float      ; Prints: 3.14
                         ; RAX = 4

; Pi with precision 6
mov  rcx, qword ptr [d_pi]
mov  rdx, 6
xor  r8,  r8
call io_print_float      ; Prints: 3.141593
                         ; RAX = 8

; Positive infinity
mov  rcx, 7FF0000000000000h
xor  rdx, rdx
xor  r8,  r8
call io_print_float      ; Prints: inf
                         ; RAX = 3

; Negative infinity
mov  rcx, 0FFF0000000000000h
xor  rdx, rdx
xor  r8,  r8
call io_print_float      ; Prints: -inf
                         ; RAX = 4

; NaN
mov  rcx, 7FF8000000000000h
xor  rdx, rdx
xor  r8,  r8
call io_print_float      ; Prints: nan
                         ; RAX = 3
```

---

## Common Patterns

### Building Formatted Output
```nasm
.data
label1 db "Count: ", 0
label2 db "Total: ", 0

.code
; Print labeled value
lea  rcx, label1
call io_print_string
mov  rcx, [count_var]
call io_print_int
call io_print_newline

lea  rcx, label2
call io_print_string
mov  rcx, [total_var]
call io_print_uint
call io_print_newline

; Output:
; Count: 42
; Total: 1234
```

### Printing Hex with Prefix
```nasm
.data
prefix db "0x", 0

.code
lea  rcx, prefix
call io_print_string
mov  rcx, 0xDEADBEEF
mov  rdx, 8              ; Min 8 digits
call io_print_hex
call io_print_newline

; Output:
; 0xDEADBEEF
```

### Printing Binary with Prefix
```nasm
.data
prefix db "0b", 0

.code
lea  rcx, prefix
call io_print_string
mov  rcx, 42
mov  rdx, 8              ; Min 8 bits
call io_print_binary
call io_print_newline

; Output:
; 0b00101010
```

### Multi-Line Report
```nasm
.data
header db "=== Report ===", 0
sep    db "---------------", 0

.code
; Header
lea  rcx, header
call io_print_string
call io_print_newline

; Separator
lea  rcx, sep
call io_print_string
call io_print_newline

; Content...
```

### Debug Output (Register Dump)
```nasm
.data
reg_fmt db "RAX: 0x", 0

.code
; Print register value in hex
lea  rcx, reg_fmt
call io_print_string
mov  rcx, rax            ; Value to print
mov  rdx, 16             ; 16 hex digits
call io_print_hex
call io_print_newline

; Output:
; RAX: 0x00000000DEADBEEF
```

### Error Handling Pattern
```nasm
.data
msg db "Hello", 0

.code
lea  rcx, msg
call io_print_string
jc   error               ; Only io_print_string sets CF=1

; Success path
test rax, rax            ; Check if any bytes written
jz   write_failed        ; RAX=0 means write failed (but CF=0)

jmp  continue

error:
    ; Handle NULL pointer (CF=1, EAX=ERR_NULLPTR)
    cmp  eax, ERR_NULLPTR
    je   handle_null

write_failed:
    ; Handle write failure (CF=0, RAX=0)
    ; ... retry or log error

continue:
```

---

## Performance Notes

- **Lazy handle initialization:** First call to any `io_*` procedure fetches stdout handle via `GetStdHandle`
- **Call `io_init()` once** at startup to cache handles if making many I/O calls
- **String concatenation:** Build strings in memory, then call `io_print_string` once (faster than multiple calls)
- **WriteFile overhead:** Each call has syscall overhead — batch output when possible
- **Floating-point conversion:** `io_print_float` is more expensive than integer printing due to decimal conversion

### Optimization Tips
1. ✅ **Batch writes** — Build complete output strings before printing
2. ✅ **Cache handles** — Call `io_init()` once at program start
3. ✅ **Avoid repeated calls** — Prefer one `io_print_string` over multiple `io_print_char`
4. ✅ **Use appropriate types** — `io_print_uint` is slightly faster than `io_print_int` for known positive values

---

## Thread Safety

- **Handle caching** uses module-private global state (`g_stdout`, `g_stdin`)
- **Not thread-safe** if multiple threads call I/O procedures before `io_init()`
- **Best practice:** Call `io_init()` once in main thread before spawning other threads
- **After initialization:** Safe for concurrent reads (all threads use cached handle)

---

## Redirection & Piping

All I/O procedures work correctly with:
- ✅ **Console output** — Normal terminal display
- ✅ **File redirection** — `program.exe > output.txt`
- ✅ **Pipe redirection** — `program.exe | another_program.exe`

Example:
```bash
# Normal console
C:\> myprogram.exe
Hello, World!

# File redirection
C:\> myprogram.exe > output.txt
# output.txt now contains: Hello, World!

# Pipe to another program
C:\> myprogram.exe | findstr "Hello"
Hello, World!
```

---

## See Also

- [Error Handling Guide](../error-handling.md) — Complete error model reference
- [I/O Examples](../examples/io-demo.asm) — Working code samples
- [Getting Started](../getting-started.md) — Installation and setup
- [Array Module](arrays.md) — QWORD array operations
- [String Module](strings.md) — String manipulation
