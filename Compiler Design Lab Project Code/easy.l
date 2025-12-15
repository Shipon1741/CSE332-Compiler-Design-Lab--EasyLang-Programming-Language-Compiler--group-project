%{
#include "easy.tab.h"
#include <stdlib.h>
#include <string.h>

void remove_quotes(char* str);
%}

DIGIT    [0-9]
LETTER   [a-zA-Z]
ID       {LETTER}({LETTER}|{DIGIT}|_)*
NUMBER   {DIGIT}+(\.{DIGIT}+)?
STRING   \"[^\"]*\"
COMMENT  \/\/[^\n]*

%%

{COMMENT}   { /* Ignore comments */ }

"var"       { return VAR; }
"print"     { return PRINT; }
"input"     { return INPUT; }
"if"        { return IF; }
"repeat"    { return REPEAT; }

"=="        { return EQ; }
"!="        { return NE; }
">"         { return GT; }
"<"         { return LT; }
">="        { return GE; }
"<="        { return LE; }

"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MULT; }
"/"         { return DIV; }
"="         { return ASSIGN; }

"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
","         { return COMMA; }

{NUMBER}    { 
               yylval.num = atof(yytext);
               return NUMBER;
            }

{STRING}    { 
               yylval.str = strdup(yytext);
               remove_quotes(yylval.str);
               return STRING;
            }

{ID}        { 
               yylval.str = strdup(yytext);
               return ID;
            }

[ \t\n\r]+  { /* Skip whitespace */ }

.           { 
               printf("Lexical error: Invalid character '%c'\n", yytext[0]);
               return yytext[0];
            }

%%

void remove_quotes(char* str) {
    if (strlen(str) >= 2) {
        memmove(str, str + 1, strlen(str));
        str[strlen(str) - 1] = '\0';
    }
}

int yywrap() {
    return 1;
}