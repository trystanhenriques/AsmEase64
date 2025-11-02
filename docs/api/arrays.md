# Array Module API Reference

The Array module (`arr_*`) provides operations for working with **QWORD (64-bit) arrays** in assembly.

All procedures follow the Windows x64 calling convention and use a consistent error model:
- **Success:** `CF=0`, result (if any) in `RAX`
- **Error:** `CF=1`, error code in `EAX`

---

## Table of Contents

### Element Access
- [arr_get_value](#arr_get_value) — Read element at index
- [arr_set_value](#arr_set_value) — Write element at index

### Bulk Operations
- [arr_fill](#arr_fill) — Fill array with a value
- [arr_copy](#arr_copy) — Copy array (overlap-safe)

### Transformations
- [arr_reverse](#arr_reverse) — Reverse array in-place
- [arr_swap](#arr_swap) — Swap two elements

### Queries (Unsigned)
- [arr_max](#arr_max) — Find maximum value (unsigned)
- [arr_min](#arr_min) — Find minimum value (unsigned)
- [arr_index_of_max](#arr_index_of_max) — Find index of max (unsigned)
- [arr_index_of_min](#arr_index_of_min) — Find index of min (unsigned)

### Queries (Signed)
- [arr_smax](#arr_smax) — Find maximum value (signed)
- [arr_smin](#arr_smin) — Find minimum value (signed)
- [arr_index_of_smax](#arr_index_of_smax) — Find index of max (signed)
- [arr_index_of_smin](#arr_index_of_smin) — Find index of min (signed)

---

## Element Access

### arr_get_value

Reads the value of an array element at a given index.

#### Signature
```nasm
arr_get_value(base, len, index)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |
| `index` | `R8` | `QWORD` | Zero-based index to read |

#### Returns
- **Success:** `CF=0`, `RAX` = element value
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |
| `2` | `ERR_OUT_OF_RANGE` | `index >= len` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11` (volatile registers per Windows x64 ABI)

#### Notes
- Index must be in range `[0, len)`
- Array elements are 8 bytes (QWORD)
- Bounds-checked: no buffer overruns

#### Example
```nasm
.data
myArray QWORD 10, 20, 30, 40, 50

.code
lea  rcx, myArray        ; base
mov  rdx, 5              ; len
mov  r8,  2              ; index (get myArray[2])
call arr_get_value
jc   error               ; Check for errors

; Success: RAX = 30
mov  result, rax

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_set_value

Writes a value to an array element at a given index.

#### Signature
```nasm
arr_set_value(base, len, index, value)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |
| `index` | `R8` | `QWORD` | Zero-based index to write |
| `value` | `R9` | `QWORD` | Value to write |

#### Returns
- **Success:** `CF=0`
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |
| `2` | `ERR_OUT_OF_RANGE` | `index >= len` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11` (volatile registers)

#### Notes
- Index must be in range `[0, len)`
- Overwrites existing value at index
- Bounds-checked: no buffer overruns

#### Example
```nasm
.data
myArray QWORD 10, 20, 30, 40, 50

.code
lea  rcx, myArray        ; base
mov  rdx, 5              ; len
mov  r8,  2              ; index
mov  r9,  99             ; value (set myArray[2] = 99)
call arr_set_value
jc   error               ; Check for errors

; Success: myArray[2] is now 99

error:
    ; Handle error (EAX contains ERR_*)
```

---

## Bulk Operations

### arr_fill

Fills all elements of an array with a specified value.

#### Signature
```nasm
arr_fill(base, len, value)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |
| `value` | `R8` | `QWORD` | Value to fill with |

#### Returns
- **Success:** `CF=0`
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `RDI` (preserved internally)

#### Notes
- Uses `rep stosq` for fast bulk fill
- All elements set to the same value
- Non-volatile registers (`RDI`) are preserved

#### Example
```nasm
.data
myArray QWORD 10 DUP(?)   ; Uninitialized array

.code
lea  rcx, myArray         ; base
mov  rdx, 10              ; len
mov  r8,  0               ; value (fill with zeros)
call arr_fill
jc   error                ; Check for errors

; Success: all 10 elements are now 0

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_copy

Copies elements from one array to another. **Overlap-safe** (uses memmove semantics).

#### Signature
```nasm
arr_copy(dst, src, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `dst` | `RCX` | `PTR QWORD` | Destination array base |
| `src` | `RDX` | `PTR QWORD` | Source array base |
| `len` | `R8` | `QWORD` | Number of elements to copy |

#### Returns
- **Success:** `CF=0`
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `dst == NULL` or `src == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `RDI`, `RSI` (preserved internally)

#### Notes
- **Overlap-safe:** Automatically chooses forward or backward copy direction
- Uses `rep movsq` for fast bulk copy
- If `dst == src`, no-op (returns success)
- Non-volatile registers (`RDI`, `RSI`) are preserved

#### Example
```nasm
.data
source QWORD 1, 2, 3, 4, 5
dest   QWORD 5 DUP(?)

.code
; Copy source -> dest
lea  rcx, dest            ; dst
lea  rdx, source          ; src
mov  r8,  5               ; len
call arr_copy
jc   error                ; Check for errors

; Success: dest = {1, 2, 3, 4, 5}

error:
    ; Handle error (EAX contains ERR_*)
```

#### Overlap Example
```nasm
.data
buffer QWORD 1, 2, 3, 4, 5, 6

.code
; Shift right: copy buffer[0..4] -> buffer[1..5]
lea  rcx, buffer
add  rcx, 8               ; dst = &buffer[1]
lea  rdx, buffer          ; src = &buffer[0]
mov  r8,  5               ; len
call arr_copy             ; Overlap-safe

; Result: buffer = {1, 1, 2, 3, 4, 5}
```

---

## Transformations

### arr_reverse

Reverses the elements of an array in-place.

#### Signature
```nasm
arr_reverse(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `RDI`, `RSI`, `R10` (preserved internally)

#### Notes
- Modifies array in-place
- No extra memory allocation
- Single-element arrays (`len == 1`) succeed without change
- Non-volatile registers (`RDI`, `RSI`) are preserved

#### Example
```nasm
.data
myArray QWORD 1, 2, 3, 4, 5

.code
lea  rcx, myArray         ; base
mov  rdx, 5               ; len
call arr_reverse
jc   error                ; Check for errors

; Success: myArray = {5, 4, 3, 2, 1}

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_swap

Swaps two elements in an array by index.

#### Signature
```nasm
arr_swap(base, len, i, j)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |
| `i` | `R8` | `QWORD` | First index |
| `j` | `R9` | `QWORD` | Second index |

#### Returns
- **Success:** `CF=0`
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |
| `2` | `ERR_OUT_OF_RANGE` | `i >= len` or `j >= len` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R10`, `R11` (used for addresses)

#### Notes
- Both indices must be in range `[0, len)`
- If `i == j`, no-op (returns success)
- Swaps values at `base[i]` and `base[j]`

#### Example
```nasm
.data
myArray QWORD 10, 20, 30, 40, 50

.code
lea  rcx, myArray         ; base
mov  rdx, 5               ; len
mov  r8,  0               ; i (first index)
mov  r9,  4               ; j (last index)
call arr_swap
jc   error                ; Check for errors

; Success: myArray = {50, 20, 30, 40, 10}

error:
    ; Handle error (EAX contains ERR_*)
```

---

## Queries (Unsigned)

### arr_max

Finds the maximum value in an array (**unsigned comparison**).

#### Signature
```nasm
arr_max(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`, `RAX` = maximum value (unsigned)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R9`, `R10`, `R11`

#### Notes
- Uses **unsigned comparison** (`cmova`)
- For signed max, use [`arr_smax`](#arr_smax)
- Returns first occurrence if duplicates exist

#### Example
```nasm
.data
myArray QWORD 5, 9, 3, 12, 7

.code
lea  rcx, myArray         ; base
mov  rdx, 5               ; len
call arr_max
jc   error                ; Check for errors

; Success: RAX = 12 (maximum value)

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_min

Finds the minimum value in an array (**unsigned comparison**).

#### Signature
```nasm
arr_min(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`, `RAX` = minimum value (unsigned)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R9`, `R10`

#### Notes
- Uses **unsigned comparison** (`cmovb`)
- For signed min, use [`arr_smin`](#arr_smin)
- Returns first occurrence if duplicates exist

#### Example
```nasm
.data
myArray QWORD 5, 9, 3, 12, 7

.code
lea  rcx, myArray         ; base
mov  rdx, 5               ; len
call arr_min
jc   error                ; Check for errors

; Success: RAX = 3 (minimum value)

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_index_of_max

Finds the index of the maximum value (**unsigned comparison**).

#### Signature
```nasm
arr_index_of_max(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`, `RAX` = index of maximum value
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R8`, `R9`, `R10`, `R11`

#### Notes
- Returns **first occurrence** if multiple elements have the same max value
- Uses **unsigned comparison**
- For signed version, use [`arr_index_of_smax`](#arr_index_of_smax)

#### Example
```nasm
.data
myArray QWORD 5, 9, 3, 12, 7

.code
lea  rcx, myArray         ; base
mov  rdx, 5               ; len
call arr_index_of_max
jc   error                ; Check for errors

; Success: RAX = 3 (index of value 12)

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_index_of_min

Finds the index of the minimum value (**unsigned comparison**).

#### Signature
```nasm
arr_index_of_min(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`, `RAX` = index of minimum value
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R8`, `R9`, `R10`, `R11`

#### Notes
- Returns **first occurrence** if multiple elements have the same min value
- Uses **unsigned comparison**
- For signed version, use [`arr_index_of_smin`](#arr_index_of_smin)

#### Example
```nasm
.data
myArray QWORD 5, 9, 3, 12, 7

.code
lea  rcx, myArray         ; base
mov  rdx, 5               ; len
call arr_index_of_min
jc   error                ; Check for errors

; Success: RAX = 2 (index of value 3)

error:
    ; Handle error (EAX contains ERR_*)
```

---

## Queries (Signed)

### arr_smax

Finds the maximum value in an array (**signed comparison**).

#### Signature
```nasm
arr_smax(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`, `RAX` = maximum value (signed, two's complement)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R9`, `R10`

#### Notes
- Uses **signed comparison** (`cmovg`)
- For unsigned max, use [`arr_max`](#arr_max)
- Correctly handles negative values (two's complement)

#### Example
```nasm
.data
myArray QWORD -10, 5, -3, 2

.code
lea  rcx, myArray         ; base
mov  rdx, 4               ; len
call arr_smax
jc   error                ; Check for errors

; Success: RAX = 5 (maximum signed value)

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_smin

Finds the minimum value in an array (**signed comparison**).

#### Signature
```nasm
arr_smin(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`, `RAX` = minimum value (signed, two's complement)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R9`, `R10`

#### Notes
- Uses **signed comparison** (`cmovl`)
- For unsigned min, use [`arr_min`](#arr_min)
- Correctly handles negative values (two's complement)

#### Example
```nasm
.data
myArray QWORD -10, 5, -3, 2

.code
lea  rcx, myArray         ; base
mov  rdx, 4               ; len
call arr_smin
jc   error                ; Check for errors

; Success: RAX = -10 (minimum signed value)

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_index_of_smax

Finds the index of the maximum value (**signed comparison**).

#### Signature
```nasm
arr_index_of_smax(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`, `RAX` = index of maximum value (signed)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R8`, `R9`, `R10`, `R11`

#### Notes
- Returns **first occurrence** if multiple elements have the same max value
- Uses **signed comparison**
- For unsigned version, use [`arr_index_of_max`](#arr_index_of_max)

#### Example
```nasm
.data
myArray QWORD -10, 5, -3, 2

.code
lea  rcx, myArray         ; base
mov  rdx, 4               ; len
call arr_index_of_smax
jc   error                ; Check for errors

; Success: RAX = 1 (index of value 5)

error:
    ; Handle error (EAX contains ERR_*)
```

---

### arr_index_of_smin

Finds the index of the minimum value (**signed comparison**).

#### Signature
```nasm
arr_index_of_smin(base, len)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `base` | `RCX` | `PTR QWORD` | Pointer to array base |
| `len` | `RDX` | `QWORD` | Array length (number of elements) |

#### Returns
- **Success:** `CF=0`, `RAX` = index of minimum value (signed)
- **Error:** `CF=1`, `EAX` = error code

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `1` | `ERR_NULLPTR` | `base == NULL` |
| `3` | `ERR_LEN_ZERO` | `len == 0` |

#### Clobbers
`RAX`, `RCX`, `RDX`, `R8`-`R11`, `R8`, `R9`, `R10`, `R11`

#### Notes
- Returns **first occurrence** if multiple elements have the same min value
- Uses **signed comparison**
- For unsigned version, use [`arr_index_of_min`](#arr_index_of_min)

#### Example
```nasm
.data
myArray QWORD -10, 5, -3, 2

.code
lea  rcx, myArray         ; base
mov  rdx, 4               ; len
call arr_index_of_smin
jc   error                ; Check for errors

; Success: RAX = 0 (index of value -10)

error:
    ; Handle error (EAX contains ERR_*)
```

---

## Common Patterns

### Error Handling
```nasm
; Always check CF after array operations
call arr_max
jc   handle_error         ; Jump if error occurred

; Success path
mov  maxValue, rax
jmp  continue

handle_error:
    ; EAX contains error code
    cmp  eax, ERR_NULLPTR
    je   null_pointer
    cmp  eax, ERR_LEN_ZERO
    je   empty_array
    ; ... handle other errors

continue:
```

### Combining Operations
```nasm
; Find max, then find its index
lea  rcx, myArray
mov  rdx, 5
call arr_max
jc   error
mov  r12, rax             ; Save max value

lea  rcx, myArray
mov  rdx, 5
call arr_index_of_max
jc   error
; RAX = index, R12 = value
```

### Iterating with Get/Set
```nasm
; Double all array values
xor  r12, r12             ; index = 0
.loop:
    lea  rcx, myArray
    mov  rdx, 5           ; len
    mov  r8,  r12         ; index
    call arr_get_value
    jc   error
    
    shl  rax, 1           ; value *= 2
    
    lea  rcx, myArray
    mov  rdx, 5
    mov  r8,  r12
    mov  r9,  rax         ; new value
    call arr_set_value
    jc   error
    
    inc  r12
    cmp  r12, 5
    jb   .loop
```

---

## Performance Notes

- **`arr_fill`** and **`arr_copy`** use `rep stosq`/`rep movsq` — very fast for bulk operations
- **Query operations** (`arr_max`, `arr_min`, etc.) are O(n) — single linear scan
- **`arr_swap`** is O(1) — constant time
- **Bounds checking** adds 1-2 instructions per call (minimal overhead)

---

## See Also

- [Error Handling Guide](../error-handling.md) — Complete error model reference
- [Array Examples](../examples/array-demo.asm) — Working code samples
- [Getting Started](../getting-started.md) — Installation and setup
