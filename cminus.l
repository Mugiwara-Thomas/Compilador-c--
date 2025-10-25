%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "cminus.tab.h"

extern int yylineno;

// Variáveis para rastrear estruturas abertas
int open_braces = 0;
int open_parens = 0;
int open_brackets = 0;

int comment_start_line = 0;

void check_unclosed_structures() {
    if (open_braces > 0) {
        fprintf(stderr, "Erro: %d chave(s) '}' não fechada(s)\n", open_braces);
    }
    if (open_parens > 0) {
        fprintf(stderr, "Erro: %d parêntese(s) ')' não fechado(s)\n", open_parens);
    }
    if (open_brackets > 0) {
        fprintf(stderr, "Erro: %d colchete(s) ']' não fechado(s)\n", open_brackets);
    }
}
%}

%option noyywrap
%option yylineno
%x COMMENT

%%

"/*"                          { 
    comment_start_line = yylineno;
    BEGIN(COMMENT); 
}

<COMMENT>"*/"                 { BEGIN(INITIAL); }
<COMMENT>\n                   { }
<COMMENT>.                    { }

<COMMENT><<EOF>>              { 
    fprintf(stderr, "Erro: comentário não fechado (iniciado na linha %d)\n", comment_start_line); 
    check_unclosed_structures();
    return 0;
}

"//".*                        { /* ignora comentário de linha */ }

"("                           { open_parens++; return TOKEN_LEFT_PARENTHESIS; }
")"                           { 
    if (open_parens > 0) open_parens--; 
    else fprintf(stderr, "Erro: parêntese fechado ')' sem abertura na linha %d\n", yylineno);
    return TOKEN_RIGHT_PARENTHESIS; 
}

"{"                           { open_braces++; return TOKEN_LEFT_BRACKET; }
"}"                           { 
    if (open_braces > 0) open_braces--; 
    else fprintf(stderr, "Erro: chave fechada '}' sem abertura na linha %d\n", yylineno);
    return TOKEN_RIGHT_BRACKET; 
}

"["                           { open_brackets++; return TOKEN_LEFT_SQUARE_BRACKET; }
"]"                           { 
    if (open_brackets > 0) open_brackets--; 
    else fprintf(stderr, "Erro: colchete fechado ']' sem abertura na linha %d\n", yylineno);
    return TOKEN_RIGHT_SQUARE_BRACKET; 
}

"+"                           { return TOKEN_PLUS; }
"-"                           { return TOKEN_MINUS; }
"*"                           { return TOKEN_MULT; }
"/"                           { return TOKEN_DIV; }
"<="                          { return TOKEN_MINOR_EQUAL; }
">="                          { return TOKEN_GREATER_EQUAL; }
"=="                          { return TOKEN_EQUAL_EQUAL; }
"!="                          { return TOKEN_NOT_EQUAL; }
"<"                           { return TOKEN_MINOR; }
">"                           { return TOKEN_GREATER; }
"="                           { return TOKEN_EQUAL; }
";"                           { return TOKEN_SEMICOLON; }
","                           { return TOKEN_COMMA; }

[0-9]+                        { return TOKEN_NUM; }

[a-zA-Z][a-zA-Z0-9_]*         {
    if (strcmp(yytext, "if") == 0) return TOKEN_IF;
    else if (strcmp(yytext, "else") == 0) return TOKEN_ELSE;
    else if (strcmp(yytext, "int") == 0) return TOKEN_INT;
    else if (strcmp(yytext, "return") == 0) return TOKEN_RETURN;
    else if (strcmp(yytext, "void") == 0) return TOKEN_VOID;
    else if (strcmp(yytext, "while") == 0) return TOKEN_WHILE;
    else return TOKEN_ID;
}

[ \t\n]+                      { /* ignora espaços, tabs e novas linhas */ }

.                             {
    fprintf(stderr, "Erro léxico na linha %d: caractere inválido '%s'\n", yylineno, yytext);
    return 0;
}

<<EOF>>                       { 
    check_unclosed_structures();
    return TOKEN_EOF_TOKEN; 
}

%%