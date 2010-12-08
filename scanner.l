BLANK [ \n\t]
DIGIT [0-9]
NUMBER {DIGIT}+\.?{DIGIT}*
ID [a-zA-Z_][a-zA-Z0-9_-]*
STRING \"[^\"]*\"
%{
	#include "y.tab.h"
%}

%%
"writeln" return(println);
"write" return(print);
"if" return(IF);
"then" return(THEN);
"else" return(ELSE);
"BEGIN" return(BEGI);
"END" return(END);
"END." return(THE_END);
"VAR" return(VAR);
"," return(Comma);
";" return(EOL);
"+" return(plus);
"-" return(minus);
"*" return(times);
"/" return(over);
"="  return(equals);
"(" return(beg);
")" return(end);
"^" return(power);
"&" return(AND);
"==" return(eq);
"!=" return(ne);
"|" return(OR);
">" return(gt);
">=" return(ge);
"<" return(lt);
"<=" return(le);
":=" return(AFFECT);
":" return(column);
"integer" return(INTEGER);
"float" return(FLOAT);
"string" return(STRING);
"boolean" return(BOOLEAN);
{NUMBER} {
    yylval.fval = atof(yytext);
    return(number);
}
{STRING} {
    yytext[yyleng-1] = '\0';
    yylval.cval = (char *) malloc(strlen(yytext) *  sizeof(char));
    strcpy(yylval.cval, yytext+1);
    return (String);
}
{ID} {
    yylval.cval = (char *) malloc((strlen(yytext) + 1) *  sizeof(char));
    strcpy(yylval.cval, yytext);
    yylval.cval[yyleng] = '\0';
    return (ID);
}
{BLANK}+ ;
. ;
