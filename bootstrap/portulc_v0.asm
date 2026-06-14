; =========================================================================
; PORTUL 1.0A4 - STAGE 0: LEXER/PARSER DE PASO ÚNICO CON HASHING
; =========================================================================

; Tabla de Hashing Perfecto (Simplificada para el bootstrap)
; 'fn'  = 0x6E66 -> Hash: (0x66 + 0x6E) & 0xFF = 0xD4
; 'if'  = 0x6669 -> Hash: (0x69 + 0x66) & 0xFF = 0xCF
; 'add' = 0x6461 -> Hash: (0x61 + 0x64 + 0x64) & 0xFF = 0x29 (simplificado a 2 chars: 0xC5)

%macro PARSE_KEYWORD 2
    ; %1 = Hash esperado (calculado previamente)
    ; %2 = Opcode a emitir
    movzx cx, word [rsi]      ; Cargar 2 chars
    movzx dx, cl              ; dx = char 1
    add dl, ch                ; dl = char 1 + char 2 (Hash ultra-rápido)
    cmp dl, %1
    je .match_%2
    jmp .no_match
.match_%2:
    EMIT_BC %2                ; ¡Single-pass! Emitimos bytecode al instante
    add rsi, 2                ; Avanzamos el puntero
    jmp lexer_continue
.no_match:
%endmacro

parse_token:
    ADVANCE_SRC               ; Macro que salta espacios
    
    cmp al, 0
    je end_compile
    
    ; Intentar hacer match con hashing
    PARSE_KEYWORD 0xD4, 0x10  ; 0xD4 es el hash de 'fn', 0x10 es OP_FN
    PARSE_KEYWORD 0xCF, 0x40  ; 0xCF es el hash de 'if', 0x40 es OP_IF
    PARSE_KEYWORD 0xC5, 0x20  ; 0xC5 es el hash de 'ad' (add), 0x20 es OP_ADD
    
    ; Si llega aquí, es un identificador o literal (manejo simplificado)
    ; En una versión completa, aquí iría la lógica de números/variables
    
lexer_continue:
    jmp parse_token
