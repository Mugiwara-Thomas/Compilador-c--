%{
  #include <stdio.h>
  #include <string.h>
  #include <stdlib.h>

  // Definição dos tokens
  typedef enum {
    TOKEN_PLUS,
    TOKEN_MINUS,
    TOKEN_MULT,
    TOKEN_DIV,
    TOKEN_MINOR,
    TOKEN_GREATER,
    TOKEN_MINOR_EQUAL,
    TOKEN_GREATER_EQUAL,
    TOKEN_EQUAL_EQUAL,
    TOKEN_NOT_EQUAL,
    TOKEN_EQUAL,
    TOKEN_SEMICOLON,
    TOKEN_COMMA,
    TOKEN_LEFT_PARENTHESIS,
    TOKEN_RIGHT_PARENTHESIS,
    TOKEN_LEFT_BRACKET,
    TOKEN_RIGHT_BRACKET,
    TOKEN_LEFT_SQUARE_BRACKET,
    TOKEN_RIGHT_SQUARE_BRACKET,
    TOKEN_IF,
    TOKEN_ELSE,
    TOKEN_INT,
    TOKEN_RETURN,
    TOKEN_VOID,
    TOKEN_WHILE,
    TOKEN_NUM,
    TOKEN_ID,
    TOKEN_COMMENT_START,
    TOKEN_COMMENT_END,
    TOKEN_EOF_TOKEN,
    TOKEN_ERROR
  } TokenType;

  // Estrutura para representar um token
  typedef struct {
    TokenType type;
    char lexema[256];
    int linha;
  } Token;

  Token current_token;

  // Função para criar um token
  Token createToken(TokenType type, const char* lexema, int linha) {
    Token t;
    t.type = type;
    t.linha = linha;
    if (lexema) {
      strncpy(t.lexema, lexema, 255);
    } else {
      t.lexema[0] = '\0';
    }
    t.lexema[255] = '\0';
    return t;
  }

  // Função para retornar o nome do token
  const char* tokenTypeName(TokenType type) {
    switch(type) {
      case TOKEN_PLUS: return "TOKEN_PLUS";
      case TOKEN_MINUS: return "TOKEN_MINUS";
      case TOKEN_MULT: return "TOKEN_MULT";
      case TOKEN_DIV: return "TOKEN_DIV";
      case TOKEN_MINOR: return "TOKEN_MINOR";
      case TOKEN_GREATER: return "TOKEN_GREATER";
      case TOKEN_MINOR_EQUAL: return "TOKEN_MINOR_EQUAL";
      case TOKEN_GREATER_EQUAL: return "TOKEN_GREATER_EQUAL";
      case TOKEN_EQUAL_EQUAL: return "TOKEN_EQUAL_EQUAL";
      case TOKEN_NOT_EQUAL: return "TOKEN_NOT_EQUAL";
      case TOKEN_EQUAL: return "TOKEN_EQUAL";
      case TOKEN_SEMICOLON: return "TOKEN_SEMICOLON";
      case TOKEN_COMMA: return "TOKEN_COMMA";
      case TOKEN_LEFT_PARENTHESIS: return "TOKEN_LEFT_PARENTHESIS";
      case TOKEN_RIGHT_PARENTHESIS: return "TOKEN_RIGHT_PARENTHESIS";
      case TOKEN_LEFT_BRACKET: return "TOKEN_LEFT_BRACKET";
      case TOKEN_RIGHT_BRACKET: return "TOKEN_RIGHT_BRACKET";
      case TOKEN_LEFT_SQUARE_BRACKET: return "TOKEN_LEFT_SQUARE_BRACKET";
      case TOKEN_RIGHT_SQUARE_BRACKET: return "TOKEN_RIGHT_SQUARE_BRACKET";
      case TOKEN_IF: return "TOKEN_IF";
      case TOKEN_ELSE: return "TOKEN_ELSE";
      case TOKEN_INT: return "TOKEN_INT";
      case TOKEN_RETURN: return "TOKEN_RETURN";
      case TOKEN_VOID: return "TOKEN_VOID";
      case TOKEN_WHILE: return "TOKEN_WHILE";
      case TOKEN_NUM: return "TOKEN_NUM";
      case TOKEN_ID: return "TOKEN_ID";
      case TOKEN_COMMENT_START: return "TOKEN_COMMENT_START";
      case TOKEN_COMMENT_END: return "TOKEN_COMMENT_END";
      case TOKEN_EOF_TOKEN: return "TOKEN_EOF";
      case TOKEN_ERROR: return "TOKEN_ERROR";
      default: return "UNKNOWN";
    }
  }

  // Função para printar um token
  void printToken(Token t) {
    printf("%s(%s) - linha %d\n", tokenTypeName(t.type), t.lexema, t.linha);
  }
%}

%option noyywrap
%option yylineno
%x COMMENT

%%

"/*"                          { current_token = createToken(TOKEN_COMMENT_START, yytext, yylineno); BEGIN(COMMENT); return 1; }
"//".*                        { /* ignora comentário de linha */ }
<COMMENT>"*/"                 { BEGIN(INITIAL); current_token = createToken(TOKEN_COMMENT_END, yytext, yylineno); return 1; }
<COMMENT>\n                   { }
<COMMENT>.                    { }
<COMMENT><<EOF>>              { BEGIN(INITIAL); /* comentário não fechado - deixa o parser detectar */ }

"+"                           { current_token = createToken(TOKEN_PLUS, yytext, yylineno); return 1; }
"-"                           { current_token = createToken(TOKEN_MINUS, yytext, yylineno); return 1; }
"*"                           { current_token = createToken(TOKEN_MULT, yytext, yylineno); return 1; }
"/"                           { current_token = createToken(TOKEN_DIV, yytext, yylineno); return 1; }
"<="                          { current_token = createToken(TOKEN_MINOR_EQUAL, yytext, yylineno); return 1; }
">="                          { current_token = createToken(TOKEN_GREATER_EQUAL, yytext, yylineno); return 1; }
"=="                          { current_token = createToken(TOKEN_EQUAL_EQUAL, yytext, yylineno); return 1; }
"!="                          { current_token = createToken(TOKEN_NOT_EQUAL, yytext, yylineno); return 1; }
"<"                           { current_token = createToken(TOKEN_MINOR, yytext, yylineno); return 1; }
">"                           { current_token = createToken(TOKEN_GREATER, yytext, yylineno); return 1; }
"="                           { current_token = createToken(TOKEN_EQUAL, yytext, yylineno); return 1; }
";"                           { current_token = createToken(TOKEN_SEMICOLON, yytext, yylineno); return 1; }
","                           { current_token = createToken(TOKEN_COMMA, yytext, yylineno); return 1; }
"("                           { current_token = createToken(TOKEN_LEFT_PARENTHESIS, yytext, yylineno); return 1; }
")"                           { current_token = createToken(TOKEN_RIGHT_PARENTHESIS, yytext, yylineno); return 1; }
"{"                           { current_token = createToken(TOKEN_LEFT_BRACKET, yytext, yylineno); return 1; }
"}"                           { current_token = createToken(TOKEN_RIGHT_BRACKET, yytext, yylineno); return 1; }
"["                           { current_token = createToken(TOKEN_LEFT_SQUARE_BRACKET, yytext, yylineno); return 1; }
"]"                           { current_token = createToken(TOKEN_RIGHT_SQUARE_BRACKET, yytext, yylineno); return 1; }

[0-9]+                        { current_token = createToken(TOKEN_NUM, yytext, yylineno); return 1; }

[a-zA-Z_][a-zA-Z0-9_]*        {
  if (strcmp(yytext, "if") == 0) current_token = createToken(TOKEN_IF, yytext, yylineno);
  else if (strcmp(yytext, "else") == 0) current_token = createToken(TOKEN_ELSE, yytext, yylineno);
  else if (strcmp(yytext, "int") == 0) current_token = createToken(TOKEN_INT, yytext, yylineno);
  else if (strcmp(yytext, "return") == 0) current_token = createToken(TOKEN_RETURN, yytext, yylineno);
  else if (strcmp(yytext, "void") == 0) current_token = createToken(TOKEN_VOID, yytext, yylineno);
  else if (strcmp(yytext, "while") == 0) current_token = createToken(TOKEN_WHILE, yytext, yylineno);
  else current_token = createToken(TOKEN_ID, yytext, yylineno);
  return 1;
}

[ \t]+                        { /* ignora espaços */ }
\n                            { /* ignora quebras de linha */ }

.                             {
  fprintf(stderr, "Erro léxico: caractere inválido '%s' na linha %d\n", yytext, yylineno);
  exit(1);
}

<<EOF>>                       { return 0; }

%%

Token getNextToken() {
  if (yylex() == 0) {
    return createToken(TOKEN_EOF_TOKEN, "", yylineno);
  }
  return current_token;
}

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

  Token t;
  printf("=== Tokens Identificados ===\n");
  while (1) {
    t = getNextToken();
    if (t.type == TOKEN_EOF_TOKEN) break;
    printToken(t);
  }

  printf("\n=== Fim da análise léxica ===\n");
  fclose(f);
  return 0;
}
