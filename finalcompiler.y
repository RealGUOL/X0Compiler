%token  <ident> ID 
%token  <number> NUM NUM_C
%token  <number_d> NUM_D
%token  <type>  INT CHAR DOUBLE BOOL CONST
%token  PLUS MINUS TIMES SLASH EQL NEQ LES LEQ GTR GEQ MOD XOR ODD SPLUS SMINUS UMINUS AND OR NOT
%token  LPAREN RPAREN LBRACKETS RBRACKETS LBRACE RBRACE 
%token  COMMA SEMICOLON PERIOD BECOMES COLON
%token  MAIN IF ELSE WHILE WRITE READ DO CALL SWITCH CASE DEFAULT BREAK CONTINUE FOR REPEAT UNTIL EXIT

%type <number> var
%type <number> get_code_addr
%type <number> else_stat
%type <number> array_size
%type <number> array_loc
%type <type> type
%type <number> statement
%type <number> loop_stat_list

%right   ODD
%left    OR
%left    AND
%left    XOR
%left    PLUS MINUS
%left    TIMES SLASH MOD
%left    SPLUS SMINUS UMINUS 
%right NOT
%nonassoc ELSE


%{

#include <stdio.h>   
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "x0code.h"
#include <malloc.h>
void yyerror(char*);
void syntax_error(char* s);
int yylex(void);
FILE *yout;
FILE *yyin;
struct list* array_ids;
%}

%union{
char *ident;
int number;
double number_d;
void* ptr;
char *type;
struct databus* db;
}

%%
program:
    MAIN LBRACE     {
                        dx=3;             /* 三个空间用于存放静态链SL、动态链DL和返回地址RA  */
                        procReg.tx0=tx;   /* 记录本层标识符的初始位置 */
                        table[tx].adr=cx; /* 记录当前层代码的开始位置 */
                        gen(jmp,0,1);     /* 产生跳转指令，跳转位置已知填1 */
                    }
    const_list      {}
    declaration_list    {
                            code[table[procReg.tx0].adr].a=cx; /* 把前面生成的跳转语句的跳转位置改成当前位置 */
                            strcpy(table[procReg.tx0].name,"main");
                            table[procReg.tx0].kind=procedur;
                            table[procReg.tx0].type=none_t;
                            table[procReg.tx0].adr=cx;         /* 记录当前过程代码地址 */
                            table[procReg.tx0].size=dx;        /* 声明部分中每增加一条声明都会给dx增加1，声明部分已经结束，dx就是当前过程数据的size */
                            procReg.cx0=cx;                    /* 记录当前过程代码地址 */
                            gen(ini,0,dx);                     /* 生成指令，此指令执行时在数据栈中为被调用的过程开辟dx个单元的数据区 */
                        }
    statement_list      {
                            gen(opr,0,0);                      /* 每个过程出口都要使用的释放数据段指令 */
                        } 
    RBRACE {}
    ;

const_list:
    const_list const_dec {}
    |
    ;

const_dec:
    CONST INT ID BECOMES NUM  SEMICOLON     {
                                                type=int_t;         /* 整型标识符 */
                                                strcpy(id,$3);      /* 获得标识符的名字 */
                                                num=$5;             /* 记录标识符的值 */
                                                enter(constant);    /* 进入符号表 */
                                            } 
    |CONST DOUBLE ID BECOMES NUM_D  SEMICOLON   {
                                                    type=double_tt; /* 浮点型标识符 */
                                                    strcpy(id,$3);  /* 获得标识符的名字 */
                                                    num_d=$5;       /* 记录标识符的值 */
                                                    enter(constant);/* 进入符号表 */
                                                } 
    |CONST CHAR ID BECOMES NUM  SEMICOLON   {
                                                type=char_t;        /* char型标识符 */
                                                strcpy(id,$3);      /* 获得标识符的名字 */
                                                num=$5;             /* 记录标识符的值 */
                                                enter(constant);    /* 进入符号表 */
                                            } 
    |CONST BOOL ID BECOMES NUM SEMICOLON    {
                                                type=bool_t;        /* 布尔型标识符 */
                                                strcpy(id,$3);      /* 获得标识符的名字 */
                                                num=$5;             /* 记录标识符的值 */
                                                enter(constant);    /* 进入符号表 */
                                            }
    ;

declaration_list:
     declaration_list declaration_stat  {
                                            procReg.dx0=dx;          /* 记录当前数据分配的相对地址 */
                                        }
     | {}
     ;

declaration_stat:
    type ID array_size SEMICOLON    {
                                        /* 记录ID的类型 */
                                        if(strcmp($1,"int")==0){
                                            type=int_t;
                                        } else if(strcmp($1,"char")==0){
                                            type=char_t;
                                        }else if(strcmp($1,"bool")==0){
                                            type=bool_t;
                                        }else if(strcmp($1,"double")==0){
                                            type=double_tt;
                                        } else{
                                            type=none_t;
                                        }

                                        /* 进入符号表 */
                                        strcpy(id,$2);
                                        enter(variable);
                                        type=none_t;
                                    }
    ;

array_size:
    array_size LBRACKETS NUM RBRACKETS      {
                                                array=1;        /* array=1，表明是数组 */
                                                array_dim++;    /* 记录维度 */
                                                /* 记录每个维度大小 */
                                                array_size=list_add(array_size,$3);
                                            }
    |   {   
            array=0;
            array_dim=0;
            array_size=NULL;
        }
    ;
type:
    INT {$$=$1;}      /* 记录标识符具体type */
    |DOUBLE {$$=$1;}
    |CHAR {$$=$1;}
    |BOOL {$$=$1;}
    ;

var:
    ID  {
            int i = position ($1);    /* 符号表中查找变量 */
            if(i<=0){
                char s[50];
                sprintf(s,"variable %s undefined!", $1);
                syntax_error(s);
            }
            $$ = i;
            if(table[i].array){
                array_ids = list_add(array_ids,i);
                array_id = i;
            }
        }
    /*
    | ID LBRACKETS expression RBRACKETS     {
                                                $$ = position ($1);
                                            }
    */
    ;

statement_list:
    statement_list statement {}
    |statement {}
    ;

statement:
    if_stat {}
    |while_stat {}
    |read_stat {}
    |write_stat {}
    |compound_stat {}
    |expression_stat {}
    /*|switch_case_stat {}*/
    |for_stat {}
    |do_while_stat {}
    |repeat_until_stat {}
    |exit_stat {}
    |break_stat {}
    |continue_stat {}
    ;

exit_stat:
    EXIT SEMICOLON {gen(ext,0,0);}
    ;

break_stat:
    BREAK SEMICOLON {
                        loop_pos++;
                        if(loop_pos>=LOOPMAX){
                            syntax_error("too many breaks or continues.");
                        }
                        loopReg[loop_pos].cx=cx;    /* 记录当前层代码开始地址 */
                        loopReg[loop_pos].type=brk; /* 记录是否跳出循环 */
                        loopReg[loop_pos].level=loop_level;
                        gen(jmp,0,0);  /* 产生跳转指令，跳转位置未知添0 */
                    }
    ;

continue_stat:
    CONTINUE SEMICOLON      {
                                loop_pos++;
                                if(loop_pos>=LOOPMAX){
                                    syntax_error("too many breaks or continues.");
                                }
                                loopReg[loop_pos].cx=cx;
                                loopReg[loop_pos].type=ctn;
                                loopReg[loop_pos].level=loop_level;
                                gen(jmp,0,0);/* 产生跳转指令，跳转位置未知填0 */
                            }
    ;

for_stat:
    FOR LPAREN for_exp1 SEMICOLON get_code_addr for_exp2 SEMICOLON get_code_addr    {
                                                                                            if(loop_level==0){
                                                                                                loop_pos=-1;
                                                                                            }
                                                                                            loop_level++;
                                                                                            gen(jpc,0,0);
                                                                                            gen(jmp,0,0);
                                                                                    }
    for_exp3    {
                    gen(jmp,0,$5);
                }
    RPAREN get_code_addr loop_stat_list {
                                            gen(jmp,0,$8+2);
                                            code[$8].a=cx;
                                            code[$8+1].a=$13;
                                            int i;
                                            for(i=0;i<=loop_pos;i++)
                                            {
                                                if(loopReg[i].level==loop_level){
                                                    switch(loopReg[i].type){
                                                        case brk:
                                                            code[loopReg[i].cx].a=cx;  /*跳转地址回填*/
                                                            break;
                                                        case ctn:
                                                            code[loopReg[i].cx].a=$8+2; /*跳转地址回填*/
                                                            break;
                                                    }
                                                }
                                            }
                                            loop_level--;

                                        }
    ;

for_exp1:
    expression  {}
    |   {}
    ;

for_exp2:
    simple_expr  {}
    |   {}
    ;

for_exp3:
    expression  {}
    |   {}
    ;

loop_stat_list:
    statement  {}
    ;

do_while_stat:
    DO  get_code_addr   {
                            if(loop_level==0)
                            {
                                loop_pos=-1;
                            }
                            loop_level++;
                        } 
    do_while_stat_list WHILE get_code_addr LPAREN simple_expr RPAREN SEMICOLON get_code_addr   {
                                                                                                                    gen(jpc,0,$11+2);
                                                                                                                    gen(jmp,0,$2);

                                                                                                                    int i;
                                                                                                                    for(i=0;i<=loop_pos;i++)
                                                                                                                    {
                                                                                                                        if(loopReg[i].level==loop_level){
                                                                                                                            switch(loopReg[i].type){
                                                                                                                                case brk:
                                                                                                                                    code[loopReg[i].cx].a=cx;
                                                                                                                                    break;
                                                                                                                                case ctn:
                                                                                                                                    code[loopReg[i].cx].a=$6;
                                                                                                                                    break;
                                                                                                                            }
                                                                                                                        }
                                                                                                                    }
                                                                                                                    loop_level--;
                                                                                                                }
    ;

do_while_stat_list:
    statement  {}
    ;

repeat_until_stat:
    REPEAT  get_code_addr   {
                                if(loop_level==0)
                                {
                                    loop_pos=-1;
                                }
                                loop_level++;
                            }
    repeat_until_stat_list UNTIL get_code_addr LPAREN simple_expr RPAREN SEMICOLON     {
                                                                                                                gen(jpc,0,$2);

                                                                                                                int i;
                                                                                                                for(i=0;i<=loop_pos;i++)
                                                                                                                {
                                                                                                                    if(loopReg[i].level==loop_level){
                                                                                                                        switch(loopReg[i].type){
                                                                                                                            case brk:
                                                                                                                                code[loopReg[i].cx].a=cx;
                                                                                                                                break;
                                                                                                                            case ctn:
                                                                                                                                code[loopReg[i].cx].a=$6;
                                                                                                                                break;
                                                                                                                        }
                                                                                                                    }
                                                                                                                }
                                                                                                                loop_level--;

                                                                                                            }
    ;

repeat_until_stat_list:
    statement  {}
    ;
/*switch_case_stat:
    SWITCH LPAREN expression RPAREN LBRACE case_list default_stat RBRACE {}
    ;

case_list:
    case_list CASE expression COLON statement_list {}
    ;

default_stat:
    DEFAULT COLON statement_list {}
    ;
*/
if_stat:
    IF LPAREN expression RPAREN get_code_addr   {
                                                    gen(jpc, 0, 0);
                                                } 
    statement else_stat   {
                    code[$5].a = $8;
                }
    ;

else_stat:
    ELSE get_code_addr  {
                            gen(jmp,0,0);
                        } 
    statement   {
                    $$=$2+1;
                    code[$2].a=cx;
                }
    |   {
            $$ = cx;
        }
    ;

while_stat:
    WHILE   get_code_addr   {
                                if(loop_level==0)
                                {
                                    loop_pos=-1;
                                }
                                loop_level++;
                            } 
    LPAREN expression RPAREN get_code_addr  {
                                                gen(jpc, 0 , 0);
                                            }
    statement   {
                    gen(jmp, 0, $2);
                    code[$7].a = cx;

                    int i;
                    for(i=0;i<=loop_pos;i++)
                    {
                        if(loopReg[i].level==loop_level){
                            switch(loopReg[i].type){
                                case brk:
                                    code[loopReg[i].cx].a=cx;
                                    break;
                                case ctn:
                                    code[loopReg[i].cx].a=$2;
                                    break;
                            }
                        }
                    }
                    loop_level--;
                }
    ;

write_stat:
    WRITE expression SEMICOLON  {
                                    gen(opr,0,14);
                                }
    |WRITE var SEMICOLON        {
                                    if(table[$2].kind==constant){
                                        if(table[$2].type==double_tt){
                                            _gen(lit,0,0,1,table[$2].val_d);
                                        }else{
                                            gen(lit,0,table[$2].val);
                                        }
                                    }else if(table[$2].kind==variable){
                                        gen(lod,0,table[$2].adr);
                                    }
                                    if(table[$2].type==char_t)
                                        gen(opr,0,17);
                                    else if(table[$2].type==int_t)
                                        gen(opr,0,14);
                                    else if(table[$2].type==bool_t)
                                        gen(opr,0,25);
                                    else if(table[$2].type==double_tt)
                                        gen(opr,0,14);
                                    else
                                        error(0); 
                                }   
    ;

array_loc:
    array_loc LBRACKETS expression RBRACKETS        {
                                                        int id=list_get_last(array_ids);
                                                        int dim_id=$1;
                                                        $$=dim_id+1;  
                                                        if(dim_id+1>table[id].array_dim){
                                                            char s[50];
                                                            sprintf(s,"dimension of array %s is %d, gived %d.", table[id].name, table[id].array_dim, dim_id);
                                                            syntax_error(s);
                                                        }
                                                        int p=list_get_product_after_id(table[id].array_size, dim_id);
                                                        gen(lit,0,p);
                                                        gen(opr,0,4);
                                                        if(dim_id>=1){
                                                            gen(opr,0,2);
                                                        }

                                                    }
    |   {$$=0;}
    ;

read_stat:
    READ var array_loc SEMICOLON    {
                                        if(table[$2].kind==constant){
                                            syntax_error("constant cannot be read.");
                                        }else{
                                            if($3>=1){
                                                gen(lit,0,table[$2].adr);
                                                gen(opr,0,2);
                                                if(table[$2].type==double_tt){
                                                    _gen(opr,0,16,1,0.0);
                                                }else{
                                                    gen(opr,0,16);
                                                }
                                                gen(sto,0,0);
                                            }else{
                                                if(table[$2].type==double_tt){
                                                    _gen(opr,0,16,1,0.0);
                                                }else{
                                                    gen(opr,0,16);
                                                }
                                                gen(sto,0,table[$2].adr);
                                            }
                                        }
                                    }
    ;

compound_stat:
    LBRACE statement_list RBRACE {}
    ;

expression_stat: 
    expression SEMICOLON {}
    | SEMICOLON {}
    ;

expression:
    var array_loc   {
                        if(table[$1].kind==constant){
                            syntax_error("constant cannot be writen.");
                        }else{
                            if($2>=1){
                                gen(lit,0,table[$1].adr);
                                gen(opr,0,2);
                            }
                        }
                    }
    BECOMES expression    {
                            if($2>=1){
                                gen(sto,0,0);
                            }else{
                                gen(sto,0,table[$1].adr);
                                gen(lod,0,table[$1].adr);
                            }
                        }
    | simple_expr {}
    ;

simple_expr:
    additive_expr {}
    | additive_expr GTR additive_expr   {
                                            gen(opr,0,12);
                                        }
    | additive_expr LES additive_expr   {
                                            gen(opr,0,10);
                                        }
    | additive_expr GEQ additive_expr   {
                                            gen(opr,0,11);
                                        }
    | additive_expr LEQ additive_expr   {
                                            gen(opr,0,13);
                                        }
    | additive_expr EQL additive_expr   {
                                            gen(opr,0,8);
                                        }
    | additive_expr NEQ additive_expr   {
                                            gen(opr,0,9);
                                        }
    | additive_expr AND additive_expr   {
                                            gen(opr,0,22);
                                        }
    | additive_expr OR additive_expr    {
                                            gen(opr,0,23);
                                        }
    |NOT additive_expr                  {
                                            gen(opr,0,24);
                                        }                                    
    ;

/*
condition:
    additive_expr GTR additive_expr     {
                                            gen(opr,0,12);
                                        }
    | additive_expr LES additive_expr   {
                                            gen(opr,0,10);
                                        }
    | additive_expr GEQ additive_expr   {
                                            gen(opr,0,11);
                                        }
    | additive_expr LEQ additive_expr   {
                                            gen(opr,0,13);
                                        }
    | additive_expr EQL additive_expr   {
                                            gen(opr,0,8);
                                        }
    | additive_expr NEQ additive_expr   {
                                            gen(opr,0,9);
                                        }
    ;
*/

additive_expr:
    term  {}
    |additive_expr PLUS term    {
                                    gen(opr,0,2);
                                }
    |additive_expr MINUS term   {
                                    gen(opr,0,3);
                                }
    ;

term:
    factor      {   

                }
    |term TIMES factor  {
                            gen(opr,0,4);
                        }
    |term SLASH factor  {
                            gen(opr,0,5);
                        }
    |term MOD factor    {
                            gen(opr,0,20);
                        }
    |term XOR factor    {
                            gen(opr,0,21);
                        }
    |ODD factor         {
                            gen(opr,0,6);
                        }
    ;

factor:
    LPAREN expression RPAREN {}
    |var  array_loc {
                        switch(table[$1].kind){
                            case constant:
                                if($2>=1){
                                    syntax_error("constant have no index.");
                                }
                                if(table[$1].type==double_tt){
                                    _gen(lit,0,0,1,table[$1].val_d);
                                }else{
                                    gen(lit,0,table[$1].val);
                                }
                                break;
                            case variable:
                                if($2>=1){
                                    if(!table[$1].array){
                                        char s[50];
                                        sprintf(s,"variable %s is not an array.", table[$1].name);
                                        syntax_error(s);
                                    }
                                    gen(lit,0,table[$1].adr);
                                    gen(opr,0,2);
                                    gen(lod,0,0);
                                    list_del_last(array_ids);
                                }else{
                                    gen(lod,0,table[$1].adr);
                                }
                                break;
                            case procedur:
                                syntax_error("procedur is not supported yet.");
                                break;
                            }
                    }
    |var SPLUS  {
                    if(table[$1].array==0){
                        gen(lod,0,table[$1].adr);
                        gen(lod,0,table[$1].adr);
                        gen(lit,0,1);
                        gen(opr,0,2);
                        gen(sto,0,table[$1].adr);
                    }else{
                        char s[50];
                        sprintf(s,"%s is an array, not a simple variable.", table[$1].name);
                        syntax_error(s);
                    }
                }
    |var SMINUS {
                    if(table[$1].array==0){
                        gen(lod,0,table[$1].adr);
                        gen(lod,0,table[$1].adr);
                        gen(lit,0,1);
                        gen(opr,0,3);
                        gen(sto,0,table[$1].adr);
                    }else{
                        char s[50];
                        sprintf(s,"%s is an array, not a simple variable.", table[$1].name);
                        syntax_error(s);
                    }
                }
    |SPLUS var  {
                    if(table[$2].array==0){
                        gen(lod,0,table[$2].adr);
                        gen(lit,0,1);
                        gen(opr,0,2);
                        gen(sto,0,table[$2].adr);
                        gen(lod,0,table[$2].adr);
                    }else{
                        char s[50];
                        sprintf(s,"%s is an array, not a simple variable.", table[$2].name);
                        syntax_error(s);
                    }
                }
    |SMINUS var {
                    if(table[$2].array==0){
                        gen(lod,0,table[$2].adr);
                        gen(lit,0,1);
                        gen(opr,0,3);
                        gen(sto,0,table[$2].adr);
                        gen(lod,0,table[$2].adr);
                    }else{
                        char s[50];
                        sprintf(s,"%s is an array, not a simple variable.", table[$2].name);
                        syntax_error(s);
                    }
                }
    |NUM    {
                int num;
                num=$1;
                if(num>AMAX){
                    char s[100];
                    sprintf(s,"integer(%d) should not greater than %d, now 0 instead. ", $1, AMAX);
                    syntax_error(s);
                    num=0;
                    }
                gen(lit,0,num);
            }
    |NUM_D  {
                num_d=$1;
                _gen(lit,0,0,1,$1);
            }
    ;

/*
get_table_addr:
               {
                $$ = tx;
               } 
          ;
*/
get_code_addr:
               {
                $$ = cx;
               }
          ;
%%


void yyerror(char *s){
    err++;
    printf("%s in line %d\n",s,line);
    fprintf(ferrout,"%s in line %d\n",s,line);
}

int compile(const char* filePath)
{
    int i;
    listswitch=true;
    int print_table=1;
    yyin = fopen(filePath,"r");

    printf("x0 compiler\n");
    if((ferrout=fopen("ferrout.txt","w"))==NULL){
        printf("Cann't open file!\n");
        exit(0);
    }
    if((fcode=fopen("fcode.txt","w"))==NULL){
        printf("Cann't open fcode.txt file!\n");
        exit(0);
    }
    if((fresult=fopen("fresult.txt","w"))==NULL){
        printf("Cann't open fresult.txt file!\n");
        exit(0);
    }
    if((ftable=fopen("ftable.txt","w"))==NULL){
        printf("Cann't open ftable.txt file!\n");
        exit(0);
    }
    yyparse();
    if(err==0)
    {
        listcode();
        interpret();
    }
    else
        printf("%d errors in PL/0 program\n",err);
    if(print_table){
        printTable(0);
    }
    fclose(fcode);
    fclose(ferrout);
    fclose(ftable);
    return 0;
}