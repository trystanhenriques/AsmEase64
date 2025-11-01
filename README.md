# AsmEase64

A modern, easy-to-use x86-64 Assembly library for Windows that streamlines low-level programming by handling stack alignment, shadow space, and register safety automatically.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20x64-lightgrey.svg)]()
[![Language](https://img.shields.io/badge/language-Assembly-green.svg)]()
[![Build](https://img.shields.io/badge/build-stable-brightgreen.svg)]()


## Overview

AsmEase64 is a modular x86-64 Assembly library built for Windows developers using MASM.  
It provides a clean, consistent set of low-level procedures that simplify the most repetitive and error-prone parts of assembly development — including stack management, calling conventions, and console I/O.

Instead of manually dealing with shadow space, alignment, or register preservation, AsmEase64 abstracts these details so you can focus purely on your logic.  
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

### Minimal Example

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
END
```

**Output:**
```
Array max value: 88
100
```

No manual stack alignment or shadow-space allocation needed —  
AsmEase64 handles all of it internally so your code stays clean and predictable.

## Project Structure

AsmEase64 is organized into modular directories for clarity and maintainability.  
Each folder contains focused components — headers, source files, and test programs — that work together to form the complete library.

- **`inc/`** – Public include files (`.inc`) containing PROC prototypes and shared constants.  
- **`src/`** – Core implementation files (`.asm`) for each module.  
- **`tests/`** – Assembly test programs used for validation and development.  
- **`README.md`** – Project overview and documentation entry point.  
- **`docs/`** – Comprehensive documentation and examples  
  - `procs.md` – Detailed list of all public procedures  
  - `reference.md` – User-friendly guide  
  - `examples/` – Example `.asm` programs demonstrating each module
 
## Getting Started

### Prerequisites
Before using AsmEase64, make sure you have the following installed:

- **Operating System:** Windows 10 or later (x64 only)
- **Assembler:** **MASM** (ML64) — included with Visual Studio or the Windows SDK
- **Linker:** `link.exe` (bundled with the Visual Studio toolchain)
- **Optional IDE:** Visual Studio 2019 or later
- **Knowledge:** Basic familiarity with x64 Assembly and the Windows calling convention

### Installation

AsmEase64 can be installed in two ways — by downloading the prebuilt release package or by cloning the repository.

#### 🟢 Option 1 — Download the Prebuilt Release (Recommended)

1. Visit the **[Releases](../../releases)** page on GitHub.  
2. Download the latest archive (for example, `AsmEase64.zip`).  
3. Extract the archive to a convenient location, such as:  
   `C:\AsmEase64\`  
4. After extraction, your folder should contain:

   - **`inc/`** – Public include files (`.inc`)  
     - `array.inc`  
     - `AsmEase64.inc`  
     - `errors.inc`  
     - `io.inc`  
     - `macros.inc`  
     - `math.inc`  
     - `random.inc`  
     - `string.inc`  
     - `win32_console.inc`  
   - **`lib/`** – Prebuilt static library
     - `AsmEase64.lib`

You only need these two directories:
- **`inc/`** → Include in your MASM project for access to all public procedures  
- **`lib/`** → Link against the precompiled library during build

#### 🟣 Option 2 — Clone the Repository
If you want the full source for editing or debugging:
```bash
git clone https://github.com/<yourusername>/AsmEase64.git
cd AsmEase64
```

After cloning, you will need to build the static library (AsmEase64.lib) yourself
using **MASM (ml64)** and the Microsoft linker **(link.exe)**.

Once the library is installed, you can begin assembling and linking programs with AsmEase64 using either:

- The command line (**ml64 + link.exe**)

- Or **Visual Studio** (by adding include and library paths in project settings)

These are detailed in the next sections.

### Visual Studio Integration

You can also use AsmEase64 directly inside **Visual Studio** for assembling, linking, and debugging your programs with a GUI workflow.

Follow these steps to configure your project:

---

#### 1️⃣ Create a New MASM Project
1. Open **Visual Studio** → **File → New → Project**  
2. Search for **“Empty Project”** (MASM projects are typically custom).  
3. Ensure the project is targeting **x64** architecture.  
   - You can check this from the toolbar → “Solution Platforms” → select **x64**.

---

#### 2️⃣ Add Include Path
Tell MASM where to find AsmEase64’s `.inc` files.

1. In **Solution Explorer**, right-click your project → **Properties**.  
2. Under **Microsoft Macro Assembler → General**, set:  
   - **Include Paths:** `C:\AsmEase64\inc` (or wherever it is stored)


   <img width="780" height="463" alt="image" src="https://github.com/user-attachments/assets/f7470154-5b96-4baa-bbd1-0907a1a0e141" />



This lets you use:
```asm
include AsmEase64.inc
```
from anywhere in your project without specifying full paths.

---

#### 3️⃣ Add Library Path

Let the linker know where to find `AsmEase64.lib`.

1. Go to **Configuration Properties** → **Linker** → **General**
2. Set **Additional Library Directories** to:

`C:\AsmEase64\lib` (or wherever it is stored)

<img width="791" height="507" alt="image" src="https://github.com/user-attachments/assets/8a5a21e0-7925-4989-925a-11928b606375" />

---

#### 4️⃣ Link the Library

Tell the linker which .lib file to use.

1. Under **Linker** → **Input**, set:
    - **Additional Dependencies**: `AsmEase64.lib`

This ensures the linker pulls in all procedures defined in the static library.

<img width="789" height="509" alt="image" src="https://github.com/user-attachments/assets/630c1671-ebbc-4c05-90f2-09e3011d9e94" />

---

#### ✅ You’re Done!

You can now build and run .asm projects that use **AsmEase64**.
Visual Studio will automatically:

- Assemble .asm files with ml64
- Link them with your chosen .lib
- Launch the executable in the debugger

---

### Example

```nasm
; hello.asm
include AsmEase64.inc

.data
msg db "Hello from AsmEase64 inside Visual Studio!", 0

.code
main PROC
    mov rcx, OFFSET msg
    call io_print_string
    call io_print_newline
    ret
main ENDP
END main
```

**Build** → **Run**, and you’ll see your message in the console window.

---

### Command-Line Setup (ML64 + LINK)

If you prefer to build your Assembly programs manually from the command line rather than through Visual Studio, you can use the MASM (ML64) assembler and Microsoft LINK utilities included with the Visual Studio toolchain.

---

#### 🧱 Folder Layout
For this example, assume you've installed AsmEase64 to:

```
C:\AsmEase64\
```

and that your project file is:

```
C:\Projects\MyTest\hello.asm
```

---

#### Step 1 — Assemble Your Source
Open **x64 Native Tools Command Prompt for VS** (installed with Visual Studio)  
and navigate to your project folder:

```bash
cd C:\Projects\MyTest
```

Then assemble your program:

```bash
ml64 /c /I "C:\AsmEase64\inc" /W3 hello.asm
```

**Explanation of flags:**

| Flag | Meaning |
|------|---------|
| `/c` | Assemble only (don't link yet) |
| `/I` | Add include path for AsmEase64 `.inc` files |
| `/W3` | Set warning level (catches common mistakes) |

After this step, you should have `hello.obj` in the same directory.

---

#### Step 2 — Link the Object File

Next, link the assembled file with the AsmEase64 static library:

```bash
link hello.obj "C:\AsmEase64\lib\AsmEase64.lib" /SUBSYSTEM:CONSOLE
```

**Explanation of flags:**

| Flag | Meaning |
|------|---------|
| `/SUBSYSTEM:CONSOLE` | Produces a console application |
| `"AsmEase64.lib"` | Links your program with the library's compiled procedures |

This produces `hello.exe` in the same directory.

---

#### Step 3 — Run the Program

```bash
hello.exe
```

You should see:

```
Hello from AsmEase64!
```

---

#### ✅ Full Example (One-Liner)

For convenience, here's the complete build command:

```bash
ml64 /c /I "C:\AsmEase64\inc" /W3 hello.asm && link hello.obj "C:\AsmEase64\lib\AsmEase64.lib" /SUBSYSTEM:CONSOLE
```

---

#### 🧠 Notes

- Always use **x64 Native Tools Command Prompt** — it configures the correct paths for `ml64.exe` and `link.exe`.
- You can create a simple `build.bat` script with these commands to automate future builds.
- If you need debugging symbols for Visual Studio, add `/Zi` to the `ml64` command.

---

#### 📝 Optional: Create a Build Script

Save this as `build.bat` in your project folder:

```batch
@echo off
ml64 /c /I "C:\AsmEase64\inc" /W3 %1.asm
if errorlevel 1 goto error
link %1.obj "C:\AsmEase64\lib\AsmEase64.lib" /SUBSYSTEM:CONSOLE
if errorlevel 1 goto error
echo Build successful!
%1.exe
goto end
:error
echo Build failed!
:end
```

Then simply run:

```bash
build hello
```

---

## Documentation

Comprehensive documentation for all modules and procedures:

- **[Complete Procedure Reference](docs/procs.md)** — Full list of all public procedures with parameters, return values, and error codes
- **[Error Handling](#error-handling)** — Understanding AsmEase64's error model and codes *(critical for all modules)*
- **[User Guide](docs/reference.md)** — In-depth usage guide and best practices
- **[Example Programs](docs/examples/)** — Working code samples for each module

### Module-Specific Docs:
- **[I/O Module](docs/io.md)** — Console input/output procedures
- **[Array Module](docs/arrays.md)** — QWORD array operations
- **[String Module](docs/strings.md)** — String manipulation utilities
- **[Math Module](docs/math.md)** — Mathematical operations
- **[Random Module](docs/random.md)** — Random number generation

> 📝 **Note:** Detailed documentation is currently in development. Core API reference and examples will be added in an upcoming release.

---

## Error Handling

AsmEase64 uses a **consistent, flag-based error model** across all modules to ensure predictable behavior and easy debugging.

### Convention

Every procedure follows the same pattern:

**Success:**
- `CF = 0` (Carry Flag cleared)
- Return value (if any) is in `RAX`

**Error:**
- `CF = 1` (Carry Flag set)
- `EAX` contains a numeric error code

This dual-signal approach allows you to:
1. Check success/failure with a single conditional jump (`jc` / `jnc`)
2. Identify the specific error using the code in `EAX`

---

### Error Codes

All error codes are defined in `errors.inc` and shared across modules:

| Code | Constant | Meaning |
|------|----------|---------|
| `0` | `ERR_OK` | No error (reserved; not returned) |
| `1` | `ERR_NULLPTR` | Required pointer was NULL |
| `2` | `ERR_OUT_OF_RANGE` | Index or value out of valid range |
| `3` | `ERR_LEN_ZERO` | Zero length where > 0 is required |
| `4` | `ERR_CAPACITY` | Insufficient capacity (buffer too small) |
| `5` | `ERR_OVERFLOW` | Arithmetic overflow (result doesn't fit in 64 bits) |

> **Note:** Some error codes have module-specific aliases (e.g., `ERR_BADARG` = 3 in the random module). Refer to the numeric value for cross-module consistency.

---

### Usage Pattern

#### Basic Error Checking
```nasm
; Example: Get array element
lea  rcx, myArray
mov  rdx, 5              ; length
mov  r8,  2              ; index
call arr_get_value
jc   error_handler       ; Jump if CF=1 (error occurred)

; Success path: RAX contains the value
mov  result, rax
jmp  continue

error_handler:
    ; EAX contains error code
    cmp  eax, ERR_OUT_OF_RANGE
    je   handle_bounds_error
    cmp  eax, ERR_NULLPTR
    je   handle_null_error
    ; ... handle other cases or use a fallback
```

#### Minimal Check (Ignore Specific Error)
If you only care about success/failure:
```nasm
call arr_reverse
jc   failed              ; Jump on any error
; ... success code ...
failed:
    ; handle failure generically
```

#### Error Propagation
When calling multiple procedures, you can chain checks:
```nasm
call str_trim
jc   cleanup             ; propagate error to caller

call str_to_upper
jc   cleanup

; ... more operations ...

cleanup:
    ; EAX still contains the original error code
    ; CF is still set
    ret                  ; return error to caller
```

---

### Module-Specific Notes

#### Arrays (`arr_*`)
- `ERR_NULLPTR` — Array base pointer is NULL
- `ERR_LEN_ZERO` — Array length is 0 (not allowed for operations like `arr_max`)
- `ERR_OUT_OF_RANGE` — Index is `>= len` (e.g., `arr_get_value`, `arr_set_value`)

#### Strings (`str_*`)
- `ERR_NULLPTR` — String pointer is NULL
- `ERR_LEN_ZERO` — String length is 0 (where required, e.g., `str_copy`)
- `ERR_CAPACITY` — Destination buffer too small (e.g., `str_copy` when `src_len > dst_cap`)

#### Math (`math_*`)
- `ERR_OVERFLOW` — Result exceeds 64-bit signed range (e.g., `math_power` with large exponents)
- `ERR_BADARG` — Invalid arguments (e.g., `math_clamp` with `min > max`)

#### Random (`rand_*`)
- `ERR_BADARG` — Invalid range (e.g., `rand_range(0)` — max must be > 0)

#### I/O (`io_*`)
- **No errors currently** — I/O procedures use best-effort semantics:
  - `CF=0` always (success flag set)
  - `RAX=0` on write failure (e.g., invalid handle)
  - Future versions may add error codes for handle failures

---

### Why This Model?

✅ **Fast** — Single flag check (`jc`/`jnc`) is optimal on x86-64  
✅ **Standard** — Aligns with native x86 conventions (like `cmp`, `sub`)  
✅ **Predictable** — Same pattern everywhere; no surprises  
✅ **Debuggable** — Numeric codes are easy to log and trace  
✅ **Composable** — Errors propagate naturally through call chains  

---

### Common Pitfalls

❌ **Forgetting to check CF**
```nasm
call arr_max
mov  result, rax         ; ⚠️ RAX might contain an error code!
```
✅ **Always check CF first:**
```nasm
call arr_max
jc   error
mov  result, rax         ; ✅ Safe: we know CF=0
```

❌ **Checking RAX before CF**
```nasm
call arr_get_value
cmp  rax, 0              ; ⚠️ Wrong: error code might be 0 (rare but possible)
je   handle_zero
```
✅ **Check CF, then examine EAX if needed:**
```nasm
call arr_get_value
jc   check_error_code    ; ✅ First check if error occurred
; ... success path ...
check_error_code:
    cmp  eax, ERR_NULLPTR
    ; ...
```

---

### Advanced: Custom Error Handling

You can wrap library procedures with your own error-handling layer:

```nasm
; Wrapper that prints error messages
safe_arr_max PROC base:QWORD, len:QWORD
    call arr_max
    jnc  @success
    
    ; Error occurred - print message
    push rax                     ; save error code
    lea  rcx, err_msg
    call io_print_string
    pop  rax
    mov  rcx, rax
    call io_print_int            ; print error code
    call io_print_newline
    
    stc                          ; restore CF=1
    ret
@success:
    clc
    ret
safe_arr_max ENDP

.data
err_msg db "Array error: ", 0
```

---

### Quick Reference Card

| Check | Instruction | Jump Condition |
|-------|-------------|----------------|
| Success? | `jnc label` | CF=0 (no carry) |
| Error? | `jc label` | CF=1 (carry set) |
| Specific error? | `cmp eax, ERR_*` then `je` | After `jc` confirms error |

**Remember:** 
- ✅ Check `CF` first
- ✅ Then check `EAX` for specifics
- ✅ `RAX` contains result only when `CF=0`

---

## Library Design & Conventions

AsmEase64 follows strict design principles to ensure consistency, safety, and ease of use across all modules.

---

### Naming Convention

All procedures follow the pattern: **`<module>_<action>_<object>`**

- **Module prefix:** Identifies the subsystem
  - `io_` — Input/Output operations
  - `arr_` — Array utilities
  - `str_` — String utilities
  - `math_` — Mathematical operations
  - `rand_` — Random number generation
  
- **Action:** Verb describing what it does
  - `print`, `get`, `set`, `copy`, `fill`, `reverse`, `compare`, `clamp`, etc.
  
- **Object:** What it operates on (when applicable)
  - `string`, `char`, `int`, `value`, `max`, `min`, etc.

#### Examples:
```
io_print_string     → I/O module, print action, string object
arr_get_value       → Array module, get action, value object
str_to_upper        → String module, to_upper action (transform)
math_abs            → Math module, abs action (unary operation)
rand_u64            → Random module, u64 type specifier
```

**Benefits:**
- ✅ **Predictable** — You can guess procedure names without looking them up
- ✅ **No collisions** — Module prefixes prevent naming conflicts with your code
- ✅ **Searchable** — Easy to find all procedures in a module (e.g., search for `arr_`)

---

### Calling Convention

AsmEase64 strictly follows the **Windows x64 ABI** (Microsoft x64 calling convention):

#### Register Usage:
| Purpose | Registers | Notes |
|---------|-----------|-------|
| **Arguments** | `RCX`, `RDX`, `R8`, `R9` | First 4 integer/pointer args |
| **Return value** | `RAX` | 64-bit result or pointer |
| **Stack args** | `[RSP+20h]`, `[RSP+28h]`, ... | 5th+ arguments (if needed) |
| **Volatile** | `RAX`, `RCX`, `RDX`, `R8`-`R11` | Caller-saved; may be clobbered |
| **Non-volatile** | `RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15` | Callee-saved; always preserved |
| **XMM volatile** | `XMM0`-`XMM5` | Used for floating-point (e.g., `io_print_float`) |
| **XMM non-volatile** | `XMM6`-`XMM15` | Preserved across calls |

#### Stack Alignment:
- **16-byte alignment** is maintained automatically
- **Shadow space** is allocated internally by each procedure
- **You don't need to manage these manually** — `SAFE_PROLOGUE` and `SAFE_EPILOGUE` macros handle it

#### What This Means For You:
```nasm
; ✅ Correct usage
mov  rcx, arg1          ; First argument
mov  rdx, arg2          ; Second argument
call arr_get_value
; RAX now contains result (if CF=0)
; RCX, RDX, R8-R11 may have changed
; RBX, RBP, RSI, RDI, R12-R15 are unchanged

; ❌ Wrong — don't assume non-volatile regs are free
mov  rbx, 123           ; RBX is non-volatile
call some_procedure     ; ✅ RBX will be preserved
; RBX still == 123 after return
```

---

### Error Handling Model

See the **[Error Handling](#error-handling)** section for complete details.

**Quick summary:**
- **Success:** `CF = 0`, result in `RAX`
- **Error:** `CF = 1`, error code in `EAX`
- **Check pattern:** Always test `CF` first with `jc` or `jnc`

This model is:
- ✅ **Uniform** — Every procedure uses it (except best-effort I/O)
- ✅ **Efficient** — Single flag check, no branching on success path
- ✅ **Composable** — Errors propagate naturally through call chains

---

### Safety Guarantees

#### 1. **No Hidden State** (Stateless Design)
- All procedures (except `rand_*`) are **stateless**
- Input is passed via registers/stack; output is returned in `RAX`
- No reliance on global variables (except I/O handles, cached lazily)
- **Thread-safety:** Most procedures are thread-safe; `rand_*` uses shared state (not thread-safe)

#### 2. **Null-Safe**
- All pointer parameters are validated before use
- Returns `ERR_NULLPTR` (CF=1) if required pointer is NULL
- You can pass NULL to optional parameters (documented per procedure)

#### 3. **Range-Checked**
- Array indices are bounds-checked: `index < len`
- Returns `ERR_OUT_OF_RANGE` (CF=1) on violations
- No buffer overruns or out-of-bounds access

#### 4. **ABI-Compliant**
- Non-volatile registers (`RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15`) are **always** preserved
- You can safely use these in your code without worrying about library calls clobbering them
- Stack is kept 16-byte aligned at all times

#### 5. **Overlap-Safe** (Where Applicable)
- Procedures like `arr_copy`, `str_copy` handle overlapping source/destination buffers correctly
- Uses **memmove semantics**: automatically chooses forward/backward copy direction
- Example:
  ```nasm
  ; Safe: copying within the same buffer
  lea  rcx, buffer[8]    ; dst = buffer + 8
  lea  r8,  buffer       ; src = buffer
  mov  rdx, 100          ; dst_cap
  mov  r9,  50           ; src_len
  call str_copy          ; ✅ Works correctly even with overlap
  ```

---

### Modularity

Each subsystem is **independent and self-contained**:

- ✅ **Use only what you need** — Include only the `.inc` files for modules you use
- ✅ **No circular dependencies** — Modules don't depend on each other (except shared `errors.inc` and `macros.inc`)
- ✅ **Small footprint** — Static linking includes only the procedures you call

#### Example: Minimal Include
```nasm
; Only using I/O
INCLUDE io.inc

.data
msg db "Hello!", 0

.code
main PROC
    mov  rcx, OFFSET msg
    call io_print_string
    ret
main ENDP
END
```

#### Example: Full Include
```nasm
; Using multiple modules
INCLUDE AsmEase64.inc    ; Includes all public APIs

.code
main PROC
    ; Use I/O, arrays, strings, math, random...
    call io_print_string
    call arr_max
    call str_trim
    call math_abs
    call rand_u64
    ret
main ENDP
END
```

---

### Macro System

AsmEase64 uses **internal macros** to ensure consistency and reduce boilerplate:

#### Procedure Frame Macros:
- `SAFE_PROLOGUE` — Allocates 40 bytes (32 shadow + 8 alignment)
- `SAFE_EPILOGUE` — Restores stack without modifying flags

#### Error Macros:
- `RET_OK` — Returns with `CF=0` (success)
- `RET_ERR <code>` — Returns with `CF=1`, `EAX=<code>`

#### Validation Macros:
- `CHECK_NULL <reg>, <errcode>` — Validates pointer; returns error if NULL
- `CHECK_BOUNDS <index>, <len>, <errcode>` — Validates index < len
- `CHECK_LEN_NONZERO <reg>, <errcode>` — Ensures length > 0
- `CHECK_CAPACITY <needed>, <cap>, <errcode>` — Ensures needed <= cap
- `CHECK_ORDER <a>, <b>, <errcode>` — Ensures a <= b (for ranges)

**You typically don't need these macros** — they're internal to the library. But if you're extending AsmEase64 or writing similar procedures, they're available in `macros.inc`.

---

### Constants

#### Special Values:
- `STR_NPOS = 0xFFFFFFFFFFFFFFFF` — "Not found" sentinel (string search operations)

#### Error Codes:
See `errors.inc` for the complete list (documented in [Error Handling](#error-handling)).

---

### Design Philosophy

**Three core principles guide AsmEase64:**

1. **Ease of Use**
   - Assembly is hard enough; the library shouldn't add complexity
   - Consistent patterns mean you learn once, apply everywhere
   - Clear error messages (numeric codes with symbolic names)

2. **Safety Without Overhead**
   - Validate inputs to prevent crashes and undefined behavior
   - But keep the fast path fast (checks compile to 1-2 instructions)
   - No dynamic allocation; no hidden costs

3. **Transparency**
   - Source code is fully documented and readable
   - You can trace exactly what each procedure does
   - No "magic" — if you need to understand or modify behavior, the code is there

---

### Extending the Library

Want to add your own procedures that fit the AsmEase64 style?

**Follow these guidelines:**

1. ✅ Use the naming convention: `module_action_object`
2. ✅ Follow Windows x64 ABI
3. ✅ Use `SAFE_PROLOGUE` / `SAFE_EPILOGUE` or equivalent
4. ✅ Return errors via CF/EAX (use `RET_ERR` macro)
5. ✅ Validate inputs with `CHECK_*` macros
6. ✅ Preserve non-volatile registers (`RBX`, `RBP`, `RDI`, `RSI`, `R12`-`R15`)
7. ✅ Document parameters, return values, errors, and clobbers in comments

**Example template:**
```nasm
;________________________________________
; mymodule_my_operation(param1, param2)
;________________________________________
; RCX = param1 (description)
; RDX = param2 (description)
; Returns:
;   CF=0, RAX = result      ; success
;   CF=1, EAX = ERR_*       ; error
; Errors:
;   ERR_NULLPTR if param1 == NULL
; Notes:
;   - Any special behavior or edge cases
;________________________________________
mymodule_my_operation PROC param1:QWORD, param2:QWORD
    SAFE_PROLOGUE
    
    CHECK_NULL rcx, ERR_NULLPTR
    
    ; ... your implementation ...
    
    mov  rax, result
    RET_OK
mymodule_my_operation ENDP
```

---

### Performance Considerations

- **Minimal branching** — Success paths are optimized for fall-through
- **Register allocation** — Hot values stay in registers; stack use is minimized
- **No hidden costs** — Every operation has predictable, constant-time overhead
- **Inlining opportunity** — Most procedures are small enough that you could inline manually if profiling shows benefit
- **SIMD where appropriate** — `rep stosq`, `rep movsq` used for bulk operations

**Rule of thumb:** If you're calling a procedure in a tight loop (e.g., processing millions of strings), consider moving the loop *into* a custom procedure to amortize call overhead.

---

### What AsmEase64 Is NOT

To set expectations clearly:

❌ **Not a high-level language** — You still write assembly; the library just handles tedious parts  
❌ **Not a standard library replacement** — It's a toolkit, not libc  
❌ **Not cryptographically secure** — Random module uses fast PRNG, not CSPRNG  
❌ **Not cross-platform** — Windows x64 only (uses Win32 console APIs)  
❌ **Not thread-safe globally** — Most procedures are, but `rand_*` has shared state  

**What it IS:**
✅ A **productivity booster** for x64 assembly development  
✅ A **learning tool** for understanding calling conventions and low-level patterns  
✅ A **foundation** you can build on or customize for your needs

---

## Testing

AsmEase64 includes a comprehensive test suite to validate all modules and ensure correctness across edge cases.

### Test Structure

Tests are located in the `tests/` directory, with one test file per module:

- **`arr_tests.asm`** — Array operations (get, set, fill, copy, reverse, max/min, etc.)
- **`io_tests.asm`** — Console I/O (print functions for strings, integers, hex, floats, etc.)
- **`str_tests.asm`** — String utilities (copy, length, compare, trim, case conversion, search/replace)
- **`math_tests.asm`** — Math helpers (abs, clamp, sign, power, parity)
- **`random_tests.asm`** — Random number generation (seeding, determinism, ranges)

### Running Tests

Each test file is a standalone console application that:
1. Calls procedures with various inputs (valid, invalid, edge cases)
2. Checks return values and error codes
3. Prints `PASS` or `FAIL` for each test case

**To run tests:**
1. Build the test program (e.g., `arr_tests.asm`) as a console application
2. Link against `AsmEase64.lib`
3. Run the executable from the command line
4. Review console output for any failures

### What's Tested

✅ **Error conditions** — NULL pointers, zero lengths, out-of-bounds indices  
✅ **Edge cases** — Empty inputs, boundary values, INT64_MIN/MAX  
✅ **Correctness** — Expected outputs for typical inputs  
✅ **Safety** — Overlap handling (memmove semantics), buffer overrun prevention  
✅ **Determinism** — Random module produces consistent output for same seed  

### Example Test Output

```
Running array sanity tests...
T1: get NULL base -> expect ERR_NULLPTR ... PASS
T2: get arr[2] -> expect RAX=30, CF=0 ... PASS
T3: get index==len -> expect ERR_OUT_OF_RANGE ... PASS
...
```

