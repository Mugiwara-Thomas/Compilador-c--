%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex(void);
extern FILE *yyin;
extern int yylineno;
extern char* yytext;

void yyerror(const char* s) {
    fprintf(stderr, "Erro sintático na linha %d: %s\n", yylineno, s);
    fprintf(stderr, "Token: '%s'\n", yytext);
}
%}

// Tokens definidos pelo analisador léxico
%token TOKEN_PLUS
%token TOKEN_MINUS
%token TOKEN_MULT
%token TOKEN_DIV
%token TOKEN_MINOR
%token TOKEN_GREATER
%token TOKEN_MINOR_EQUAL
%token TOKEN_GREATER_EQUAL
%token TOKEN_EQUAL_EQUAL
%token TOKEN_NOT_EQUAL
%token TOKEN_EQUAL
%token TOKEN_SEMICOLON
%token TOKEN_COMMA
%token TOKEN_LEFT_PARENTHESIS
%token TOKEN_RIGHT_PARENTHESIS
%token TOKEN_LEFT_BRACKET
%token TOKEN_RIGHT_BRACKET
%token TOKEN_LEFT_SQUARE_BRACKET
%token TOKEN_RIGHT_SQUARE_BRACKET
%token TOKEN_IF
%token TOKEN_ELSE
%token TOKEN_INT
%token TOKEN_RETURN
%token TOKEN_VOID
%token TOKEN_WHILE
%token TOKEN_NUM
%token TOKEN_ID
%token TOKEN_EOF_TOKEN

// Definição de precedência de operadores
%left TOKEN_PLUS TOKEN_MINUS
%left TOKEN_MULT TOKEN_DIV
%nonassoc TOKEN_MINOR TOKEN_GREATER TOKEN_MINOR_EQUAL TOKEN_GREATER_EQUAL TOKEN_EQUAL_EQUAL TOKEN_NOT_EQUAL
%precedence TOKEN_ELSE

%%

program:
    declaration_list
    ;

declaration_list:
    declaration_list declaration
    | declaration
    ;

declaration:
    var_declaration
    | fun_declaration
    ;

var_declaration:
    type_specifier TOKEN_ID TOKEN_SEMICOLON
    | type_specifier TOKEN_ID TOKEN_LEFT_SQUARE_BRACKET TOKEN_NUM TOKEN_RIGHT_SQUARE_BRACKET TOKEN_SEMICOLON
    ;

type_specifier:
    TOKEN_INT
    | TOKEN_VOID
    ;

fun_declaration:
    type_specifier TOKEN_ID TOKEN_LEFT_PARENTHESIS params TOKEN_RIGHT_PARENTHESIS compound_stmt
    ;

params:
    param_list
    | TOKEN_VOID
    ;

param_list:
    param_list TOKEN_COMMA param
    | param
    ;

param:
    type_specifier TOKEN_ID
    | type_specifier TOKEN_ID TOKEN_LEFT_SQUARE_BRACKET TOKEN_RIGHT_SQUARE_BRACKET
    ;

compound_stmt:
    TOKEN_LEFT_BRACKET local_declarations statement_list TOKEN_RIGHT_BRACKET
    ;

local_declarations:
    local_declarations var_declaration
    | /* empty */
    ;

statement_list:
    statement_list statement
    | /* empty */
    ;

statement:
    expression_stmt
    | compound_stmt
    | selection_stmt
    | iteration_stmt
    | return_stmt
    ;

expression_stmt:
    expression TOKEN_SEMICOLON
    | TOKEN_SEMICOLON
    ;

selection_stmt:
    TOKEN_IF TOKEN_LEFT_PARENTHESIS expression TOKEN_RIGHT_PARENTHESIS statement
    | TOKEN_IF TOKEN_LEFT_PARENTHESIS expression TOKEN_RIGHT_PARENTHESIS statement TOKEN_ELSE statement
    ;

iteration_stmt:
    TOKEN_WHILE TOKEN_LEFT_PARENTHESIS expression TOKEN_RIGHT_PARENTHESIS statement
    ;

return_stmt:
    TOKEN_RETURN TOKEN_SEMICOLON
    | TOKEN_RETURN expression TOKEN_SEMICOLON
    ;

expression:
    var TOKEN_EQUAL expression
    | simple_expression
    ;

var:
    TOKEN_ID
    | TOKEN_ID TOKEN_LEFT_SQUARE_BRACKET expression TOKEN_RIGHT_SQUARE_BRACKET
    ;

simple_expression:
    additive_expression relop additive_expression
    | additive_expression
    ;

relop:
    TOKEN_MINOR_EQUAL
    | TOKEN_MINOR
    | TOKEN_GREATER
    | TOKEN_GREATER_EQUAL
    | TOKEN_EQUAL_EQUAL
    | TOKEN_NOT_EQUAL
    ;

additive_expression:
    additive_expression addop term
    | term
    ;

addop:
    TOKEN_PLUS
    | TOKEN_MINUS
    ;

term:
    term mulop factor
    | factor
    ;

mulop:
    TOKEN_MULT
    | TOKEN_DIV
    ;

factor:
    TOKEN_LEFT_PARENTHESIS expression TOKEN_RIGHT_PARENTHESIS
    | var
    | call
    | TOKEN_NUM
    ;

call:
    TOKEN_ID TOKEN_LEFT_PARENTHESIS args TOKEN_RIGHT_PARENTHESIS
    ;

args:
    arg_list
    | /* empty */
    ;

arg_list:
    arg_list TOKEN_COMMA expression
    | expression
    ;

%%

int main(int argc, char **argv) {
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
    } else {
        printf("=== Análise sintática concluída com ERROS ===\n");
    }
    
    fclose(f);
    return result;
}