# Compiler
Compiler for a C-like language. Converts the code to MIPS Assembly Language which can be run using SPIM.

## Inside
1. Lexical analysis done in Lexer.lex
2. syntax analysis , symantic analysis and intermediate code generation code done in parser.y
3. Three_address_code.txt contains intermediate code.
4. mips code generated using ASMgenerator.cpp , Register.cpp and Debugger.cpp
5. mips_code.s contains mips code.
 
## Features of the Language

* Data types : void, int, float, bool, char, string

* Variable Declaration

* Variable Assignment

* Function Declaration

* Reading from console

* Printing to console

* Logical Expressions involving '&&' and '||'

* Relational operators : '>', '<', '>=', '<=', '==', '<>', '!='

* Arithmatic operators : '+', '-', '*', '/', '%'

* Unary Operators : '+', '-'

* For Loop

* Foreach loop

* While Loop

* Conditional statements

* Nested code blocks

* Explicit Scope specifiers

* breaks in loops

* continues in loops
