# Error Handling Guide

Complete reference for AsmEase64's unified error model.

---

## Table of Contents

- [Overview](#overview)
- [The Error Model](#the-error-model)
  - [Success Convention](#success-convention)
  - [Error Convention](#error-convention)
  - [Why This Design?](#why-this-design)
- [Error Codes Reference](#error-codes-reference)
  - [Global Error Codes](#global-error-codes)
  - [Module-Specific Aliases](#module-specific-aliases)
- [Checking for Errors](#checking-for-errors)
  - [Basic Pattern](#basic-pattern)
  - [Minimal Check (Ignore Specifics)](#minimal-check-ignore-specifics)
  - [Detailed Error Handling](#detailed-error-handling)
  - [Error Propagation](#error-propagation)
- [Module-Specific Behavior](#module-specific-behavior)
  - [Arrays (`arr_*`)](#arrays-arr_)
  - [Strings (`str_*`)](#strings-str_)
  - [Math (`math_*`)](#math-math_)
  - [Random (`rand_*`)](#random-rand_)
  - [I/O (`io_*`)](#io-io_)
- [Common Patterns](#common-patterns)
  - [Safe Wrapper Functions](#safe-wrapper-functions)
  - [Chaining Operations](#chaining-operations)
  - [Logging Errors](#logging-errors)
  - [Assertions in Debug Builds](#assertions-in-debug-builds)
- [Common Pitfalls](#common-pitfalls)
- [Advanced Topics](#advanced-topics)
  - [Custom Error Codes](#custom-error-codes)
  - [Error Context Passing](#error-context-passing)
  - [Recovery Strategies](#recovery-strategies)
- [Quick Reference](#quick-reference)

---

## Overview

AsmEase64 uses a **consistent, flag-based error model** across all modules to ensure predictable behavior and easy debugging.

Every procedure follows the **same pattern**:
- **Success:** Carry Flag (CF) is **cleared** (`CF=0`), result (if any) in `RAX`
- **Error:** Carry Flag (CF) is **set** (`CF=1`), error code in `EAX`

This dual-signal approach allows you to:
1. ✅ Check success/failure with a **single conditional jump** (`jc` / `jnc`)
2. ✅ Identify the **specific error** using the code in `EAX`
3. ✅ **Propagate errors** naturally through call chains

---

## The Error Model

### Success Convention

When a procedure **succeeds**:

| Register/Flag | Value | Description |
|---------------|-------|-------------|
| **CF** | `0` (cleared) | Indicates success |
| **RAX** | Result value | Procedure-specific return value (if applicable) |
| **EAX** | Undefined | Do not rely on `EAX` when `CF=0` |

**Example:**
```nasm
lea  rcx, myArray
mov  rdx, 5              ; length
mov  r8,  2              ; index
call arr_get_value
jc   error               ; Jump if CF=1 (error)

; Success path: RAX contains the value at arr[2]
mov  [result], rax
```

---

### Error Convention

When a procedure **fails**:

| Register/Flag | Value | Description |
|---------------|-------|-------------|
| **CF** | `1` (set) | Indicates failure |
| **EAX** | Error code | Numeric constant (see [Error Codes](#error-codes-reference)) |
| **RAX** | Undefined | Do not rely on full `RAX` value when `CF=1` |

**Example:**
```nasm
lea  rcx, myArray
mov  rdx, 5
mov  r8,  10             ; Out of bounds!
call arr_get_value
jc   error               ; CF=1, jump to error handler

error:
    ; EAX contains error code
    cmp  eax, ERR_OUT_OF_RANGE
    je   handle_bounds_error
    ; ... handle other errors
```

---

### Why This Design?

✅ **Fast** — Single flag check (`jc`/`jnc`) is optimal on x86-64  
✅ **Standard** — Aligns with native x86 conventions (like `cmp`, `sub`, `adc`)  
✅ **Predictable** — Same pattern everywhere; no surprises  
✅ **Debuggable** — Numeric codes are easy to log, trace, and compare  
✅ **Composable** — Errors propagate naturally through call chains without extra logic  
✅ **ABI-friendly** — Uses volatile registers; no hidden state

---

## Error Codes Reference

### Global Error Codes

All error codes are defined in `errors.inc` and shared across modules:

```nasm
ERR_OK               EQU 0    ; Reserved (not returned)
ERR_NULLPTR          EQU 1    ; Required pointer was NULL
ERR_OUT_OF_RANGE     EQU 2    ; Index or value out of valid range
ERR_LEN_ZERO         EQU 3    ; Zero length where > 0 is required
ERR_CAPACITY         EQU 4    ; Insufficient capacity (buffer too small)
ERR_OVERFLOW         EQU 5    ; Arithmetic overflow (result doesn't fit)
```

#### Detailed Descriptions

| Code | Constant | Meaning | Common Causes |
|------|----------|---------|---------------|
| `0` | `ERR_OK` | No error | Reserved; never returned |
| `1` | `ERR_NULLPTR` | NULL pointer detected | Passing `NULL` for required pointer parameter |
| `2` | `ERR_OUT_OF_RANGE` | Index out of bounds | Array index ≥ length, invalid range |
| `3` | `ERR_LEN_ZERO` | Zero length invalid | Length parameter is 0 where > 0 required |
| `4` | `ERR_CAPACITY` | Buffer too small | Destination buffer can't fit source data |
| `5` | `ERR_OVERFLOW` | Arithmetic overflow | Result exceeds 64-bit signed range |

---

### Module-Specific Aliases

Some modules use **aliases** for clarity:

#### Random Module (`rand_*`)
```nasm
ERR_BADARG  EQU 3    ; Alias for ERR_LEN_ZERO (e.g., rand_range(0))
```

**Usage:**
- `rand_range(0)` → `ERR_BADARG` (numeric value `3`)
- `rand_range_s64(min, max)` where `min >= max` → `ERR_BADARG`

---

## Checking for Errors

### Basic Pattern

**Always check `CF` first**, then examine `EAX` if needed:

```nasm
call arr_get_value
jc   error_handler       ; Jump if CF=1 (error occurred)

; Success path: RAX contains result
mov  [result], rax
jmp  continue

error_handler:
    ; EAX contains error code
    cmp  eax, ERR_OUT_OF_RANGE
    je   handle_bounds_error
    cmp  eax, ERR_NULLPTR
    je   handle_null_error
    ; ... default handler
```

---

### Minimal Check (Ignore Specifics)

If you only care about **success or failure**:

```nasm
call arr_reverse
jc   failed              ; Jump on ANY error
; ... success code ...
failed:
    ; Handle failure generically
    xor  eax, eax
    ret
```

---

### Detailed Error Handling

**Jump table approach** for multiple error codes:

```nasm
call str_copy
jc   check_error         ; CF=1 → error occurred
; Success path
jmp  continue

check_error:
    ; EAX contains error code
    cmp  eax, ERR_NULLPTR
    je   handle_null
    cmp  eax, ERR_LEN_ZERO
    je   handle_empty
    cmp  eax, ERR_CAPACITY
    je   handle_overflow
    jmp  handle_unknown

handle_null:
    ; ... print "NULL pointer error"
    jmp  cleanup

handle_empty:
    ; ... print "Empty buffer error"
    jmp  cleanup

handle_overflow:
    ; ... print "Buffer too small"
    jmp  cleanup

handle_unknown:
    ; ... print "Unknown error code: <EAX>"

cleanup:
    ; ... common cleanup code
    xor  eax, eax
    ret

continue:
    ; ... success path
```

---

### Error Propagation

**Automatically propagate errors** through call chains:

```nasm
process_data PROC buffer:QWORD, len:QWORD
    SAFE_PROLOGUE
    
    ; Step 1: Trim whitespace
    mov  rcx, buffer
    mov  rdx, len
    call str_trim
    jc   propagate           ; CF=1 → return immediately
    mov  r12, rax            ; Save new length
    
    ; Step 2: Convert to uppercase
    mov  rcx, buffer
    mov  rdx, r12
    call str_to_upper
    jc   propagate           ; CF=1 → return immediately
    
    ; Step 3: Reverse
    mov  rcx, buffer
    mov  rdx, r12
    call str_reverse
    jc   propagate           ; CF=1 → return immediately
    
    ; Success: all steps completed
    mov  rax, r12
    RET_OK

propagate:
    ; CF is still 1, EAX contains original error code
    ; Just return without modifying flags/EAX
    SAFE_EPILOGUE
process_data ENDP
```

**Key insight:** `SAFE_EPILOGUE` preserves flags, so `CF=1` and `EAX` automatically propagate to the caller.

---

## Module-Specific Behavior

### Arrays (`arr_*`)

#### Error Conditions

| Procedure | `ERR_NULLPTR` | `ERR_LEN_ZERO` | `ERR_OUT_OF_RANGE` |
|-----------|---------------|----------------|--------------------|
| `arr_get_value` | ✅ base=NULL | ✅ len=0 | ✅ index≥len |
| `arr_set_value` | ✅ base=NULL | ✅ len=0 | ✅ index≥len |
| `arr_fill` | ✅ base=NULL | ✅ len=0 | — |
| `arr_copy` | ✅ dst/src=NULL | ✅ len=0 | — |
| `arr_reverse` | ✅ base=NULL | ✅ len=0 | — |
| `arr_swap` | ✅ base=NULL | ✅ len=0 | ✅ i≥len or j≥len |
| `arr_max` / `arr_min` | ✅ base=NULL | ✅ len=0 | — |
| `arr_smax` / `arr_smin` | ✅ base=NULL | ✅ len=0 | — |
| `arr_index_of_*` | ✅ base=NULL | ✅ len=0 | — |

#### Example: Bounds Checking

```nasm
; Safe element access with error handling
lea  rcx, myArray
mov  rdx, [arrayLen]
mov  r8,  [userIndex]
call arr_get_value
jc   check_error

; Success: RAX contains value
mov  [result], rax
jmp  done

check_error:
    cmp  eax, ERR_OUT_OF_RANGE
    jne  other_error
    
    ; Bounds error: print message
    lea  rcx, errMsg_bounds
    call io_print_string
    jmp  done

other_error:
    ; Handle other errors...

done:
```

---

### Strings (`str_*`)

#### Error Conditions

| Procedure | `ERR_NULLPTR` | `ERR_LEN_ZERO` | `ERR_CAPACITY` |
|-----------|---------------|----------------|----------------|
| `str_copy` | ✅ dst/src=NULL | ✅ src_len=0 | ✅ src_len>dst_cap |
| `str_length` | ✅ base=NULL | ✅ max_len=0 | — |
| `str_compare` | ✅ a/b=NULL | — | — |
| `str_trim` | ✅ base=NULL | — | — |
| `str_to_upper` | ✅ base=NULL | — | — |
| `str_to_lower` | ✅ base=NULL | — | — |
| `str_reverse` | ✅ base=NULL | — | — |
| `str_fill` | ✅ base=NULL | — | — |
| `str_find_char` | ✅ base=NULL | — | — |
| `str_replace_char` | ✅ base=NULL | — | — |

#### Example: Safe Copy with Capacity Check

```nasm
.data
srcBuf  db "Hello, World!", 0
dstBuf  db 10 dup(?)
dstCap  dq 10

.code
; Copy will fail: src_len (13) > dst_cap (10)
lea  rcx, dstBuf
mov  rdx, [dstCap]
lea  r8,  srcBuf
mov  r9,  13             ; src_len
call str_copy
jc   check_error

; Success path...
jmp  done

check_error:
    cmp  eax, ERR_CAPACITY
    jne  other_error
    
    ; Buffer too small error
    lea  rcx, errMsg_overflow
    call io_print_string

done:
```

---

### Math (`math_*`)

#### Error Conditions

| Procedure | Never Fails | `ERR_BADARG` | `ERR_OVERFLOW` |
|-----------|-------------|--------------|----------------|
| `math_abs` | ✅ | — | — |
| `math_sign` | ✅ | — | — |
| `math_is_even` | ✅ | — | — |
| `math_is_odd` | ✅ | — | — |
| `math_clamp` | — | ✅ min>max | — |
| `math_power` | — | — | ✅ overflow |

#### Example: Power Overflow Handling

```nasm
; Compute 2^63 (overflows signed 64-bit)
mov  rcx, 2
mov  rdx, 63
call math_power
jc   check_error

; Success: RAX = result
mov  [result], rax
jmp  done

check_error:
    cmp  eax, ERR_OVERFLOW
    jne  other_error
    
    ; Use max safe value as fallback
    mov  rax, 7FFFFFFFFFFFFFFFh
    mov  [result], rax

done:
```

---

### Random (`rand_*`)

#### Error Conditions

| Procedure | Never Fails | `ERR_BADARG` |
|-----------|-------------|--------------|
| `rand_seed` | ✅ | — |
| `rand_u64` | ✅ | — |
| `rand_s64` | ✅ | — |
| `rand_bool` | ✅ | — |
| `rand_range` | — | ✅ max=0 |
| `rand_range_s64` | — | ✅ min≥max |

#### Example: Range Validation

```nasm
; User input: generate random in [0, max)
mov  rcx, [userMax]
call rand_range
jc   check_error

; Success: RAX = random value
mov  [result], rax
jmp  done

check_error:
    cmp  eax, ERR_BADARG
    jne  other_error
    
    ; Invalid range: print error
    lea  rcx, errMsg_badrange
    call io_print_string

done:
```

---

### I/O (`io_*`)

#### Special Behavior

**I/O procedures use best-effort semantics:**
- **Always return `CF=0`** (success flag)
- **Return `RAX=0` on write failure** (e.g., invalid handle)
- **No error codes currently defined** for I/O failures

> **Future versions** may add error codes for handle failures.

#### Example: Best-Effort Printing

```nasm
; Print always "succeeds" (CF=0), even if handle is invalid
lea  rcx, myString
call io_print_string
; CF=0 always

; Check bytes written
test rax, rax
jz   write_failed        ; RAX=0 means write failed

; Success: RAX = bytes written
jmp  done

write_failed:
    ; Handle missing output (e.g., log to file)

done:
```

---

## Common Patterns

### Safe Wrapper Functions

Wrap library calls with **error-logging wrappers**:

```nasm
safe_arr_max PROC base:QWORD, len:QWORD
    SAFE_PROLOGUE
    
    call arr_max
    jnc  success
    
    ; Error occurred: log it
    push rax                     ; Save error code
    lea  rcx, errPrefix
    call io_print_string
    pop  rax
    mov  rcx, rax
    call io_print_uint           ; Print error code
    call io_print_newline
    
    stc                          ; Restore CF=1
    SAFE_EPILOGUE

success:
    clc                          ; CF=0
    SAFE_EPILOGUE
safe_arr_max ENDP

.data
errPrefix db "Array error: ERR=", 0
```

---

### Chaining Operations

**Validate inputs once**, then chain multiple operations:

```nasm
process_buffer PROC buffer:QWORD, len:QWORD
    SAFE_PROLOGUE
    
    ; Validate inputs
    CHECK_NULL buffer, ERR_NULLPTR
    CHECK_LEN_NONZERO len, ERR_LEN_ZERO
    
    ; Chain operations (errors propagate automatically)
    mov  rcx, buffer
    mov  rdx, len
    call str_trim
    jc   propagate
    mov  r12, rax            ; Save new length
    
    mov  rcx, buffer
    mov  rdx, r12
    call str_to_upper
    jc   propagate
    
    mov  rax, r12
    RET_OK

propagate:
    SAFE_EPILOGUE
process_buffer ENDP
```

---

### Logging Errors

**Create a central error logger**:

```nasm
log_error PROC errorCode:QWORD
    SAFE_PROLOGUE
    
    lea  rcx, errLogPrefix
    call io_print_string
    
    mov  rcx, errorCode
    call io_print_uint
    
    lea  rcx, errLogSuffix
    call io_print_string
    
    RET_OK
log_error ENDP

.data
errLogPrefix db "[ERROR] Code: ", 0
errLogSuffix db 13, 10, 0
```

**Usage:**
```nasm
call arr_get_value
jc   log_it
; ... success path ...

log_it:
    movzx rcx, al            ; Error code in EAX
    call  log_error
    ; ... handle error ...
```

---

### Assertions in Debug Builds

**Conditional error checking** for debug vs release:

```nasm
; Debug-only assertion macro
IFDEF DEBUG
ASSERT_OK MACRO
    LOCAL L_ok
    jnc  L_ok
    ; Error: break into debugger
    int  3
L_ok:
ENDM
ELSE
ASSERT_OK MACRO
    ; No-op in release
ENDM
ENDIF

; Usage
call arr_get_value
ASSERT_OK                ; Break if error (debug only)
```

---

## Common Pitfalls

### ❌ Pitfall 1: Forgetting to Check `CF`

```nasm
; WRONG: No error check
call arr_max
mov  [result], rax       ; ⚠️ RAX might contain garbage if CF=1!
```

**✅ Fix:**
```nasm
call arr_max
jc   error               ; Check CF first!
mov  [result], rax       ; ✅ Safe: we know CF=0
```

---

### ❌ Pitfall 2: Checking `RAX` Before `CF`

```nasm
; WRONG: Checking RAX first
call arr_get_value
test rax, rax            ; ⚠️ Misleading check
jz   handle_zero
```

**✅ Fix:**
```nasm
call arr_get_value
jc   error               ; Check CF first!
test rax, rax            ; ✅ Now we can safely check RAX
jz   handle_zero
```

---

### ❌ Pitfall 3: Assuming `EAX=0` Means Success

```nasm
; WRONG: Checking EAX instead of CF
call str_trim
test eax, eax            ; ⚠️ EAX undefined on success!
jnz  error
```

**✅ Fix:**
```nasm
call str_trim
jc   error               ; ✅ Check CF, not EAX
```

---

### ❌ Pitfall 4: Modifying Flags Before Checking

```nasm
; WRONG: CMP clobbers CF
call arr_reverse
cmp  rax, 10             ; ⚠️ Destroys CF!
jc   error               ; ✅ Now checking wrong flag
```

**✅ Fix:**
```nasm
call arr_reverse
jc   error               ; ✅ Check CF immediately
; ... then check RAX
```

---

## Advanced Topics

### Custom Error Codes

**Extend the error system** for your own code:

```nasm
; Custom error codes (start at 100 to avoid conflicts)
ERR_CUSTOM_TIMEOUT    EQU 100
ERR_CUSTOM_BADFORMAT  EQU 101

my_procedure PROC
    SAFE_PROLOGUE
    
    ; ... some check ...
    jnz  timeout_error
    
    RET_OK

timeout_error:
    RET_ERR ERR_CUSTOM_TIMEOUT
my_procedure ENDP
```

---

### Error Context Passing

**Pass additional context** via stack or global:

```nasm
.data
g_last_error_line   dq 0

.code
set_error_context MACRO line
    mov  qword ptr [g_last_error_line], line
ENDM

my_function PROC
    SAFE_PROLOGUE
    
    set_error_context __LINE__
    call some_operation
    jc   error
    
    ; ... more code ...
    RET_OK

error:
    ; Caller can check g_last_error_line
    SAFE_EPILOGUE
my_function ENDP
```

---

### Recovery Strategies

**Automatic fallback** on errors:

```nasm
robust_get PROC array:QWORD, len:QWORD, index:QWORD, default:QWORD
    SAFE_PROLOGUE
    
    mov  rcx, array
    mov  rdx, len
    mov  r8,  index
    call arr_get_value
    jnc  success
    
    ; Error: return default value
    mov  rax, default
    clc                      ; Clear CF (fake success)
    
success:
    RET_OK
robust_get ENDP
```

---

## Quick Reference

### Error Checking Cheat Sheet

| Check | Instruction | Jump Condition |
|-------|-------------|----------------|
| Success? | `jnc label` | CF=0 (no carry) |
| Error? | `jc label` | CF=1 (carry set) |
| Specific error? | `cmp eax, ERR_*` then `je` | After `jc` confirms error |

### Order of Operations

1. ✅ **Call procedure**
2. ✅ **Check `CF` immediately** with `jc` or `jnc`
3. ✅ **If `CF=1`**, examine `EAX` for error code
4. ✅ **If `CF=0`**, use `RAX` for result

### Error Code Summary

| Code | Name | Meaning |
|------|------|---------|
| `1` | `ERR_NULLPTR` | NULL pointer |
| `2` | `ERR_OUT_OF_RANGE` | Index out of bounds |
| `3` | `ERR_LEN_ZERO` / `ERR_BADARG` | Zero length / invalid argument |
| `4` | `ERR_CAPACITY` | Buffer too small |
| `5` | `ERR_OVERFLOW` | Arithmetic overflow |

### Module Error Matrix

| Module | NULL Errors | Range Errors | Capacity Errors | Overflow Errors |
|--------|-------------|--------------|-----------------|-----------------|
| **Arrays** | ✅ | ✅ | — | — |
| **Strings** | ✅ | — | ✅ | — |
| **Math** | — | ✅ | — | ✅ |
| **Random** | — | ✅ | — | — |
| **I/O** | ✅ | — | — | — |

---

## See Also

- [Getting Started Guide](getting-started.md) — Installation and setup
- [API Reference](api/) — Complete procedure documentation
- [Examples](examples/) — Working code samples
- [Library Design](../README.md#library-design--conventions) — Core principles

---

**Questions or Issues?** Open an issue on [GitHub Issues](https://github.com/trystanhenriques/AsmEase64/issues)
