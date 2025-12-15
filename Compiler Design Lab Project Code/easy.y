%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef struct {
    char name[50];
    int type;          // 0 = number, 1 = string
    int initialized;
    double num_value;
    char str_value[100];
} SymbolEntry;

SymbolEntry symbol_table[100];
int sym_count = 0;

void yyerror(const char *s);
int yylex(void);
int lookup_symbol(char *name);
int add_symbol(char *name, int type);
void windows_input(char *var_name, int index);
%}

%union {
    double num;
    char *str;
}

%token <num> NUMBER
%token <str> STRING ID
%token VAR PRINT INPUT IF REPEAT
%token EQ NE GT LT GE LE
%token PLUS MINUS MULT DIV
%token ASSIGN LPAREN RPAREN LBRACE RBRACE COMMA

%type <num> expression
/* REMOVE THIS LINE: %type <str> string_expr */

%%

program:
    | program statement
    ;

statement:
    declaration
    | assignment
    | print_stmt
    | input_stmt
    | if_stmt
    | repeat_stmt
    ;

declaration:
    VAR ID
    {
        add_symbol($2, -1);
        free($2);
    }
    | VAR ID ASSIGN expression
    {
        int index = add_symbol($2, 0);
        symbol_table[index].num_value = $4;
        free($2);
    }
    | VAR ID ASSIGN STRING
    {
        int index = add_symbol($2, 1);
        strcpy(symbol_table[index].str_value, $4);
        free($2);
        free($4);
    }
    ;

assignment:
    ID ASSIGN expression
    {
        int index = lookup_symbol($1);
        if (index == -1) {
            printf("Error: Variable '%s' not declared\n", $1);
        } else {
            symbol_table[index].type = 0;
            symbol_table[index].initialized = 1;
            symbol_table[index].num_value = $3;
        }
        free($1);
    }
    | ID ASSIGN STRING
    {
        int index = lookup_symbol($1);
        if (index == -1) {
            printf("Error: Variable '%s' not declared\n", $1);
        } else {
            symbol_table[index].type = 1;
            symbol_table[index].initialized = 1;
            strcpy(symbol_table[index].str_value, $3);
        }
        free($1);
        free($3);
    }
    ;

print_stmt:
    PRINT print_list { printf("\n"); }
    ;

print_list:
    print_item
    | print_list COMMA print_item
    ;

print_item:
    expression { printf("%g ", $1); }
    | STRING { printf("%s ", $1); free($1); }
    | ID
    {
        int index = lookup_symbol($1);
        if (index == -1) {
            printf("Error: Variable '%s' not declared\n", $1);
        } else if (!symbol_table[index].initialized) {
            printf("Error: Variable '%s' not initialized\n", $1);
        } else {
            if (symbol_table[index].type == 0) {
                printf("%g ", symbol_table[index].num_value);
            } else {
                printf("%s ", symbol_table[index].str_value);
            }
        }
        free($1);
    }
    ;

input_stmt:
    INPUT ID
    {
        int index = lookup_symbol($2);
        if (index == -1) {
            printf("Error: Variable '%s' not declared\n", $2);
        } else {
            windows_input($2, index);
        }
        free($2);
    }
    ;

if_stmt:
    IF LPAREN condition RPAREN LBRACE program RBRACE
    ;

condition:
    expression EQ expression
    {
        if ($1 == $3) printf("Condition true\n");
        else printf("Condition false\n");
    }
    | expression GT expression
    {
        if ($1 > $3) printf("Condition true\n");
        else printf("Condition false\n");
    }
    | expression LT expression
    {
        if ($1 < $3) printf("Condition true\n");
        else printf("Condition false\n");
    }
    ;

repeat_stmt:
    REPEAT expression LBRACE program RBRACE
    {
        printf("Repeated %g times\n", $2);
    }
    ;

expression:
    NUMBER { $$ = $1; }
    | ID
    {
        int index = lookup_symbol($1);
        if (index == -1) {
            printf("Error: Variable '%s' not declared\n", $1);
            $$ = 0;
        } else if (!symbol_table[index].initialized) {
            printf("Error: Variable '%s' not initialized\n", $1);
            $$ = 0;
        } else if (symbol_table[index].type != 0) {
            printf("Error: Variable '%s' is not a number\n", $1);
            $$ = 0;
        } else {
            $$ = symbol_table[index].num_value;
        }
        free($1);
    }
    | expression PLUS expression { $$ = $1 + $3; }
    | expression MINUS expression { $$ = $1 - $3; }
    | expression MULT expression { $$ = $1 * $3; }
    | expression DIV expression
    {
        if ($3 == 0) {
            printf("Error: Division by zero\n");
            $$ = 0;
        } else {
            $$ = $1 / $3;
        }
    }
    | LPAREN expression RPAREN { $$ = $2; }
    ;

%%

int lookup_symbol(char *name) {
    for (int i = 0; i < sym_count; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

int add_symbol(char *name, int type) {
    if (lookup_symbol(name) == -1) {
        strcpy(symbol_table[sym_count].name, name);
        symbol_table[sym_count].type = type;
        symbol_table[sym_count].initialized = (type != -1) ? 1 : 0;
        symbol_table[sym_count].num_value = 0;
        symbol_table[sym_count].str_value[0] = '\0';
        return sym_count++;
    }
    return lookup_symbol(name);
}

void windows_input(char *var_name, int index) {
    printf("Input value for %s: ", var_name);
    fflush(stdout);
    
    char input[100];
    if (fgets(input, sizeof(input), stdin)) {
        input[strcspn(input, "\n")] = 0;
        input[strcspn(input, "\r")] = 0;
        
        char *endptr;
        double num = strtod(input, &endptr);
        
        if (endptr != input && *endptr == '\0') {
            symbol_table[index].type = 0;
            symbol_table[index].initialized = 1;
            symbol_table[index].num_value = num;
        } else {
            symbol_table[index].type = 1;
            symbol_table[index].initialized = 1;
            strcpy(symbol_table[index].str_value, input);
        }
    }
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        printf("Usage: easy.exe <filename.easy>\n");
        return 1;
    }
    
    FILE *file = fopen(argv[1], "r");
    if (!file) {
        printf("Cannot open file: %s\n", argv[1]);
        return 1;
    }
    
    extern FILE *yyin;
    yyin = file;
    
    printf("=== EasyLang Compiler ===\n");
    yyparse();
    
    printf("\n=== Symbol Table ===\n");
    for (int i = 0; i < sym_count; i++) {
        printf("%s: ", symbol_table[i].name);
        if (symbol_table[i].type == 0)
            printf("number = %g", symbol_table[i].num_value);
        else if (symbol_table[i].type == 1)
            printf("string = \"%s\"", symbol_table[i].str_value);
        else
            printf("uninitialized");
        printf("\n");
    }
    
    fclose(file);
    printf("\nCompilation completed.\n");
    return 0;
}