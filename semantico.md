# Objetivos
Percorrer a árvore construida pelo parser e verificar regras que a gramática não consegue capturar.

[] Tabela de Símbolos
[] Analisador Semântico (AST)

# Tabela de Símbolos
Ela é basicamente um banco de dados do compilador, ela vai guardar informações, 
por exemplo, quando ele ler `int x;`, ele vai precisar salbar isso em algum lugar,
algo como "tem uma variável x do tipo int declaração na linha", se em algum momento 
ele ler `x = 5;`, ele vai consultar esse banco de dados para saber se `x` existe
e se pode receber um número.

Para o compilador ser rápido, nós usamos uma tabela hash, visto que a consulta
é O(1). Com isso, usamos uma conta matemática que transforma o nome da variável
em um número índice desse array.

