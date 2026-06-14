# Compiler - EL CEREBRO

Toolchain completo del lenguaje Portul.

## Módulos

- **lexer/**: Tokenización con reglas estrictas de 3-6 caracteres
- **parser/**: Generación del AST basado en EBNF
- **ast/**: Definición de nodos del Árbol de Sintaxis Abstracta
- **semantic/**: Chequeo de tipos, `own` vs `ptr`, scopes (LAS LEYES DEL LENGUAJE)
- **ir/**: Representación Intermedia optimizada para hardware de 5KB
- **codegen/**: Generación de bytecode o ensamblador objetivo

## Estructura

```
compiler/
├── src/
│   ├── lexer/
│   │   └── mod.rs
│   ├── parser/
│   │   └── mod.rs
│   ├── ast/
│   │   └── mod.rs
│   ├── semantic/
│   │   └── mod.rs
│   ├── ir/
│   │   └── mod.rs
│   ├── codegen/
│   │   └── mod.rs
│   └── main.rs
├── tests/
│   └── integration_tests.rs
└── Cargo.toml
```

## Tests

Todos los cambios en el compilador DEBEN pasar los tests unitarios e integración.

```bash
cargo test
```
