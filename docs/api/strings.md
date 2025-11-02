
# String Module API Reference

The String module (`str_*`) provides operations for working with **byte arrays** (ASCII-focused string manipulation).

All procedures follow the Windows x64 calling convention and use a consistent error model:
- **Success:** `CF=0`, result (if any) in `RAX`
- **Error:** `CF=1`, error code in `EAX`

---

## Table of Contents

### Copy Operations
- [str_copy](#str_copy) — Copy string (overlap-safe)

### Length & Comparison
- [str_length](#str_length) — Find length (up to NUL or max)
- [str_compare](#str_compare) — Lexicographic comparison

### In-Place Transformations
- [str_trim](#str_trim) — Remove leading/trailing whitespace
- [str_to_upper](#str_to_upper) — Convert to uppercase
- [str_to_lower](#str_to_lower) — Convert to lowercase
- [str_reverse](#str_reverse) — Reverse string
- [str_fill](#str_fill) — Fill with byte value

### Search & Replace
- [str_find_char](#str_find_char) — Find first occurrence of byte
- [str_replace_char](#str_replace_char) — Replace all occurrences

---

## Module Overview

The String module provides explicit-length string operations (no assumption of NUL-termination unless documented).

### Key Features
- ✅ **Binary-safe** — Handles arbitrary byte sequences (including embedded NULs)
- ✅ **Explicit lengths** — No hidden strlen() calls; you specify exact byte counts
- ✅ **Overlap-safe** — Copy operations use memmove semantics
- ✅ **ASCII-focused** — Case conversions and whitespace detection use ASCII rules
- ✅ **No allocation** — All operations work in-place or with caller-provided buffers

### Important Constants
| Constant | Value | Meaning |
|----------|-------|---------|
| `STR_NPOS` | `0xFFFFFFFFFFFFFFFF` (`-1`) | "Not found" sentinel (returned by search operations) |

> **Note:** All procedures preserve non-volatile registers (`RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15`).

---

## Copy Operations

### str_copy

Copies bytes from source to destination buffer. **Overlap-safe** (uses memmove semantics).

#### Signature
```nasm
str_copy(dst, dst_cap, src, src_len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `dst` | `RCX` | `PTR BYTE` | Destination buffer base |
| `dst_cap` | `RDX` | `QWORD` | Destination buffer capacity (bytes) |
| `src` | `R8` | `PTR BYTE` | Source buffer base |
| `src_len` | `R9` | `QWORD` | Number of bytes to copy |

#### Returns
- **Success:** `CF=0`, `RAX` = new length (== `src_len`)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `dst == NULL` or `src == NULL` |
| `3` | `ERR_LEN_ZERO` | `src_len == 0` |
| `4` | `ERR_CAPACITY` | `src_len > dst_cap` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Copies exactly `src_len` bytes (no NUL terminator added)
- **Overlap-safe:** Automatically chooses forward or backward copy direction
- If `dst == src`, no-op (returns success)
- Length units are **bytes** (not characters)
- Binary-safe (handles embedded NULs)

#### Example
```nasm
.data
source db "hello"
dest   db 10 dup(?)

.code
; Normal copy (no overlap)
lea  rcx, dest           ; dst
mov  rdx, 10             ; dst_cap
lea  r8,  source         ; src
mov  r9,  5              ; src_len
call str_copy
jc   error               ; Check for errors

; Success: dest = "hello" (5 bytes), RAX = 5

error:
    ; Handle error (EAX contains ERR_*)
```

#### Overlap Example
```nasm
.data
buffer db "ABCDEF"

.code
; Shift right (overlap: dst > src)
lea  rcx, buffer[1]      ; dst = &buffer[1]
mov  rdx, 6              ; dst_cap
lea  r8,  buffer         ; src = &buffer[0]
mov  r9,  4              ; src_len (copy "ABCD")
call str_copy            ; Overlap-safe

; Result: buffer = "AABCD" + original 'F'
```

---

## Length & Comparison

### str_length

Finds the length of a byte sequence (up to first NUL or max_len).

#### Signature
```nasm
str_length(src, max_len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `src` | `RCX` | `PTR BYTE` | Buffer base |
| `max_len` | `RDX` | `QWORD` | Maximum bytes to scan |

#### Returns
- **Success:** `CF=0`, `RAX` = length (bytes before first `0x00`, up to `max_len`)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `src == NULL` |
| `3` | `ERR_LEN_ZERO` | `max_len == 0` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Binary-safe `strnlen`: scans for first `0x00` byte
- If no NUL found within `max_len`, returns `max_len`
- Does **not** read past `max_len` (safe for non-terminated buffers)
- Uses `repne scasb` internally (fast)

#### Example
```nasm
.data
str1 db "hello", 0
str2 db "world"          ; No terminator

.code
; Normal NUL-terminated string
lea  rcx, str1
mov  rdx, 10             ; max_len
call str_length
jc   error

; Success: RAX = 5 (length of "hello")

; Non-terminated buffer
lea  rcx, str2
mov  rdx, 5              ; max_len
call str_length
jc   error

; Success: RAX = 5 (no NUL found, returns max_len)

error:
    ; Handle error
```

---

### str_compare

Lexicographic comparison of two byte sequences (unsigned).

#### Signature
```nasm
str_compare(a, a_len, b, b_len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `a` | `RCX` | `PTR BYTE` | First buffer base |
| `a_len` | `RDX` | `QWORD` | First buffer length (bytes) |
| `b` | `R8` | `PTR BYTE` | Second buffer base |
| `b_len` | `R9` | `QWORD` | Second buffer length (bytes) |

#### Returns
- **Success:** `CF=0`, `RAX` = comparison result:
  - `RAX =  0` if `a == b` (same bytes, same length)
  - `RAX = -1` if `a < b` (first differing byte in `a` is smaller, or `a` is prefix of `b`)
  - `RAX =  1` if `a > b` (first differing byte in `a` is larger, or `b` is prefix of `a`)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `a == NULL` or `b == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Binary-safe:** Compares raw bytes (unsigned 0..255), NULs treated like any byte
- **Lexicographic:** Byte-by-byte comparison (like `memcmp` + length check)
- No length restrictions: `a_len` and/or `b_len` may be zero
- Uses `repe cmpsb` internally (fast)
- Overlap between `a` and `b` is harmless (read-only)

#### Example
```nasm
.data
str1 db "apple"
str2 db "banana"
str3 db "apple"

.code
; Compare equal strings
lea  rcx, str1           ; a
mov  rdx, 5              ; a_len
lea  r8,  str3           ; b
mov  r9,  5              ; b_len
call str_compare
jc   error

; Success: RAX = 0 (equal)

; Compare different strings
lea  rcx, str1           ; a = "apple"
mov  rdx, 5              ; a_len
lea  r8,  str2           ; b = "banana"
mov  r9,  6              ; b_len
call str_compare
jc   error

; Success: RAX = -1 (a < b, because 'a' < 'b')

; Prefix comparison
lea  rcx, str1           ; a = "apple"
mov  rdx, 3              ; a_len = 3 ("app")
lea  r8,  str1           ; b = "apple"
mov  r9,  5              ; b_len = 5
call str_compare
jc   error

; Success: RAX = -1 (a is prefix of b)

error:
    ; Handle error
```

---

## In-Place Transformations

### str_trim

Removes leading and trailing ASCII whitespace from a string (in-place).

#### Signature
```nasm
str_trim(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR BYTE` | Buffer base (modified in-place) |
| `len` | `RDX` | `QWORD` | Buffer length (bytes) |

#### Returns
- **Success:** `CF=0`, `RAX` = new length after trimming
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Whitespace definition:** ASCII bytes in `{0x20, 0x09..0x0D}`:
  - `0x20` — Space
  - `0x09` — Horizontal tab
  - `0x0A` — Line feed (LF)
  - `0x0B` — Vertical tab
  - `0x0C` — Form feed
  - `0x0D` — Carriage return (CR)
- **Middle whitespace is preserved**
- Data is left-shifted if leading whitespace removed
- `len == 0` is allowed (returns 0, success)
- Binary-safe for non-whitespace bytes
- Does **not** add NUL terminator

#### Example
```nasm
.data
str1 db "   hello   "    ; 11 bytes
str2 db 9, 9, "abc", 0Dh, 0Ah  ; tabs and CR/LF

.code
; Trim spaces
lea  rcx, str1
mov  rdx, 11
call str_trim
jc   error

; Success: RAX = 5, str1 = "hello" (shifted left)

; Trim tabs and CR/LF
lea  rcx, str2
mov  rdx, 7
call str_trim
jc   error

; Success: RAX = 3, str2 = "abc" (shifted left)

error:
    ; Handle error
```

---

### str_to_upper

Converts ASCII lowercase letters to uppercase (in-place).

#### Signature
```nasm
str_to_upper(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR BYTE` | Buffer base (modified in-place) |
| `len` | `RDX` | `QWORD` | Buffer length (bytes) |

#### Returns
- **Success:** `CF=0`, `RAX` = bytes processed (== `len`)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **ASCII-only:** Bytes in `['a' (0x61) .. 'z' (0x7A)]` → uppercase (subtract `0x20`)
- **All other bytes unchanged** (digits, punctuation, non-ASCII, etc.)
- Binary-safe (no NUL required)
- `len == 0` is allowed (returns 0, success)
- Does **not** add NUL terminator

#### Example
```nasm
.data
str1 db "hello"
str2 db "Hello, World!"
str3 db "ABC123"

.code
; Convert all lowercase
lea  rcx, str1
mov  rdx, 5
call str_to_upper
jc   error

; Success: str1 = "HELLO"

; Mixed case
lea  rcx, str2
mov  rdx, 13
call str_to_upper
jc   error

; Success: str2 = "HELLO, WORLD!"

; Already uppercase + digits
lea  rcx, str3
mov  rdx, 6
call str_to_upper
jc   error

; Success: str3 = "ABC123" (unchanged)

error:
    ; Handle error
```

---

### str_to_lower

Converts ASCII uppercase letters to lowercase (in-place).

#### Signature
```nasm
str_to_lower(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR BYTE` | Buffer base (modified in-place) |
| `len` | `RDX` | `QWORD` | Buffer length (bytes) |

#### Returns
- **Success:** `CF=0`, `RAX` = bytes processed (== `len`)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **ASCII-only:** Bytes in `['A' (0x41) .. 'Z' (0x5A)]` → lowercase (add `0x20`)
- **All other bytes unchanged** (digits, punctuation, non-ASCII, etc.)
- Binary-safe (no NUL required)
- `len == 0` is allowed (returns 0, success)
- Does **not** add NUL terminator

#### Example
```nasm
.data
str1 db "HELLO"
str2 db "Hello, World!"
str3 db "abc123"

.code
; Convert all uppercase
lea  rcx, str1
mov  rdx, 5
call str_to_lower
jc   error

; Success: str1 = "hello"

; Mixed case
lea  rcx, str2
mov  rdx, 13
call str_to_lower
jc   error

; Success: str2 = "hello, world!"

; Already lowercase + digits
lea  rcx, str3
mov  rdx, 6
call str_to_lower
jc   error

; Success: str3 = "abc123" (unchanged)

error:
    ; Handle error
```

---

### str_reverse

Reverses a byte sequence in-place.

#### Signature
```nasm
str_reverse(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR BYTE` | Buffer base (modified in-place) |
| `len` | `RDX` | `QWORD` | Buffer length (bytes) |

#### Returns
- **Success:** `CF=0`, `RAX` = `len`
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Binary-safe (treats bytes as raw data)
- `len == 0` or `len == 1` → no-op (returns success)
- Uses two-pointer swap from ends (O(n), in-place)
- Does **not** add NUL terminator

#### Example
```nasm
.data
str1 db "hello"
str2 db "abcd"
str3 db "racecar"

.code
; Reverse normal string
lea  rcx, str1
mov  rdx, 5
call str_reverse
jc   error

; Success: str1 = "olleh"

; Reverse even-length
lea  rcx, str2
mov  rdx, 4
call str_reverse
jc   error

; Success: str2 = "dcba"

; Reverse palindrome
lea  rcx, str3
mov  rdx, 7
call str_reverse
jc   error

; Success: str3 = "racecar" (unchanged)

error:
    ; Handle error
```

---

### str_fill

Fills a buffer with a specific byte value.

#### Signature
```nasm
str_fill(base, len, byteval)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR BYTE` | Buffer base (modified in-place) |
| `len` | `RDX` | `QWORD` | Buffer length (bytes) |
| `byteval` | `R8` | `QWORD` | Byte value to write (low 8 bits used) |

#### Returns
- **Success:** `CF=0`, `RAX` = `len`
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Binary-safe: writes exactly `len` bytes of `byteval` (low 8 bits)
- `len == 0` is allowed (no writes, returns 0 with success)
- Does **not** add NUL terminator
- Useful for clearing buffers or initializing memory

#### Example
```nasm
.data
buffer db 10 dup(?)

.code
; Fill with 'A'
lea  rcx, buffer
mov  rdx, 10
mov  r8,  'A'
call str_fill
jc   error

; Success: buffer = "AAAAAAAAAA" (10 A's)

; Fill with zero
lea  rcx, buffer
mov  rdx, 10
xor  r8,  r8             ; byteval = 0
call str_fill
jc   error

; Success: buffer = all zeros

; Fill with binary value
lea  rcx, buffer
mov  rdx, 10
mov  r8,  0xFF
call str_fill
jc   error

; Success: buffer = 0xFF repeated 10 times

error:
    ; Handle error
```

---

## Search & Replace

### str_find_char

Finds the first occurrence of a byte in a buffer.

#### Signature
```nasm
str_find_char(base, len, byteval)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR BYTE` | Buffer base (read-only) |
| `len` | `RDX` | `QWORD` | Buffer length (bytes) |
| `byteval` | `R8` | `QWORD` | Target byte (low 8 bits used) |

#### Returns
- **Success:** `CF=0`, `RAX` = index (0..len-1) of first occurrence, or `STR_NPOS` if not found
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Binary-safe: scans for any byte (including NUL)
- `len == 0` is allowed (returns `STR_NPOS`, success)
- Does **not** over-read: only examines exactly `len` bytes
- Uses `repne scasb` internally (fast)
- **Not an error if not found** — check `RAX == STR_NPOS`

#### Example
```nasm
.data
str1 db "hello"
str2 db "banana"

.code
; Find 'l' in "hello"
lea  rcx, str1
mov  rdx, 5
mov  r8,  'l'
call str_find_char
jc   error

; Success: RAX = 2 (index of first 'l')

; Find 'a' in "banana"
lea  rcx, str2
mov  rdx, 6
mov  r8,  'a'
call str_find_char
jc   error

; Success: RAX = 1 (index of first 'a')

; Find 'x' (not present)
lea  rcx, str1
mov  rdx, 5
mov  r8,  'x'
call str_find_char
jc   error

; Success: RAX = STR_NPOS (-1) — not found

error:
    ; Handle error
```

---

### str_replace_char

Replaces all occurrences of one byte with another (in-place).

#### Signature
```nasm
str_replace_char(base, len, oldch, newch)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR BYTE` | Buffer base (modified in-place) |
| `len` | `RDX` | `QWORD` | Buffer length (bytes) |
| `oldch` | `R8` | `QWORD` | Target byte to replace (low 8 bits) |
| `newch` | `R9` | `QWORD` | Replacement byte (low 8 bits) |

#### Returns
- **Success:** `CF=0`, `RAX` = number of bytes replaced (0..len)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Binary-safe (works with any byte values)
- `len == 0` is allowed (returns 0, success)
- If `oldch == newch`, buffer is unchanged but count is still returned
- Replaces **all** occurrences in the buffer
- Does **not** add NUL terminator

#### Example
```nasm
.data
str1 db "banana"
str2 db "hello"
str3 db "abcabc"

.code
; Replace 'a' with 'o' in "banana"
lea  rcx, str1
mov  rdx, 6
mov  r8,  'a'
mov  r9,  'o'
call str_replace_char
jc   error

; Success: str1 = "bonono", RAX = 3

; Replace 'x' (not present) in "hello"
lea  rcx, str2
mov  rdx, 5
mov  r8,  'x'
mov  r9,  'y'
call str_replace_char
jc   error

; Success: str2 = "hello" (unchanged), RAX = 0

; Replace with same character (count only)
lea  rcx, str3
mov  rdx, 6
mov  r8,  'a'
mov  r9,  'a'
call str_replace_char
jc   error

; Success: str3 = "abcabc" (unchanged), RAX = 2

error:
    ; Handle error
```

---

## Common Patterns

### Building Strings
```nasm
.data
buffer db 100 dup(?)
part1  db "Hello"
part2  db "World"

.code
; Copy first part
lea  rcx, buffer
mov  rdx, 100
lea  r8,  part1
mov  r9,  5
call str_copy
jc   error

; Manually append (str_concat not yet implemented)
; ... add spacing, second part, etc.
```

### String Processing Pipeline
```nasm
.data
input db "   HELLO, WORLD!   "

.code
; 1. Trim whitespace
lea  rcx, input
mov  rdx, 19
call str_trim
jc   error
mov  [trimmed_len], rax

; 2. Convert to lowercase
lea  rcx, input
mov  rdx, [trimmed_len]
call str_to_lower
jc   error

; Result: input = "hello, world!" (trimmed + lowercased)

error:
    ; Handle error
```

### Search and Replace Pattern
```nasm
.data
log_msg db "user:admin pass:1234"

.code
; Redact password digits
lea  rcx, log_msg
mov  rdx, 20
mov  r8,  ':'
call str_find_char
jc   error

; Check if found
cmp  rax, STR_NPOS
je   not_found

; Replace digits after second ':'
; ... (find second ':', then replace '0'-'9' with '*')

not_found:
error:
```

### Binary Data Manipulation
```nasm
.data
packet db 0x01, 0x02, 0x00, 0x03  ; With embedded NUL

.code
; Find NUL byte
lea  rcx, packet
mov  rdx, 4
xor  r8,  r8             ; byteval = 0x00
call str_find_char
jc   error

; Success: RAX = 2 (index of NUL)

; Replace NUL with escape sequence (manual handling required)
```

---

## Performance Notes

- **`str_copy`** uses byte-by-byte loop (overlap detection overhead minimal)
- **`str_length`** and **`str_find_char`** use `repne scasb` (very fast string scan)
- **`str_compare`** uses `repe cmpsb` (fast lexicographic compare)
- **Case conversions** (`str_to_upper`, `str_to_lower`) are O(n) single-pass
- **`str_reverse`** is O(n/2) with in-place swaps (no extra memory)
- **`str_fill`** is O(n) (consider using `rep stosb` for very large buffers)

### Optimization Tips
1. ✅ **Batch operations** — Chain transformations without intermediate copies
2. ✅ **Avoid repeated trimming** — Trim once and cache result length
3. ✅ **Use explicit lengths** — Faster than repeated strlen()-style scans
4. ✅ **Pre-allocate buffers** — Avoid capacity errors

---

## Thread Safety

- **All procedures are thread-safe** (no global state)
- Safe for concurrent operations on **different buffers**
- **Not safe** for concurrent modifications to the **same buffer** (data race)

---

## Binary Safety

All procedures are **binary-safe** unless noted:
- ✅ **Handle embedded NULs** correctly
- ✅ **No assumptions about terminators**
- ✅ **Explicit byte counts** (not string lengths)

**Exception:** `str_length` specifically scans **for** NULs (that's its purpose).

---

## See Also

- [Error Handling Guide](../error-handling.md) — Complete error model reference
- [String Examples](../examples/string-demo.asm) — Working code samples
- [Getting Started](../getting-started.md) — Installation and setup
- [Array Module](arrays.md) — QWORD array operations
- [I/O Module](io.md) — Console output
