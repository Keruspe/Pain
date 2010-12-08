%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <math.h>
    void yyerror(char* error);
    extern int yylex (void);

    typedef enum {
	TRUE,
	FALSE
    } Bool;

    typedef enum {
	PRINT,
	AFFECT,
	NONE
    } Action;

    typedef struct _Instr Instr;
    struct _Instr {
	Instr * next;
	Action action;
	const char * format;
	char * svalue;
	float value;
    };

    Instr start = {NULL, NONE, NULL, NULL, 0};
    Instr * current = &start;
    Instr * new;
%}

%union { float fval; char * cval; Instr * instr; }
%token <fval> number
%token <cval> String
%type  <fval> Expression
%type  <instr> Print Printable stmt stmts OUT

%token equals beg end print println EOL Comma ID IF THEN ELSE BEGI END THE_END
%left  plus minus
%left  times over
%left  neg
%right power

%start OUT

%%
OUT   : BEGI stmts THE_END {
		Instr * toFree;
		current = $2;
		while (current != NULL) {
			toFree = current;
			if (current->action == PRINT) {
				if (current->svalue == NULL)
					printf(current->format, current->value);
				else
				{
					printf(current->format, current->svalue);
					free(current->svalue);
				}
				printf("\n");
			}
			current = current->next;
			free(toFree);
		}
		exit(0);
	   }
      | BEGI THE_END { exit(0);}
      ;

stmts : stmt { $$ = $1; }
      | stmts stmt {
			current = $1;
			while (current->next != NULL) current = current->next;
			current->next = new;
			$$ = $1;
      	   }
      ;

stmt : Print EOL { $$ = $1; }
     | IF Expression THEN stmt { $$ = $4; }
     | IF Expression THEN stmt ELSE stmt { $$ = $4; }
     | BEGI stmts END { $$ = $2; }
     ;

Print : print beg Printable end           { $$ = $3; }
      | println beg Printable end         {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->format = "%s";
			new->svalue = (char *) malloc(2 * sizeof(char));
			strcpy(new->svalue, "\n");
			new->next = $3;
			$$ = new;
      		}
      | println beg end                   {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->format = "%s";
			new->svalue = (char *) malloc(2 * sizeof(char));
			strcpy(new->svalue, "\n");
			new->next = NULL;
			$$ = new;
	        }
      ;

Printable : Expression              {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->format = "%.3f";
			new->svalue = NULL;
			new->value = $1;
			new->next = NULL;
			$$ = new;
		}
          | String                  {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->format = "%s";
			new->svalue = (char *) malloc((strlen($1) + 1) * sizeof(char));
			strcpy(new->svalue, $1);
			new->next = NULL;
			$$ = new;
		}
          | Printable Comma String {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->format = "%s";
			new->svalue = (char *) malloc((strlen($3) + 1) * sizeof(char));
			strcpy(new->svalue, $3);
			new->next = NULL;
			current = $1;
			while (current->next != NULL) current = current->next;
			current->next = new;
			$$ = $1;
		}
          | Printable Comma Expression {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->format = "%.3f";
			new->svalue = NULL;
			new->value = $3;
			new->next = NULL;
			current = $1;
			while (current->next != NULL) current = current->next;
			current->next = new;
			$$ = $1;
		}
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

void yyerror(char* error) {
    fprintf(stderr, "Erreur : %s\n", error);
    exit(1);
}

int main() {
    yyparse();
    return(0);
}
