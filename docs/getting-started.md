# Getting Started with AsmEase64

Complete installation and setup guide for Windows x64 assembly development.

This guide will walk you through **everything** you need to start using AsmEase64 — from downloading the library to writing and running your first program.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Option 1: Download Prebuilt Release (Recommended)](#option-1-download-prebuilt-release-recommended)
  - [Option 2: Clone from Source](#option-2-clone-from-source)
- [Setup for Visual Studio](#setup-for-visual-studio)
  - [Step 1: Create a New MASM Project](#step-1-create-a-new-masm-project)
  - [Step 2: Add Include Path](#step-2-add-include-path)
  - [Step 3: Add Library Path](#step-3-add-library-path)
  - [Step 4: Link the Library](#step-4-link-the-library)
  - [Verification](#verification)
- [Setup for Command-Line (ML64 + LINK)](#setup-for-command-line-ml64--link)
  - [Folder Layout](#folder-layout)
  - [Step 1: Assemble Your Source](#step-1-assemble-your-source)
  - [Step 2: Link the Object File](#step-2-link-the-object-file)
  - [Step 3: Run the Program](#step-3-run-the-program)
  - [Full One-Liner Build](#full-one-liner-build)
  - [Optional: Create a Build Script](#optional-create-a-build-script)
- [Your First Program](#your-first-program)
  - [Hello World Example](#hello-world-example)
  - [Understanding the Code](#understanding-the-code)
- [Next Steps](#next-steps)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before using AsmEase64, make sure you have the following installed:

### Required Software

| Component | Requirement | Notes |
|-----------|-------------|-------|
| **Operating System** | Windows 10 or later (x64 only) | AsmEase64 uses Windows-specific APIs |
| **Assembler** | MASM (ML64) | Included with Visual Studio or Windows SDK |
| **Linker** | `link.exe` | Bundled with Visual Studio toolchain |
| **IDE (optional)** | Visual Studio 2019 or later | For GUI-based development |

### Required Knowledge

- **Basic x86-64 Assembly** — Familiarity with registers, instructions, and syntax
- **Windows x64 Calling Convention** — Understanding of `RCX`, `RDX`, `R8`, `R9` parameter passing
- **MASM Syntax** — Knowledge of MASM-specific directives (`.data`, `.code`, `PROC`, etc.)

> **New to Assembly?** Check out these resources:
> - [MASM Documentation (Microsoft)](https://docs.microsoft.com/en-us/cpp/assembler/masm/masm-for-x64-ml64-exe)
> - [x64 Calling Convention Guide](https://docs.microsoft.com/en-us/cpp/build/x64-calling-convention)

---

## Installation

AsmEase64 can be installed in two ways — by downloading the prebuilt release or by cloning the repository.

### Option 1: Download Prebuilt Release (Recommended)

This is the **fastest and easiest** way to get started.

#### Steps:

1. **Visit the Releases page:**
   - Go to [https://github.com/trystanhenriques/AsmEase64/releases](https://github.com/trystanhenriques/AsmEase64/releases)

2. **Download the latest release:**
   - Look for the most recent version (e.g., `v1.0.0`)
   - Download the `AsmEase64.zip` file

3. **Extract the archive:**
   - Extract to a convenient location, such as:
     ```
     C:\AsmEase64\
     ```
   - **Important:** Choose a path **without spaces** to avoid linker issues

4. **Verify the folder structure:**
   After extraction, your folder should look like this:
   ```
   C:\AsmEase64\
   ├── inc/                    (Include files)
   │   ├── AsmEase64.inc
   │   ├── array.inc
   │   ├── errors.inc
   │   ├── io.inc
   │   ├── macros.inc
   │   ├── math.inc
   │   ├── random.inc
   │   ├── string.inc
   │   └── win32_console.inc
   └── lib/                    (Prebuilt library)
       └── AsmEase64.lib
   ```

> **✅ That's it!** You only need the `inc/` and `lib/` folders.

---

### Option 2: Clone from Source

If you want to **modify the library** or **inspect the source code**, clone the repository.

#### Steps:

1. **Open a terminal** (PowerShell or Command Prompt)

2. **Clone the repository:**
   ```bash
   git clone https://github.com/trystanhenriques/AsmEase64.git
   cd AsmEase64
   ```

3. **Build the static library:**
   - Open **x64 Native Tools Command Prompt for VS**
   - Navigate to the `src/` directory
   - Run the build commands:
     ```bash
     ml64 /c /Fo obj\ *.asm
     lib /OUT:lib\AsmEase64.lib obj\*.obj
     ```

4. **Verify the build:**
   - You should have `lib\AsmEase64.lib`
   - The `inc/` folder contains all header files

> **Note:** Building from source requires the **Visual Studio toolchain** to be installed.

---

## Setup for Visual Studio

If you prefer a **GUI-based workflow**, you can integrate AsmEase64 directly into Visual Studio for assembling, linking, and debugging your programs.

### Step 1: Create a New MASM Project

1. **Open Visual Studio**
   - Go to **File → New → Project**

2. **Create an Empty Project**
   - Search for **"Empty Project"** (C++ projects work for MASM)
   - Name your project (e.g., `HelloAsmEase`)
   - Click **Create**

3. **Set the platform to x64**
   - In the toolbar, find the **Solution Platforms** dropdown
   - Select **x64** (not Win32!)

   > **Important:** AsmEase64 is **x64-only**. Make sure your project targets x64.

---

### Step 2: Add Include Path

Tell MASM where to find AsmEase64's `.inc` files.

1. **Open Project Properties:**
   - In **Solution Explorer**, right-click your project → **Properties**

2. **Navigate to MASM settings:**
   - Go to **Configuration Properties → Microsoft Macro Assembler → General**

3. **Set the Include Paths:**
   - Find the **Include Paths** field
   - Add the path to your `inc/` folder:
     ```
     C:\AsmEase64\inc
     ```
   - *(Adjust the path if you installed elsewhere)*

4. **Apply the changes:**
   - Click **Apply** → **OK**

#### Screenshot Reference:

<img width="780" height="463" alt="Visual Studio Include Path Configuration" src="https://github.com/user-attachments/assets/f7470154-5b96-4baa-bbd1-0907a1a0e141" />

> **What this does:** Now you can write `include AsmEase64.inc` in your code without specifying the full path.

---

### Step 3: Add Library Path

Tell the linker where to find `AsmEase64.lib`.

1. **Open Project Properties:**
   - Right-click your project → **Properties**

2. **Navigate to Linker settings:**
   - Go to **Configuration Properties → Linker → General**

3. **Set Additional Library Directories:**
   - Find the **Additional Library Directories** field
   - Add the path to your `lib/` folder:
     ```
     C:\AsmEase64\lib
     ```

4. **Apply the changes:**
   - Click **Apply** → **OK**

#### Screenshot Reference:

<img width="791" height="507" alt="Visual Studio Library Path Configuration" src="https://github.com/user-attachments/assets/8a5a21e0-7925-4989-925a-11928b606375" />

> **What this does:** The linker now knows where to find `AsmEase64.lib`.

---

### Step 4: Link the Library

Tell the linker to include `AsmEase64.lib` in your build.

1. **Open Project Properties:**
   - Right-click your project → **Properties**

2. **Navigate to Linker Input:**
   - Go to **Configuration Properties → Linker → Input**

3. **Set Additional Dependencies:**
   - Find the **Additional Dependencies** field
   - Add:
     ```
     AsmEase64.lib
     ```
   - *(Leave existing dependencies like `kernel32.lib` unchanged)*

4. **Apply the changes:**
   - Click **Apply** → **OK**

#### Screenshot Reference:

<img width="789" height="509" alt="Visual Studio Additional Dependencies Configuration" src="https://github.com/user-attachments/assets/630c1671-ebbc-4c05-90f2-09e3011d9e94" />

> **What this does:** Ensures the linker pulls in all AsmEase64 procedures during the build.

---

### Verification

Test your Visual Studio setup with a simple program:

1. **Add a new `.asm` file:**
   - Right-click your project → **Add → New Item**
   - Select **C++ File (.cpp)** *(yes, really!)*
   - Rename it to `main.asm`

2. **Write a test program:**
   ```nasm
   include AsmEase64.inc

   .data
   msg db "Hello from AsmEase64 in Visual Studio!", 0

   .code
   main PROC
       mov  rcx, OFFSET msg
       call io_print_string
       call io_print_newline
       ret
   main ENDP
   END main
   ```

3. **Build and Run:**
   - Press **F5** (or **Build → Build Solution**)
   - You should see:
     ```
     Hello from AsmEase64 in Visual Studio!
     ```

**✅ Success!** Your Visual Studio setup is complete.

---

## Setup for Command-Line (ML64 + LINK)

If you prefer **manual control** or don't want to use Visual Studio, you can build your programs from the command line.

### Folder Layout

For this example, assume:
- **AsmEase64 installed at:** `C:\AsmEase64\`
- **Your project folder:** `C:\Projects\MyTest\`
- **Your source file:** `C:\Projects\MyTest\hello.asm`

---

### Step 1: Assemble Your Source

1. **Open x64 Native Tools Command Prompt:**
   - Search for **"x64 Native Tools Command Prompt for VS"** in the Start menu
   - This configures paths for `ml64.exe` and `link.exe`

2. **Navigate to your project folder:**
   ```bash
   cd C:\Projects\MyTest
   ```

3. **Assemble your `.asm` file:**
   ```bash
   ml64 /c /I "C:\AsmEase64\inc" /W3 hello.asm
   ```

#### Explanation of Flags:

| Flag | Meaning |
|------|---------|
| `/c` | Assemble only (don't link yet) |
| `/I "C:\AsmEase64\inc"` | Add include path for AsmEase64 `.inc` files |
| `/W3` | Set warning level 3 (catches common mistakes) |

#### Expected Output:

```
Microsoft (R) Macro Assembler (x64) Version 14.XX.XXXXX
Copyright (C) Microsoft Corporation. All rights reserved.

Assembling: hello.asm
```

After this step, you should have `hello.obj` in your project folder.

---

### Step 2: Link the Object File

Link the assembled object file with `AsmEase64.lib`:

```bash
link hello.obj "C:\AsmEase64\lib\AsmEase64.lib" /SUBSYSTEM:CONSOLE
```

#### Explanation of Flags:

| Flag | Meaning |
|------|---------|
| `/SUBSYSTEM:CONSOLE` | Creates a console application (not a GUI app) |
| `"C:\AsmEase64\lib\AsmEase64.lib"` | Links your program with the AsmEase64 library |

#### Expected Output:

```
Microsoft (R) Incremental Linker Version 14.XX.XXXXX
Copyright (C) Microsoft Corporation. All rights reserved.

/OUT:hello.exe
hello.obj
C:\AsmEase64\lib\AsmEase64.lib
```

After this step, you should have `hello.exe` in your project folder.

---

### Step 3: Run the Program

Execute your program:

```bash
hello.exe
```

**Expected Output:**

```
Hello from AsmEase64!
```

**✅ Success!** Your command-line setup is complete.

---

### Full One-Liner Build

For convenience, here's the complete build command:

```bash
ml64 /c /I "C:\AsmEase64\inc" /W3 hello.asm && link hello.obj "C:\AsmEase64\lib\AsmEase64.lib" /SUBSYSTEM:CONSOLE
```

This assembles and links in one step (uses `&&` to chain commands).

---

### Optional: Create a Build Script

Save this as `build.bat` in your project folder for **one-command builds**:

```batch
@echo off
REM ==========================================
REM AsmEase64 Build Script
REM Usage: build.bat <filename_without_extension>
REM Example: build.bat hello
REM ==========================================

IF "%~1"=="" (
    echo Error: No filename provided
    echo Usage: build.bat ^<filename^>
    exit /b 1
)

echo ==========================================
echo Building %1.asm...
echo ==========================================

REM Assemble
ml64 /c /I "C:\AsmEase64\inc" /W3 %1.asm
IF ERRORLEVEL 1 (
    echo Assembly failed!
    exit /b 1
)

REM Link
link %1.obj "C:\AsmEase64\lib\AsmEase64.lib" /SUBSYSTEM:CONSOLE
IF ERRORLEVEL 1 (
    echo Linking failed!
    exit /b 1
)

echo ==========================================
echo Build successful! Running %1.exe...
echo ==========================================
%1.exe
```

**Usage:**

```bash
build hello
```

This will:
1. Assemble `hello.asm` → `hello.obj`
2. Link `hello.obj` → `hello.exe`
3. Run `hello.exe`

---

## Your First Program

Let's write a complete program to verify everything works.

### Hello World Example

Create a file called `hello.asm`:

```nasm
; ==========================================
; hello.asm — Your first AsmEase64 program
; ==========================================

include AsmEase64.inc

.data
msg db "Hello from AsmEase64!", 0

.code
main PROC
    ; Print the message
    mov  rcx, OFFSET msg
    call io_print_string
    
    ; Print a newline
    call io_print_newline
    
    ; Exit cleanly
    xor  ecx, ecx
    ret
main ENDP
END main
```

**Build and run:**

- **Visual Studio:** Press **F5**
- **Command-line:** `build hello` (or use the one-liner)

**Expected Output:**

```
Hello from AsmEase64!
```

---

### Understanding the Code

Let's break down what each part does:

#### 1. Include the Library
```nasm
include AsmEase64.inc
```
- Brings in all AsmEase64 procedure prototypes
- Equivalent to `#include` in C

#### 2. Define Data
```nasm
.data
msg db "Hello from AsmEase64!", 0
```
- `.data` section holds global variables
- `msg` is a **NUL-terminated string** (C-style string)
- `db` = "define byte"

#### 3. Main Procedure
```nasm
.code
main PROC
    ; ... your code ...
    ret
main ENDP
END main
```
- `.code` section holds executable instructions
- `main PROC` defines the entry point
- `END main` tells MASM where execution starts

#### 4. Print the String
```nasm
mov  rcx, OFFSET msg
call io_print_string
```
- `OFFSET msg` gets the **address** of `msg`
- `RCX` holds the first argument (Windows x64 ABI)
- `io_print_string` prints a NUL-terminated string

#### 5. Print a Newline
```nasm
call io_print_newline
```
- Prints a Windows-style newline (`\r\n`)

#### 6. Exit
```nasm
xor  ecx, ecx
ret
```
- `xor ecx, ecx` sets `RCX` to 0 (exit code)
- `ret` returns to the OS

---

## Next Steps

Now that you have AsmEase64 set up, explore the library:

### 📖 Learn the API
- **[I/O Module](api/io.md)** — Console output procedures
- **[Array Module](api/arrays.md)** — QWORD array operations
- **[String Module](api/strings.md)** — String manipulation utilities
- **[Math Module](api/math.md)** — Integer math helpers
- **[Random Module](api/random.md)** — Pseudo-random number generation

### 🎯 Try Examples
- **[Example Programs](examples/)** — Working code samples for each module

### 🛠️ Understand Errors
- **[Error Handling Guide](error-handling.md)** — Complete guide to the CF/EAX error model

### 🚀 Build Something
Try writing:
- A number guessing game (use `rand_range`)
- A text adventure (use `str_compare`, `io_print_string`)
- Array sorting (use `arr_swap`, `arr_get_value`)

---

## Troubleshooting

### Issue: "Cannot open include file: 'AsmEase64.inc'"

**Cause:** MASM can't find the include path.

**Solution:**
- **Visual Studio:** Check that you added `C:\AsmEase64\inc` to **Include Paths** (Step 2)
- **Command-line:** Make sure you use `/I "C:\AsmEase64\inc"` flag

---

### Issue: "Unresolved external symbol 'io_print_string'"

**Cause:** Linker can't find `AsmEase64.lib`.

**Solution:**
- **Visual Studio:** Verify you added `C:\AsmEase64\lib` to **Additional Library Directories** (Step 3) and `AsmEase64.lib` to **Additional Dependencies** (Step 4)
- **Command-line:** Make sure you specify `"C:\AsmEase64\lib\AsmEase64.lib"` in the `link` command

---

### Issue: "fatal error LNK1112: module machine type 'x86' conflicts with target machine type 'x64'"

**Cause:** Your project is set to **Win32** instead of **x64**.

**Solution:**
- **Visual Studio:** Change **Solution Platforms** from **Win32** to **x64** in the toolbar
- **Command-line:** Make sure you're using **x64 Native Tools Command Prompt** (not x86)

---

### Issue: Build succeeds but nothing prints

**Cause:** Program might be exiting before you see output (in Visual Studio debugger).

**Solution:**
Add a pause at the end:
```nasm
; Before ret
call io_print_string    ; or any I/O call
; Optionally: add a breakpoint here in debugger
ret
```

Or run from **Command Prompt** instead of debugger.

---

### Issue: "Access violation" or crash

**Cause:** NULL pointer, bad stack alignment, or register corruption.

**Solution:**
- Check that you're passing valid pointers to procedures
- Use error checking: `jc error` after calls
- Verify you're following Windows x64 ABI (first 4 args in `RCX`, `RDX`, `R8`, `R9`)

---

## Still Need Help?

- **Check the API docs** — [docs/api/](api/)
- **Look at test files** — `tests/` folder has working examples
- **Open an issue** — [GitHub Issues](https://github.com/trystanhenriques/AsmEase64/issues)

---

**Happy coding! 🚀**
