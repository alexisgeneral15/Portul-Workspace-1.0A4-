// AST - Árbol de Sintaxis Abstracta
// Definición de nodos del árbol

#[derive(Debug, Clone)]
pub enum ASTNode {
    Program(Vec<ASTNode>),
    FunctionDef {
        name: String,
        params: Vec<(String, String)>, // (name, type)
        return_type: String,
        body: Box<ASTNode>,
    },
    VariableDef {
        name: String,
        var_type: String,
        value: Option<Box<ASTNode>>,
    },
    BinaryOp {
        op: String,
        left: Box<ASTNode>,
        right: Box<ASTNode>,
    },
    Literal(String),
    Identifier(String),
}
