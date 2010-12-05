BLANK [ \n\t]
DIGIT [0-9]
NUMBER {DIGIT}+\.?{DIGIT}*

%%
\+ return(plus);
\- return(minus);
\* return(times);
\/ return(over);
=  return(equals);
\( return(beg);
\) return(end);
\^ return(power);
e  return(expo);
{NUMBER} {
    yylval.fval = atof(yytext);
    return(number);
}
{BLANK}+ ;
. fprintf(stderr, "Caractère (%c) non reconnu.\n", yytext[0]);
