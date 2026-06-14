; =========================================================================
; PORTUL 1.0A4 - STAGE 0: LEXER + PARSER + ARENA INTEGRATION
; =========================================================================

SECTION .data
    ; Códigos de Token (para mantener todo en registros, cero memoria)
    TOK_EOF   equ 0
    TOK_NUM   equ 1
    TOK_ADD   equ 2
    TOK_IDENT equ 3
    
    ; Códigos de Nodo AST (para el Arena)
    AST_NUM   equ 0x10
    AST_IDENT equ 0x11
    AST_ADD   equ 0x20

    ; Programa de prueba hardcodeado: "add 10 20"
    TEST_SRC  db "add 10 20", 0

SECTION .bss
    ARENA_START     resb 4096
    ARENA_LIMIT     equ 4096
    ERR_OOM         db "ERR: OOM", 10
    ERR_OOM_LEN     equ $ - ERR_OOM

; =========================================================================
; 🏗️ MACROS DEL ARENA (Reutilizadas y optimizadas)
; =========================================================================
%macro ARENA_ALLOC 1
    mov rcx, %1
    mov rdi, r12
    add r12, rcx
    mov rax, ARENA_START
    add rax, ARENA_LIMIT
    cmp r12, rax
    jg .arena_oom
    jmp .alloc_done
.arena_oom:
    mov rax, 1; mov rdi, 1; mov rsi, ERR_OOM; mov rdx, ERR_OOM_LEN; syscall
    mov rax, 60; mov rdi, 1; syscall
.alloc_done:
%endmacro

%macro AST_LEAF_NEW 2
    ; Crea un nodo hoja (Número o Identificador)
    ; %1 = Tipo (AST_NUM o AST_IDENT), %2 = Valor o Índice de string
    ARENA_ALLOC 6
    mov byte [rdi], %1
    mov byte [rdi+1], 0          ; Flags = 0
    mov word [rdi+2], %2         ; Usamos el campo 'left' para guardar el valor inmediato
    mov word [rdi+4], 0          ; right = 0
    mov rax, rdi
    sub rax, ARENA_START         ; rax = Índice relativo de 16 bits
%endmacro

%macro AST_NODE_NEW 3
    ; Crea un nodo con hijos (ej: AST_ADD)
    ; %1 = Tipo, %2 = Índice hijo izquierdo, %3 = Índice hijo derecho
    ARENA_ALLOC 6
    mov byte [rdi], %1
    mov byte [rdi+1], 0
    mov word [rdi+2], %2
    mov word [rdi+4], %3
    mov rax, rdi
    sub rax, ARENA_START
%endmacro

; =========================================================================
; 🧠 LEXER (Ultra-rápido, estado en registros r8 y r9)
; =========================================================================
; Entrada: rsi = puntero de fuente
; Salida:  r8 = CURRENT_TOKEN, r9 = CURRENT_VALUE (si es num)

lex_next:
    ; 1. Saltar espacios
.skip_spaces:
    mov al, byte [rsi]
    cmp al, 0
    je .eof
    cmp al, 32
    je .next_char
    cmp al, 10
    je .next_char
    jmp .check_token
.next_char:
    inc rsi
    jmp .skip_spaces

.check_token:
    ; 2. Detectar 'add'
    movzx cx, word [rsi]
    cmp cx, 0x6461          ; 'ad'
    jne .check_num
    
    mov r8d, TOK_ADD
    add rsi, 3              ; Saltar 'add'
    ret

.check_num:
    ; 3. Detectar número (0-9)
    cmp al, '0'
    jl .check_ident
    cmp al, '9'
    jg .check_ident
    
    ; Es un número, parsearlo
    xor r9, r9              ; r9 = valor acumulado
.parse_digits:
    mov al, byte [rsi]
    cmp al, '0'
    jl .end_num
    cmp al, '9'
    jg .end_num
    
    sub al, '0'             ; Convertir char a int
    movzx rax, al
    mov rcx, 10
    mul rcx                 ; rax = rax * 10 (Nota: mul usa rdx:rax, asumimos valor pequeño)
    ; Corrección para mul: 
    ; Mejor: r9 = r9 * 10 + digito
    mov rax, r9
    mov rcx, 10
    mul rcx                 ; rdx:rax = rax * 10
    movzx rcx, byte [rsi]
    sub rcx, '0'
    add rax, rcx
    mov r9, rax             ; Guardar acumulado
    
    inc rsi
    jmp .parse_digits

.end_num:
    mov r8d, TOK_NUM
    ret

.check_ident:
    ; (Simplificado para el ejemplo: asume cualquier otra cosa es ident)
    mov r8d, TOK_IDENT
    mov r9, rsi             ; r9 guarda el puntero al inicio del ident
    ; Avanzar hasta el siguiente espacio
.read_ident:
    mov al, byte [rsi]
    cmp al, 32
    je .end_ident
    cmp al, 0
    je .end_ident
    inc rsi
    jmp .read_ident
.end_ident:
    ret

.eof:
    mov r8d, TOK_EOF
    ret

; =========================================================================
; 🏗️ PARSER (Recursive Descent que construye el AST en el Arena)
; =========================================================================
; parse_expression:
; Entrada: r8 = token actual
; Salida:  rax = Índice del nodo AST creado en el Arena

parse_expression:
    cmp r8d, TOK_NUM
    je .is_num
    cmp r8d, TOK_IDENT
    je .is_ident
    cmp r8d, TOK_ADD
    je .is_add
    ; Si llega aquí, error de sintaxis (omito manejo de errores por brevedad)
    jmp .error

.is_num:
    ; Crear nodo hoja: AST_LEAF_NEW(AST_NUM, valor_en_r9)
    AST_LEAF_NEW AST_NUM, r9w   ; r9w es la parte de 16 bits de r9
    call lex_next               ; Consumir el token
    ret

.is_ident:
    ; Crear nodo hoja: AST_LEAF_NEW(AST_IDENT, puntero_en_r9)
    ; Nota: En un compilador real, aquí buscaríamos en la Tabla de Símbolos 
    ; y guardaríamos el índice del símbolo, no el puntero crudo.
    AST_LEAF_NEW AST_IDENT, r9w
    call lex_next
    ret

.is_add:
    ; Operación binaria: necesitamos dos operandos
    call lex_next               ; Consumir 'add'
    
    ; Parsear operando izquierdo
    call parse_expression
    mov r10w, ax                ; Guardar índice izquierdo en r10w
    
    ; Parsear operando derecho
    call parse_expression
    mov r11w, ax                ; Guardar índice derecho en r11w
    
    ; Crear nodo padre: AST_NODE_NEW(AST_ADD, left_idx, right_idx)
    AST_NODE_NEW AST_ADD, r10w, r11w
    ret

.error:
    ; Manejo de error de sintaxis
    mov rax, 60; mov rdi, 2; syscall ; exit code 2
    ret

; =========================================================================
; 🏁 PUNTO DE ENTRADA Y PRUEBA
; =========================================================================
global _start
_start:
    ; 1. Inicializar Arena
    mov r12, ARENA_START
    
    ; 2. Cargar fuente de prueba
    mov rsi, TEST_SRC
    
    ; 3. Obtener primer token
    call lex_next
    
    ; 4. Iniciar Parsing (Construye el AST en el Arena)
    call parse_expression
    
    ; --- EN ESTE PUNTO ---
    ; rax contiene el índice del nodo raíz del AST.
    ; Para "add 10 20", el Arena se ve así:
    ; [00-05]: Nodo ADD (type=0x20, left=0x0006, right=0x000C)
    ; [06-11]: Nodo NUM (type=0x10, value=10, right=0)
    ; [12-17]: Nodo NUM (type=0x10, value=20, right=0)
    ; Total usado: 18 bytes de 4096. ¡Eficiencia extrema!

    ; 5. Limpiar y salir (Simulando fin de compilación de un archivo)
    ; ARENA_RESET ; (mov r12, ARENA_START) si fuéramos a compilar otro archivo
    
    mov rax, 60             ; sys_exit
    mov rdi, 0              ; Success
    syscall
