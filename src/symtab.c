#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"

/* Tamanho da tabela hash */
#define SIZE 211
#define SHIFT 4

/* A tabela hash (array de listas) */
static BucketList hashTable[SIZE];

/* Função de Hash */
static int hash(char * key) {
    int temp = 0;
    int i = 0;
    while (key[i] != '\0') {
        temp = ((temp << SHIFT) + key[i]) % SIZE;
        ++i;
    }
    return temp;
}

/* Insere na tabela */
void st_insert(char * name, int lineno, int loc, int scope, 
               ExpType type, IdKind kind) {
    int h = hash(name);
    BucketList l = (BucketList) malloc(sizeof(struct BucketListRec));
    

    
    l->name = strdup(name);
    l->lineno = lineno;
    l->loc = loc;
    l->scope = scope;
    l->type = type;
    l->kind = kind;
    
    /* Zera os campos opcionais por segurança */
    l->size = 0;
    l->numParams = 0;
    l->paramTypes = NULL;

    /* Encadeia na lista */
    l->next = hashTable[h];
    hashTable[h] = l;
}


/* Busca simples pelo nome (retorna localização) */
int st_lookup(char * name) {
    int h = hash(name);
    BucketList l = hashTable[h];
    
    /* Retorna a primeira ocorrência encontrada (escopo mais recente) */
    while ((l != NULL) && (strcmp(name, l->name) != 0))
        l = l->next;
        
    if (l == NULL) return -1;
    else return l->loc;
}

/* Busca específica por escopo (para evitar redeclaração) */
int st_lookup_scope(char * name, int scope) {
    int h = hash(name);
    BucketList l = hashTable[h];
    while (l != NULL) {
        if (strcmp(name, l->name) == 0 && l->scope == scope) {
            return l->loc;
        }
        l = l->next;
    }
    return -1;
}

BucketList st_lookup_scope_rec(char * name, int scope) {
    int h = hash(name);
    BucketList l = hashTable[h];
    while (l != NULL) {
        if (strcmp(l->name, name) == 0 && l->scope == scope) return l;
        l = l->next;
    }
    return NULL;
}

/* Busca que retorna o registro completo (para checar tipos) */
BucketList st_lookup_rec(char * name) {
    int h = hash(name);
    BucketList l = hashTable[h];
    while (l != NULL) {
        if (strcmp(name, l->name) == 0) return l;
        l = l->next;
    }
    return NULL;
}

/* Define parâmetros para função já inserida */
void st_set_params(char * name, int numParams, ExpType * types) {
    BucketList l = st_lookup_rec(name);
    if (l == NULL) return;
    if (l->paramTypes != NULL) {
        free(l->paramTypes);
        l->paramTypes = NULL;
    }
    if (numParams > 0) {
        l->paramTypes = (ExpType *) malloc(sizeof(ExpType) * numParams);
        for (int i = 0; i < numParams; ++i) l->paramTypes[i] = types[i];
        l->numParams = numParams;
    } else {
        l->paramTypes = NULL;
        l->numParams = 0;
    }
}

/* Imprime a tabela formatada */
void printSymTab(FILE * listing) {
    int i;
    fprintf(listing, "Nome           Escopo  Tipo      Kind    Linha  #P\n");
    fprintf(listing, "-------------  ------  --------  ------  -----  ---\n");
    for (i = 0; i < SIZE; ++i) {
        if (hashTable[i] != NULL) {
            BucketList l = hashTable[i];
            while (l != NULL) {
                fprintf(listing, "%-14s %-6d  ", l->name, l->scope);
                
                /* Imprime Tipo */
                if(l->type == Integer) fprintf(listing, "INT       "); 
                else if (l->type == Void) fprintf(listing, "VOID      ");
                else fprintf(listing, "BOOL      ");

                /* Imprime Kind */
                if(l->kind == ID_VAR) fprintf(listing, "VAR     "); 
                else if(l->kind == ID_FUN) fprintf(listing, "FUN     ");
                else fprintf(listing, "ARRAY   ");

                fprintf(listing, "%-5d  %-3d\n", l->lineno, l->numParams);
                l = l->next;
            }
        }
    }
}