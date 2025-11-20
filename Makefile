# --- Definições de Diretórios ---
SRC_DIR = src
INC_DIR = include
OBJ_DIR = obj
BIN_DIR = bin
TEST_DIR = tests

# --- Nome do Executável Final ---
TARGET = $(BIN_DIR)/cminus

# --- Compilador e Flags ---
CC = gcc
CFLAGS = -I$(INC_DIR) -I$(SRC_DIR) -Wall -g

# --- Arquivos Fonte e Objetos ---
# AQUI ESTAVA O ERRO: Adicionamos symtab.o na lista
OBJS = $(OBJ_DIR)/cminus.tab.o $(OBJ_DIR)/lex.yy.o $(OBJ_DIR)/arvore.o $(OBJ_DIR)/symtab.o

# --- Regras Principais ---

$(shell mkdir -p $(OBJ_DIR) $(BIN_DIR))

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# --- Regras de Compilação Específicas ---

$(SRC_DIR)/cminus.tab.c $(SRC_DIR)/cminus.tab.h: $(SRC_DIR)/cminus.y
	bison -d $< -o $(SRC_DIR)/cminus.tab.c

$(SRC_DIR)/lex.yy.c: $(SRC_DIR)/cminus.l $(SRC_DIR)/cminus.tab.h
	flex -o $@ $<

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# Regra explícita para symtab (opcional se a regra genérica %.o acima funcionar, mas bom garantir)
$(OBJ_DIR)/symtab.o: $(SRC_DIR)/symtab.c $(INC_DIR)/symtab.h
	$(CC) $(CFLAGS) -c $< -o $@

# --- Utilitários ---

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
	rm -f $(SRC_DIR)/cminus.tab.c $(SRC_DIR)/cminus.tab.h $(SRC_DIR)/lex.yy.c

check: all
	valgrind --leak-check=full ./$(TARGET) $(TEST_DIR)/gcd.txt