# Especificación de Portul 1.0A4

## Introducción

Portul es un lenguaje de programación diseñado para sistemas embebidos con restricciones extremas de memoria (5KB). Combina:

- **Seguridad de tipos**: Type checking estricto en compilación
- **Gestión de memoria inteligente**: `own` vs `ptr`, bloque `fin`
- **Operaciones atómicas**: `cas`, `atm`, `lck`
- **Optimización extrema**: IR compacta, zero-copy

## Características Principales

### 1. Sistema de Tipos

```portul
i32, i64, f32, f64     ; Tipos numéricos
bool                   ; Booleano
str                    ; String
ptr<T>                 ; Puntero a tipo T
own<T>                 ; Ownership de tipo T
```

### 2. Gestión de Memoria

**own** (Ownership):
```portul
own<i32> x = 42;
; x es el único propietario de este valor
; Se limpia automáticamente al salir del scope
```

**ptr** (Puntero):
```portul
ptr<i32> p = &x;
; p es una referencia a x
; No transfiere ownership
```

**fin** (Bloque de finalización):
```portul
fin {
    ; Código que se ejecuta al limpiar recursos
}
```

### 3. Operaciones Atómicas

**cas** (Compare-And-Swap):
```portul
own<i32> x = 10;
if cas(&x, 10, 20) {
    ; Swap atómico si x == 10
}
```

**atm** (Atomic increment):
```portul
atm(&x);  ; x++ de forma atómica
```

**lck** (Lock):
```portul
lck(lock_id);
; Sección crítica
unlck(lock_id);
```

### 4. Función Básica

```portul
fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

### 5. Control de Flujo

```portul
if condition {
    ; ...
} else {
    ; ...
}

while condition {
    ; ...
}

for i in 0..10 {
    ; ...
}
```

## Reglas de Compilación

1. **Todo tipo DEBE declararse explícitamente**
2. **No hay type inference automático**
3. **Memory safety DEBE garantizarse en compilación**
4. **Ownership DEBE transferirse explícitamente**
5. **Punteros DEBEN ser validados antes de usar**

## Optimizaciones para 5KB

1. **IR Compacta**: Representación intermedia optimizada
2. **Zero-Copy**: Transferencias de datos sin copias
3. **Inline Assembly**: Acceso directo a instrucciones
4. **Cache Awareness**: Optimización para cache L1

## Versión

- **1.0A4**: Primera versión alpha (Abril 2026)
