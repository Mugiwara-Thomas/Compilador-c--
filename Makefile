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
# -I inclui as pastas de headers para não precisar por caminhos no #include
# -Wall ativa avisos (boas práticas)
# -g adiciona símbolos de debug (essencial para o Valgrind)
CFLAGS = -I$(INC_DIR) -I$(SRC_DIR) -Wall -g

# --- Arquivos Fonte e Objetos ---
# Objetos que precisamos gerar
OBJS = $(OBJ_DIR)/cminus.tab.o $(OBJ_DIR)/lex.yy.o $(OBJ_DIR)/arvore.o

# --- Regras Principais ---

# Garante que as pastas de saída existam antes de compilar
$(shell mkdir -p $(OBJ_DIR) $(BIN_DIR))

all: $(TARGET)

# Linkagem final
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# --- Regras do Bison e Flex ---

# Gera o parser (.c) e o header (.h) na pasta src
$(SRC_DIR)/cminus.tab.c $(SRC_DIR)/cminus.tab.h: $(SRC_DIR)/cminus.y
	bison -d $< -o $(SRC_DIR)/cminus.tab.c

# Gera o scanner (.c) na pasta src
$(SRC_DIR)/lex.yy.c: $(SRC_DIR)/cminus.l $(SRC_DIR)/cminus.tab.h
	flex -o $@ $<

# --- Regra Genérica de Compilação (.c -> .o) ---
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

# --- Utilitários ---

# Limpa tudo (arquivos gerados pelo bison/flex e binários)
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
	rm -f $(SRC_DIR)/cminus.tab.c $(SRC_DIR)/cminus.tab.h $(SRC_DIR)/lex.yy.c

# Roda o teste com Valgrind apontando para a pasta tests
check: all
	valgrind --leak-check=full ./$(TARGET) $(TEST_DIR)/gcd.txt