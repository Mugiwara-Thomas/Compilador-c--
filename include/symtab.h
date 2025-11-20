#ifndef _SYMTAB_H_
#define _SYMTAB_H_

#include <stdio.h>

// Precisamos ter nome, tipo e escopo

// Lista encadeada para armazenar números das linhas
typedef struct LineListRec
{
  int lineno;
  struct LineListRec *next;
} *LineList;

typedef struct BucketListRec
{
  char *nome;
  char *escopo;
  char *idType;
  char *dataType;
  LineList lines;
  int memloc;
  struct BucketListRec *next;
} *BucketList;

void st_insert(char * nome, int lineno, char * escopo, char * idType, char * dataType);
int st_lookup(char * nome, char * escopo);
char* st_lookup_type(char* nome, char* escopo);
void printSymTab(FILE * listing);

#endif