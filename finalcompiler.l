%{ 

#include "finalcompiler.tab.h"
#include <stdio.h>
#include <string.h>
#include <malloc.h>
int line = 0;
char msg[50];
int yywrap();
void yyerror(char*);
%} 


whitespace  ([ \t\n])+
ID          [a-zA-Z_]([a-zA-Z_]|[0-9])*
NUM         ([0-9])+

%% 
[ \t]	{;}
\n		{line++;}
\r\n	{line++;}
"/*"([^\*]|(\*)*[^\*/])*(\*)*"*/" 	{
										char* c = yytext;
										while(*c!='\0'){
											if(*c=='\n'){
												line++;
											}
											c++;
										}
									}
"+"     {return PLUS;}
"-"     {return MINUS;}
"*"     {return TIMES;}
"/"     {return SLASH;}

"%"     {return MOD;}
"^"     {return XOR;}

"++"		{return SPLUS;}
"--"		{return SMINUS;}

"=="       {return EQL;}
"!="       {return NEQ;}
"<"       {return LES;}
"<="       {return LEQ;}
">"       {return GTR;}
">="       {return GEQ;}
"("    {return LPAREN;}
")"    {return RPAREN;}
"[" {return LBRACKETS;}
"]" {return RBRACKETS;}
"{"    {return LBRACE;}
"}"    {return RBRACE;}
","     {return COMMA;}
";" {return SEMICOLON;}
":"		{return COLON;}
"."    {return PERIOD;}
"="   {return BECOMES;}

"odd"|"ODD"	{return ODD;}
"switch"	{return SWITCH;}
"case"		{return CASE;}
"default"	{return DEFAULT;}
"break"		{return BREAK;}
"continue"	{return CONTINUE;}
"main"     {return MAIN;}
"const"		{return CONST;}
"true"		{yylval.number=1;return NUM;}
"false"		{yylval.number=0;return NUM;}
"if"     {return IF;}
"else"   {return ELSE;}
"while"  {return WHILE;}
"for"		{return FOR;}
"do"		{return DO;}
"repeat"	{return REPEAT;}
"until"		{return UNTIL;}
"write"  {return WRITE;}
"read"   {return READ;}
"call"   {return CALL;}
"exit"		{return EXIT;}
"int"      	{	
				yylval.type = (char *)malloc(strlen(yytext)+1);
				strcpy(yylval.type,yytext);
				return INT;
			}
"double"    {	
				yylval.type = (char *)malloc(strlen(yytext)+1);
				strcpy(yylval.type,yytext);
				return DOUBLE;
			}

"char"      {	
				yylval.type = (char *)malloc(strlen(yytext)+1);
				strcpy(yylval.type,yytext);
				return CHAR;
			}
"bool"      {	
				yylval.type = (char *)malloc(strlen(yytext)+1);
				strcpy(yylval.type,yytext);
				return BOOL;
			}
"and"		{return AND;}
"or"		{return OR;}
"not"		{return NOT;}

[0-9]+[.][0-9]+		{
						yylval.number_d=atof(yytext);
						return NUM_D;
					}

'[^'\n]'	{
				yylval.number=(int)(yytext[1]);
				return NUM;
			}

"'\\n'"		{
				yylval.number='\n';
				return NUM;
			}

"'\\t'"		{
				yylval.number='\t';
				return NUM;
			}

{ID}        {
				yylval.ident=(char *)malloc(strlen(yytext)+1);
				strcpy(yylval.ident,yytext);
				return ID;
			}

{NUM}       {
				yylval.number=atoi(yytext);
				return NUM;
			}

.           {   
				sprintf(msg,"yyerror: unexpected character %s",yytext);
                yyerror(msg);
            }

%% 

int yywrap(void) 
{
    return 1; 
}
