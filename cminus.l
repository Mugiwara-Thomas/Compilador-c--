%{
  #include <stdio.h>
  #include <string.h>

  void printToken(const char* token, const char* lexema){
    printf("%s(%s)\n", token, lexema)
  }
%}

%option noyywrap

%% 
/* Palavras reservadas */
"if" {printToken("TOKEN_IF", yytext);}

/* Identificadores e números */
[0-9]+ {printToken("NUM", yytext);}
[a-zA-Z_][a-zA-Z0-9_]* { printToken("ID", yytext);}

[ \t\n]+ { }
"/*"([^*]|\*+[^*/])*\*+"/" { }

. { printToken("UNKNOWN", yytext);}
%%

int main(int argc, char **argv){
  if(argc < 2){
    fprint(stderr, "Uso: %s arquivo_de_entrada\n", argv[0]);
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