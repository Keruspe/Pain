%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <math.h>
    void yyerror(char* error);
    extern int yylex (void);
    extern int yylex_destroy(void);
    extern FILE * yyin;

    typedef enum {
	PRINT,
	AFF,
	NONE
    } Action;

    typedef union {
	char * s;
	float f;
	int i;
	int b;
    } Value;

    typedef enum {
	STR,
	FL,
	INT,
	BOOL
    } Type;

    typedef struct _Instr Instr;
    struct _Instr {
	Instr * next;
	Action action;
	Type type;
	Value value;
    };

    typedef struct {
	char * name;
	Type type;
	Value value;
    } Var;

    Instr * current = NULL;
    Instr * new;

    char ** var_names = NULL;
    int var_names_number = 0;
    Var * vars = NULL;
    int vars_number = 0;

    int varNameExists(char * name)
    {
	int i;
	for (i = 0 ; i < var_names_number ; ++i)
	{
		if (strcmp(name, var_names[i]) == 0)
			return 1;
	}
	for (i = 0 ;  i < vars_number ; ++i)
	{
		if (strcmp(name, vars[i].name) == 0)
			return 1;
	}
	return 0;
    }

    Var * getVar(char * id) {
	int i;
	Var * var;
	for (i=0 ; i < vars_number ; ++i)
	{
		var = &(vars[i]);
		if (strcmp(var->name, id) == 0)
			return var;
	}
	return NULL;
    }
%}

%expect 2

%union { float fval; char * cval; struct _Instr * instr; int bval; int type; char ** ccval; }
%token <fval> number
%token <cval> String ID
%type  <fval> Expression vars var
%type  <bval> Boolean
%type  <instr> Print Printable stmt stmts main OUT
%type  <type> TYPE
%type  <ccval> ids

%token equals beg end print println EOL Comma IF THEN ELSE BEGI END THE_END gt ge lt le eq ne VAR INTEGER FLOAT STRING BOOLEAN column
%left  AND OR
%right AFFECT
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
		if (varNameExists($1) == 1)
		{
			printf("%s already exists !\n", $1);
			return(1);
		}
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
				switch (current->type)
				{
				case STR:
					printf("%s", current->value.s);
					free(current->value.s);
					break;
				case FL:
					printf("%f", current->value.f);
					break;
				case INT:
					printf("%d", current->value.i);
					break;
				case BOOL:
					printf("%s", (current->value.b) ? "true" : "false");
					break;
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
		return(0);
	   }
      | BEGI THE_END { return(0);}
      ;

stmts : stmt { $$ = $1; }
      | stmts stmt {
      			current = $1;
			if (current == NULL)
				$$ = $2;
			else
			{
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
				if (toFree->type == STR)
					free(toFree->value.s);
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
			if (toFree->type == STR)
				free(toFree->value.s);
			current = current->next;
			free(toFree);
		}
 	    }
     | BEGI stmts END { $$ = $2; }
     | ID AFFECT Expression EOL {
     		$$ = NULL;
     		Var * var = getVar($1);
		if (var == NULL)
		{
			printf("No such var: %s\n", $1);
			return(1);
		}
		else if (var->type != FL)
		{
			printf("%s is not a float\n", $1);
			return(1);
		}
		else
			var->value.f = $3;
	   }
     | ID AFFECT Boolean EOL {
     		$$ = NULL;
     		Var * var = getVar($1);
		if (var == NULL)
		{
			printf("No such var: %s\n", $1);
			return(1);
		}
		else if (var->type != BOOL)
		{
			printf("%s is not a boolean\n", $1);
			return(1);
		}
		else
			var->value.b = $3;
	   }
     | ID AFFECT String EOL {
     		$$ = NULL;
     		Var * var = getVar($1);
		if (var == NULL)
		{
			printf("No such var: %s\n", $1);
			return(1);
		}
		else if (var->type != STR)
		{
			printf("%s is not a string\n", $1);
			return(1);
		}
		else
			var->value.s = $3;
	   }
     | ID AFFECT ID EOL {
     		$$ = NULL;
     		Var * var = getVar($1);
		Var * var2  =  getVar($3);
		if (var == NULL)
		{
			printf("No such var: %s\n", $1);
			return(1);
		} 
		else if (var2 == NULL)
		{
			printf("No such var: %s\n", $3);
			return(1);
		}
		else if (var->type != var2->type)
		{
			printf("%s and %s have not the same type\n", $1, $3);
			return(1);
		}
		else
		{
			switch (var->type)
			{
			case STR:
				var->value.s = var2->value.s;
				break;
			case FL:
				var->value.f = var2->value.f;
				break;
			case INT:
				var->value.i = var2->value.i;
				break;
			case BOOL:
				var->value.b = var2->value.b;
				break;
			}
		}
	   }
     ;

Print : print beg Printable end           { $$ = $3; }
      | println beg Printable end         {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = STR;
			new->value.s = (char *) malloc(2 * sizeof(char));
			strcpy(new->value.s, "\n");
			new->next = NULL;
			current = $3;
			while (current->next != NULL) current = current->next;
			current->next = new;
			$$ = $3;
      		}
      | println beg end                   {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = STR;
			new->value.s = (char *) malloc(2 * sizeof(char));
			strcpy(new->value.s, "\n");
			new->next = NULL;
			$$ = new;
	        }
      ;

Printable : Expression              {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->value.f = $1;
			new->type = FL;
			new->next = NULL;
			$$ = new;
		}
          | String                  {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = STR;
			new->value.s = $1;
			new->next = NULL;
			$$ = new;
		}
          | ID                 {
	  		Var * var = getVar($1);
			if (var == NULL)
			{
				printf("No such var: %s\n", $1);
				return(1);
			}
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = var->type;
			new->value = var->value;
			new->next = NULL;
			$$ = new;
		}
          | Printable Comma String {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = STR;
			new->value.s = $3;
			new->next = NULL;
			current = $1;
			while (current->next != NULL) current = current->next;
			current->next = new;
			$$ = $1;
		}
          | Printable Comma Expression {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = FL;
			new->value.f = $3;
			new->next = NULL;
			current = $1;
			while (current->next != NULL) current = current->next;
			current->next = new;
			$$ = $1;
		}
          | Printable Comma ID {
	  		Var * var = getVar($3);
			if (var == NULL)
			{
				printf("No such var: %s\n", $3);
				return(1);
			}
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = var->type;
			new->value = var->value;
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
           | ID {
     		Var * var = getVar($1);
		if (var == NULL)
		{
			printf("No such var: %s\n", $1);
			return(1);
		}
		else if (var->type != BOOL)
		{
			printf("%s is not a boolean\n", $1);
			return(1);
		}
		else
			$$ = var->value.b;
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

void yyerror(char * error) {
    fprintf(stderr, "Erreur : %s\n", error);
    yylex_destroy();
    exit(1);
}

int main(int argc, char ** argv) {
    ++argv; --argc;
    if (argc > 0)
    	yyin = fopen(argv[0], "r");
    else
        yyin = stdin;
    yyparse();
    yylex_destroy();
    return(0);
}
