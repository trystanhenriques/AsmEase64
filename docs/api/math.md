# Math Module API Reference

The Math module (`math_*`) provides integer mathematical operations for Windows x64.

All procedures follow the Windows x64 calling convention and use a consistent error model:
- **Success:** `CF=0`, result in `RAX`
- **Error:** `CF=1`, error code in `EAX`

---

## Table of Contents

### Basic Operations
- [math_abs](#math_abs) — Absolute value (magnitude)
- [math_sign](#math_sign) — Sign of value (-1, 0, +1)
- [math_clamp](#math_clamp) — Clamp value to range

### Advanced Operations
- [math_power](#math_power) — Integer exponentiation

### Predicates
- [math_is_even](#math_is_even) — Test if value is even
- [math_is_odd](#math_is_odd) — Test if value is odd

---

## Module Overview

The Math module provides pure integer math helpers with no global state.

### Key Features
- ✅ **Pure functions** — No global state; thread-safe
- ✅ **Overflow detection** — `math_power` detects and reports arithmetic overflow
- ✅ **Branchless implementations** — `math_abs`, `math_sign`, predicates use branchless algorithms
- ✅ **Signed arithmetic** — Handles full 64-bit signed range (including `INT64_MIN`)
- ✅ **No floating-point** — All operations are integer-only

### Design Philosophy
- **No exceptions** — Errors returned via CF/EAX (e.g., overflow, invalid arguments)
- **Explicit behavior** — Special cases like `0^0` are documented
- **Predictable performance** — All operations are O(1) except `math_power` (O(log exp))

> **Note:** All procedures preserve non-volatile registers (`RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15`).

---

## Basic Operations

### math_abs

Returns the absolute value (magnitude) of a signed 64-bit integer.

#### Signature
```nasm
math_abs(value)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `SQWORD` | Signed 64-bit integer |

#### Returns
- **Success:** `CF=0`, `RAX` = magnitude (unsigned 64-bit)
- **Error:** None (never fails)

#### Errors
None — always succeeds

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Branchless implementation** using mask arithmetic: `(x ^ mask) - mask` where `mask = x >> 63`
- **Special case:** For `INT64_MIN` (`-9223372036854775808` or `0x8000000000000000`), returns `0x8000000000000000` (2^63)
  - This is the **only** case where magnitude doesn't fit in signed 64-bit range
- Result is always unsigned (even though technically returns `SQWORD`, interpret as `QWORD`)

#### Example
```nasm
; Positive value
mov  rcx, 42
call math_abs
; RAX = 42

; Negative value
mov  rcx, -100
call math_abs
; RAX = 100

; Zero
mov  rcx, 0
call math_abs
; RAX = 0

; INT64_MIN (special case)
mov  rcx, 8000000000000000h
call math_abs
; RAX = 0x8000000000000000 (2^63)
```

---

### math_sign

Returns the sign of a signed 64-bit integer.

#### Signature
```nasm
math_sign(value)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `SQWORD` | Signed 64-bit integer |

#### Returns
- **Success:** `CF=0`, `RAX` = sign:
  - `RAX = -1` if `value < 0`
  - `RAX =  0` if `value == 0`
  - `RAX = +1` if `value > 0`
- **Error:** None (never fails)

#### Errors
None — always succeeds

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Branchless implementation:** `sign = (x >> 63) | (x != 0)`
- Handles full signed 64-bit range including `INT64_MIN`
- Result is always one of three values: `-1`, `0`, `+1`

#### Example
```nasm
; Positive value
mov  rcx, 42
call math_sign
; RAX = 1

; Negative value
mov  rcx, -100
call math_sign
; RAX = -1 (0xFFFFFFFFFFFFFFFF)

; Zero
mov  rcx, 0
call math_sign
; RAX = 0

; INT64_MIN
mov  rcx, 8000000000000000h
call math_sign
; RAX = -1
```

---

### math_clamp

Clamps a value to a specified range `[min, max]`.

#### Signature
```nasm
math_clamp(value, min, max)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `SQWORD` | Value to clamp |
| `min` | `RDX` | `SQWORD` | Minimum allowed value |
| `max` | `R8` | `SQWORD` | Maximum allowed value |

#### Returns
- **Success:** `CF=0`, `RAX` = clamped value:
  - `RAX = min` if `value < min`
  - `RAX = max` if `value > max`
  - `RAX = value` otherwise
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `3` | `ERR_BADARG` | `min > max` (invalid range) |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Range validation: **requires `min <= max`**
- Uses signed comparison (`jge`, `jle`)
- Useful for bounds checking, saturation arithmetic, UI constraints

#### Example
```nasm
; Value in range
mov  rcx, 5             ; value
mov  rdx, 0             ; min
mov  r8,  10            ; max
call math_clamp
; RAX = 5 (unchanged)

; Value below min
mov  rcx, -5            ; value
mov  rdx, 0             ; min
mov  r8,  10            ; max
call math_clamp
; RAX = 0 (clamped to min)

; Value above max
mov  rcx, 15            ; value
mov  rdx, 0             ; min
mov  r8,  10            ; max
call math_clamp
; RAX = 10 (clamped to max)

; Invalid range (min > max)
mov  rcx, 5             ; value
mov  rdx, 10            ; min
mov  r8,  0             ; max
call math_clamp
jc   error
; CF=1, EAX=ERR_BADARG

error:
    ; Handle error
```

---

## Advanced Operations

### math_power

Computes integer exponentiation: `base^exp`.

#### Signature
```nasm
math_power(base, exp)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `SQWORD` | Base value (signed 64-bit) |
| `exp` | `RDX` | `QWORD` | Exponent (unsigned 64-bit, non-negative) |

#### Returns
- **Success:** `CF=0`, `RAX` = `base^exp` (signed 64-bit)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `5` | `ERR_OVERFLOW` | Result doesn't fit in 64-bit signed integer |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Algorithm:** Exponentiation by squaring (O(log exp))
- **Special cases:**
  - `0^0` returns `1` (by mathematical convention)
  - `0^n` (n > 0) returns `0`
  - `1^n` always returns `1`
  - `(-1)^n` returns `-1` if n is odd, `+1` if n is even
- **Overflow detection:** Checks magnitude bounds during multiplication
  - For non-negative results: max allowed is `INT64_MAX` (`0x7FFFFFFFFFFFFFFF`)
  - For negative results: max allowed magnitude is `2^63` (`0x8000000000000000`)
- **Negative base handling:**
  - Sign of result determined by parity of exponent
  - Magnitude computed separately, then sign applied

#### Example
```nasm
; Basic powers
mov  rcx, 2             ; base
mov  rdx, 10            ; exp
call math_power
; RAX = 1024 (2^10)

mov  rcx, 3             ; base
mov  rdx, 5             ; exp
call math_power
; RAX = 243 (3^5)

; Special case: 0^0
mov  rcx, 0             ; base
mov  rdx, 0             ; exp
call math_power
; RAX = 1

; Zero to any positive power
mov  rcx, 0             ; base
mov  rdx, 5             ; exp
call math_power
; RAX = 0

; Negative base, odd exponent
mov  rcx, -2            ; base
mov  rdx, 3             ; exp
call math_power
; RAX = -8 ((-2)^3)

; Negative base, even exponent
mov  rcx, -2            ; base
mov  rdx, 4             ; exp
call math_power
; RAX = 16 ((-2)^4)

; Maximum safe negative power
mov  rcx, -2            ; base
mov  rdx, 63            ; exp
call math_power
; RAX = 0x8000000000000000 ((-2)^63 = -2^63 = INT64_MIN)

; Overflow case
mov  rcx, 2             ; base
mov  rdx, 63            ; exp (2^63 doesn't fit in signed 64-bit)
call math_power
jc   overflow
; CF=1, EAX=ERR_OVERFLOW

overflow:
    ; Handle overflow
```

---

## Predicates

### math_is_even

Tests if a value is even.

#### Signature
```nasm
math_is_even(value)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `QWORD` | Value to test (unsigned 64-bit) |

#### Returns
- **Success:** `CF=0`, `RAX` = result:
  - `RAX = 1` if value is even
  - `RAX = 0` if value is odd
- **Error:** None (never fails)

#### Errors
None — always succeeds

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Branchless implementation:** `test value, 1` + `setz`
- Tests least significant bit (LSB)
- Works for both signed and unsigned interpretation

#### Example
```nasm
; Even value
mov  rcx, 42
call math_is_even
; RAX = 1

; Odd value
mov  rcx, 43
call math_is_even
; RAX = 0

; Zero (even)
mov  rcx, 0
call math_is_even
; RAX = 1

; Negative even value
mov  rcx, -2
call math_is_even
; RAX = 1

; Negative odd value
mov  rcx, -1
call math_is_even
; RAX = 0
```

---

### math_is_odd

Tests if a value is odd.

#### Signature
```nasm
math_is_odd(value)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `value` | `RCX` | `QWORD` | Value to test (unsigned 64-bit) |

#### Returns
- **Success:** `CF=0`, `RAX` = result:
  - `RAX = 1` if value is odd
  - `RAX = 0` if value is even
- **Error:** None (never fails)

#### Errors
None — always succeeds

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Branchless implementation:** `test value, 1` + `setnz`
- Tests least significant bit (LSB)
- Works for both signed and unsigned interpretation

#### Example
```nasm
; Odd value
mov  rcx, 43
call math_is_odd
; RAX = 1

; Even value
mov  rcx, 42
call math_is_odd
; RAX = 0

; Zero (even, so not odd)
mov  rcx, 0
call math_is_odd
; RAX = 0

; Negative odd value
mov  rcx, -1
call math_is_odd
; RAX = 1

; Negative even value
mov  rcx, -2
call math_is_odd
; RAX = 0
```

---

## Common Patterns

### Absolute Difference
```nasm
; Compute |a - b| without overflow concerns
.data
a dq 100
b dq 200

.code
; a - b
mov  rcx, [a]
sub  rcx, [b]       ; rcx = -100
call math_abs
; RAX = 100 (absolute difference)
```

### Clamping User Input
```nasm
; Clamp user input to valid range [1, 100]
.data
user_input dq ?

.code
mov  rcx, [user_input]
mov  rdx, 1         ; min
mov  r8,  100       ; max
call math_clamp
jc   invalid_range
mov  [validated_input], rax

invalid_range:
    ; Handle error (shouldn't happen if min/max are correct)
```

### Sign-Based Branching
```nasm
; Branch based on sign of value
mov  rcx, [some_value]
call math_sign

cmp  rax, -1
je   handle_negative

cmp  rax, 0
je   handle_zero

; else: handle positive
```

### Power Table Generation
```nasm
; Generate powers of 2: 2^0, 2^1, ..., 2^10
.data
powers dq 11 dup(?)

.code
xor  rbx, rbx       ; index = 0
loop_start:
    mov  rcx, 2     ; base
    mov  rdx, rbx   ; exp
    call math_power
    jc   overflow   ; Skip if overflow
    
    lea  rdi, powers
    mov  [rdi + rbx*8], rax
    
    inc  rbx
    cmp  rbx, 11
    jb   loop_start

overflow:
    ; Handle overflow (shouldn't happen for 2^10)
```

### Parity Check in Loop
```nasm
; Process even and odd indices differently
xor  rbx, rbx       ; index = 0
loop_start:
    mov  rcx, rbx
    call math_is_even
    test rax, rax
    jz   process_odd
    
    ; Process even index
    ; ...
    jmp  loop_continue
    
process_odd:
    ; Process odd index
    ; ...
    
loop_continue:
    inc  rbx
    cmp  rbx, [array_len]
    jb   loop_start
```

### Safe Exponentiation with Fallback
```nasm
; Compute power with overflow fallback
.data
base  dq 10
exp   dq 18
max_val dq 0x7FFFFFFFFFFFFFFF

.code
mov  rcx, [base]
mov  rdx, [exp]
call math_power
jnc  success

; Overflow: use max value as fallback
mov  rax, [max_val]

success:
    mov  [result], rax
```

---

## Performance Notes

- **`math_abs`** — O(1), branchless (2-3 instructions)
- **`math_sign`** — O(1), branchless (4-5 instructions)
- **`math_clamp`** — O(1), uses conditional moves where possible
- **`math_power`** — O(log exp), exponentiation by squaring
- **`math_is_even`** — O(1), branchless (1 instruction + movzx)
- **`math_is_odd`** — O(1), branchless (1 instruction + movzx)

### Optimization Tips
1. ✅ **Use predicates in tight loops** — Branchless = no pipeline stalls
2. ✅ **Cache `math_power` results** — If computing same powers repeatedly
3. ✅ **Prefer `math_clamp` over manual checks** — Cleaner and optimized
4. ✅ **Avoid repeated `math_power` calls** — Pre-compute tables when possible

---

## Edge Cases & Special Values

### `math_abs`
| Input | Output | Notes |
|-------|--------|-------|
| `0` | `0` | Identity |
| `42` | `42` | Positive unchanged |
| `-42` | `42` | Negated |
| `INT64_MAX` | `INT64_MAX` | `0x7FFFFFFFFFFFFFFF` |
| `INT64_MIN` | `0x8000000000000000` | Special: magnitude = 2^63 (doesn't fit in signed) |

### `math_power`
| Base | Exp | Result | Notes |
|------|-----|--------|-------|
| `0` | `0` | `1` | Mathematical convention |
| `0` | `n > 0` | `0` | Any power of zero |
| `1` | `any` | `1` | Identity |
| `-1` | `even` | `1` | Alternating sign |
| `-1` | `odd` | `-1` | Alternating sign |
| `2` | `62` | `4611686018427387904` | Max safe power of 2 (signed) |
| `2` | `63` | Overflow | `ERR_OVERFLOW` |
| `-2` | `63` | `-9223372036854775808` | `INT64_MIN` (boundary case) |
| `-2` | `64` | Overflow | `ERR_OVERFLOW` (2^64 too large) |

### `math_clamp`
| Value | Min | Max | Result | Notes |
|-------|-----|-----|--------|-------|
| `5` | `0` | `10` | `5` | In range |
| `-5` | `0` | `10` | `0` | Below min |
| `15` | `0` | `10` | `10` | Above max |
| `5` | `5` | `5` | `5` | Single valid value |
| `x` | `10` | `5` | Error | `ERR_BADARG` (min > max) |

---

## Thread Safety

- **All procedures are thread-safe** — No global state
- Safe for concurrent calls from multiple threads
- No synchronization required

---

## See Also

- [Error Handling Guide](../error-handling.md) — Complete error model reference
- [Math Examples](../examples/math-demo.asm) — Working code samples
- [Getting Started](../getting-started.md) — Installation and setup
- [Array Module](arrays.md) — QWORD array operations (uses signed/unsigned max/min)
