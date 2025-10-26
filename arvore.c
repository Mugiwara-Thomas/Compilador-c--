#include "arvore.h"

TreeNode *raizArvore = NULL;

TreeNode *novoNo(NodeType tipo, int lineno)
{
  TreeNode *no = (TreeNode *)malloc(sizeof(TreeNode));
  if (no == NULL)
  {
    fprintf(stderr, "Erro: Falha na alocação de memória para o nó da árvore.\n");
    exit(1);
  }

  no->filho = NULL;
  no->irmao = NULL;
  no->tipoNo = tipo;
  no->lineno = lineno;

  return no;
}

TreeNode *novoNoToken(NodeType tipo, char *lexema, int lineno)
{
  TreeNode *no = novoNo(tipo, lineno);
  if (lexema != NULL)
  {
    no->attr.lexema = strdup(lexema);
  }
  else
  {
    no->attr.lexema = NULL;
  }
  return no;
}

static void imprimeIndent(int indent)
{
  for (int i = 0; i < indent; i++)
  {
    printf(" ");
  }
}

void imprimeArvore(TreeNode *arvore, int indent)
{
  if (arvore == NULL)
    return;

  imprimeIndent(indent);

  switch (arvore->tipoNo)
  {
  case NO_PROGRAMA:
    printf("[Programa]\n");
    break;
  case NO_DECLARACAO_VAR:
    printf("[Declaracao Var]\n");
    break;
  case NO_DECLARACAO_FUN:
    printf("[Declaracao Funcao: %s]\n", arvore->filho->irmao->attr.lexema);
    break;
  case NO_TIPO_INT:
    printf("[Tipo int]\n");
    break;
  case NO_TIPO_VOID:
    printf("[Tipo void]\n");
    break;
  case NO_PARAM:
    printf("[Parametro: %s]\n", arvore->filho->irmao->attr.lexema);
    break;
  case NO_BLOCO:
    printf("[Bloco]\n");
    break;
  case NO_IF:
    printf("[If]\n");
    break;
  case NO_WHILE:
    printf("[While]\n");
    break;
  case NO_RETURN:
    printf("[Return]\n");
    break;
  case NO_ATRIBUICAO:
    printf("[Atribuicao =]\n");
    break;
  case NO_OP_REL:
    printf("[Op Relacional: %s]\n", arvore->attr.lexema);
    break;
  case NO_OP_SOMA:
    printf("[Op Soma: %s]\n", arvore->attr.lexema);
    break;
  case NO_OP_MULT:
    printf("[Op Mult: %s]\n", arvore->attr.lexema);
    break;
  case NO_VAR:
    printf("[Var: %s]\n", arvore->attr.lexema);
    break;
  case NO_ARRAY_IDX:
    printf("[Array Index]\n");
    break;
  case NO_CHAMADA:
    printf("[Chamada Funcao: %s]\n", arvore->attr.lexema);
    break;
  case NO_ID:
    printf("[ID: %s]\n", arvore->attr.lexema);
    break;
  case NO_NUM:
    printf("[Num: %s]\n", arvore->attr.lexema);
    break;
  default:
    printf("[No Desconhecido]\n");
  }

  TreeNode *filho = arvore->filho;
  while (filho != NULL)
  {
    imprimeArvore(filho, indent + 1);
    filho = filho->irmao;
  }
}