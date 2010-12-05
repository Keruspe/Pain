%{
    #include <stdio.h>
    #include <math.h>
    void yyerror(char* error);
    extern int yylex (void);
%}

%union { float fval; char * cval; }
%token <fval> number
%token <cval> String
%type  <fval> Expression Result FIN Print Printable

%token equals beg end print println EOL Comma ID
%left  plus minus
%left  times over
%left  neg
%right power

%start FIN

%%
FIN : Result
    | FIN Result
    | Print
    ;

Print : print beg Printable end EOL           { $$ = 0; }
      | println beg Printable end EOL         { $$ = printf("\n"); }
      | println beg end EOL                   { $$ = printf("\n"); }
      ;

Printable : Expression              { $$ = printf("%.3f", $1); }
          | String                  { $$ = printf("%s", $1); }
          | Printable Comma String { $$ = printf("%s", $3); }
          | Printable Comma Expression { $$ = printf("%.3f", $3); }
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
