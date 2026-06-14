# 🚀 Portul Workspace 1.0A4

**Portul** es un lenguaje de programación innovador diseñado específicamente para sistemas embebidos con restricciones extremas de memoria (5KB). Combina la seguridad de tipos, gestión inteligente de memoria y un IDE nativo con capacidades de IA.

## 📋 Visión General

```
portul-workspace/
│
├── 📂 compiler/           # EL CEREBRO (Toolchain del lenguaje)
├── 📂 ide-core/           # EL CUERPO (La aplicación Visual Studio-like)
├── 📂 ai-copilot/         # EL ALMA (Integración nativa de IA)
├── 📂 stdlib/             # LA BIBLIOTECA ESTÁNDAR (Escrita en puro Portul)
├── 📂 docs/               # LA VERDAD ÚNICA (Documentación)
└── 📂 examples/           # CASOS DE USO
```

## 🧠 Arquitectura

### 1. **Compiler** (`compiler/`)
El toolchain completo del lenguaje Portul:
- **Lexer**: Tokenización con reglas estrictas (3-6 caracteres)
- **Parser**: Generación del AST basado en EBNF
- **Semantic**: Chequeo de tipos, `own` vs `ptr`, scopes
- **IR**: Representación intermedia optimizada para 5KB
- **Codegen**: Generación de bytecode o ensamblador objetivo

### 2. **IDE Core** (`ide-core/`)
Aplicación visual estilo Visual Studio:
- **Editor**: Motor de texto, syntax highlighting, renderizado
- **UI**: Paneles, explorador de archivos, terminal integrada
- **LSP**: Language Server Protocol - puente editor ↔ compilador
- **Workspace**: Gestión de proyectos y configuración `.portulrc`

### 3. **AI Copilot** (`ai-copilot/`)
Motor de IA integrado:
- **Context**: Indexación de AST sin saturar RAM
- **Prompts**: Plantillas basadas en spec 1.0A4 (Zero hallucination)
- **Actions**: Autocompletado, refactorización, explicación de errores
- **Local Engine**: Soporte para modelos locales (Phi-3, Llama-3 8B)

### 4. **Standard Library** (`stdlib/`)
Implementación en puro Portul:
- `core.portul`: Tipos básicos, `put`, `get`, `len`
- `math.portul`: Operaciones avanzadas
- `concurrency.portul`: `cas`, `atm`, `lck`, `pool workers`
- `system.portul`: `pin core`, `heap alloc`, `cache hot`

### 5. **Documentation** (`docs/`)
Especificación y referencias:
- `spec_1.0A4.md`: Especificación oficial
- `grammar.ebnf`: Gramática formal
- `ai_guidelines.md`: Reglas de comportamiento de IA

## 🚀 Características Clave

✅ **Gestión de Memoria Inteligente**
- `own`: Ownership explícito
- `ptr`: Punteros seguros
- Bloque `fin`: Limpieza automática

✅ **Operaciones Atómicas**
- `cas` (Compare-And-Swap)
- `atm` (Atomic operations)
- `lck` (Locks)

✅ **Optimizado para 5KB**
- IR compacta
- Zero-copy donde sea posible
- Cache-aware code generation

✅ **IDE Nativo**
- Syntax highlighting específico de Portul
- Integración con LSP
- Copilot de IA integrado

## 📦 Estructura de Carpetas

```
├── compiler/
│   ├── src/
│   │   ├── lexer/
│   │   ├── parser/
│   │   ├── ast/
│   │   ├── semantic/
│   │   ├── ir/
│   │   └── codegen/
│   └── tests/
│
├── ide-core/
│   ├── src/
│   │   ├── editor/
│   │   ├── ui/
│   │   ├── lsp/
│   │   └── workspace/
│   └── assets/
│
├── ai-copilot/
│   ├── src/
│   │   ├── context/
│   │   ├── prompts/
│   │   ├── actions/
│   │   └── local_engine/
│   └── model_config.json
│
├── stdlib/
│   ├── core.portul
│   ├── math.portul
│   ├── concurrency.portul
│   └── system.portul
│
├── docs/
│   ├── spec_1.0A4.md
│   ├── grammar.ebnf
│   └── ai_guidelines.md
│
└── examples/
    ├── lock_free_demo.portul
    └── memory_safety.portul
```

## 🛠️ Desarrollo

### Requisitos
- Rust o C/C++ (para el compilador)
- Node.js (para el IDE)
- Python 3.9+ (para el Copilot)

### Compilar
```bash
# Compilador
cd compiler && cargo build --release

# IDE
cd ide-core && npm install && npm start

# Copilot
cd ai-copilot && pip install -r requirements.txt
```

## 📚 Especificación

La especificación completa está en [`docs/spec_1.0A4.md`](docs/spec_1.0A4.md).

## 📝 Ejemplos

Consulta [`examples/`](examples/) para casos de uso completos.

## 📄 Licencia

MIT License

---

**Hecho con ❤️ para sistemas embebidos extremadamente restringidos.**
