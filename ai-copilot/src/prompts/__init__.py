# Prompts - Plantillas estrictas basadas en spec 1.0A4
# Zero hallucination

class PromptTemplates:
    SYSTEM_PROMPT = """Eres un asistente de IA especializado en Portul 1.0A4.
NUNCA inventes sintaxis o características no mencionadas en la especificación.
Siempre valida contra: spec_1.0A4.md, grammar.ebnf, ai_guidelines.md"""

    @staticmethod
    def error_explanation(code, error):
        return f"""[SPEC: 1.0A4]
[ERROR]: {error}
[CODE]: {code}

Explica el error citando la especificación. Proporciona una solución spec-compliant."""

    @staticmethod
    def code_generation(description):
        return f"""[SPEC: 1.0A4]
[MEMORY: 5KB limit]
[TASK]: {description}

Genera código Portul válido. Valida sintaxis contra grammar.ebnf."""

    @staticmethod
    def optimization(code):
        return f"""[SPEC: 1.0A4]
[MEMORY: 5KB limit]
[CODE]: {code}

Suggestions para optimizar el código para 5KB. Prefiere ptr<T> sobre own<T>."""
