Compilation Steps:

1. flex easy.l
2. bison -d easy.y
3. gcc lex.yy.c easy.tab.c -o easy.exe -lm
4. easy.exe test1.easy