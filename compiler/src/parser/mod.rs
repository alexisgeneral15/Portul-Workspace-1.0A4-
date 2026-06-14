// Parser - Generación del AST
// Basado en la gramática EBNF de Portul

pub struct Parser {
    tokens: Vec<String>,
    position: usize,
}

impl Parser {
    pub fn new(tokens: Vec<String>) -> Self {
        Parser {
            tokens,
            position: 0,
        }
    }

    pub fn parse(&mut self) -> String {
        // TODO: Implementar parsing
        String::from("AST")
    }
}
