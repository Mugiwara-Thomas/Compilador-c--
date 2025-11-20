# Compilador-c--

# Estrutura
- **Makefile**: Script para compilação, limpeza e verificações de memória.

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