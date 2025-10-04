%{
  #include <stdio.h>
  #include <string.h>

  int comment_start_line; 
  void printToken(const char* token, const char* lexema){
    printf("%s(%s)\n", token, lexema);
  }
%}

%option noyywrap
%option yylineno

%x COMMENT

%% 
"/*" {printToken("TOKEN_COMMENT_START", yytext);}
"//".* {printToken("TOKEN_LINE_COMMENT", yytext);}
"*/" {printToken("TOKEN_COMMENT_END", yytext);}
"&" { /* Verifica símbolos especiais */}
"+" {printToken("TOKEN_PLUS", yytext);}
"-" {printToken("TOKEN_MINUS", yytext);}
"*" {printToken("TOKEN_MULT", yytext);}
"/" {printToken("TOKEN_DIV", yytext);}
"<" {printToken("TOKEN_MINOR", yytext);}
">" {printToken("TOKEN_GREATER", yytext);}
"<=" {printToken("TOKEN_MINOR_EQUAL", yytext);}
">=" {printToken("TOKEN_GREATER_EQUAL", yytext);}
"==" {printToken("TOKEN_EQUAL_EQUAL", yytext);}
"!=" {printToken("TOKEN_NOT_EQUAL", yytext);}
"=" {printToken("TOKEN_EQUAL", yytext);}
";" {printToken("TOKEN_SEMICOLON", yytext);}
"," {printToken("TOKEN_COMMA", yytext);}
"(" {printToken("TOKEN_LEFT_PARENTHESIS", yytext);}
")" {printToken("TOKEN_RIGHT_PARENTHESIS", yytext);}
"{" {printToken("TOKEN_LEFT_BRACKET", yytext);}
"}" {printToken("TOKEN_RIGHT_BRACKET", yytext);}
"[" {printToken("TOKEN_LEFT_SQUARE_BRACKET", yytext);}
"]" {printToken("TOKEN_RIGHT_SQUARE_BRACKET", yytext);}

[0-9]+ {printToken("NUM", yytext);}


[a-zA-Z_][a-zA-Z0-9_]* {
      if (strcmp(yytext, "if") == 0) printToken("TOKEN_IF", yytext);
    else if (strcmp(yytext, "else") == 0) printToken("TOKEN_ELSE", yytext);
    else if (strcmp(yytext, "int") == 0) printToken("TOKEN_INT", yytext);
    else if (strcmp(yytext, "return") == 0) printToken("TOKEN_RETURN", yytext);
    else if (strcmp(yytext, "void") == 0) printToken("TOKEN_VOID", yytext);
    else if (strcmp(yytext, "while") == 0) printToken("TOKEN_WHILE", yytext);
    else printToken("ID", yytext);
}

[ \t]+ { }
\r\n { }
\n { }
\r { }
. { 
    fprintf(stderr, "Erro léxico: caractere inválido '%s' na linha %d\n", yytext, yylineno);
    exit(1);
}
%%

int main(int argc, char **argv){
  if(argc < 2){
    fprintf(stderr, "Uso: %s arquivo_de_entrada\n", argv[0]);
    return 1;
  }
  FILE *f = fopen(argv[1], "r");
  if(!f){
    perror("Erro ao abrir arquivo");
    return 1;
  }

  yyin = f;
  yylex();
  fclose(f);
  return 0;
}
