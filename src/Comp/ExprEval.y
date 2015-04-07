%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../SymTab/SymTab.h"
#include "../IOMngr/IOMngr.h"
#include "semantics.h"
#include "codegen.h"

int yylex(); /* The next token function. */
int yyerror(const char *);

extern struct SymTab *table;
extern struct SymEntry *entry;

%}

%glr-parser

%union {
  int val;
  char * string;
  struct ExprRes * ExprRes;
  struct InstrSeq * InstrSeq;
  struct BExprRes * BExprRes;
  struct VarType *vType;
  struct IdAddr *IdAddr;
}

%type <IdAddr> IdAddr
%type <vType> Ty
%type <vType> Type
%type <string> Id
%type <string> Str
%type <val> IntLit
%type <ExprRes> Factor
%type <ExprRes> Term
%type <ExprRes> ETerm
%type <ExprRes> NTerm
%type <ExprRes> Expr
%type <InstrSeq> StmtSeq
%type <InstrSeq> Stmt
%type <ExprRes> BExpr
%type <ExprRes> BHExpr
%type <ExprRes> OExpr
%type <ExprRes> AExpr
%type <ExprRes> FuncCall
%type <InstrSeq> PVarSeq
%type <InstrSeq> RVarSeq
%type <InstrSeq> RVar
%type <InstrSeq> FuncSeq
%type <InstrSeq> FuncDec

%token Func
%token Return
%token Id 
%token IntLit   
%token Int
%token Bool
%token Float
%token Str
%token NOT
%token OR
%token AND
%token True
%token False
%token Write
%token Writeln
%token Writesp
%token Read
%token While
%token IF
%token ELSE
%token EQ   
%token LT
%token LTE
%token GT
%token GTE
%token NE

%%

Prog            :   DecsCompl FuncSeq                                       {Finish($2); } ;
DecsCompl       :   Declarations                                            {doPushDecs();};
Declarations    :   Dec Declarations                                        { };
Declarations    :                                                           { };
Dec             :   Type Id ';'                                             {doDeclare($2, $1, 0, 1); };
Dec             :   Ty '[' IntLit ']' Id ';'                                {doDeclare($5, $1, 0, $3); };
FuncSeq         :   FuncDec FuncSeq                                         {$$ = AppendSeq($1, $2);};
FuncSeq         :                                                           {$$ = NULL;};
FuncDec         :   Type Id '(' Params ')' '{' DecsCompl                    {doFuncInit($2, $1);}
                    StmtSeq '}'                                             {$$ = doDecFunc($2, $9);};
Params          :   Param ',' Params                                        { };
Params          :   Param                                                   { };
Params          :                                                           { };
Param           :   Type Id                                                 {doDeclare($2, $1, 1, 1);};
StmtSeq         :   Stmt StmtSeq                                            {$$ = AppendSeq($1, $2); };
StmtSeq         :                                                           {$$ = NULL; };
Stmt            :   Return AExpr ';'                                        {$$ = doReturn($2);};
Stmt            :   FuncCall ';'                                            {$$ = doFuncInstrs($1);};
Stmt            :   While '(' AExpr ')' '{' StmtSeq '}'                     {$$ = doWhile($3, $6); };
Stmt            :   IF '(' AExpr ')' '{' StmtSeq '}'                        {$$ = doIf($3, $6);};
Stmt            :   IF '(' AExpr ')' '{' StmtSeq '}' ELSE '{' StmtSeq '}'   {$$ = doIfElse($3, $6, $10);};
Stmt            :   Read '(' RVarSeq ')' ';'                                {$$ = $3;};
Stmt            :   Writesp '(' AExpr ')' ';'                               {$$ = doPrintSp($3);};
Stmt            :   Writeln ';'                                             {$$ = doPrintLn();};
Stmt            :   Write '(' PVarSeq ')' ';'                               {$$ = $3;};
Stmt            :   IdAddr '=' AExpr ';'                                    {$$ = doAssign($1, $3, 0);};
RVarSeq         :   RVar ',' RVarSeq                                        {$$ = AppendSeq($1, $3);};
RVarSeq         :   RVar                                                    {$$ = $1;};
RVar            :   IdAddr                                                  {$$ = doRead($1);};
PVarSeq         :   AExpr ',' PVarSeq                                       {$$ = doPrintList($1, $3);};
PVarSeq         :   AExpr                                                   {$$ = doPrint($1);};
AExpr           :   AExpr AND OExpr                                         {$$ = doBoolOp($1, $3, B_AND); };
AExpr           :   OExpr                                                   {$$ = $1;};
OExpr           :   OExpr OR BHExpr                                         {$$ = doBoolOp($1, $3, B_OR); };
OExpr           :   BHExpr                                                  {$$ = $1;};
BHExpr          :   BHExpr EQ BExpr                                         {$$ = doComp($1, $3, B_EQ);};
BHExpr          :   BHExpr NE BExpr                                         {$$ = doComp($1, $3, B_NE);};
BHExpr          :   BExpr                                                   {$$ = $1;};
BExpr           :   BExpr LT Expr                                           {$$ = doComp($1, $3, B_LT);};
BExpr           :   BExpr LTE Expr                                          {$$ = doComp($1, $3, B_LTE);};
BExpr           :   BExpr GT Expr                                           {$$ = doComp($1, $3, B_GT);};
BExpr           :   BExpr GTE Expr                                          {$$ = doComp($1, $3, B_GTE);};
BExpr           :   Expr                                                    {$$ = $1;};
Expr            :   Expr '+' Term                                           {$$ = doArith($1, $3, '+'); };
Expr            :   Expr '-' Term                                           {$$ = doArith($1, $3, '-'); };
Expr            :   Term                                                    {$$ = $1; };
Term            :   Term '*' ETerm                                          {$$ = doArith($1, $3, '*'); };
Term            :   Term '/' ETerm                                          {$$ = doArith($1, $3, '/'); };
Term            :   Term '%' ETerm                                          {$$ = doArith($1, $3, '%'); };
Term            :   ETerm                                                   {$$ = $1; }
ETerm           :   NTerm '^' ETerm                                         {$$ = doPow($1, $3); };
ETerm           :   NTerm                                                   {$$ = $1; };
NTerm           :   '-' Factor                                              {$$ = doNegate($2); };
NTerm           :   Factor                                                  {$$ = $1; };
Factor          :   IntLit                                                  {$$ = doIntLit($1); };
Factor          :   '&' IdAddr                                              {$$ = doAddr($2);};
Factor          :   IdAddr                                                  {$$ = doRval($1); };
Factor          :   '(' AExpr ')'                                           {$$ = $2; };
Factor          :   NOT AExpr                                               {$$ = doNot($2);};
Factor          :   True                                                    {$$ = doBoolLit(B_TRUE);};
Factor          :   False                                                   {$$ = doBoolLit(B_FALSE);};
Factor          :   Str                                                     {$$ = doStrLit($1);};
Factor          :   FuncCall                                                {$$ = $1;};
FuncCall        :   Id '(' Args  ')'                                        {$$ = doCall($1);};
Args            :   Arg ',' Args                                            { };            
Args            :   Arg                                                     { };
Args            :                                                           { };
Arg             :   AExpr                                                   {doDecArg($1); };
IdAddr          :   Id                                                      {$$ = doIdAddr($1, 0);};
IdAddr          :   Id '[' AExpr ']'                                        {$$ = doDeRef(doIdAddr($1, 0), $3);};
IdAddr          :   '*' Id                                                  {$$ = doDeRef(doIdAddr($2, 0), NULL);};
Type            :   Ty '*'                                                  {  
                                                                                $$ = $1;
                                                                                $1->isRef = 1;
                                                                            };
                |   Ty '[' ']'                                              {
                                                                                $$ = $1;
                                                                                $1->isRef = 1;
                                                                            };
Type            :   Ty                                                      {$$ = $1;};
Ty              :   Bool                                                    {$$ = doVarType(T_BOOL);};
Ty              :   Int                                                     {$$ = doVarType(T_INT);};
 
%%

int yyerror(const char *s)  {
  WriteIndicator(GetCurrentColumn());
  WriteMessage("Illegal Character in YACC");
  return 1;
}
