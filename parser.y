%{
#include <iostream>
using namespace std;

// stuff from flex that bison needs to know about:
extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int yylineno;
extern const char *yytext;
 
void yyerror(const char *s);
%}

%union {
	int ival;
}


%type <ival> expr
%type <ival> term
%token <ival> INT


%%
statement:
	  statement expr ';'  {cout << $2 << endl; } 
	| expr ';' 	      {cout << $1 << endl; }
;
expr:
      expr '+' INT       { $$ = $1 + $3; }
    | term	          { $$ = $1; }
;
term:
      INT '+' INT     { $$ = $1 + $3;}
;
%%

int main(int, char**) {
	FILE *myfile = fopen("test.cal", "r");
	if (!myfile) {
		cout << "Invalid input file" << endl;
		return -1;
	}
	yyin = myfile;
	int val = yyparse();
	cout<< "yyparse value: " << val << endl;
}

void yyerror(const char *s) {
	cout << "DAMN IT! "<< s << " near " << yytext <<endl;
}
