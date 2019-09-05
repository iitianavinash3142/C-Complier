%{
	#include <bits/stdc++.h>
	using namespace std;
	#include "parser4.tab.h"
%}

%option noyywrap

%%
[\t ]+    ;
[\n]      ;
";"		{
          return SEMI;}
":"		{return COLON;}
"="		{
         return EQUAL;}
">"		{ return GT;}
"<"		{ return LT;}
">="	{ return GE;}
"<="	{ return LE;}
"=="	{ return EQ;}
("!="|"<>")	{ return NE;}
"+"		{ return PLUS;}
"-"		{ return MINUS;}
"*"		{ return MUL;}
"/"		{ return DIV;}
"||"	{ return OR;}
"&&"	{ return AND;}
"!"		{ return NOT;}
"{"		{ return LB_CURLY;}
"}"		{ return RB_CURLY;}
"[" 	{ return LB_SQUARE;}
"]"		{ return RB_SQUARE;}
"("		{ return LB_ROUND;}
")"		{ return RB_ROUND;}
","		{ return COMMA;}
"int main"	{return MAIN;}
"int"	{ return INT;}
"float"	{ return FLOAT;}
"for" { return FOR;}
"while"	{ return WHILE;}
"if"	{ return IF;}
"else"	{ return ELSE;}
"switch"	{ return SWITCH;}
"case"	{ return CASE;}
"break"	{ return BREAK;}
"continue"	{ return CONTINUE;}
"default"		{return DEFAULT;}
"return"	{ return RETURN;}
"void" {return VOID;}
-?[0-9]+|-?[0-9]+E[-+]?[0-9]+|-?[0-9]+"."[0-9]*E[-+]?[0-9]+|-?"."[0-9]+E[-+]?[0-9]+ {
																					yylval.num = atoi(yytext);
																					return INTNUM;
																								}
-?[0-9]+|-?[0-9]+"."[0-9]*|-?"."[0-9]+|-?[0-9]+E[-+]?[0-9]+|-?[0-9]+"."[0-9]*E[-+]?[0-9]+|-?"."[0-9]+E[-+]?[0-9]+  {
                                                                                        yylval.floatval = atof(yytext);
                                                                                        return FINTNUM; }
[A-Za-z]([A-Za-z0-9_])* {
                          yylval.strval = strdup(yytext);
						  return NAME; }
.    { cout<<"mystery character\n"; }
%%
