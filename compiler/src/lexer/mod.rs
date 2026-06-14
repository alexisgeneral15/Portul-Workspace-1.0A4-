// Lexer - Tokenización
// Reglas estrictas de 3-6 caracteres para tokens

pub struct Lexer {
    input: String,
    position: usize,
}

impl Lexer {
    pub fn new(input: String) -> Self {
        Lexer {
            input,
            position: 0,
        }
    }

    pub fn tokenize(&mut self) -> Vec<String> {
        // TODO: Implementar tokenización
        vec![]
    }
}
