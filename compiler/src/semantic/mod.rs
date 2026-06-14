// Semantic Analysis - Chequeo de Tipos y Ownership
// LAS LEYES DEL LENGUAJE
// - own vs ptr
// - Type checking
// - Scope management

pub struct SemanticChecker {
    scopes: Vec<std::collections::HashMap<String, String>>,
}

impl SemanticChecker {
    pub fn new() -> Self {
        SemanticChecker {
            scopes: vec![std::collections::HashMap::new()],
        }
    }

    pub fn check(&mut self, ast: &str) -> Result<(), String> {
        // TODO: Implementar type checking y validación de ownership
        Ok(())
    }

    pub fn validate_ownership(&self, var_type: &str) -> bool {
        var_type.starts_with("own<") || var_type.starts_with("ptr<")
    }
}
