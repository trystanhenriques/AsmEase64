
# x64AsmLib — Prebuilt MASM Helper Library (Windows x64)

**x64AsmLib** is a small helper library for **MASM (ml64.exe)** on Windows x64.  
You link the **prebuilt static library** and include the provided **`.inc`** files—no need to compile our sources.

> Current coverage: QWORD array helpers (`arr_*`), with a strict, uniform error model (CF/EAX) and Windows x64 ABI.

## Requirements

- Windows 10/11 x64
- Visual Studio 2022 (Community or higher) **or** a build system that can link MSVC static libs for x64
- A project that uses **MASM (ml64.exe)** for your assembly files

## Install & Link (Visual Studio)

In your **consumer project** (the app that calls our procs):

1. **Copy** the folders from this package somewhere in (or next to) your repo, e.g.:
```masm
third_party\x64AsmLib\inc
third_party\x64AsmLib\lib\x64\Release\x64AsmLib.lib
```

2. **Project Properties → Configuration: x64** (very important)

3. **VC++ Directories → Include Directories**  
    Add: `path\to\third_party\x64AsmLib\inc
    `
4. **Linker → General → Additional Library Directories**  
    Add: `path\to\third_party\x64AsmLib\lib\x64\Release`
    
5. **Linker → Input → Additional Dependencies**  
    Add: `x64AsmLib.lib` (use the actual filename if you renamed it)
    

> If you link the **Debug** build, point (4) to the Debug lib folder instead.

## Using the library (MASM)

1. Include the header(s) in your assembly:
```
INCLUDE array.inc         ; arr_* public API
; INCLUDE macros.inc      ; only if you directly use the macros yourself
OPTION casemap:none
```

2. Call procedures with **Windows x64 ABI**:
	- Args: `RCX`, `RDX`, `R8`, `R9` (then stack if needed)
	- Return value: `RAX`
	- **Success:** `CF = 0`
	- **Error:** `CF = 1` and **`EAX = ARR_ERR_*`**

3. Minimal Example 

```masm
.data
arr QWORD 10, 20, 30, 40, 50

.code
main PROC
    ; Read arr[2] -> RAX
    lea  rcx, arr            ; base (QWORD*)
    mov  rdx, 5              ; len
    mov  r8,  2              ; index
    call arr_get_value
    jc   had_error
    ; RAX == 30 on success

    ; Reverse in-place
    lea  rcx, arr
    mov  rdx, 5
    call arr_reverse
    jc   had_error

    xor  ecx, ecx
    ret

had_error:
    ; EAX has one of:
    ;   ARR_ERR_NULLPTR = 1
    ;   ARR_ERR_OUTOFRANGE = 2
    ;   ARR_ERR_LEN_ZERO  = 3
    ;   ARR_ERR_CAPACITY  = 4 (reserved for future ops)
    ret
main ENDP
END
```

## Error model (applies to all public procs)

- **Success:** CF=0. (`RAX` may return a value.)
- **Error:** CF=1 and **`EAX = ARR_ERR_*`**
    - `ARR_ERR_NULLPTR` (1) — a required pointer was NULL
    - `ARR_ERR_OUTOFRANGE`(2) — index not in `[0, len)`
    - `ARR_ERR_LEN_ZERO` (3) — zero length where >0 is required
    - `ARR_ERR_CAPACITY` (4) — insufficient capacity (for future capacity-aware ops)
**Suggested pattern:**

```
call arr_max
jc   err
; use RAX
; ...
err:
cmp  eax, ARR_ERR_NULLPTR
je   handle_null
; ...
```

## Documentation

- **Array module reference:** `docs/arrays.md`  
    This contains everything you need to call each `arr_*` procedure: parameters, returns, errors, clobbers, notes, and examples.
- Future modules (strings, I/O) will ship their own docs later and be linked from here.

## Notes & Tips

- **Platform:** The library is built for **x64**. Ensure your consumer project’s platform is **x64** (not Win32).
- **Signed vs. unsigned:** Choose the proc that matches your comparison semantics:
    - Unsigned queries: `arr_max`, `arr_min`, `arr_index_of_max`, `arr_index_of_min`
    - Signed queries: `arr_smax`, `arr_smin`, `arr_index_of_smax`, `arr_index_of_smin`
- **64-bit immediate compares:** `cmp rax, imm64` isn’t encodable; load large constants to a register first:

```
mov rdx, 7FFFFFFFFFFFFFFFh
cmp rax, rdx
```

