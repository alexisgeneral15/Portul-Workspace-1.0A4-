# Directrices de IA para Portul 1.0A4

## Principio Fundamental

**Zero Hallucination**: La IA NUNCA debe inventar sintaxis, tipos o comportamientos que no estén en la especificación 1.0A4.

## Reglas de Comportamiento

### 1. Validación de Código

Antes de sugerir cualquier código Portul:

- ✅ Verificar que la sintaxis esté en `grammar.ebnf`
- ✅ Verificar que los tipos sean válidos (i32, i64, f32, f64, bool, str, ptr<T>, own<T>)
- ✅ Verificar que `own` vs `ptr` sean correctos para el contexto
- ✅ Verificar que las operaciones atómicas (`cas`, `atm`, `lck`) se usen correctamente

### 2. Explicación de Errores

Cuando se encuentre un error:

1. Identificar el tipo de error (syntax, type, ownership, etc.)
2. Citar la regla de la especificación que se violó
3. Proponer una solución basada en la especificación
4. Incluir un ejemplo correcto

### 3. Sugerencias de Optimización

Para sistemas de 5KB:

- Preferir `ptr<T>` sobre `own<T>` cuando sea seguro
- Usar operaciones atómicas para concurrencia sin locks
- Evitar allocaciones innecesarias
- Considerar `cache_hot` para datos críticos

### 4. Contexto de Prompt

Cada prompt debe incluir:

```
[SPEC: 1.0A4]
[CONTEXT: AST del proyecto actual]
[MEMORY: 5KB limit]
[TASK: Tu tarea específica]
```

## Comandos Especiales

El usuario puede usar:

- `err <code>`: Explicar un error
- `opt <code>`: Sugerencias de optimización
- `gen <description>`: Generar código
- `refactor <code>`: Refactorizar código

## No Hacer

❌ Inventar nuevas palabras clave
❌ Cambiar la semántica de operaciones existentes
❌ Ignorar restricciones de memoria
❌ Sugerir características no en la especificación
❌ Alucinaciones de sintaxis

## Hacer

✅ Validar contra la especificación
✅ Citar la especificación
✅ Proponer soluciones spec-compliant
✅ Mantener respeto por el límite de 5KB
✅ Ser claro y didáctico
