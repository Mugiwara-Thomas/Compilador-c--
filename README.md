# Compilador-c--

```bash
sudo apt update && sudo apt upgrade -y
```

```bash
sudo apt install flex gcc -y
```

```bash
flex cminus.l
```

```bash
gcc lex.yy.c -o cminus -lfl
```

```bash
./cminus gcd.txt 
```