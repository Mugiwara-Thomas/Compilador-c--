#include "../include/analyze.h"
#include "../include/symtab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Contador para alocação de memória
static int location = 0;

// Escopo atual (0 = global)
static int scope = 0;

#define MAX_SCOPE_STACK 512
static int scopeStack[MAX_SCOPE_STACK];
static int scopeTop = -1;
static int nextScopeId = 0;
static int globalScopeId = -1;

static int activeScopeStack[MAX_SCOPE_STACK];
static int activeTop = -1;

static TreeNode *parentStack[MAX_SCOPE_STACK];
static int parentTop = -1;

#define FUNC_STACK_MAX 64
static ExpType funcTypeStack[FUNC_STACK_MAX];
static int funcStackTop = -1;

static TreeNode *currentParentNode(void) {
  if (parentTop >= 0) return parentStack[parentTop];
  return NULL;
}

static int pushScope(void) {
  if (scopeTop < MAX_SCOPE_STACK - 1) {
    int id = nextScopeId++;
    scopeStack[++scopeTop] = id;
    return id;
  }
  return -1;
}
static int popScope(void) {
  if (scopeTop >= 0) {
    int id = scopeStack[scopeTop--];
    return id;
  }
  return -1;
}
static int currentScope(void) {
  if (scopeTop >= 0) return scopeStack[scopeTop];
  return 0; 
}

static int pushNewScope(void) {
  if (scopeTop < MAX_SCOPE_STACK-1) {
    int id = nextScopeId++;
    scopeStack[++scopeTop] = id;
    return id;
  }
  return -1;
}
static int popGeneratedScope(void) {
  if (scopeTop >= 0) {
    return scopeStack[scopeTop--];
  }
  return -1;
}
static int currentGeneratedScope(void) {
  if (scopeTop >= 0) return scopeStack[scopeTop];
  return -1;
}

static void pushActiveScope(int id) {
  if (activeTop < MAX_SCOPE_STACK-1) activeScopeStack[++activeTop] = id;
}
static int popActiveScope(void) {
  if (activeTop >= 0) return activeScopeStack[activeTop--];
  return -1;
}
static int getActiveTop(void) {
  if (activeTop >= 0) return activeScopeStack[activeTop];
  return -1;
}

static void pushFuncType(ExpType t) {
  if (funcStackTop < FUNC_STACK_MAX-1) funcTypeStack[++funcStackTop] = t;
}
static void popFuncType(void) {
  if (funcStackTop >= 0) --funcStackTop;
}
static ExpType currentFuncType(void) {
  if (funcStackTop >= 0) return funcTypeStack[funcStackTop];
  return Void; /* default quando fora de função */
}

static BucketList st_lookup_visible(char * name) {
  for (int i = activeTop; i >= 0; --i) {
    int sc = activeScopeStack[i];
    BucketList b = st_lookup_scope_rec(name, sc);
    if (b != NULL) return b;
  }
  return NULL;
}

// ==== função para percorrer a árvore ====
static void traverse(TreeNode *t,
                     void (*preProc)(TreeNode *),
                     void (*postProc)(TreeNode *))
{
  if (t != NULL)
  {
    if (preProc) preProc(t);

    /* antes de descer aos filhos, empilhamos este nó como pai */
    if (parentTop < MAX_SCOPE_STACK - 1) parentStack[++parentTop] = t;

    traverse(t->filho, preProc, postProc);

    /* ao terminar filhos, removemos o nó para que postProc veja o pai correto */
    parentTop--;

    if (postProc) postProc(t);

    /* e então processamos irmão (não é filho, então não altera a pilha de pais) */
    traverse(t->irmao, preProc, postProc);
  }
}

// Checar tipos
static int countParamNodes(TreeNode *paramNode, ExpType *outTypes) {
  int count = 0;
  TreeNode *p = paramNode;
  while (p != NULL) {
    int isParam = 0;
    /* detecta explicitamente nó de parâmetro ou padrão (tipo -> id) */
    if (p->tipoNo == NO_PARAM) isParam = 1;
    else if (p->filho != NULL && p->irmao != NULL) {
      /* filho = Tipo, irmão = ID -> é um parâmetro */
      isParam = 1;
    }
    if (isParam) {
      ExpType t = Integer; /* default int */
      if (p->filho != NULL && p->filho->tipoNo == NO_TIPO_VOID) t = Void;
      if (outTypes != NULL) outTypes[count] = t;
      count++;
    }
    p = p->irmao;
  }
  return count;
}

// Contar argumentos
static int countArgNodesAndFillTypes(TreeNode *argNode, ExpType *outTypes) {
  int count = 0;
  TreeNode *a = argNode;
  while (a != NULL) {
    // assumimos que os nós de argumentos já tiveram seus tipos setados pelos filhos
    if (outTypes != NULL) outTypes[count] = a->type;
    count++;
    a = a->irmao;
  }
  return count;
}

// === quando chegar em um nó, inserir declarações ou verificar usos ===
static void insertNode(TreeNode *t)
{
  switch (t->tipoNo)
  {
  case NO_DECLARACAO_FUN:
  {
    TreeNode *tipoNode = t->filho;
    TreeNode *idNode = tipoNode->irmao;
    TreeNode *paramsNode = idNode->irmao;
    char *funcName = idNode->attr.lexema;

    /* insere a função no escopo atual (geralmente global) */
    if (st_lookup_rec(funcName) == NULL)
    {
      ExpType funcType = (tipoNode->tipoNo == NO_TIPO_INT) ? Integer : Void;
      st_insert(funcName, t->lineno, location++, currentScope(), funcType, ID_FUN);

      /* contar e registrar parâmetros (eles serão inseridos no próximo passo, já no escopo da função) */
      int nparams = 0;
      ExpType *types = NULL;
      if (paramsNode != NULL) {
        nparams = countParamNodes(paramsNode, NULL);
        if (nparams > 0) {
          types = (ExpType *) malloc(sizeof(ExpType) * nparams);
          countParamNodes(paramsNode, types);
          st_set_params(funcName, nparams, types);
          free(types);
        } else {
          st_set_params(funcName, 0, NULL);
        }
      } else {
        st_set_params(funcName, 0, NULL);
      }
    }
    else
    {
      fprintf(stderr, "ERRO SEMÂNTICO: Função '%s' já declarada na linha %d.\n", funcName, t->lineno);
    }

    int newScope = pushNewScope();
    t->scopeId = newScope;
  }
  break;

  case NO_BLOCO:
  {
    int newScope = pushNewScope();
    t->scopeId = newScope;
  }
  break;

  case NO_DECLARACAO_VAR:
  {
    TreeNode *tipoNode = t->filho;
    TreeNode *idNode = tipoNode->irmao;
    char *varName = idNode->attr.lexema;

    /* Caso: void variável => inválido */
    if (tipoNode->tipoNo == NO_TIPO_VOID) {
      fprintf(stderr, "ERRO SEMÂNTICO: declaração inválida de variável '%s' com tipo void. Linha %d.\n", varName, t->lineno);
      break;
    }

    /* Caso: não permitir declarar variável com nome de função já declarada (no escopo global) */
    BucketList existing = st_lookup_rec(varName);
    if (existing != NULL && existing->kind == ID_FUN) {
      fprintf(stderr, "ERRO SEMÂNTICO: declaração inválida '%s' - já existe função com esse nome. Linha %d.\n", varName, t->lineno);
      break;
    }

    /* verificamos se já existe no escopo atual (redeclaração local) */
    int cs = currentScope();
    if (st_lookup_scope(varName, cs) == -1)
    {
      ExpType varType = (tipoNode->tipoNo == NO_TIPO_INT) ? Integer : Void;
      IdKind kind = ID_VAR;
      if (idNode->irmao != NULL && idNode->irmao->tipoNo == NO_NUM)
      {
        kind = ID_ARRAY;
      }
      st_insert(varName, t->lineno, location++, currentGeneratedScope(), varType, kind);
    }
    else
    {
      fprintf(stderr, "ERRO SEMÂNTICO: Variável '%s' já declarada na linha %d.\n", varName, t->lineno);
    }
  }
  break;

  case NO_PARAM:
  {
    TreeNode *tipoNode = t->filho;
    if (tipoNode->tipoNo != NO_TIPO_VOID)
    {
      TreeNode *idNode = tipoNode->irmao;
      char *paramName = idNode->attr.lexema;

      int cs = currentScope();
      if (st_lookup_scope(paramName, cs) == -1)
      {
        st_insert(paramName, t->lineno, location++, cs, Integer, ID_VAR);
      }
      else
      {
        fprintf(stderr, "ERRO SEMÂNTICO: Parâmetro '%s' redeclarado na linha %d.\n", paramName, t->lineno);
      }
    }
  }
  break;

  default:
    break;
  }
}

/* pós-ordem: ao sair do nó função, desfaz escopo e desempilha tipo */
static void afterNode(TreeNode *t)
{
  if (t == NULL) return;

  if (t->tipoNo == NO_DECLARACAO_FUN || t->tipoNo == NO_BLOCO)
  {
    /* fechar o scope gerado (não apagar a tabela agora) */
    popGeneratedScope();
  }
}

//Type checking (pós-ordem)

static void nullProc(TreeNode *t) { (void)t; }

// checkNode é executado após os filhos terem sido processados
static void checkNode(TreeNode *t) {
  if (t == NULL) return;

  switch (t->tipoNo) {

    case NO_NUM:
    {
      /* Literal numérico -> tipo int */
      t->type = Integer;
    }
    break;

    case NO_OP_SOMA:
    {
      /* operação binária soma/subtração (filho = left, filho->irmao = right) */
      TreeNode *left = t->filho;
      TreeNode *right = (left != NULL) ? left->irmao : NULL;
      ExpType lt = (left != NULL) ? left->type : Void;
      ExpType rt = (right != NULL) ? right->type : Void;

      if (lt == Integer && rt == Integer) {
        t->type = Integer;
      } else {
        fprintf(stderr, "ERRO SEMÂNTICO: Operação aritmética exige int,int (obtido %s,%s). Linha %d.\n",
                (lt==Integer)?"int":"void",
                (rt==Integer)?"int":"void",
                t->lineno);
        t->type = Void;
      }
    }
    break;

    case NO_OP_MULT:
    {
      /* multiplicação/divisão */
      TreeNode *left = t->filho;
      TreeNode *right = (left != NULL) ? left->irmao : NULL;
      ExpType lt = (left != NULL) ? left->type : Void;
      ExpType rt = (right != NULL) ? right->type : Void;

      if (lt == Integer && rt == Integer) {
        t->type = Integer;
      } else {
        fprintf(stderr, "ERRO SEMÂNTICO: Operação aritmética exige int,int (obtido %s,%s). Linha %d.\n",
                (lt==Integer)?"int":"void",
                (rt==Integer)?"int":"void",
                t->lineno);
        t->type = Void;
      }
    }
    break;

    case NO_OP_REL:
    {
      /* operações relacionais: retornam Boolean se operandos OK */
      TreeNode *left = t->filho;
      TreeNode *right = (left != NULL) ? left->irmao : NULL;
      ExpType lt = (left != NULL) ? left->type : Void;
      ExpType rt = (right != NULL) ? right->type : Void;

      if (lt == Integer && rt == Integer) {
        t->type = Boolean;
      } else {
        fprintf(stderr, "ERRO SEMÂNTICO: Operação relacional exige int,int (obtido %s,%s). Linha %d.\n",
                (lt==Integer)?"int":"void",
                (rt==Integer)?"int":"void",
                t->lineno);
        t->type = Void;
      }
    }
    break;

    case NO_VAR:
    {
      char *name = t->attr.lexema;
      BucketList l = st_lookup_visible(name);
      if (l == NULL) {
        fprintf(stderr, "ERRO SEMÂNTICO: Variável '%s' não foi declarada. Linha %d.\n", name, t->lineno);
        t->type = Void;
      } else {
        if (l->kind == ID_FUN) {
          fprintf(stderr, "ERRO SEMÂNTICO: '%s' é função e foi usada como variável. Linha %d.\n", name, t->lineno);
          t->type = Void;
        } else {
          t->type = l->type;
        }
      }
    }
    break;

    case NO_CHAMADA:
    {
      char *name = t->attr.lexema;
      BucketList l = st_lookup_visible(name);
      if (l == NULL) {
        fprintf(stderr, "ERRO SEMÂNTICO: Chamada de função '%s' não declarada. Linha %d.\n", name, t->lineno);
        t->type = Void;
        break;
      }
      if (l->kind != ID_FUN) {
        fprintf(stderr, "ERRO SEMÂNTICO: Identificador '%s' não é função (não pode ser chamado). Linha %d.\n", name, t->lineno);
        t->type = Void;
        break;
      }

      TreeNode *argNode = t->filho;
      int nargs = (argNode == NULL) ? 0 : countArgNodesAndFillTypes(argNode, NULL);

      if (nargs != l->numParams) {
        fprintf(stderr, "ERRO SEMÂNTICO: Chamada '%s' com número inválido de parâmetros (esperado %d, obtido %d). Linha %d.\n",
                name, l->numParams, nargs, t->lineno);
      }

      if (l->numParams == 0 && nargs > 0) {
        fprintf(stderr, "ERRO SEMÂNTICO: Chamada '%s' não espera argumentos (0) mas recebeu %d. Linha %d.\n",
                name, nargs, t->lineno);
      }

      /* verificar tipos quando disponíveis */
      if (l->numParams > 0 && l->paramTypes != NULL) {
        ExpType *argTypes = malloc(sizeof(ExpType) * (nargs>0 ? nargs : 1));
        countArgNodesAndFillTypes(argNode, argTypes);
        int limit = (nargs < l->numParams) ? nargs : l->numParams;
        for (int i = 0; i < limit; ++i) {
          if (argTypes[i] != l->paramTypes[i]) {
            fprintf(stderr, "ERRO SEMÂNTICO: Chamada '%s' parâmetro %d tipo inválido (esperado %s, obtido %s). Linha %d.\n",
                    name, i+1,
                    (l->paramTypes[i]==Integer) ? "int" : "void",
                    (argTypes[i]==Integer) ? "int" : "void",
                    t->lineno);
          }
        }
        free(argTypes);
      }

      t->type = l->type;
      TreeNode *parent = currentParentNode();
      int callUsedAsStatement = 0;
      if (parent == NULL) {
        callUsedAsStatement = 1;
      } else if (parent->tipoNo == NO_BLOCO || parent->tipoNo == NO_PROGRAMA) {
        /* chamada aparece diretamente como filho do bloco -> usada como statement */
        callUsedAsStatement = 1;
      } else {
        /* há outros casos que consideramos expressão (atribuição, return, operação, argumento) */
        callUsedAsStatement = 0;
      }

      if (callUsedAsStatement && t->type != Void) {
        /* erro: função retorna valor mas a chamada foi feita como statement */
        fprintf(stderr, "ERRO SEMÂNTICO: Chamada a função '%s' retorna valor e seu retorno foi ignorado. Linha %d.\n",
                name, t->lineno);
      }
    }
    break;
    case NO_ARRAY_IDX:
    {
      /* estrutura: filho = base (Var), filho->irmao = index(expr) */
      TreeNode *base = t->filho;
      TreeNode *index = (base != NULL) ? base->irmao : NULL;

      if (base == NULL) {
        fprintf(stderr, "ERRO SEMÂNTICO: Índice de array inválido (sem base). Linha %d.\n", t->lineno);
        t->type = Void;
        break;
      }

      /* resolve o identificador da base respeitando escopos ativos */
      if (base->tipoNo != NO_VAR) {
        fprintf(stderr, "ERRO SEMÂNTICO: Base do index não é variável. Linha %d.\n", t->lineno);
        t->type = Void;
        break;
      }

      BucketList b = st_lookup_visible(base->attr.lexema);
      if (b == NULL) {
        fprintf(stderr, "ERRO SEMÂNTICO: Variável '%s' não foi declarada (uso em index). Linha %d.\n", base->attr.lexema, t->lineno);
        t->type = Void;
        break;
      }

      if (b->kind != ID_ARRAY) {
        fprintf(stderr, "ERRO SEMÂNTICO: Identificador '%s' não é array. Linha %d.\n", base->attr.lexema, t->lineno);
        t->type = Void;
        break;
      }

      if (index == NULL) {
        fprintf(stderr, "ERRO SEMÂNTICO: Índice ausente para array '%s'. Linha %d.\n", base->attr.lexema, t->lineno);
        t->type = Void;
        break;
      }

      /* index já teve seu tipo calculado (pós-ordem) */
      if (index->type != Integer) {
        fprintf(stderr, "ERRO SEMÂNTICO: Índice de array deve ser int (obtido %s). Linha %d.\n",
                (index->type==Integer) ? "int" : "void", t->lineno);
        t->type = Void;
        break;
      }

      /* tudo ok: tipo do elemento do array (por enquanto usamos o mesmo tipo guardado no símbolo) */
      t->type = b->type; /* normalmente Integer */
    }
    break;
    case NO_ATRIBUICAO:
    {
      TreeNode *left = t->filho;
      TreeNode *right = (left != NULL) ? left->irmao : NULL;
      ExpType lt = (left != NULL) ? left->type : Void;
      ExpType rt = (right != NULL) ? right->type : Void;

      if (lt == Void) {
        fprintf(stderr, "ERRO SEMÂNTICO: Lado esquerdo da atribuição não é variável válida. Linha %d.\n", t->lineno);
      } else if (rt == Void && lt != Void) {
        fprintf(stderr, "ERRO SEMÂNTICO: Atribuição inválida: atribuir 'void' a '%s'. Linha %d.\n",
                (lt==Integer)?"int":"void", t->lineno);
      } else if (lt != rt) {
        fprintf(stderr, "ERRO SEMÂNTICO: Atribuição com tipos incompatíveis (%s = %s). Linha %d.\n",
                (lt==Integer)?"int":"void",
                (rt==Integer)?"int":"void",
                t->lineno);
      }
    }
    break;

    case NO_RETURN:
    {
      ExpType funcType = currentFuncType();
      TreeNode *expr = t->filho;
      if (funcType == Void) {
        if (expr != NULL) {
          fprintf(stderr, "ERRO SEMÂNTICO: Função 'void' retornando valor. Linha %d.\n", t->lineno);
        }
      } else { /* função int esperada */
        if (expr == NULL) {
          fprintf(stderr, "ERRO SEMÂNTICO: Função com retorno 'int' sem valor no return. Linha %d.\n", t->lineno);
        } else if (expr->type == Void) {
          /* <- aqui o problema anterior: se expr->type não foi definido, era Void, gerando falso-positivo.
             agora, com NO_NUM/NO_OP_* definindo tipos, isso deve resolver. */
          fprintf(stderr, "ERRO SEMÂNTICO: Return retorna 'void' em função 'int'. Linha %d.\n", t->lineno);
        }
      }
    }
    break;

    default:
      break;
  }
}

// função principal para construir a tabela de simbols
void buildSymTab(TreeNode *syntaxTree)
{
  location = 0;
  nextScopeId = 0;
  scopeTop = -1;

  /* cria escopo global e guarda o id */
  globalScopeId = pushNewScope();  /* por exemplo, id 0 */

  /* inserir predefinidas no scope global */
  st_insert("input", 0, location++, globalScopeId, Integer, ID_FUN);
  st_set_params("input", 0, NULL);

  /* output recebe 1 parâmetro int */
  st_insert("output", 0, location++, globalScopeId, Void, ID_FUN);
  {
    ExpType outTypes[1];
    outTypes[0] = Integer;
    st_set_params("output", 1, outTypes);
  }

  traverse(syntaxTree, insertNode, afterNode);

  if (st_lookup_scope_rec("main", globalScopeId) == NULL)
  {
    fprintf(stderr, "ERRO SEMÂNTICO: Função 'main' não definida.\n");
  }

  printf("\n");
  printSymTab(stdout);
}

/* preProc usado em typeCheck: quando entramos numa função/bloco,
   empilhamos seu scopeId e (se função) empilhamos também o tipo da função */
static void tc_pre(TreeNode *t) {
  if (t == NULL) return;

  /* garantir global ativo ao entrar na raiz (se ainda não empilhado) */
  if (t->tipoNo == NO_PROGRAMA && activeTop < 0) {
    pushActiveScope(globalScopeId);
  }

  if (t->tipoNo == NO_DECLARACAO_FUN) {
    /* empilha scope ativo (se disponível) */
    if (t->scopeId >= 0) pushActiveScope(t->scopeId);
    else pushActiveScope(globalScopeId);

    /* empilha tipo da função para validação de RETURN */
    TreeNode *tipoNode = t->filho;
    ExpType ftype = (tipoNode && tipoNode->tipoNo == NO_TIPO_INT) ? Integer : Void;
    pushFuncType(ftype);
    return;
  }

  if (t->tipoNo == NO_BLOCO) {
    if (t->scopeId >= 0) pushActiveScope(t->scopeId);
    else pushActiveScope(globalScopeId);
  }
}

/* postProc: executa a checagem e depois desempilha caso feche função/bloco.
   Observação: desempilhamos o tipo da função apenas quando fechamos NO_DECLARACAO_FUN */
static void tc_post_and_check(TreeNode *t) {
  if (t == NULL) return;

  checkNode(t);

  if (t->tipoNo == NO_BLOCO) {
    popActiveScope();
  } else if (t->tipoNo == NO_DECLARACAO_FUN) {
    /* primeiro checamos o nó, depois desempilhamos tipo e escopo */
    popFuncType();
    popActiveScope();
  }
}


/* e a própria typeCheck: usa tc_pre/tc_post_and_check */
void typeCheck(TreeNode * syntaxTree) {
  /* inicializa pilha ativa vazia e empilha global para segurança */
  activeTop = -1;
  pushActiveScope(globalScopeId);
  traverse(syntaxTree, tc_pre, tc_post_and_check);
}

