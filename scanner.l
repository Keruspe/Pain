BLANK [ \n\t]
DIGIT [0-9]
INUMBER {DIGIT}+
FNUMBER {DIGIT}+\.?{DIGIT}*
ID [a-zA-Z_][a-zA-Z0-9_-]*
STRING \"[^\"]*\"
CHAR \'\\?.\'
%{
    #include "y.tab.h"
%}

%%
"writeln"|"Writeln" return(println);
"write"|"Write" return(print);
"if"|"If" return(IF);
"then"|"Then" return(THEN);
"else"|"Else" return(ELSE);
"BEGIN"|"begin"|"Begin" return(BEGI);
"END"|"end"|"End" return(END);
"END."|"end."|"End." return(THE_END);
"VAR"|"var"|"Var" return(VAR);
"," return(Comma);
";" return(EOL);
"+" return(plus);
"-" return(minus);
"*" return(times);
"/" return(over);
"(" return(beg);
")" return(end);
"^" return(power);
"&" return(AND);
"="  return(eq);
"!=" return(ne);
"|" return(OR);
">" return(gt);
">=" return(ge);
"<" return(lt);
"<=" return(le);
"!" return (not);
":=" return(AFFECT);
":" return(column);
"integer"|"Integer" return(INTEGER);
"real"|"Real" return(FLOAT);
"string"|"String" return(STRING);
"boolean"|"Boolean" return(BOOLEAN);
"char"|"Char" return(CHAR);
"true"|"True"|"TRUE" return(T);
"false"|"False"|"FALSE" return(F);
{INUMBER} {
    yylval.ival = atoi(yytext);
    return(inumber);
}
{FNUMBER} {
    yylval.fval = atof(yytext);
    return(fnumber);
}
{CHAR} {
    yylval.cval=yytext[1];
    return(Char);
}
{STRING} {
    yytext[yyleng-1] = '\0';
    yylval.sval = (char *) malloc(yyleng *  sizeof(char));
    strcpy(yylval.sval, yytext+1);
    return (String);
}
{ID} {
    yylval.sval = (char *) malloc((yyleng + 1) *  sizeof(char));
    strcpy(yylval.sval, yytext);
    yylval.sval[yyleng] = '\0';
    return (ID);
}
"program"[^\n]*"\n"|"Program"[^\n]*"\n"|"PROGRAM"[^\n]*"\n";
"//"[^\n]*"\n" ;
"/\*"[^\*]*"\*/" ;
{BLANK}+ ;
. ;
