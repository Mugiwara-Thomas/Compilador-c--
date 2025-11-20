# Compilador-c--

# Estrutura
- **Makefile**: Código para compilação, limpeza e verificações de memória.
- **cminus.l**: Código com as regras para a análise léxica utilizando Flex.

```bash
sudo apt update && sudo apt upgrade -y
```

```bash
sudo apt install flex bison gcc -y
```

```bash
bisond -d cminus.y
```

```bash
flex cminus.l
```

```bash
gcc -o cminus cminus.tab.c lex.yy.c arvore.c
```

```bash
./cminus gcd.txt 
```