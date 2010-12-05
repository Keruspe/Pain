%{
    #include <stdio.h>
    #include <math.h>
    void yyerror(char* error);
    extern int yylex (void);
%}

%union { float fval; char * cval; }
%token <fval> number
%type  <fval> FIN Expression Result

%token equals beg end
%left  plus minus
%left  times over
%left  neg
%right power expo

%start FIN

%%
FIN : Result
    | FIN Result
    ;

Result : Expression equals         { printf("Résultat : %.3f\n", $1); }
     ;

Expression : number                      { $$ = $1; }
           | Expression plus Expression  { $$ = $1 + $3; }
           | Expression minus Expression { $$ = $1 - $3; }
           | Expression over Expression  { $$ = $1 / $3; }
           | Expression times Expression { $$ = $1 * $3; }
           | beg Expression end          { $$ = $2; }
           | minus Expression %prec neg  { $$ = -$2; }
           | Expression power Expression { $$ = pow($1, $3); }
           | Expression expo Expression  { $$ = $1 * pow(10, $3); }
           ;
%%

#include "lex.yy.c"

void yyerror(char* error) {
    fprintf(stderr, "Erreur : %s\n", error);
    exit(1);
}

int main() {
    yyparse();
    return(0);
}
