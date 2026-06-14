// CodeGen - Generación de Código
// Bytecode o ensamblador objetivo

pub struct CodeGenerator {
    output: String,
}

impl CodeGenerator {
    pub fn new() -> Self {
        CodeGenerator {
            output: String::new(),
        }
    }

    pub fn generate(&mut self, ir: Vec<String>) -> String {
        // TODO: Generar bytecode o ensamblador
        self.output.clone()
    }
}
