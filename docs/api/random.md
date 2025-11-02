
# Random Module API Reference

The Random module (`rand_*`) provides pseudo-random number generation for Windows x64.

All procedures follow the Windows x64 calling convention and use a consistent error model:
- **Success:** `CF=0`, result in `RAX`
- **Error:** `CF=1`, error code in `EAX`

---

## Table of Contents

### Seeding
- [rand_seed](#rand_seed) — Set PRNG state (seed)

### Basic Generation
- [rand_u64](#rand_u64) — Generate 64-bit unsigned random value
- [rand_s64](#rand_s64) — Generate 64-bit signed random value
- [rand_bool](#rand_bool) — Generate random boolean (0 or 1)

### Range Generation
- [rand_range](#rand_range) — Generate uniform unsigned integer in range
- [rand_range_s64](#rand_range_s64) — Generate uniform signed integer in range

---

## Module Overview

The Random module implements a fast, deterministic pseudo-random number generator (PRNG) based on **SplitMix64**.

### Key Features
- ✅ **Fast** — SplitMix64 is one of the fastest PRNGs (O(1) generation)
- ✅ **Deterministic** — Same seed always produces same sequence
- ✅ **Bias-free ranges** — Uses multiply-high rejection sampling to avoid modulo bias
- ✅ **Zero-seed protection** — Automatically uses fallback seed if seeded with 0
- ✅ **Full 64-bit output** — All 64 bits are usable (no wasted entropy)

### Important Warnings
- ❌ **NOT cryptographically secure** — Do not use for security-sensitive applications
- ❌ **NOT thread-safe** — Uses global state; concurrent access will produce races
- ❌ **NOT suitable for simulation** — Use a higher-quality PRNG (e.g., xoshiro256**, PCG) for Monte Carlo

### Algorithm Details
- **Core PRNG:** SplitMix64
  - State: single 64-bit unsigned integer
  - Output function: avalanche mixing with 64-bit multiplications
  - Period: 2^64 (full state space)
- **Range generation:** Multiply-high with rejection sampling (eliminates modulo bias)
- **Fallback seed:** `0xDDB2BD6C9BB22173` (used when seeding with 0)

> **Note:** All procedures preserve non-volatile registers (`RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15`).

---

## Seeding

### rand_seed

Sets the PRNG state (seed) and returns the previous state.

#### Signature
```nasm
rand_seed(new_state)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `new_state` | `RCX` | `QWORD` | New seed value (unsigned 64-bit) |

#### Returns
- **Success:** `CF=0`, `RAX` = previous state
- **Error:** None (never fails)

#### Errors
None — always succeeds

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Zero-seed protection:** If `new_state == 0`, uses fallback seed `0xDDB2BD6C9BB22173` instead
  - This prevents PRNG from getting stuck in all-zeros state
- Returns **old state** before updating (useful for saving/restoring PRNG state)
- **Determinism:** Same seed always produces same sequence
- **Initial state:** Global state starts at `0` (first call returns `0`)

#### Example
```nasm
; Seed with specific value
mov  rcx, 0x123456789ABCDEF
call rand_seed
; RAX = old state (0 on first call)

; Save old state for later restoration
push rax

; ... generate random numbers ...

; Restore old state
pop  rcx
call rand_seed

; Zero-seed (uses fallback)
xor  rcx, rcx
call rand_seed
; RAX = old state
; New state = 0xDDB2BD6C9BB22173 (fallback)
```

---

## Basic Generation

### rand_u64

Generates a 64-bit unsigned pseudo-random value.

#### Signature
```nasm
rand_u64()
```

#### Parameters
None

#### Returns
- **Success:** `CF=0`, `RAX` = random 64-bit unsigned value
- **Error:** None (never fails)

#### Errors
None — always succeeds

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Algorithm:** SplitMix64 output function:
  ```
  state += 0x9E3779B97F4A7C15
  z = state
  z ^= z >> 30; z *= 0xBF58476D1CE4E5B9
  z ^= z >> 27; z *= 0x94D049BB133111EB
  z ^= z >> 31
  return z
  ```
- **Side effect:** Advances internal PRNG state
- **All bits are random** — Full 64-bit output is usable
- **Deterministic** — Same state always produces same output

#### Example
```nasm
; Seed first for reproducibility
mov  rcx, 0x123456789ABCDEF
call rand_seed

; Generate random value
call rand_u64
; RAX = random 64-bit value

; Generate another
call rand_u64
; RAX = different random value

; Print as hex
mov  rcx, rax
mov  rdx, 16
call io_print_hex
```

---

### rand_s64

Generates a 64-bit signed pseudo-random value.

#### Signature
```nasm
rand_s64()
```

#### Parameters
None

#### Returns
- **Success:** `CF=0`, `RAX` = random 64-bit signed value
- **Error:** None (never fails)

#### Errors
None — always succeeds

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Thin wrapper around `rand_u64`** — Returns same bit pattern, interpret as signed
- **Side effect:** Advances internal PRNG state
- Use `io_print_int` to print as signed decimal

#### Example
```nasm
; Seed first
mov  rcx, 0x123456789ABCDEF
call rand_seed

; Generate signed random value
call rand_s64
; RAX = random signed 64-bit value (may be negative)

; Print as signed decimal
mov  rcx, rax
call io_print_int
call io_print_newline

; Print as hex (same bit pattern)
mov  rcx, rax
mov  rdx, 16
call io_print_hex
```

---

### rand_bool

Generates a random boolean value (0 or 1).

#### Signature
```nasm
rand_bool()
```

#### Parameters
None

#### Returns
- **Success:** `CF=0`, `AL` = 0 or 1 (RAX zero-extended)
- **Error:** None (never fails)

#### Errors
None — always succeeds

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- Extracts **least significant bit** from `rand_u64` output
- **Side effect:** Advances internal PRNG state
- Result is zero-extended to full 64-bit RAX (upper 56 bits are 0)
- **50/50 distribution** (over many samples)

#### Example
```nasm
; Seed first
mov  rcx, 0x123456789ABCDEF
call rand_seed

; Generate random boolean
call rand_bool
; AL = 0 or 1

; Branch on result
test al, al
jz   handle_false

handle_true:
    ; ... AL was 1
    jmp  continue

handle_false:
    ; ... AL was 0

continue:

; Print as integer
movzx rcx, al
call  io_print_int
```

---

## Range Generation

### rand_range

Generates a uniform random unsigned integer in the range `[0, max)`.

#### Signature
```nasm
rand_range(max_exclusive)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `max_exclusive` | `RCX` | `QWORD` | Maximum value (exclusive, unsigned) |

#### Returns
- **Success:** `CF=0`, `RAX` = random value in `[0, max)`
- **Error:** `CF=1`, `EAX=ERR_BADARG` if `max == 0`

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `3` | `ERR_BADARG` | `max_exclusive == 0` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Bias-free** — Uses multiply-high rejection sampling to eliminate modulo bias
- **Algorithm:**
  ```
  threshold = (-max) % max
  loop:
      x = rand_u64()
      product = x * max  (128-bit)
      low64 = product & 0xFFFFFFFFFFFFFFFF
      high64 = product >> 64
      if low64 >= threshold:
          return high64
  ```
- **Side effect:** Advances internal PRNG state (may call `rand_u64` multiple times due to rejection)
- **Uniform distribution** over `[0, max)`

#### Example
```nasm
; Seed first
mov  rcx, 0x123456789ABCDEF
call rand_seed

; Generate random value in [0, 100)
mov  rcx, 100
call rand_range
jc   error
; RAX in [0, 99]

; Print result
mov  rcx, rax
call io_print_int

; Error case: max == 0
xor  rcx, rcx
call rand_range
jc   error
; CF=1, EAX=ERR_BADARG

error:
    ; Handle error
```

#### Dice Roll Example
```nasm
; Roll a 6-sided die (1..6)
mov  rcx, 6
call rand_range
jc   error
inc  rax             ; Convert [0, 5] to [1, 6]
; RAX = die roll

mov  rcx, rax
call io_print_int
```

---

### rand_range_s64

Generates a uniform random signed integer in the range `[min, max)`.

#### Signature
```nasm
rand_range_s64(min_inclusive, max_exclusive)
```

#### Parameters
| Parameter | Register | Type | Description |
|-----------|----------|------|-------------|
| `min_inclusive` | `RCX` | `SQWORD` | Minimum value (inclusive, signed) |
| `max_exclusive` | `RDX` | `SQWORD` | Maximum value (exclusive, signed) |

#### Returns
- **Success:** `CF=0`, `RAX` = random value in `[min, max)`
- **Error:** `CF=1`, `EAX=ERR_BADARG` if `min >= max`

#### Errors
| Code | Constant | Condition |
|------|----------|-----------|
| `3` | `ERR_BADARG` | `min_inclusive >= max_exclusive` |

#### Clobbers
**Volatile registers** (`RAX`, `RCX`, `RDX`, `R8`-`R11`)

#### Notes
- **Algorithm:**
  ```
  width = (uint64_t)(max - min)
  offset = rand_range(width)  (unsigned range)
  return min + offset
  ```
- **Bias-free** — Inherits bias-free property from `rand_range`
- **Side effect:** Advances internal PRNG state
- Handles negative ranges correctly (e.g., `[-10, 10)`)

#### Example
```nasm
; Seed first
mov  rcx, 0x123456789ABCDEF
call rand_seed

; Generate random value in [-10, 10)
mov  rcx, -10
mov  rdx, 10
call rand_range_s64
jc   error
; RAX in [-10, 9]

; Print result
mov  rcx, rax
call io_print_int

; Generate random value in [INT64_MIN, INT64_MIN+2)
mov  rcx, 8000000000000000h  ; INT64_MIN
mov  rdx, 8000000000000002h  ; INT64_MIN + 2
call rand_range_s64
jc   error
; RAX in [INT64_MIN, INT64_MIN+1]

; Error case: min >= max
mov  rcx, 10
mov  rdx, 5
call rand_range_s64
jc   error
; CF=1, EAX=ERR_BADARG

error:
    ; Handle error
```

---

## Common Patterns

### Initialization at Program Start
```nasm
.code
main PROC
    ; Seed PRNG with fixed value for reproducibility
    mov  rcx, 0x123456789ABCDEF
    call rand_seed
    
    ; ... rest of program ...
    
    ret
main ENDP
```

### Time-Based Seeding (Simple)
```nasm
; Use RDTSC (CPU timestamp counter) as seed
rdtsc                ; EDX:EAX = timestamp
shl  rdx, 32
or   rax, rdx        ; RAX = full 64-bit timestamp
mov  rcx, rax
call rand_seed

; Note: For production, use GetSystemTime or QueryPerformanceCounter
```

### Simulating Coin Flips
```nasm
.data
heads_count dq 0
tails_count dq 0

.code
; Flip 1000 coins
xor  rbx, rbx       ; counter = 0
flip_loop:
    call rand_bool
    test al, al
    jz   tails
    
    inc  qword ptr [heads_count]
    jmp  next_flip
    
tails:
    inc  qword ptr [tails_count]
    
next_flip:
    inc  rbx
    cmp  rbx, 1000
    jb   flip_loop
```

### Generating Random Index
```nasm
; Select random element from array
.data
array dq 10, 20, 30, 40, 50
arr_len dq 5

.code
mov  rcx, [arr_len]
call rand_range
jc   error

; RAX = random index in [0, 5)
lea  rcx, array
mov  rax, [rcx + rax*8]   ; Get random element

mov  rcx, rax
call io_print_int
```

### Shuffling Array (Fisher-Yates)
```nasm
; Shuffle array in-place
.data
array dq 1, 2, 3, 4, 5
arr_len dq 5

.code
; Seed first
mov  rcx, 0x123456789ABCDEF
call rand_seed

; i = len - 1 down to 1
mov  rbx, [arr_len]
dec  rbx
shuffle_loop:
    cmp  rbx, 0
    jbe  shuffle_done
    
    ; j = rand_range(i + 1)
    mov  rcx, rbx
    inc  rcx
    call rand_range
    jc   error
    
    ; swap array[i] and array[j]
    lea  rcx, array
    mov  rdx, [rcx + rbx*8]    ; temp = array[i]
    mov  r8,  [rcx + rax*8]    ; r8 = array[j]
    mov  [rcx + rbx*8], r8     ; array[i] = array[j]
    mov  [rcx + rax*8], rdx    ; array[j] = temp
    
    dec  rbx
    jmp  shuffle_loop
    
shuffle_done:
error:
```

### Random Password Generation
```nasm
.data
chars db "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
chars_len equ 62
password db 16 dup(?)

.code
; Generate 16-character password
xor  rbx, rbx
gen_loop:
    mov  rcx, chars_len
    call rand_range
    jc   error
    
    lea  rcx, chars
    mov  al, [rcx + rax]       ; Get random char
    
    lea  rcx, password
    mov  [rcx + rbx], al       ; Store in password
    
    inc  rbx
    cmp  rbx, 16
    jb   gen_loop
    
; Print password
lea  rcx, password
mov  rdx, 16
mov  r8,  0                    ; No min_bits (print as-is)
; ... (print as string)

error:
```

### Monte Carlo Simulation (Area Estimation)
```nasm
; Estimate π using Monte Carlo (quarter circle in unit square)
.data
inside  dq 0
total   dq 10000

.code
mov  rcx, 0x123456789ABCDEF
call rand_seed

xor  rbx, rbx
monte_loop:
    ; x = rand_range(10000) / 10000.0 (simplified: use integer)
    mov  rcx, 10000
    call rand_range
    jc   error
    mov  r12, rax              ; x
    
    ; y = rand_range(10000)
    mov  rcx, 10000
    call rand_range
    jc   error
    mov  r13, rax              ; y
    
    ; if (x*x + y*y < 10000*10000) inside++
    mov  rax, r12
    mul  r12                   ; x²
    mov  r14, rax
    
    mov  rax, r13
    mul  r13                   ; y²
    add  rax, r14              ; x² + y²
    
    mov  r15, 10000
    imul r15, r15              ; 10000²
    cmp  rax, r15
    jae  next_sample
    
    inc  qword ptr [inside]
    
next_sample:
    inc  rbx
    cmp  rbx, [total]
    jb   monte_loop
    
; π ≈ 4 * (inside / total)
; Print result...

error:
```

---

## Performance Notes

- **`rand_u64`** — O(1), very fast (~10 instructions)
- **`rand_bool`** — O(1), calls `rand_u64` once
- **`rand_range`** — O(1) expected, may loop due to rejection sampling
  - Worst case: O(k) where k is rejection count (rare for large max)
  - Average rejection rate ≈ 0.5 calls per sample
- **`rand_range_s64`** — O(1) expected, delegates to `rand_range`

### Optimization Tips
1. ✅ **Seed once** — Don't reseed inside loops (breaks determinism)
2. ✅ **Batch generation** — If needing many randoms, generate in tight loop
3. ✅ **Avoid small ranges** — `rand_range(2)` wastes 63 bits; use `rand_bool` instead
4. ❌ **Don't modulo** — `rand_u64() % n` is biased; use `rand_range(n)` instead

---

## Determinism & Reproducibility

### Same Seed → Same Sequence
```nasm
; Run 1
mov  rcx, 0xBEEF
call rand_seed
call rand_u64
; RAX = X

; Run 2
mov  rcx, 0xBEEF
call rand_seed
call rand_u64
; RAX = X (same as Run 1)
```

### Saving/Restoring State
```nasm
; Save state
mov  rcx, 0
call rand_seed       ; Returns old state
push rax             ; Save it

; ... generate randoms ...

; Restore state
pop  rcx
call rand_seed       ; Restore old state

; Future calls will continue from saved point
```

---

## Thread Safety

- ❌ **NOT thread-safe** — Uses single global state variable
- **Data race** if multiple threads call any `rand_*` procedure concurrently
- **Solutions:**
  1. Use thread-local storage (TLS) for per-thread PRNG state
  2. Use mutex to synchronize access (slow)
  3. Generate randoms in single thread, distribute to workers

---

## Quality & Statistical Properties

### SplitMix64 Characteristics
- ✅ **Fast** — One of the fastest PRNGs
- ✅ **Good statistical quality** — Passes BigCrush test suite
- ✅ **Full period** — 2^64 unique states
- ❌ **Short period** — Only 2^64 (use xoshiro256** for longer)
- ❌ **Predictable** — NOT cryptographically secure

### When NOT to Use
- ❌ Cryptographic keys, nonces, passwords
- ❌ Security tokens, session IDs
- ❌ Gambling/lottery systems
- ❌ Long-running simulations (period 2^64)

### Alternatives
- **For security:** Use OS-provided CSPRNG (e.g., `BCryptGenRandom`)
- **For simulation:** Use xoshiro256**, PCG64, or Mersenne Twister
- **For games:** SplitMix64 is fine

---

## Edge Cases & Special Values

### `rand_seed`
| Input | Behavior | Notes |
|-------|----------|-------|
| `0` | Uses fallback `0xDDB2BD6C9BB22173` | Prevents stuck state |
| Any non-zero | Uses input directly | Standard seeding |

### `rand_range`
| Max | Result | Notes |
|-----|--------|-------|
| `0` | `ERR_BADARG` | Invalid range |
| `1` | Always `0` | Trivial range [0, 1) = {0} |
| `2` | `0` or `1` | Binary choice |
| `UINT64_MAX` | Full 64-bit range | [0, 2^64-1) |

### `rand_range_s64`
| Min | Max | Result | Notes |
|-----|-----|--------|-------|
| `5` | `5` | `ERR_BADARG` | Empty range |
| `10` | `11` | Always `10` | Single value |
| `-10` | `10` | `[-10, 9]` | Includes negatives |
| `INT64_MIN` | `INT64_MIN+1` | Always `INT64_MIN` | Extreme boundary |

---

## See Also

- [Error Handling Guide](../error-handling.md) — Complete error model reference
- [Random Examples](../examples/random-demo.asm) — Working code samples
- [Getting Started](../getting-started.md) — Installation and setup
- [I/O Module](io.md) — Printing random values
- [Math Module](math.md) — Mathematical operations (useful with randoms)
