#include "../include/analyze.h"
#include "../include/symtab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Contador para alocação de memória
static int location = 0;

// Escopo atual (0 = global)
static int scope = 0;

// ==== função para percorrer a árvore ====
static void traverse(TreeNode *t,
                     void (*preProc)(TreeNode *),
                     void (*postProc)(TreeNode *))
{
  if (t != NULL)
  {
    preProc(t);
    // visita o primeiro filho o qual vai visitar seus irmãos de forma recursiva
    traverse(t->filho, preProc, postProc);
    postProc(t);
    // Visitar o próximo irmão deste nó
    traverse(t->irmao, preProc, postProc);
  }
}

// === quando chegar em um nó, inserir declarações ou verificar usos ===
static void insertNode(TreeNode *t)
{
  switch (t->tipoNo)
  {
    // a estrutura do nó de função é:
    // filho(tipo) -> irmão (id) -> irmao(params)
  case NO_DECLARACAO_FUN:
  {
    TreeNode *tipoNode = t->filho;
    TreeNode *idNode = tipoNode->irmao;
    char *funcName = idNode->attr.lexema;

    // Precisamos verificar se ele já existe (no escopo global)
    if (st_lookup(funcName) == -1)
    {
      ExpType funcType = (tipoNode->tipoNo == NO_TIPO_INT) ? Integer : Void;
      st_insert(funcName, t->lineno, location++, scope, funcType, ID_FUN);
    }
    else
    {
      fprintf(stderr, "ERRO SEMÂNTICO: Função '%s' já declarada na linha %d.\n", funcName, t->lineno);
    }
    scope++;
  }
  break;
  // Caso seja declaração de variável
  // Estrutura: Filho (Tipo) -> Irmão (ID) [ -> Irmão (TAMANHO se array) ]
  case NO_DECLARACAO_VAR:
  {
    TreeNode *tipoNode = t->filho;
    TreeNode *idNode = tipoNode->irmao;
    char *varName = idNode->attr.lexema;

    // verificamos se já existe no escopo atual
    if (st_lookup_scope(varName, scope) == -1)
    {
      ExpType varType = (tipoNode->tipoNo == NO_TIPO_INT) ? Integer : Void;

      // Precisamos também verificar se tem um irmão q é no_num, indicando que é um vetor
      IdKind kind = ID_VAR;
      if (idNode->irmao != NULL && idNode->irmao->tipoNo == NO_NUM)
      {
        kind = ID_ARRAY;
      }
      st_insert(varName, t->lineno, location++, scope, varType, kind);
    }
    else
    {
      fprintf(stderr, "ERRO SEMÂNTICO: Variável '%s' já declarada na linha %d.\n", varName, t->lineno);
    }
  }
  break;

  // Verifica se é um parâmetro de função
  // Estrutura: Filho (Tipo) -> Irmão (ID)
  case NO_PARAM:
  {
    TreeNode *tipoNode = t->filho;
    // verifica se o paraemtro não é void
    if (tipoNode->tipoNo != NO_TIPO_VOID)
    {
      TreeNode *idNode = tipoNode->irmao;
      char *paramName = idNode->attr.lexema;

      if (st_lookup_scope(paramName, scope) == -1)
      {
        st_insert(paramName, t->lineno, location++, scope, Integer, ID_VAR);
      }
      else
      {
        fprintf(stderr, "ERRO SEMÂNTICO: Parâmetro '%s' redeclarado na linha %d.\n", paramName, t->lineno);
      }
    }
  }
  break;

  // Aqui a gente verifica o uso de variáveis e chamadas, verificamos se a variável foi declarada antes de ser usada
  case NO_VAR:
  case NO_CHAMADA:
  {
    char *name = t->attr.lexema;
    BucketList l = st_lookup_rec(name);

    if (l == NULL)
    {
      fprintf(stderr, "ERRO SEMÂNTICO: '%s' não foi declarado. Linha %d.\n", name, t->lineno);
      t->type = Void;
    }
    else
    {
      t->type = l->type;
    }
  }
  break;
  default:
    break;
  }
}

// Quando saimos de um nó do tipo função, nós precisamos voltar um escopo
static void afterNode(TreeNode *t)
{
  if (t->tipoNo == NO_DECLARACAO_FUN)
  {
    scope--;
  }
}

// função principal para construir a tabela de simbols
void buildSymTab(TreeNode *syntaxTree)
{
  location = 0;
  scope = 0;

  // Insere funções predefinidas
  st_insert("input", 0, location++, 0, Integer, ID_FUN);
  st_insert("output", 0, location++, 0, Void, ID_FUN);

  // Percorrer a árvore para processar o resto
  traverse(syntaxTree, insertNode, afterNode);

  // checar se existe a função main
  if (st_lookup("main") == -1)
  {
    fprintf(stderr, "ERRO SEMÂNTICO: Função 'main' não definida.\n");
  }

  printf("\n");
  printSymTab(stdout);
}

void typeCheck(TreeNode * syntaxTree)
{
  /* Por enquanto não faz nada, será o próximo passo do projeto */
  // traverse(syntaxTree, nullProc, checkNode);
}