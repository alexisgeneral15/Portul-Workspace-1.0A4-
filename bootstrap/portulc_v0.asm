; =========================================================================
; PORTUL 1.0A4 - STAGE 0 BOOTSTRAP COMPILER (portulc_v0.asm)
; Arquitectura: x86_64 Linux (NASM)
; Filosofía: Cero libc, cero malloc, macros de velocidad, memoria estática.
; =========================================================================

BITS 64
SECTION .bss
    ; Memoria estática ultra-limitada (Filosofía 5KB)
    SOURCE_BUF      resb 4096       ; Buffer para el código fuente Portul
    BYTECODE_BUF    resb 4096       ; Buffer de salida (Bytecode/ASM intermedio)
    BC_PTR          resq 1          ; Puntero actual de escritura en bytecode
    SRC_PTR         resq 1          ; Puntero actual de lectura en fuente
    TOKEN_TYPE      resb 1          ; Tipo de token actual

SECTION .data
    ; Mensajes de error/sistema (mínimos)
    ERR_SYN         db "ERR: SYNTAX", 10
    ERR_SYN_LEN     equ $ - ERR_SYN
    MSG_COMPILE     db "PORTUL STAGE 0: COMPILING...", 10
    MSG_COMPILE_LEN equ $ - MSG_COMPILE

; =========================================================================
; 🚀 MACROS DE OPTIMIZACIÓN EXTREMA
; =========================================================================

; Macro 1: Syscall directa (Evita cualquier overhead de libc)
%macro SYSCALL 1
    mov rax, %1
    syscall
%endmacro

; Macro 2: Emisión de Bytecode ultra-rápida (Registro fijo, sin llamadas a función)
%macro EMIT_BC 1
    mov rdi, [BC_PTR]       ; rdi = puntero de escritura
    mov byte [rdi], %1      ; escribe el opcode
    inc rdi                 ; avanza puntero
    mov [BC_PTR], rdi       ; guarda nuevo puntero
%endmacro

; Macro 3: Avanzar puntero de fuente y saltar espacios en blanco (Unrolled)
%macro ADVANCE_SRC 0
.skip_spaces:
    mov al, byte [rsi]      ; rsi es nuestro SRC_PTR fijo
    cmp al, 32              ; espacio
    je .next_char
    cmp al, 10              ; newline
    je .next_char
    cmp al, 9               ; tab
    je .next_char
    jmp .done
.next_char:
    inc rsi
    jmp .skip_spaces
.done:
%endmacro

; =========================================================================
; 🏁 PUNTO DE ENTRADA
; =========================================================================
global _start
_start:
    ; 1. Imprimir mensaje de inicio
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, MSG_COMPILE
    mov rdx, MSG_COMPILE_LEN
    syscall

    ; 2. Simulación de carga de archivo (En un caso real, usarías sys_open/sys_read)
    ; Para este bootstrap, asumimos que el código está hardcodeado o cargado en SOURCE_BUF
    ; Aquí cargamos un string de prueba: "fn main { add a b; ret a; }"
    mov qword [SRC_PTR], SOURCE_BUF
    mov qword [BC_PTR], BYTECODE_BUF
    
    ; Hardcodeamos un mini programa Portul para probar el lexer/parser
    mov rdi, SOURCE_BUF
    mov byte [rdi], 'f'
    mov byte [rdi+1], 'n'
    mov byte [rdi+2], ' '
    mov byte [rdi+3], 'm'
    mov byte [rdi+4], 'a'
    mov byte [rdi+5], 'i'
    mov byte [rdi+6], 'n'
    mov byte [rdi+7], ' '
    mov byte [rdi+8], '{'
    mov byte [rdi+9], 0     ; Null terminator

    mov rsi, [SRC_PTR]      ; rsi = puntero de fuente (Convención: rsi para source)

; =========================================================================
; 🧠 LEXER (Optimizado con saltos directos, sin tablas de hash lentas)
; =========================================================================
lexer:
    ADVANCE_SRC             ; Macro: salta espacios, deja el primer char en 'al' y 'rsi' apuntando a él

    cmp al, 0               ; Fin de archivo
    je end_compile

    ; Detección ultra-rápida de keywords de 2-3 letras (ej: 'fn')
    ; Comparamos 2 bytes a la vez para velocidad (Little Endian)
    movzx rcx, word [rsi]   ; Carga 2 caracteres (ej: 'fn' = 0x6E66)
    
    cmp cx, 0x6E66          ; 'fn' (0x66='f', 0x6E='n')
    je is_fn
    
    ; ... aquí irían más comparaciones para 'if', 'whl', 'add', 'ret', etc.
    ; Usando la misma técnica de word/dword compare para velocidad extrema.

    jmp lexer               ; Si no coincide, avanzar y probar de nuevo (simplificado para el ejemplo)

is_fn:
    mov byte [TOKEN_TYPE], 1 ; Token ID para 'fn'
    add rsi, 2               ; Avanzar 2 bytes ('f', 'n')
    call parse_fn
    jmp lexer

; =========================================================================
; 🏗️ PARSER & CODEGEN (Recursivo descendente mínimo)
; =========================================================================
parse_fn:
    ADVANCE_SRC             ; Saltar espacio después de 'fn'
    ; Aquí iría la extracción del nombre de la función (IDENTIFIER)
    ; ...
    ADVANCE_SRC             ; Saltar hasta '{'
    
    ; EMITIR OPCODE DE INICIO DE FUNCIÓN
    EMIT_BC 0x10            ; Opcode ficticio: OP_FN_START

parse_body:
    ; Lexer interno para el cuerpo de la función
    ADVANCE_SRC
    cmp al, '}'
    je end_fn

    ; Detectar 'add'
    movzx rcx, word [rsi]
    cmp cx, 0x6461          ; 'ad'
    jne check_ret
    
    ; Es 'add', parsear operandos y emitir
    EMIT_BC 0x20            ; Opcode: OP_ADD
    add rsi, 3              ; saltar 'add'
    jmp parse_body

check_ret:
    movzx cx, word [rsi]
    cmp cx, 0x7472          ; 're' (de 'ret')
    jne parse_body          ; Si no es nada conocido, seguir (simplificado)
    
    EMIT_BC 0x30            ; Opcode: OP_RET
    add rsi, 3
    jmp parse_body

end_fn:
    EMIT_BC 0x11            ; Opcode: OP_FN_END
    ret

; =========================================================================
; 🏁 FINALIZACIÓN
; =========================================================================
end_compile:
    ; Aquí escribiríamos BYTECODE_BUF en un archivo de salida (sys_open, sys_write)
    ; Por ahora, solo terminamos limpiamente.
    
    mov rax, 60             ; sys_exit
    mov rdi, 0              ; exit code 0
    syscall
