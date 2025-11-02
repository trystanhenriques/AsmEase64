# AsmEase64

A modern, easy-to-use x86-64 Assembly library for Windows that streamlines low-level programming by handling stack alignment, shadow space, and register safety automatically.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20x64-lightgrey.svg)]()
[![Language](https://img.shields.io/badge/language-Assembly-green.svg)]()
[![Build](https://img.shields.io/badge/build-stable-brightgreen.svg)]()

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Minimal Example](#minimal-example)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Error Handling](#error-handling)
- [Library Design & Conventions](#library-design--conventions)
- [Testing](#testing)
- [License](#license)

---

## Overview

**AsmEase64** is a modular x86-64 Assembly library built for Windows developers using **MASM**.  
It provides a clean, consistent set of low-level procedures that simplify the most repetitive and error-prone parts of assembly development — including stack management, calling conventions, and console I/O.

Instead of manually dealing with shadow space, alignment, or register preservation, **AsmEase64** abstracts these details so you can focus purely on your logic.  
Every procedure follows the Windows x64 calling convention, uses standardized error codes, and maintains consistent naming and parameter rules across all modules.

### Design Goals
- **Ease of Use** — Make assembly development approachable without sacrificing performance.  
- **Safety** — Prevent common pitfalls like stack misalignment and register corruption.  
- **Consistency** — Unified calling conventions, return rules, and error handling across all modules.  
- **Transparency** — Source code is fully documented and open for learning or modification.

### Core Capabilities
- Built-in stack alignment and shadow-space handling.  
- Unified error handling system with symbolic constants (`ERR_*`).  
- Modular design with subsystems for I/O, arrays, strings, math, and random generation.  
- Clean, predictable naming scheme (`prefix_action_object`).  
- Ready-to-extend architecture for future utilities, debugging, and system operations.

---

## Features

AsmEase64 is organized into modular subsystems, each designed to handle a specific area of low-level development with consistent conventions and safety guarantees.

- ✅ **Console Output (`io_*`)** — Print characters, strings, integers, hex, and floating-point values through Windows console APIs with automatic stack alignment.  
- 🔜 **Console Input (`io_read_*`)** — Planned support for reading characters, strings, and integers from the console (to be added in a future release).  
- ✅ **String Utilities (`str_*`)** — Common ASCII string operations such as copy, compare, trim, reverse, case conversion, and search/replace.  
- ✅ **Array Utilities (`arr_*`)** — Tools for working with QWORD arrays: element access, fill, copy, reverse, max/min, and index queries (both signed and unsigned).  
- ✅ **Math Helpers (`math_*`)** — Integer math functions like absolute value, clamping, sign detection, power, and parity checks.  
- ✅ **Random Number Generation (`rand_*`)** — Lightweight 64-bit PRNG with seeding, uniform ranges, and boolean generation.  
- 🔜 **Debug Module (`dbg_*`)** — Planned stack and register dump utilities for runtime inspection.  
- 🔜 **Utility Module (`util_*`)** — Planned general-purpose helpers (timing, memory, conversions, assertions).

---

## Minimal Example

A simple program demonstrating multiple AsmEase64 features:

```nasm
; Example: demo.asm
include AsmEase64.inc

.data
numbers QWORD 42, 15, 88, 3, 67
arrLen  QWORD 5
msg     db "Array max value: ", 0

.code
main PROC
    ; Print message
    mov rcx, OFFSET msg
    call io_print_string
    
    ; Find max value in array
    lea rcx, numbers           ; RCX = array base
    mov rdx, arrLen            ; RDX = length
    call arr_max               ; Result in RAX
    jc error                   ; Check for errors
    
    ; Print the max value (88)
    mov rcx, rax
    call io_print_int
    call io_print_newline
    
    ; Calculate absolute value of -100
    mov rcx, -100
    call math_abs              ; Result in RAX = 100
    
    mov rcx, rax
    call io_print_int
    call io_print_newline
    
    xor ecx, ecx
    ret

error:
    mov rcx, rax               ; Print error code
    call io_print_int
    ret
main ENDP
END main
```

**Output:**
```
Array max value: 88
100
```

No manual stack alignment or shadow-space allocation needed —  
AsmEase64 handles all of it internally so your code stays clean and predictable.

---

## Project Structure

AsmEase64 is organized into modular directories for clarity and maintainability.  
Each folder contains focused components — headers, source files, and test programs — that work together to form the complete library.

- **`inc/`** – Public include files (`.inc`) containing PROC prototypes and shared constants.  
- **`src/`** – Core implementation files (`.asm`) for each module.  
- **`tests/`** – Assembly test programs used for validation and development.  
- **`docs/`** – Comprehensive documentation and guides  
  - **`Getting-Started.md`** – Complete installation and setup guide  
  - **`error-handling.md`** – Deep dive into the CF/EAX error model  
  - **`api/`** – Detailed API reference for each module
  - **`examples/`** 🚧 – Usage examples for each module *(under construction)*

---

## Getting Started

### Quick Setup

**Choose one of the following installation methods:**

**Option 1 — Download Prebuilt Release** (Recommended)
- Visit the [latest release](../../releases) page
- Download and extract `AsmEase64.zip`
- Contains prebuilt `AsmEase64.lib` — ready to use immediately

**Option 2 — Clone Repository**
- Clone for full source access and customization
- You'll need to build `AsmEase64.lib` yourself using MASM

**You can also do both** — download the release for quick setup, then clone later if you need source access.

---

### Basic Requirements

- Windows 10+ (x64)
- MASM (ML64) — included with Visual Studio or Windows SDK
- Linker (`link.exe`)

---

### Next Steps

For **complete installation instructions** including:
- Visual Studio integration (step-by-step with screenshots)
- Command-line setup (ml64 + link)
- Build scripts and troubleshooting

See the full guide: **[docs/Getting-Started.md](docs/getting-started.md)**

---

## Documentation

### Core Guides
- **[Getting Started](docs/getting-started.md)** — Installation, setup, Visual Studio integration, command-line builds
- **[Error Handling](docs/error-handling.md)** — Complete guide to the CF/EAX error model, error codes, and patterns

### API Reference
Detailed API documentation for each module (parameters, return values, error codes, usage notes):

- **[Arrays API](docs/api/arrays.md)** — Array operations (get/set, fill, copy, reverse, max/min)
- **[Strings API](docs/api/strings.md)** — String utilities (copy, compare, trim, case conversion, search/replace)
- **[I/O API](docs/api/io.md)** — Console I/O (print functions for all data types)
- **[Math API](docs/api/math.md)** — Math helpers (abs, clamp, sign, power, parity)
- **[Random API](docs/api/random.md)** — Random number generation (seed, ranges, booleans)

> 💡 **Quick Reference:** Each `.inc` header file ([array.inc](inc/array.inc), [string.inc](inc/string.inc), [io.inc](inc/io.inc), [math.inc](inc/math.inc), [random.inc](inc/random.inc)) also contains inline API documentation.

### Usage Examples 🚧
The `docs/examples/` directory is **under construction**. In the meantime:
- Check the **test files** (`tests/*.asm`) for working examples of every function
- Refer to the **API reference** above for detailed usage patterns

---

## Error Handling

AsmEase64 uses a **consistent, flag-based error model** across all modules:

**Success:**
- `CF = 0` (Carry Flag cleared)
- Result (if any) in `RAX`

**Error:**
- `CF = 1` (Carry Flag set)
- Error code in `EAX`

### Common Error Codes

| Code | Constant | Meaning |
|------|----------|---------|
| `1` | `ERR_NULLPTR` | Required pointer was NULL |
| `2` | `ERR_OUT_OF_RANGE` | Index out of valid range |
| `3` | `ERR_LEN_ZERO` | Zero length where > 0 required |
| `4` | `ERR_CAPACITY` | Buffer too small |
| `5` | `ERR_OVERFLOW` | Arithmetic overflow |

### Example Usage

```nasm
call arr_get_value
jc   error_handler       ; Jump if CF=1 (error occurred)

; Success path: RAX contains the value
mov  result, rax
jmp  continue

error_handler:
    cmp  eax, ERR_OUT_OF_RANGE
    je   handle_bounds_error
    ; ... handle other errors
```

**For complete details** (error propagation, best practices, module-specific notes), see:  
**[docs/error-handling.md](docs/error-handling.md)**

---

## Library Design & Conventions

AsmEase64 follows strict design principles to ensure consistency, safety, and ease of use across all modules.

### Naming Convention

All procedures follow the pattern: **`<module>_<action>_<object>`**

- **Module prefix:** `io_`, `arr_`, `str_`, `math_`, `rand_`
- **Action:** `print`, `get`, `set`, `copy`, `fill`, `reverse`, `compare`, etc.
- **Object:** `string`, `char`, `int`, `value`, `max`, `min`, etc.

**Examples:**
```
io_print_string     → I/O module, print action, string object
arr_get_value       → Array module, get action, value object
str_to_upper        → String module, to_upper action
math_abs            → Math module, abs action
rand_u64            → Random module, u64 type
```

---

### Calling Convention

AsmEase64 strictly follows the **Windows x64 ABI**:

| Purpose | Registers | Notes |
|---------|-----------|-------|
| **Arguments** | `RCX`, `RDX`, `R8`, `R9` | First 4 args |
| **Return value** | `RAX` | 64-bit result |
| **Volatile** | `RAX`, `RCX`, `RDX`, `R8`-`R11` | May be clobbered |
| **Non-volatile** | `RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15` | Always preserved |

**Stack alignment and shadow space are handled automatically** — you don't need to manage them manually.

---

### Safety Guarantees

1. **Stateless** — No hidden global state (except I/O handles and PRNG)
2. **Null-Safe** — All pointers validated; returns `ERR_NULLPTR` if NULL
3. **Range-Checked** — Array indices bounds-checked; no buffer overruns
4. **ABI-Compliant** — Non-volatile registers always preserved
5. **Overlap-Safe** — Copy operations handle overlapping buffers (memmove semantics)

---

### Modularity

- **Independent modules** — Use only what you need
- **No circular dependencies** — Clean separation of concerns
- **Small footprint** — Static linking includes only called procedures

```nasm
; Minimal include
INCLUDE io.inc

; Full include
INCLUDE AsmEase64.inc    ; All modules
```

---

### Design Philosophy

**Three core principles:**

1. **Ease of Use** — Consistent patterns; learn once, apply everywhere
2. **Safety Without Overhead** — Validate inputs but keep the fast path fast
3. **Transparency** — Fully documented source; no magic

---

### What AsmEase64 Is NOT

❌ **Not a high-level language** — You still write assembly  
❌ **Not a standard library replacement** — It's a toolkit, not libc  
❌ **Not cryptographically secure** — Fast PRNG, not CSPRNG  
❌ **Not cross-platform** — Windows x64 only  
❌ **Not thread-safe globally** — Most procedures are; `rand_*` has shared state

**What it IS:**  
✅ A **productivity booster** for x64 assembly development  
✅ A **learning tool** for understanding calling conventions  
✅ A **foundation** you can build on or customize

---

## Testing

AsmEase64 includes a comprehensive test suite with **200+ test cases** covering all modules.

### Test Structure

Tests are located in the `tests/` directory:

- **`arr_tests.asm`** — Array operations
- **`io_tests.asm`** — Console I/O
- **`str_tests.asm`** — String utilities
- **`math_tests.asm`** — Math helpers
- **`random_tests.asm`** — Random number generation

Each test file is a standalone console application that prints `PASS` or `FAIL` for each test case.

### What's Tested

✅ **Error conditions** — NULL pointers, zero lengths, out-of-bounds indices  
✅ **Edge cases** — Empty inputs, boundary values, INT64_MIN/MAX  
✅ **Correctness** — Expected outputs for typical inputs  
✅ **Safety** — Overlap handling, buffer overrun prevention  
✅ **Determinism** — PRNG consistency with same seed

### Running Tests

1. Build a test program (e.g., `arr_tests.asm`) as a console application
2. Link against `AsmEase64.lib`
3. Run the executable
4. Review console output

**Example output:**
```
Running array sanity tests...
T1: get NULL base -> expect ERR_NULLPTR ... PASS
T2: get arr[2] -> expect RAX=30, CF=0 ... PASS
T3: get index==len -> expect ERR_OUT_OF_RANGE ... PASS
...
```

> 💡 **Tip:** Test files also serve as **usage examples** — check them to see real-world patterns.

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

### Summary

You are free to:
- ✅ Use this library in personal or commercial projects
- ✅ Modify the source code
- ✅ Distribute copies or modified versions

**Requirements:**
- Include the original copyright notice and license text

**Disclaimer:**
- This software is provided "as is" without warranty of any kind
