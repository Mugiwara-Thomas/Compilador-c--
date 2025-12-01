#ifndef _SYMTAB_H_
#define _SYMTAB_H_

#include <stdio.h>
#include "arvore.h" 

typedef enum { ID_VAR, ID_FUN, ID_ARRAY } IdKind;

typedef struct BucketListRec {
    char * name;
    int lineno;
    int loc;
    int scope;
    
    ExpType type;
    IdKind kind;    
    
    int size;
    int numParams;
    ExpType * paramTypes;

    struct BucketListRec * next;
} * BucketList;

void st_insert(char * name, int lineno, int loc, int scope, 
               ExpType type, IdKind kind);

int st_lookup(char * name);
int st_lookup_scope(char * name, int scope);
BucketList st_lookup_rec(char * name);
BucketList st_lookup_scope_rec(char * name, int scope);
void printSymTab(FILE * listing);
void st_set_params(char * name, int numParams, ExpType * types);

#endif