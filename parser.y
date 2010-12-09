%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>
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
    int compile = 0;

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

%union { int ival; float fval; char cval; char * sval; struct _Instr * instr; int bval; int type; char ** ccval; }
%token <cval>  Char
%token <fval> fnumber
%token <ival> inumber
%token <sval> String ID
%type  <ival> IExpression
%type  <fval> FExpression vars var
%type  <bval> Boolean
%type  <instr> Print Printable stmt stmts main OUT
%type  <type> TYPE
%type  <ccval> ids

%token equals beg end print println EOL Comma IF THEN ELSE BEGI END THE_END gt ge lt le eq ne VAR INTEGER FLOAT STRING BOOLEAN column T F
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
		FILE * tmp = NULL;
		if (compile)
		{
			tmp = fopen("/tmp/.pascal.c", "w");
			fprintf(tmp, "#include <stdio.h>\nint\nmain()\n{\n");
		}
		while (current != NULL) {
			toFree = current;
			if (current->action == PRINT) {
				switch (current->type)
				{
				case STR:
					if (compile)
					{
					    fprintf(tmp, "\tprintf(\"");
					    unsigned int i;
					    for (i = 0 ; i<(strlen(current->value.s)) ; ++i)
					    {
						if (current->value.s[i] == '\n')
							fprintf(tmp, "%c%c", '\\', 'n');
						else
							fprintf(tmp, "%c", current->value.s[i]);
					    }
					    fprintf(tmp, "\");\n");
					}
					else
					    printf("%s", current->value.s);
					free(current->value.s);
					break;
				case FL:
				        if (compile)
					    fprintf(tmp, "\tprintf(\"%f\");\n", current->value.f);
					else
					    printf("%f", current->value.f);
					break;
				case INT:
					if (compile)
					    fprintf(tmp, "\tprintf(\"%d\");\n", current->value.i);
					else
					    printf("%d", current->value.i);
					break;
				case BOOL:
					if (compile)
					    fprintf(tmp, "\tprintf(\"%s\");\n", (current->value.b) ? "true" : "false");
					else
					    printf("%s", (current->value.b) ? "true" : "false");
					break;
				}
			}
			current = current->next;
			free(toFree);
		}
		free(vars);
		if (compile)
		{
			fprintf(tmp, "\treturn 0;\n}\n");
			fclose(tmp);
		}
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
     | ID AFFECT FExpression EOL {
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
     | ID AFFECT IExpression EOL {
     		$$ = NULL;
     		Var * var = getVar($1);
		if (var == NULL)
		{
			printf("No such var: %s\n", $1);
			return(1);
		}
		else if (var->type != INT && var->type != FL)
		{
			printf("%s is not an int nor a float\n", $1);
			return(1);
		}
		else if (var->type == FL)
			var->value.f = $3+0.;
		else
			var->value.i = $3;
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

Printable : FExpression              {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->value.f = $1;
			new->type = FL;
			new->next = NULL;
			$$ = new;
		}
          | IExpression                  {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = INT;
			new->value.i = $1;
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
          | Printable Comma FExpression {
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
          | Printable Comma IExpression {
	  		new = (Instr *) malloc(sizeof(Instr));
			new->action = PRINT;
			new->type = INT;
			new->value.i = $3;
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

Boolean    : FExpression gt FExpression { $$ = ($1 > $3); }
           | FExpression ge FExpression { $$ = ($1 >= $3); }
           | FExpression lt FExpression { $$ = ($1 < $3); }
           | FExpression le FExpression { $$ = ($1 <= $3); }
           | FExpression eq FExpression { $$ = ($1 == $3); }
           | FExpression ne FExpression { $$ = ($1 != $3); }
           | IExpression gt IExpression { $$ = ($1 > $3); }
	   | IExpression ge IExpression { $$ = ($1 >= $3); }
           | IExpression lt IExpression { $$ = ($1 < $3); }
           | IExpression le IExpression { $$ = ($1 <= $3); }
           | IExpression eq IExpression { $$ = ($1 == $3); }
           | IExpression ne IExpression { $$ = ($1 != $3); }
           | Boolean AND Boolean { $$ = ($1 && $3); }
           | Boolean OR Boolean { $$ = ($1 || $3); }
	   | beg Boolean end { $$ = $2; }
	   | T { $$ = 1; }
	   | F { $$ = 0; }
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

FExpression : fnumber                       { $$ = $1; }
            | FExpression plus FExpression  { $$ = $1 + $3; }
            | FExpression minus FExpression { $$ = $1 - $3; }
            | FExpression over FExpression  { $$ = $1 / $3; }
            | FExpression times FExpression { $$ = $1 * $3; }
            | beg FExpression end           { $$ = $2; }
            | minus FExpression %prec neg   { $$ = -$2; }
            | FExpression power FExpression { $$ = pow($1, $3); }
            | IExpression plus FExpression  { $$ = $1 + $3; }
            | IExpression minus FExpression { $$ = $1 - $3; }
            | IExpression over FExpression  { $$ = $1 / $3; }
            | IExpression times FExpression { $$ = $1 * $3; }
            | IExpression power FExpression { $$ = pow($1, $3); }
            | FExpression plus IExpression  { $$ = $1 + $3; }
            | FExpression minus IExpression { $$ = $1 - $3; }
            | FExpression over IExpression  { $$ = $1 / $3; }
            | FExpression times IExpression { $$ = $1 * $3; }
            | FExpression power IExpression { $$ = pow($1, $3); }
            ;

IExpression : inumber                       { $$ = $1; }
            | IExpression plus IExpression  { $$ = $1 + $3; }
            | IExpression minus IExpression { $$ = $1 - $3; }
            | IExpression over IExpression  { $$ = $1 / $3; }
            | IExpression times IExpression { $$ = $1 * $3; }
            | beg IExpression end           { $$ = $2; }
            | minus IExpression %prec neg   { $$ = -$2; }
            | IExpression power IExpression { $$ = pow($1, $3); }
            ;
%%

void yyerror(char * error) {
    fprintf(stderr, "Erreur : %s\n", error);
    yylex_destroy();
    exit(1);
}

int main(int argc, char ** argv) {
    switch(argc) {
    case 1: 
        break;
    case 2:
    	if (strcmp(argv[1], "--compile") == 0)
	    compile = 1;
	else
    	    yyin = fopen(argv[1], "r");
	break;
    case 3:
    	if (strcmp(argv[1], "--compile") == 0)
	{
	    compile = 1;
	    yyin = fopen(argv[2], "r");
	}
	else
	{
    	    yyin = fopen(argv[1], "r");
    	    if (strcmp(argv[2], "--compile") == 0)
	        compile = 1;
	}
	break;
    }
    yyparse();
    yylex_destroy();
    if (compile)
    {
	printf("Compiling your program to ./binary\n");
    	execl("/usr/bin/gcc", "/usr/bin/gcc", "/tmp/.pascal.c", "-o", "./binary", NULL);
    }
    return(0);
}
