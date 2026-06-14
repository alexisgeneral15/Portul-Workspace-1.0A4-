# AI Copilot - EL ALMA

Integración nativa de IA para Portul.

## Módulos

- **context/**: Gestor de contexto - Indexa el AST para que la IA no sature la RAM
- **prompts/**: Plantillas estrictas basadas en spec 1.0A4 (Zero hallucination)
- **actions/**: Autocompletado, refactorización, explicación de errores
- **local_engine/**: Conexión a modelos locales ligeros (Phi-3, Llama-3 8B)

## Configuración

Edita `model_config.json` para ajustar:

```json
{
  "model": "gpt-4",
  "temperature": 0.2,
  "max_tokens": 2048,
  "local_model": null,
  "enable_local": false
}
```

## Principios

1. **Zero Hallucination**: Los prompts están diseñados para minimizar alucinaciones
2. **Context-Aware**: El contexto se extrae del AST, no de todo el archivo
3. **Memory-Efficient**: Indexación inteligente para no saturar RAM en sistemas de 5KB
4. **Spec-Compliant**: Todas las respuestas deben respetar la especificación 1.0A4

## Desarrollo

```bash
pip install -r requirements.txt
python -m ai_copilot.main
```
