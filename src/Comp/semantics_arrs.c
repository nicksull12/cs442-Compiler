#include "semantics.h"

struct InstrSeq*
doReadArr( char* name, struct ExprRes* Pos )
{
    struct ExprRes* res = malloc( sizeof( struct ExprRes ) );
    res->Reg = AvailTmpReg();
    res->Instrs = GenInstr( NULL, "li", "$v0", "5", NULL );
    res->Type = doVarType(T_ANY);
    AppendSeq( res->Instrs, GenInstr( NULL, "syscall", NULL, NULL, NULL ) );
    AppendSeq( res->Instrs, GenInstr( NULL, "move",
                                TmpRegName( res->Reg ),
                                "$v0", NULL ) );
    return doAssignArr( name, res, Pos );
}

struct InstrSeq*
doAssignArr( char* name, struct ExprRes* Expr, struct ExprRes* Pos )
{
    char buf[ 50 ];
    int reg_addr = AvailTmpReg();
    struct InstrSeq* code;
    struct VarType* vType = doFindVar( name );
    if ( !vType )
    {
        WriteIndicator( GetCurrentColumn() );
        WriteMessage( "Undeclared variable" );
        exit( 1 );
    }
    if ( (Expr->Type->Type != T_ANY && (vType->Type != Expr->Type->Type)) 
            || Pos->Type->Type != T_INT || Pos->Type->isRef
            || vType->isRef != Expr->Type->isRef)
    {
        typeMismatch();
    }
    snprintf( buf, 50, "0(%s)", TmpRegName( reg_addr ) );
    code = Pos->Instrs;
    AppendSeq( code, Expr->Instrs );
    if ( vType->Loc == V_GBL )
    {
        AppendSeq( code, GenInstr( NULL, "la",
                             TmpRegName( reg_addr ),
                             name, NULL ) );
    }
    else
    {
        AppendSeq( code, GenInstr( NULL, "addi",
                             TmpRegName( reg_addr ),
                             "$sp",
                             Imm(vType->SPos) ) );
    }
    AppendSeq( code, GenInstr( NULL, "mul",
                         TmpRegName( Pos->Reg ),
                         TmpRegName( Pos->Reg ),
                         "4" ) );
    AppendSeq( code, GenInstr( NULL, "add",
                         TmpRegName( reg_addr ),
                         TmpRegName( reg_addr ),
                         TmpRegName( Pos->Reg ) ) );
    AppendSeq( code, GenInstr( NULL, "sw",
                         TmpRegName( Expr->Reg ),
                         buf, NULL ) );
    ReleaseTmpReg( Expr->Reg );
    ReleaseTmpReg( Pos->Reg );
    ReleaseTmpReg( reg_addr );
    free( Expr->Type );
    free( Expr );
    free( Pos->Type );
    free( Pos );
    return code;
}

struct ExprRes*
doArrVal( char* name, struct ExprRes* Pos )
{
    char buf[ 50 ];
    int reg_addr = AvailTmpReg();
    struct VarType* vType = doFindVar( name );
    if ( !vType )
    {
        WriteIndicator( GetCurrentColumn() );
        WriteMessage( "Undeclared Variable" );
        exit( 1 );
    }
    if ( Pos->Type->Type != T_INT || Pos->Type->isRef )
    {
        typeMismatch();
    }
    snprintf( buf, 50, "0(%s)", TmpRegName( reg_addr ) );
    if ( vType->Loc == V_GBL )
    {
        AppendSeq( Pos->Instrs, GenInstr( NULL, "la",
                                    TmpRegName( reg_addr ),
                                    name, NULL ) );
    }
    else
    {
        AppendSeq( Pos->Instrs, GenInstr( NULL, "addi",
                                    TmpRegName( reg_addr ),
                                    "$sp", 
                                    Imm(vType->SPos)));
    }
    AppendSeq( Pos->Instrs, GenInstr( NULL, "mul",
                                TmpRegName( Pos->Reg ),
                                TmpRegName( Pos->Reg ),
                                "4" ) );
    AppendSeq( Pos->Instrs, GenInstr( NULL, "add",
                                TmpRegName( reg_addr ),
                                TmpRegName( reg_addr ),
                                TmpRegName( Pos->Reg ) ) );
    AppendSeq( Pos->Instrs, GenInstr( NULL, "lw",
                                TmpRegName( Pos->Reg ),
                                buf, NULL ) );

    Pos->Type = malloc(sizeof(struct VarType));
    memcpy(Pos->Type, vType, sizeof(struct VarType));
    ReleaseTmpReg( reg_addr );
    return Pos;
}
