%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <math.h>
    void yyerror(char* error);
    extern int yylex (void);

    typedef enum {
	PRINT,
	AFF,
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

    typedef enum {
	STR,
	FL,
	INT,
	BOOL
    } Type;

    typedef struct {
	char * name;
	Type type;
	union {
		char * s;
		float f;
		int i;
		int b;
	} value;
    } Var;

    Instr * current = NULL;
    Instr * new;

    char ** var_names = NULL;
    int var_names_number = 0;
    Var * vars = NULL;
    int vars_number = 0;
%}

%expect 1

%union { float fval; char * cval; struct _Instr * instr; int bval; int type; char ** ccval; }
%token <fval> number
%token <cval> String ID
%type  <fval> Expression vars var
%type  <bval> Boolean
%type  <instr> Print Printable stmt stmts main OUT
%type  <type> TYPE
%type  <ccval> ids

%token equals beg end print println EOL Comma IF THEN ELSE BEGI END THE_END gt ge lt le eq ne VAR AFFECT INTEGER FLOAT STRING BOOLEAN column
%left  AND OR
%left  plus minus
%left  times over
%left  neg
%right power

%start OUT

%%

OUT    : main
       | VAR vars main { $$ = NULL; }
       ;

vars   : var
       | vars var
       ;

var    : ids column TYPE EOL { 
			int i;
			for (i = 0 ;  i < var_names_number ; ++i)
			{
				if ((vars_number % 10) == 0)
					vars = (Var *) realloc(vars, (10 + vars_number) * sizeof(Var));
				Var var;
				var.name = var_names[i];
				var.type = $3;
				vars[vars_number++] = var;
			}
			free(var_names);
			var_names = NULL;
			var_names_number = 0;
		}
       ;

ids    : ID {
		if ((var_names_number % 10) == 0)
			var_names = (char **) realloc(var_names, (10 + var_names_number) * sizeof(char *));
		var_names[var_names_number++] = $1;
		$$ = var_names;
	    }
       | ids Comma ID {
		if ((var_names_number % 10) == 0)
			var_names = (char **) realloc(var_names, (10 + var_names_number) * sizeof(char *));
		var_names[var_names_number++] = $3;
		$$ = var_names;
            }
       ;

TYPE   : INTEGER { $$ = INT; }
       | FLOAT { $$ = FL; }
       | STRING { $$ = STR; }
       | BOOLEAN { $$ = BOOL; }
       ;

main   : BEGI stmts THE_END {
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
			}
			current = current->next;
			free(toFree);
		}
		int i;
		Var var;
		printf("\nVars:\n");
		for (i = 0 ; i < vars_number ; ++i)
		{
			var = vars[i];
			printf("%s: ", var.name);
			free(var.name);
			switch (var.type)
			{
			case INT:
				printf("int");
				break;
			case FL:
				printf("float");
				break;
			case STR:
				printf("string");
				break;
			case BOOL:
				printf("bool");
				break;
			}
			printf("\n");
		}
		free(vars);
		exit(0);
	   }
      | BEGI THE_END { exit(0);}
      ;

stmts : stmt { $$ = $1; }
      | stmts stmt {
			if ($1 == NULL)
				$$ = $2;
			else
			{
				current = $1;
				while (current->next != NULL) current = current->next;
				current->next = $2;
				$$ = $1;
			}
      	   }
      ;

stmt : Print EOL { $$ = $1; }
     | IF Boolean THEN stmt {
                if ($2)
			$$ = $4;
		else
		{
			current = $4;
			Instr * toFree;
			while (current != NULL)
			{
				toFree = current;
				current = current->next;
				free(toFree);
			}
			$$ = NULL;
		}
	   }
     | IF Boolean THEN stmt ELSE stmt {
     		Instr * toFree;
		if ($2)
		{
			current = $6;
			$$ = $4;
		}
		else
		{
			current = $4;
			$$ = $6;
		}
		while (current != NULL)
		{
			toFree = current;
			current = current->next;
			free(toFree);
		}
 	    }
     | BEGI stmts END { $$ = $2; }
     ;

Print : print beg Printable end           { $$ = $3; }
      | println beg Printable end         {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->format = "%s";
			new->svalue = (char *) malloc(2 * sizeof(char));
			strcpy(new->svalue, "\n");
			new->next = NULL;
			current = $3;
			while (current->next != NULL) current = current->next;
			current->next = new;
			$$ = $3;
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
			new->svalue = $1;
			new->next = NULL;
			$$ = new;
		}
          | Printable Comma String {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->format = "%s";
			new->svalue = $3;
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

Boolean    : Expression gt Expression { $$ = ($1 > $3); }
           | Expression ge Expression { $$ = ($1 >= $3); }
           | Expression lt Expression { $$ = ($1 < $3); }
           | Expression le Expression { $$ = ($1 <= $3); }
           | Expression eq Expression { $$ = ($1 == $3); }
           | Expression ne Expression { $$ = ($1 != $3); }
           | Boolean AND Boolean { $$ = ($1 && $3); }
           | Boolean OR Boolean { $$ = ($1 || $3); }
	   | beg Boolean end { $$ = $2; }
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
