bison -d -v parser4.y
flex lexer.lex
g++ -g -std=c++11 lex.yy.c parser4.tab.c -o main
./main < $1
g++ ASMGenerator.cpp Registers.cpp Debugger.cpp
./a.out
