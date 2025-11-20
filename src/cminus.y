%{
#include <stdio.h>
#include <stdlib.h>
#include "arvore.h"
#include "symtab.h"

// Declarações externas para funções e variáveis do analisador léxico
extern int yylex(void);
extern FILE *yyin;
extern int yylineno;
extern char* yytext;

// Função para tratamento de erro padrão do bison
void yyerror(const char* s) {
    printf("ERRO SINTÁTICO: %s LINHA: %d\n", yytext, yylineno);
}
%}

/* Isso aqui define os tipos de dados que um símbolo pode carregar 
    - nó,ponteiro para um nó da árvore (Treenode*)
    - lexema, string pura, usada para tokens com id e num
*/
%union {
    TreeNode *no;
    char *lexema;
}

/* Definição de tokens (símbolos terminais) */
%token TOKEN_PLUS TOKEN_MINUS TOKEN_MULT TOKEN_DIV
%token TOKEN_MINOR TOKEN_GREATER TOKEN_MINOR_EQUAL TOKEN_GREATER_EQUAL
%token TOKEN_EQUAL_EQUAL TOKEN_NOT_EQUAL TOKEN_EQUAL
%token TOKEN_SEMICOLON TOKEN_COMMA
%token TOKEN_LEFT_PARENTHESIS TOKEN_RIGHT_PARENTHESIS
%token TOKEN_LEFT_BRACKET TOKEN_RIGHT_BRACKET
%token TOKEN_LEFT_SQUARE_BRACKET TOKEN_RIGHT_SQUARE_BRACKET
%token TOKEN_IF TOKEN_ELSE TOKEN_INT TOKEN_RETURN TOKEN_VOID TOKEN_WHILE

/* Definição de tokens (símbolos terminais) que carregam um lexema*/
%token <lexema> TOKEN_NUM
%token <lexema> TOKEN_ID

/* Definição de precedencia e associatividade de operadores, isso é feito para resolver a ambiguidade e evitar excesso de regras gramáticais
    A ordem define a prioridade dos operadores (de baixo para cima: menor para maior prioridade)
 */
%left TOKEN_PLUS TOKEN_MINUS
%left TOKEN_MULT TOKEN_DIV
%nonassoc TOKEN_MINOR TOKEN_GREATER TOKEN_MINOR_EQUAL TOKEN_GREATER_EQUAL TOKEN_EQUAL_EQUAL TOKEN_NOT_EQUAL

/* Isso aqui é feito para resolver o problema de dangling else, (if sem else vs if com else) */
%nonassoc TOKEN_IF_SEM_ELSE
%precedence TOKEN_ELSE

/* Definição dos tipos dos símbolos não-terminais (mapeiam para union) */
%type <no> program declaration_list declaration var_declaration type_specifier
%type <no> fun_declaration params param_list param compound_stmt
%type <no> local_declarations statement_list statement expression_stmt
%type <no> selection_stmt iteration_stmt return_stmt expression var
%type <no> simple_expression relop additive_expression addop term
%type <no> mulop factor call args arg_list

%%

/* Regra Inicial: program
   Um programa consiste em uma lista de declarações.
   A raiz da árvore (raizArvore) aponta para este nó.
*/
program:
    declaration_list
    {
        $$ = novoNo(NO_PROGRAMA, yylineno);
        
        $$->filho = $1;
        raizArvore = $$;
    }
    ;

/* Lista de declarações (variáveis ou funções).
   Lógica de Lista Encadeada: Percorre os irmãos de $1 até o fim 
   e anexa a nova declaração ($2) lá.
*/
declaration_list:
    declaration_list declaration 
    {
        // Lógica de Lista: anexa 'declaraçao' ($2) como irmão do último item
        // da 'declaration_list' ($1)
        TreeNode *t = $1;
        if (t != NULL){
            while(t->irmao != NULL){
                t = t->irmao;
            }
            t->irmao = $2;
            $$ = $1;
        } else {
            $$ = $2;
        }
    }
    | declaration
    {
        $$ = $1;
    }
    ;

declaration:
    var_declaration { $$ = $1;}
    | fun_declaration { $$ = $1;}
    ;

/* Declaração de Variável: int x; ou int x[10]; */
var_declaration:
    type_specifier TOKEN_ID TOKEN_SEMICOLON 
    {
        $$ = novoNo(NO_DECLARACAO_VAR, yylineno);
        $$->filho = $1;
        $$->filho->irmao = novoNoToken(NO_ID, $2, yylineno);
        free($2);
    }
    | type_specifier TOKEN_ID TOKEN_LEFT_SQUARE_BRACKET TOKEN_NUM TOKEN_RIGHT_SQUARE_BRACKET TOKEN_SEMICOLON
    {
        $$ = novoNo(NO_DECLARACAO_VAR, yylineno);
        $$->filho = $1;
        $$->filho->irmao = novoNoToken(NO_ID, $2, yylineno);
        $$->filho->irmao->irmao = novoNoToken(NO_NUM, $4, yylineno);
        free($2);
        free($4);
    }
    ;

type_specifier:
    TOKEN_INT { $$ = novoNo(NO_TIPO_INT, yylineno); }
    | TOKEN_VOID { $$ = novoNo(NO_TIPO_VOID, yylineno); }
    ;

/* Declaração de Função: int main(...) { ... }
   Estrutura: Nó Função -> (Filho: Tipo) -> (Irmão: ID) -> (Irmão: Params) -> (Irmão: Corpo)
*/
fun_declaration:
    type_specifier TOKEN_ID TOKEN_LEFT_PARENTHESIS params TOKEN_RIGHT_PARENTHESIS compound_stmt
    {
        $$ = novoNo(NO_DECLARACAO_FUN, yylineno);
        $$->filho = $1;
        $$->filho->irmao = novoNoToken(NO_ID, $2, yylineno);
        $$->filho->irmao->irmao = $4;

        // precisamos encontrar o ultimo parametro da lista
        TreeNode *curr = $4;
        while(curr != NULL && curr->irmao != NULL){
            curr = curr->irmao;
        }

        // Se nos tivermos parametros, conecta o corpo ao ultimo deles
        // Se nao houver (curr == NULL), conecta no ID da funçao
        if(curr != NULL){
            curr->irmao = $6;
        } else {
            $$->filho->irmao->irmao = $6;
        }
        free($2);
    }
    ;

params:
    param_list { $$ = $1; }
    | TOKEN_VOID { $$ = novoNo(NO_TIPO_VOID, yylineno); }
    ;

/* Lista de parâmetros separados por vírgula */
param_list:
    param_list TOKEN_COMMA param
    {
        TreeNode *t = $1;
        while(t->irmao != NULL) t = t->irmao;
        t->irmao = $3;
        $$ = $1;
    }
    | param { $$ = $1; }
    ;

param:
    type_specifier TOKEN_ID
    {
        $$ = novoNo(NO_PARAM, yylineno);
        $$->filho = $1;
        $$->filho->irmao = novoNoToken(NO_ID, $2, yylineno);
        free($2);

    }
    | type_specifier TOKEN_ID TOKEN_LEFT_SQUARE_BRACKET TOKEN_RIGHT_SQUARE_BRACKET
    {
        $$ = novoNo(NO_PARAM, yylineno);
        $$->filho = $1;
        $$->filho->irmao = novoNoToken(NO_ID, $2, yylineno);
        free($2);
    }
    ;

/* Bloco de Código: { declarações locais ... comandos ... } */
compound_stmt:
    TOKEN_LEFT_BRACKET local_declarations statement_list TOKEN_RIGHT_BRACKET
    {
        $$ = novoNo(NO_BLOCO, yylineno);
        $$->filho = $2;
        if($2 != NULL){
            TreeNode *t = $2;
            while(t->irmao != NULL){
                t = t->irmao;
            }
            t->irmao = $3;
        } else {
            $$->filho = $3;
        }
    }
    ;

local_declarations:
    local_declarations var_declaration
    {
        TreeNode *t = $1;
        if(t != NULL){
            while (t->irmao != NULL)
            {
                t = t->irmao;
            }
            t->irmao = $2;
            $$ = $1;
        } else {
            $$ = $2;
        }
    }
    | /* empty */ { $$ = NULL; }
    ;

statement_list:
    statement_list statement
    {
        TreeNode *t = $1;
        if (t != NULL) {
            while (t->irmao != NULL) t = t->irmao;
            t->irmao = $2;
            $$ = $1;
        } else {
            $$ = $2;
        }
    }
    | /* empty */ { $$ = NULL; }
    ;

/* Tipos de Statements (Comandos) */
statement:
    expression_stmt { $$ = $1; }
    | compound_stmt   { $$ = $1; }
    | selection_stmt  { $$ = $1; }
    | iteration_stmt  { $$ = $1; }
    | return_stmt     { $$ = $1; }
    ;

expression_stmt:
    expression TOKEN_SEMICOLON { $$ = $1; }
    | TOKEN_SEMICOLON { $$ = NULL; }
    ;

/* IF e IF-ELSE */
selection_stmt:
    TOKEN_IF TOKEN_LEFT_PARENTHESIS expression TOKEN_RIGHT_PARENTHESIS statement %prec TOKEN_IF_SEM_ELSE
    {
        $$ = novoNo(NO_IF, yylineno);
        $$->filho = $3; /* 1. Condição */
        $$->filho->irmao = $5; /* 2. Corpo 'then' */
    }
    | TOKEN_IF TOKEN_LEFT_PARENTHESIS expression TOKEN_RIGHT_PARENTHESIS statement TOKEN_ELSE statement
    {
        $$ = novoNo(NO_IF, yylineno);
        $$->filho = $3; /* 1. Condição */
        $$->filho->irmao = $5; /* 2. Corpo 'then' */
        $$->filho->irmao->irmao = $7; /* 3. Corpo 'else' */
    }
    ;

/* WHILE */
iteration_stmt:
    TOKEN_WHILE TOKEN_LEFT_PARENTHESIS expression TOKEN_RIGHT_PARENTHESIS statement
    {
        $$ = novoNo(NO_WHILE, yylineno);
        $$->filho = $3; /* 1. Condição */
        $$->filho->irmao = $5; /* 2. Corpo */
    }
    ;

return_stmt:
    TOKEN_RETURN TOKEN_SEMICOLON
    {
        $$ = novoNo(NO_RETURN, yylineno);
    }
    | TOKEN_RETURN expression TOKEN_SEMICOLON
    {
        $$ = novoNo(NO_RETURN, yylineno);
        $$->filho = $2; /* 1. Expressão de retorno */
    }
    ;

/* Expressão de Atribuição ou Simples */
expression:
    var TOKEN_EQUAL expression
    {
        $$ = novoNo(NO_ATRIBUICAO, yylineno);
        $$->filho = $1; /* 1. Var (L-value) */
        $$->filho->irmao = $3; /* 2. Expressão (R-value) */
    }
    | simple_expression { $$ = $1; }
    ;

var:
    TOKEN_ID
    {
        $$ = novoNoToken(NO_VAR, $1, yylineno);
        free($1);
    }
    | TOKEN_ID TOKEN_LEFT_SQUARE_BRACKET expression TOKEN_RIGHT_SQUARE_BRACKET
    {
        $$ = novoNo(NO_ARRAY_IDX, yylineno);
        $$->filho = novoNoToken(NO_VAR, $1, yylineno); /* 1. ID do Array */
        $$->filho->irmao = $3; /* 2. Expressão do Índice */
        free($1);
    }
    ;

/* Operações Relacionais (==, !=, <, etc) */
simple_expression:
    additive_expression relop additive_expression
    {
        $$ = $2; /* O nó do operador (relop) é o pai */
        $$->filho = $1; /* 1. Lado esquerdo */
        $$->filho->irmao = $3; /* 2. Lado direito */
    }
    | additive_expression { $$ = $1; }
    ;

relop:
    TOKEN_MINOR_EQUAL   { $$ = novoNoToken(NO_OP_REL, "<=", yylineno); }
    | TOKEN_MINOR       { $$ = novoNoToken(NO_OP_REL, "<", yylineno); }
    | TOKEN_GREATER     { $$ = novoNoToken(NO_OP_REL, ">", yylineno); }
    | TOKEN_GREATER_EQUAL { $$ = novoNoToken(NO_OP_REL, ">=", yylineno); }
    | TOKEN_EQUAL_EQUAL   { $$ = novoNoToken(NO_OP_REL, "==", yylineno); }
    | TOKEN_NOT_EQUAL     { $$ = novoNoToken(NO_OP_REL, "!=", yylineno); }
    ;

/* Expressões Aditivas (+, -) */
additive_expression:
    additive_expression addop term
    {
        $$ = $2; /* O nó do operador (addop) é o pai */
        $$->filho = $1; /* 1. Lado esquerdo */
        $$->filho->irmao = $3; /* 2. Lado direito */
    }
    | term { $$ = $1; }
    ;

addop:
    TOKEN_PLUS  { $$ = novoNoToken(NO_OP_SOMA, "+", yylineno); }
    | TOKEN_MINUS { $$ = novoNoToken(NO_OP_SOMA, "-", yylineno); }
    ;

/* Expressões Multiplicativas (*, /) */
term:
    term mulop factor
    {
        $$ = $2; /* O nó do operador (mulop) é o pai */
        $$->filho = $1; /* 1. Lado esquerdo */
        $$->filho->irmao = $3; /* 2. Lado direito */
    }
    | factor { $$ = $1; }
    ;

mulop:
    TOKEN_MULT { $$ = novoNoToken(NO_OP_MULT, "*", yylineno); }
    | TOKEN_DIV  { $$ = novoNoToken(NO_OP_MULT, "/", yylineno); }
    ;

factor:
    TOKEN_LEFT_PARENTHESIS expression TOKEN_RIGHT_PARENTHESIS { $$ = $2; }
    | var { $$ = $1; }
    | call { $$ = $1; }
    | TOKEN_NUM
    {
        $$ = novoNoToken(NO_NUM, $1, yylineno);
        free($1);
    }
    ;

/* Chamada de Função */
call:
    TOKEN_ID TOKEN_LEFT_PARENTHESIS args TOKEN_RIGHT_PARENTHESIS
    {
        $$ = novoNoToken(NO_CHAMADA, $1, yylineno);
        $$->filho = $3; /* 1. Lista de argumentos */
        free($1);
    }
    ;

args:
    arg_list { $$ = $1; }
    | /* empty */ { $$ = NULL; }
    ;

arg_list:
    arg_list TOKEN_COMMA expression
    {
        /* Lógica de lista (anexar $3 como irmão de $1) */
        TreeNode *t = $1;
        while (t->irmao != NULL) t = t->irmao;
        t->irmao = $3;
        $$ = $1;
    }
    | expression { $$ = $1; }
    ;
%%

int main(int argc, char **argv) {

    printf("=== TESTE DA TABELA DE SIMBOLOS ===\n");
    
    /* Simulando: int gcd(int u, int v) ... */
    st_insert("gcd", 1, "global", "fun", "int");
    st_insert("u", 1, "gcd", "param", "int");
    st_insert("v", 1, "gcd", "param", "int");
    
    /* Simulando o uso de variáveis na main */
    st_insert("x", 6, "main", "var", "int");
    st_insert("y", 6, "main", "var", "int");
    
    /* Simulando uma nova ocorrência de x na linha 7 */
    st_insert("x", 7, "main", "var", "int");

    /* Imprime a tabela formatada */
    printSymTab(stdout);
    printf("===================================\n\n");
    /* --------------------------------------------- */
    
    if (argc < 2) {
        fprintf(stderr, "Uso: %s arquivo_de_entrada\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "r");
    if (!f) {
        perror("Erro ao abrir arquivo");
        return 1;
    }

    yyin = f;
    
    printf("=== Iniciando análise sintática ===\n");
    
    int result = yyparse();
    
    if (result == 0) {
        printf("=== Análise sintática concluída com SUCESSO ===\n");
        printf("\n=== Árvore Sintática Abstrata ===\n");
        imprimeArvore(raizArvore, 0); 
    } else {
        printf("=== Análise sintática concluída com ERROS ===\n");
    }
    
    fclose(f);
    return result;
}