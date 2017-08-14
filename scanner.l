%{
#include <iostream>
using namespace std;
#define YY_DECL extern int yylex()
#include "parser.hpp"  // to get the token types that we return
%}
%%

[ \t]
\n		  { yylineno++; }
[0-9]+            { yylval.ival = atoi(yytext); return INT; }
[;+]		  { return yytext[0]; }
.                ;
%%
