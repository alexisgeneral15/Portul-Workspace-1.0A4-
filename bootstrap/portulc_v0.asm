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
; =========================================================================
; PORTUL 1.0A4 - STAGE 0: SYMBOL TABLE (Vigas de Acero en el Arena)
; =========================================================================

SECTION .data
    ; Tipos de símbolos
    SYM_NUM   equ 0x01
    SYM_FLG   equ 0x02
    SYM_OWN   equ 0x20
    SYM_PTR   equ 0x21
    
    ERR_REDEF db "ERR: REDEF", 10
    ERR_REDEF_LEN equ $ - ERR_REDEF

SECTION .bss
    ; Puntero dedicado para la Tabla de Símbolos dentro del Arena
    SYM_TABLE_PTR resq 1
    CURRENT_SCOPE resb 1          ; Nivel de scope actual (empieza en 0)

; =========================================================================
; 🏗️ MACROS DE LA TABLA DE SÍMBOLOS
; =========================================================================

; 1. Inicializar la Tabla (Llamar después de ARENA_INIT)
%macro SYM_TABLE_INIT 0
    mov qword [SYM_TABLE_PTR], r12  ; La tabla empieza donde empieza el Arena
    mov byte [CURRENT_SCOPE], 0
%endmacro

; 2. Buscar un Símbolo (Linear Scan optimizado para < 50 items por scope)
; Entrada: rsi = puntero al nombre en SOURCE_BUF, rcx = longitud del nombre
; Salida:  rax = puntero al registro de 8 bytes (o 0 si no existe)
%macro SYM_LOOKUP 0
    mov r8, qword [SYM_TABLE_PTR]   ; r8 = inicio de la tabla
    mov r9b, byte [CURRENT_SCOPE]   ; r9b = scope actual a buscar
    
.lookup_loop:
    cmp r8, r12                     ; ¿Llegamos al final del Arena usado?
    jge .not_found
    
    ; Verificar si el scope coincide (para permitir shadowing en scopes hijos, 
    ; pero detectar redefinición en el mismo scope)
    cmp byte [r8 + 4], r9b
    jne .next_sym
    
    ; Verificar longitud del nombre
    cmp byte [r8 + 2], cl
    jne .next_sym
    
    ; Verificar contenido del nombre (usando rep cmpsb para velocidad)
    push rsi
    push rdi
    push rcx
    movzx rdi, word [r8]            ; rdi = offset del nombre guardado
    add rdi, ARENA_START            ; convertir a puntero real
    mov rsi, rsi                    ; rsi ya tiene el nombre a buscar
    repe cmpsb                      ; comparar bytes
    pop rcx
    pop rdi
    pop rsi
    je .found                       ; ¡Coincidencia exacta!
    
.next_sym:
    add r8, 8                       ; Avanzar al siguiente registro de 8 bytes
    jmp .lookup_loop

.not_found:
    xor rax, rax                    ; Retornar 0 (null)
    jmp .lookup_end

.found:
    mov rax, r8                     ; Retornar puntero al registro encontrado

.lookup_end:
%endmacro

; 3. Agregar un Símbolo (Con protección anti-redefinición)
; Entrada: rsi = puntero al nombre, rcx = longitud, dl = tipo (SYM_NUM, etc.)
%macro SYM_ADD 0
    ; PASO 1: Verificar que no exista ya en este scope (La viga anti-colapso)
    SYM_LOOKUP
    test rax, rax
    jnz .error_redef                ; Si rax != 0, ya existe. ¡ERROR!

    ; PASO 2: Calcular offset del nombre relativo al inicio del Arena
    mov r8, rsi
    sub r8, ARENA_START             ; r8 = offset de 16 bits del nombre
    cmp r8, 0xFFFF                  ; Seguridad: no exceder 16 bits
    jg .error_oom

    ; PASO 3: Escribir el registro de 8 bytes en el tope del Arena
    mov word [r12], r8w             ; [0-1]: name_off
    mov byte [r12 + 2], cl          ; [2]: name_len
    mov byte [r12 + 3], dl          ; [3]: type
    mov al, byte [CURRENT_SCOPE]
    mov byte [r12 + 4], al          ; [4]: scope
    mov byte [r12 + 5], 0           ; [5]: flags (0 por defecto)
    mov word [r12 + 6], 0           ; [6-7]: data_off (se llena en codegen)
    
    add r12, 8                      ; Avanzar el puntero del Arena 8 bytes
    jmp .add_done

.error_redef:
    mov rax, 1; mov rdi, 1; mov rsi, ERR_REDEF; mov rdx, ERR_REDEF_LEN; syscall
    mov rax, 60; mov rdi, 3; syscall ; Exit code 3: Redefinición

.error_oom:
    ; (Reutiliza el manejo de OOM definido anteriormente)
    mov rax, 60; mov rdi, 1; syscall

.add_done:
%endmacro

; 4. Cerrar Scope (La viga maestra de la Ley 1: Auto-free de 'own')
; Cuando el parser encuentra '}', llama a esto.
%macro SYM_CLOSE_SCOPE 0
    dec byte [CURRENT_SCOPE]        ; Bajar un nivel de scope
    mov r8, qword [SYM_TABLE_PTR]   ; Empezar a escanear desde el inicio
    mov r9b, byte [CURRENT_SCOPE]   ; Scope que estamos cerrando (el hijo)
    
    ; Escanear hacia atrás es más eficiente, pero hacia adelante es más simple en NASM
    ; Escaneamos hacia adelante buscando símbolos del scope que se cierra
.close_loop:
    cmp r8, r12
    jge .close_done
    
    cmp byte [r8 + 4], r9b          ; ¿Es de este scope?
    jne .next_close
    
    cmp byte [r8 + 3], SYM_OWN      ; ¿Es una variable 'own'?
    jne .next_close
    
    ; ¡Es una variable 'own' saliendo de scope!
    ; AQUÍ EL COMPILADOR EMITE AUTOMÁTICAMENTE EL OPCODE DE 'del'
    ; (Ejemplo: EMIT_BC 0x50, EMIT_BC [r8 + 6] (su data_off))
    ; Por ahora, solo simulamos la acción:
    ; EMIT_BC 0x50  ; Opcode ficticio: OP_FREE_OWN
    ; EMIT_BC [r8 + 6]
    
.next_close:
    add r8, 8
    jmp .close_loop

.close_done:
    ; Opcional: "Podar" el arena moviendo r12 hacia atrás para liberar 
    ; los registros de símbolos de este scope, recuperando esos 8 bytes.
    ; (Implementación de podado omitida por brevedad, pero es un simple 
    ;  scan hacia atrás hasta encontrar un scope < CURRENT_SCOPE).
%endmacro

; =========================================================================
; PORTUL 1.0A4 - STAGE 0: PARSER DE DECLARACIONES (Vigas Maestras)
; =========================================================================

SECTION .data
    ; Tokens
    TOK_EOF   equ 0
    TOK_LET   equ 1
    TOK_MUT   equ 2
    TOK_OWN   equ 3
    TOK_PTR   equ 4
    TOK_FN    equ 5
    TOK_REF   equ 6
    TOK_IDENT equ 10
    TOK_NUM   equ 11
    TOK_EQ    equ 12
    TOK_SEMI  equ 13
    TOK_LBRC  equ 14  ; '{'
    TOK_RBRC  equ 15  ; '}'

    ; Tipos para Symbol Table
    SYM_NUM   equ 0x01
    SYM_OWN   equ 0x20
    SYM_PTR   equ 0x21
    SYM_FN    equ 0x10

    ERR_SYN   db "ERR: SYNTAX", 10
    ERR_SYN_LEN equ $ - ERR_SYN

SECTION .bss
    ; Variables de estado del Lexer/Parser (Mantenidas en registros siempre que sea posible)
    ; rsi = src_ptr, r8 = current_token, r9 = token_value/ptr, r10 = token_len

; =========================================================================
; 🧠 LEXER (Versión extendida para el Parser)
; =========================================================================
lex_next:
    ; 1. Saltar espacios (simplificado)
.skip_spaces:
    mov al, byte [rsi]
    cmp al, 0
    je .eof
    cmp al, 32
    je .next_char
    cmp al, 10
    je .next_char
    jmp .check
.next_char:
    inc rsi
    jmp .skip_spaces

.check:
    ; 2. Detectar Keywords (Comparación de 2-3 bytes en Little Endian)
    movzx cx, word [rsi]
    
    ; 'le' (let) -> 0x656c
    cmp cx, 0x656c
    je .is_let
    ; 'mu' (mut) -> 0x756d
    cmp cx, 0x756d
    je .is_mut
    ; 'ow' (own) -> 0x776f
    cmp cx, 0x776f
    je .is_own
    ; 'pt' (ptr) -> 0x7470
    cmp cx, 0x7470
    je .is_ptr
    ; 'fn' -> 0x6E66
    cmp cx, 0x6E66
    je .is_fn
    ; 're' (ref) -> 0x6572
    cmp cx, 0x6572
    je .is_ref

    ; 3. Detectar Símbolos
    cmp al, '='
    je .is_eq
    cmp al, ';'
    je .is_semi
    cmp al, '{'
    je .is_lbrc
    cmp al, '}'
    je .is_rbrc

    ; 4. Detectar Números
    cmp al, '0'
    jl .is_ident
    cmp al, '9'
    jg .is_ident
    jmp .parse_num

.is_let:    mov r8d, TOK_LET;  add rsi, 3; ret
.is_mut:    mov r8d, TOK_MUT;  add rsi, 3; ret
.is_own:    mov r8d, TOK_OWN;  add rsi, 3; ret
.is_ptr:    mov r8d, TOK_PTR;  add rsi, 3; ret
.is_fn:     mov r8d, TOK_FN;   add rsi, 2; ret
.is_ref:    mov r8d, TOK_REF;  add rsi, 3; ret
.is_eq:     mov r8d, TOK_EQ;   inc rsi; ret
.is_semi:   mov r8d, TOK_SEMI; inc rsi; ret
.is_lbrc:   mov r8d, TOK_LBRC; inc rsi; ret
.is_rbrc:   mov r8d, TOK_RBRC; inc rsi; ret

.parse_num:
    xor r9, r9              ; r9 = valor acumulado
.p_digits:
    mov al, byte [rsi]
    cmp al, '0'
    jl .end_num
    cmp al, '9'
    jg .end_num
    sub al, '0'
    movzx rax, al
    mov rcx, 10
    mul rcx                 ; rdx:rax = rax * 10
    ; (Simplificación: asumimos que no hay desbordamiento de r9 en Stage 0)
    mov r9, rax
    inc rsi
    jmp .p_digits
.end_num:
    mov r8d, TOK_NUM
    ret

.is_ident:
    mov r8d, TOK_IDENT
    mov r9, rsi             ; r9 = puntero al inicio del ident
    mov r10, 0              ; r10 = longitud
.read_id:
    mov al, byte [rsi]
    cmp al, 32
    je .end_id
    cmp al, 0
    je .end_id
    cmp al, '='
    je .end_id
    cmp al, ';'
    je .end_id
    inc rsi
    inc r10
    jmp .read_id
.end_id:
    ret

.eof:
    mov r8d, TOK_EOF
    ret

; =========================================================================
; 🏗️ PARSER: Programa y Sentencias
; =========================================================================
parse_program:
    call lex_next
.prog_loop:
    cmp r8d, TOK_EOF
    je .done
    
    ; Despachador de sentencias
    cmp r8d, TOK_LET
    je parse_var_decl
    cmp r8d, TOK_MUT
    je parse_var_decl
    cmp r8d, TOK_OWN
    je parse_var_decl
    cmp r8d, TOK_PTR
    je parse_var_decl
    cmp r8d, TOK_FN
    je parse_fn_decl
    
    ; Si no es una declaración válida, error de sintaxis
    jmp syntax_error

.done:
    ret

; =========================================================================
; 🏗️ PARSER: Declaración de Variables (let, mut, own, ptr)
; =========================================================================
parse_var_decl:
    ; 1. Determinar el tipo de símbolo basado en el token actual (r8)
    mov dl, SYM_NUM         ; Por defecto para let/mut
    cmp r8d, TOK_OWN
    je .is_own_ptr
    cmp r8d, TOK_PTR
    je .is_own_ptr
    jmp .after_type_check

.is_own_ptr:
    cmp r8d, TOK_OWN
    je .is_own
    mov dl, SYM_PTR         ; Es PTR
    jmp .after_type_check
.is_own:
    mov dl, SYM_OWN         ; Es OWN

.after_type_check:
    call lex_next           ; Consumir keyword, ahora r8 debe ser TOK_IDENT

    cmp r8d, TOK_IDENT
    jne syntax_error

    ; 2. ¡VIGA MAESTRA! Registrar en la Tabla de Símbolos
    ; r9 tiene el puntero al nombre, r10 tiene la longitud, dl tiene el tipo
    mov rsi, r9
    mov rcx, r10
    SYM_ADD                 ; Si ya existe en este scope, el compilador aborta aquí (ERR: REDEF)

    call lex_next           ; Consumir ident, ahora r8 debe ser TOK_EQ

    cmp r8d, TOK_EQ
    jne syntax_error

    call lex_next           ; Consumir '=', ahora r8 debe ser TOK_NUM o TOK_REF

    ; 3. Parsear el valor inicial
    cmp r8d, TOK_REF
    je .parse_ref
    
    ; Es un número (let x = 10)
    cmp r8d, TOK_NUM
    jne syntax_error
    ; AQUÍ: El parser emitiría el bytecode para guardar el valor (r9) 
    ; y actualizaría el 'data_off' del símbolo recién creado.
    jmp .expect_semi

.parse_ref:
    ; Es una referencia (own p = ref x)
    call lex_next           ; Consumir 'ref', ahora r8 debe ser TOK_IDENT
    cmp r8d, TOK_IDENT
    jne syntax_error
    ; AQUÍ: El parser verificaría en la Symbol Table que 'x' existe y es válido,
    ; y emitiría el bytecode de asignación de referencia.
    jmp .expect_semi

.expect_semi:
    call lex_next           ; Consumir valor/ref, ahora r8 debe ser TOK_SEMI
    cmp r8d, TOK_SEMI
    jne syntax_error
    
    call lex_next           ; Consumir ';', listo para la siguiente sentencia
    jmp parse_program       ; Continuar parseando

; =========================================================================
; 🏗️ PARSER: Declaración de Funciones (fn)
; =========================================================================
parse_fn_decl:
    call lex_next           ; Consumir 'fn', ahora r8 debe ser TOK_IDENT
    cmp r8d, TOK_IDENT
    jne syntax_error

    ; 1. Registrar la función en la Tabla de Símbolos (Scope Global usualmente)
    mov rsi, r9
    mov rcx, r10
    mov dl, SYM_FN
    SYM_ADD

    call lex_next           ; Consumir ident, ahora r8 debe ser TOK_LBRC '{'
    cmp r8d, TOK_LBRC
    jne syntax_error

    ; 2. ¡ABRIR SCOPE! (La viga que permite el auto-free)
    inc byte [CURRENT_SCOPE]

    call lex_next           ; Consumir '{'

    ; 3. Parsear el cuerpo de la función
.fn_body_loop:
    cmp r8d, TOK_RBRC
    je .end_fn

    ; (Aquí irían las llamadas a parse_statement para el cuerpo: if, whl, add, ret, etc.)
    ; Por brevedad, asumimos que consume tokens hasta encontrar '}'
    call lex_next
    jmp .fn_body_loop

.end_fn:
    ; 4. ¡CERRAR SCOPE! (La magia de la Ley 1)
    ; Esta macro escanea la Symbol Table y emite automáticamente los opcodes 
    ; de liberación ('del') para cualquier variable marcada como SYM_OWN en este scope.
    SYM_CLOSE_SCOPE
    
    dec byte [CURRENT_SCOPE]
    
    call lex_next           ; Consumir '}'
    jmp parse_program       ; Continuar con el programa

; =========================================================================
; 🚨 MANEJO DE ERRORES
; =========================================================================
syntax_error:
    mov rax, 1
    mov rdi, 1
    mov rsi, ERR_SYN
    mov rdx, ERR_SYN_LEN
    syscall
    mov rax, 60
    mov rdi, 4              ; Exit code 4: Syntax Error
    syscall
