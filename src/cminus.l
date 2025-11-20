%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "arvore.h"
#include "cminus.tab.h"

extern int yylineno;
int comment_start_line = 0;
%}

%option noyywrap
%option yylineno
%option nounput
%option noinput
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
    printf("ERRO LÉXICO: Comentario nao fechado LINHA: %d\n", comment_start_line);
    return 0;
}

"("                           { return TOKEN_LEFT_PARENTHESIS; }
")"                           { return TOKEN_RIGHT_PARENTHESIS; }
"{"                           { return TOKEN_LEFT_BRACKET; }
"}"                           { return TOKEN_RIGHT_BRACKET; }
"["                           { return TOKEN_LEFT_SQUARE_BRACKET; }
"]"                           { return TOKEN_RIGHT_SQUARE_BRACKET; }

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

[0-9]+                        { 
    yylval.lexema = strdup(yytext);
    return TOKEN_NUM; 
}

[a-zA-Z]+                     {
    if (strcmp(yytext, "if") == 0) return TOKEN_IF;
    else if (strcmp(yytext, "else") == 0) return TOKEN_ELSE;
    else if (strcmp(yytext, "int") == 0) return TOKEN_INT;
    else if (strcmp(yytext, "return") == 0) return TOKEN_RETURN;
    else if (strcmp(yytext, "void") == 0) return TOKEN_VOID;
    else if (strcmp(yytext, "while") == 0) return TOKEN_WHILE;
    else {
        yylval.lexema = strdup(yytext);
        return TOKEN_ID;
    }
}

[ \t\n]+                      { /* ignora espaços, tabs e novas linhas */ }

.                             {
    printf("ERRO LÉXICO: %s LINHA: %d\n", yytext, yylineno);
    return 0;
}

<<EOF>>                       { return 0; }

%%