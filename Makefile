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
CFLAGS = -I$(INC_DIR) -I$(SRC_DIR) -I. -Wall -g

OBJS = $(OBJ_DIR)/cminus.tab.o $(OBJ_DIR)/lex.yy.o $(OBJ_DIR)/arvore.o $(OBJ_DIR)/symtab.o $(OBJ_DIR)/analyze.o

# --- Regras Principais ---

# Garante que os diretórios existem antes de compilar
$(shell mkdir -p $(OBJ_DIR) $(BIN_DIR))

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# --- Regras de Compilação Específicas ---

# Parser (Bison)
$(SRC_DIR)/cminus.tab.c $(SRC_DIR)/cminus.tab.h: $(SRC_DIR)/cminus.y
	bison -d $< -o $(SRC_DIR)/cminus.tab.c

# Lexer (Flex)
$(SRC_DIR)/lex.yy.c: $(SRC_DIR)/cminus.l $(SRC_DIR)/cminus.tab.h
	flex -o $@ $<

# Regra Genérica para qualquer .c em src/ virar .o em obj/
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# --- Utilitários ---

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
	# Cuidado: Isso remove arquivos gerados dentro de src/
	rm -f $(SRC_DIR)/cminus.tab.c $(SRC_DIR)/cminus.tab.h $(SRC_DIR)/lex.yy.c

check: all
	valgrind --leak-check=full ./$(TARGET) $(TEST_DIR)/gcd.txt