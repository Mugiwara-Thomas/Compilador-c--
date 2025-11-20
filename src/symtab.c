#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtab.h"

#define SIZE 211
#define SHIFT 4

static BucketList hashTable[SIZE];

/* Função Hash: Multiplicação e deslocamento */
static int hash(char * key) {
    int temp = 0;
    int i = 0;
    while (key[i] != '\0') { 
        temp = ((temp << SHIFT) + key[i]) % SIZE;
        ++i;
    }
    return temp;
}

/* Insere na tabela com os novos campos exigidos */
void st_insert(char * nome, int lineno, char * escopo, char * idType, char * dataType) {
    int h = hash(nome);
    BucketList l = hashTable[h];
    
    // Procura se já existe nessa posição E no mesmo escopo
    while ((l != NULL) && ((strcmp(nome, l->nome) != 0) || (strcmp(escopo, l->escopo) != 0))) {
        l = l->next;
    }

    if (l == NULL) { /* Variável não está na tabela: inserir nova */
        l = (BucketList) malloc(sizeof(struct BucketListRec));
        l->nome = strdup(nome);
        l->escopo = strdup(escopo);
        l->idType = strdup(idType);     // Ex: "var", "fun"
        l->dataType = strdup(dataType); // Ex: "int", "void"
        l->lines = (LineList) malloc(sizeof(struct LineListRec));
        l->lines->lineno = lineno;
        l->lines->next = NULL;
        
        l->next = hashTable[h];
        hashTable[h] = l; 
    } else { /* Já existe: apenas adiciona a linha e atualiza tipos se necessário */
        LineList t = l->lines;
        while (t->next != NULL) t = t->next;
        
        // Adiciona linha apenas se for nova
        if (t->lineno != lineno) {
            t->next = (LineList) malloc(sizeof(struct LineListRec));
            t->next->lineno = lineno;
            t->next->next = NULL;
        }
    }
}

/* Busca simples: retorna se existe */
int st_lookup(char * nome, char * escopo) {
    int h = hash(nome);
    BucketList l = hashTable[h];
    
    while ((l != NULL) && ((strcmp(nome, l->nome) != 0) || (strcmp(escopo, l->escopo) != 0))) {
        l = l->next;
    }
    
    if (l == NULL) return -1;
    else return 0;
}

/* Função auxiliar nova: Retorna o tipo de dado para checagem semântica */
char* st_lookup_type(char * nome, char * escopo) {
    int h = hash(nome);
    BucketList l = hashTable[h];
    while ((l != NULL) && ((strcmp(nome, l->nome) != 0) || (strcmp(escopo, l->escopo) != 0))) {
        l = l->next;
    }
    if (l == NULL) return NULL;
    else return l->dataType;
}

/* Imprime a tabela formatada conforme Slide 23 */
void printSymTab(FILE * listing) {
    int i;
    // Cabeçalho conforme Page 23 do PDF
    fprintf(listing, "Nome ID        Escopo         Tipo ID        Tipo dado      n. Linha\n");
    fprintf(listing, "-------------  -------------  -------------  -------------  -------------\n");
    
    for (i = 0; i < SIZE; ++i) {
        if (hashTable[i] != NULL) {
            BucketList l = hashTable[i];
            while (l != NULL) {
                LineList t = l->lines;
                fprintf(listing, "%-14s ", l->nome);
                fprintf(listing, "%-14s ", l->escopo);
                fprintf(listing, "%-14s ", l->idType);   // Novo campo
                fprintf(listing, "%-14s ", l->dataType); // Novo campo
                
                while (t != NULL) {
                    fprintf(listing, "%d ", t->lineno); // Formato simples de lista
                    t = t->next;
                }
                fprintf(listing, "\n");
                l = l->next;
            }
        }
    }
}