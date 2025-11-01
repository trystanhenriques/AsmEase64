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

A simple “Hello, world” using AsmEase64’s I/O subsystem:  

```nasm
; Example: hello.asm
include AsmEase64.inc

.data
msg db "Hello from AsmEase64!", 0

.code
main PROC
    mov rcx, OFFSET msg        ; RCX = pointer to string
    call io_print_string       ; prints the string
    call io_print_newline      ; prints CRLF ("\r\n")
    ret
main ENDP
END main
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

#### Example

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
