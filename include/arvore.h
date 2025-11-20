#ifndef _ARVORE_H_
#define _ARVORE_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum
{
  NO_PROGRAMA,
  NO_DECLARACAO_VAR,
  NO_DECLARACAO_FUN,
  NO_TIPO_INT,
  NO_TIPO_VOID,
  NO_PARAM,
  NO_BLOCO,
  NO_IF,
  NO_WHILE,
  NO_RETURN,
  NO_ATRIBUICAO,
  NO_OP_REL,
  NO_OP_SOMA,
  NO_OP_MULT,
  NO_VAR,
  NO_ARRAY_IDX,
  NO_CHAMADA,
  NO_ID,
  NO_NUM
} NodeType;

typedef enum {
  Void,
  Integer,
  Boolean
} ExpType;

typedef struct TreeNode
{
  struct TreeNode *filho;
  struct TreeNode *irmao;

  NodeType tipoNo;
  int lineno;

  union
  {
    char *lexema;
    int valor;
  } attr;

  ExpType type;
} TreeNode;

// Funções auxiliares

TreeNode *novoNo(NodeType tipo, int lineno);

TreeNode *novoNoToken(NodeType tipo, char *lexema, int lineno);

void imprimeArvore(TreeNode *arvore, int indent);

extern TreeNode *raizArvore;

#endif