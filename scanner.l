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
"begin" return(BEGI);
"end" return(END);
"end." return(THE_END);
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
{NUMBER} {
    yylval.fval = atof(yytext);
    return(number);
}
{STRING} {
    yytext[yyleng-1] = '\0';
    ++yytext;
    yylval.cval = yytext;
    return (String);
}
{ID} {
    yylval.cval = yytext;
    return (ID);
}
{BLANK}+ ;
. ;
