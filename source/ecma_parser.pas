unit ecma_parser;

//�ċA���~�p�[�T
//2001/04/20 ~
//by Wolfy


{
 Token��r�̌��GetLex
 if Token = ___ then
 begin
   GetLex;
}

{
 1+2*3���\����͂����...
 add    : add + multi | multi

 multi  : multi * number | number

 number : 1 | 2 | 3

 BNF�����̂܂܃R�[�h�ɂ����...
 function add: Integer;
 begin
   Result := add; //�����ċA�ɂȂ�
   if token = '+' then
     Result := Result + multi
   else
     Result := multi; // ???
 end;

 �Ȃ̂ŁAwhile�ɕϊ�����
 function add: Integer;
 begin
   Result := multi;
   while(token = '+') do
     Result := Result + multi;
 end;

}

{
  ������ȊO�͍��ċA�i������]���j
  ������͉E�ċA�i�E����]�� a := 1 + 2�j
}


{ TODO : �����Z�~�R�����}�� }

interface

uses
  sysutils,classes,windows,dialogs,ecma_expr,ecma_stmt,ecma_type,ecma_lex,
  ecma_misc,ecma_object,hashtable,contnrs;

type
  TJParser = class(TObject)
  private
    FExpr: TJExprFactory;
    FStmt: TJStatementFactory;
    FLex: TJLex;
    FRoot: PJStatement;
    FLibPath: TStringList;
    FPackages: TObjectList;
    FSourceCode: ECMAString;
    FCC: TIntegerHashTable;
    FFuncStack: TStack;

    function Token: Integer;
    function GetLex: Boolean;
    procedure Error(Msg: String = '');
    //
    function SourceElements: PJStatement;
    function SourceElement: PJStatement;
    //�錾
    function ImportDeclaration: PJStatement;
    function Declaration: PJStatement;
    function ClassDeclaration: PJStatement;
    function ClassElements: PJStatement;
    function ClassElement: PJStatement;
    function MemberDeclaration: PJStatement;

    function FunctionDeclaration: PJStatement;
    function ParameterDeclaration: PJStatement;

    function VarStatement: PJStatement;
    function VariableDeclarationList: PJStatement;
    function VariableDeclaration: PJStatement;
    //��
    function Statement: PJStatement;
    function StatementList: PJStatement;
    function BlockStatement: PJStatement;
    function EmptyStatement: PJStatement;
    function ExpressionStatement: PJStatement;
    function IfStatement: PJStatement;
    function WhileStatement: PJStatement;
    function DoStatement: PJStatement;
    function ForStatement: PJStatement;
    function ContinueStatement: PJStatement;
    function BreakStatement: PJStatement;
    function ReturnStatement: PJStatement;
    function WithStatement: PJStatement;
    function TryStatement: PJStatement;
    function CatchStatement: PJStatement;
    function FinallyStatement: PJStatement;
    function ThrowStatement: PJStatement;
    function SwitchStatement: PJStatement;
    function LabeledStatement(var Default: Boolean): PJStatement;
    function LabeledStatementList: PJStatement;
    //�����R���p�C��
    function ConditionalCompile: PJStatement;
    function AtSetStatement: PJStatement;

    //��
    function OptionExpression: PJExpr;
    function OptionVarExpression: PJExpr;
    function Variable(var lval: Boolean): PJExpr;
    function ConstFalse(var lval: Boolean): PJExpr;
    function ConstTure(var lval: Boolean): PJExpr;
    function ConstNull(var lval: Boolean): PJExpr;
    function ConstNaN(var lval: Boolean): PJExpr;
    function QuoteString(var lval: Boolean): PJExpr;
    function RegExp(var lval: Boolean): PJExpr;
    function Number(var lval: Boolean): PJExpr;
    function FunctionExpression: PJExpr;
    function Constant(var lval: Boolean): PJExpr;

    function This(var lval: Boolean): PJExpr;
    function Super(var lval: Boolean): PJExpr;
    function NewExpression(var lval: Boolean): PJExpr;

    function ObjectElements: PJExpr;
    function ObjectElement: PJExpr;

    function PrimaryExpression(var lval: Boolean): PJExpr;
    function PostfixExpression(var lval: Boolean): PJExpr;
    function Arguments(var lval: Boolean): PJExpr;
    function UnaryExpression(var lval: Boolean): PJExpr;
    function MultiplicaveExpression(var lval: Boolean): PJExpr;
    function AddtiveExpression(var lval: Boolean): PJExpr;
    function ShiftExpression(var lval: Boolean): PJExpr;
    function RelationalExpression(var lval: Boolean): PJExpr;
    function EqualityExpression(var lval: Boolean): PJExpr;
    function AndExpression(var lval: Boolean): PJExpr;
    function XorExpression(var lval: Boolean): PJExpr;
    function OrExpression(var lval: Boolean): PJExpr;
    function LogicalAndExpression(var lval: Boolean): PJExpr;
    function LogicalOrExpression(var lval: Boolean): PJExpr;
    function ConditionalExpression(var lval: Boolean): PJExpr;
    function AssignmentExpression: PJExpr;
    function Expression: PJExpr;

    //�V���A���C�Y
    procedure SerializeRoot(ARoot: PJStatement; Stream: TStream);
    procedure SerializeStatement(P: PJStatement; Stream: TStream);
    procedure SerializeExpr(P: PJExpr; Stream: TStream);
    procedure SerializeValue(P: PJValue; Stream: TStream);
    //�f�V���A���C�Y
    function DeserializeRoot(Stream: TStream): PJStatement;
    function DeserializeStatement(Stream: TStream): PJStatement;
    function DeserializeExpr(Stream: TStream): PJExpr;
    function DeserializeValue(Stream: TStream): PJValue;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Parse(ANameSpace: PJExpr = nil): Boolean;
    function ParseEval(ACode: String): PJExpr;
    function Serialize(Filename: String): Boolean;
    function Deserialize(Filename: String): Boolean;
    function FindImportFilename(Filename: String; var FindedFilename: String): Boolean;

    property Root: PJStatement read FRoot;
    property Lex: TJLex read FLex;
    property SourceCode: ECMAString read FSourceCode write FSourceCode;
    property LibPath: TStringList read FLibPath;
    property Packages: TObjectList read FPackages;
  end;

implementation

{ TJParser }

function TJParser.AddtiveExpression(var lval: Boolean): PJExpr;
//������
//addtive_expression  : addtive_expression ADDOP[+|-] multiplicave_expression
//                    | multiplicave_expression
var
  expr: PJExpr;
  op: ECMAChar;
begin
  Result := MultiplicaveExpression(lval);
  while Assigned(Result) do
  begin
    if Token = ADDOP then
    begin
      op := FLex.yylval.yyChar;
      GetLex;
      expr := MultiplicaveExpression(lval);
      if Assigned(expr) then
      begin
        case op of
          '+': Result := FExpr.MakeExpr2(opAdd,Result,expr);
          '-': Result := FExpr.MakeExpr2(opSub,Result,expr);
        end;
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.AndExpression(var lval: Boolean): PJExpr;
//and��
//and_expression  : and_expression OP_BIT_AND[&] equality_expression
//                | equality_expression
var
  expr: PJExpr;
begin
  Result := EqualityExpression(lval);
  while Assigned(Result) do
  begin
    if Token = OP_BIT_AND then
    begin
      GetLex;
      expr := EqualityExpression(lval);
      if Assigned(expr) then
      begin
        Result := FExpr.MakeExpr2(opBitAnd,Result,expr);
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.Arguments(var lval: Boolean): PJExpr;
//����
//arguments(right) : assignment_expression COMMA[,] arguments
//                 | assignment_expression
//arguments(left)  : assignment_expression
//                 | arguments COMMA[,] assignment_expression
var
  prev,expr: PJExpr;
begin
  Result := nil;
  prev := AssignmentExpression;
  if not Assigned(prev) then
    Exit
  else
    Result := FExpr.MakeArguments(nil,prev);
  {//�E�ċA ���������Ԃɕ���
  while True do
  begin
    if Token = COMMA then
    begin
      GetLex;
      expr := Arguments(lval);
      if Assigned(expr) then
        Result := FExpr.MakeArguments(Result,expr)
      else
        Error;
    end
    else
      Break;
  end;
  }
  //   ���ċA �������t���ɕ���
  while True do
  begin
    if Token = COMMA then
    begin
      GetLex;
      expr := AssignmentExpression;
      if Assigned(expr) then
        Result := FExpr.MakeArguments(Result,expr)
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.AssignmentExpression: PJExpr;
//�����
//assignment_expression : assignment_expression ASSIGNOP[+|-|*|/|%|<|>|>>|&|\|] assignment_expression
//                      | assignment_expression OP_ASSIGN[=] assignment_expression
//                      | conditional_expression
var
  expr1,expr2: PJExpr;
  op: ECMAChar;
  lval: Boolean;
begin
  lval := False;
  expr1 := ConditionalExpression(lval);//UnaryExpression;
  Result := expr1;
  if Assigned(expr1) then
  begin
    //���Ӓl�ɑ���ł���ꍇ
    if lval then
    begin
      if Token = OP_ASSIGN then
      begin
        GetLex;
        expr2 := AssignmentExpression;
        if Assigned(expr2) then
        begin
          Result := FExpr.MakeExpr2(opAssign,expr1,expr2);
        end
        else
          Error;
      end
      else if Token = ASSIGNOP then
      begin
        op := FLex.yylval.yyChar;
        GetLex;
        expr2 := Assignmentexpression;
        if Assigned(expr2) then
        begin
          case op of
            '+': Result := FExpr.MakeExpr2(opAddAssign,expr1,expr2);
            '-': Result := FExpr.MakeExpr2(opSubAssign,expr1,expr2);
            '*': Result := FExpr.MakeExpr2(opMulAssign,expr1,expr2);
            '/': Result := FExpr.MakeExpr2(opDivAssign,expr1,expr2);
            '%': Result := FExpr.MakeExpr2(opModAssign,expr1,expr2);
            '<': Result := FExpr.MakeExpr2(opBitLeftAssign,expr1,expr2);
            '>': Result := FExpr.MakeExpr2(opBitRightAssign,expr1,expr2);
            '3': Result := FExpr.MakeExpr2(opBitRightZeroAssign,expr1,expr2);
            '&': Result := FExpr.MakeExpr2(opBitAndAssign,expr1,expr2);
            '|': Result := FExpr.MakeExpr2(opBitOrAssign,expr1,expr2);
            '^': Result := FExpr.MakeExpr2(opBitXorAssign,expr1,expr2);
          end;
        end
        else
          Error;
      end;
    end;
  end;

end;

function TJParser.BlockStatement: PJStatement;
//7 �u���b�N
//block : LB[{] statement_list rb[}]
//      | LB[{] rb[}]
var
  stmt: PJStatement;
begin
  Result := nil;
  if Token = LB then
  begin
    GetLex;
    stmt := StatementList;
    if Token = RB then
    begin
      GetLex;
      Result := FStmt.MakeBlockStatement(FLex.LineNo,stmt);
    end
    else
      Error;
  end;
end;

function TJParser.BreakStatement: PJStatement;
//break_statement         : _BREAK sc[;]
begin
  Result := nil;
  if Token = _BREAK then
  begin
    GetLex;
    if Token = SC then
      Result := FStmt.MakeBreakStatement(FLex.LineNo)
    else
      Error;
  end;
end;

function TJParser.CatchStatement: PJStatement;
//catch_statement : _CATCH LP[(] variable RP[)] statement
//                | _CATCH LP[(] RP[)] statement
//                | _CATCH statement
var
  expr: PJExpr;
  stmt: PJStatement;
  lval: Boolean;
begin
  Result := nil;
  if Token = _CATCH then
  begin
    GetLex;
    if Token = LP then
    begin
      GetLex;
      expr := Variable(lval);
      if Token = RP then
      begin
        GetLex;
        stmt := Statement;
        if Assigned(stmt) then
          Result := FStmt.MakeCatchStatement(FLex.LineNo,expr,stmt)
        else
          Error;
      end
      else
        Error;
    end
    else begin
      stmt := Statement;
      if Assigned(stmt) then
        Result := FStmt.MakeCatchStatement(FLex.LineNo,nil,stmt)
      else
        Error;
    end;
  end;
end;

procedure TJParser.Clear;
//�N���A����
begin
  FLex.Clear;
  FExpr.Clear;
  FStmt.Clear;
  FPackages.Clear;
  FRoot := nil;
  FCC.Clear;
  while FFuncStack.Count > 0 do
    FFuncStack.Pop;
end;

function TJParser.ConditionalExpression(var lval: Boolean): PJExpr;
//������
//conditional_expression
//  : logical_or_expression QUERY[?] expression COLON[:] conditipnal_expression
var
  expr,cond: PJExpr;
begin
  Result := LogicalOrExpression(lval);
  if Assigned(Result) then
  begin
    if Token = QUERY then
    begin
      GetLex;
      expr := Expression;
      if Assigned(expr) then
      begin
        if Token = COLON then
        begin
          GetLex;
          cond := ConditionalExpression(lval);
          if Assigned(cond) then
            Result := FExpr.MakeExpr3(opConditional,Result,expr,cond)
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end;
  end;
end;

function TJParser.Constant(var lval: Boolean): PJExpr;
//constant  : number
//          | string
//          | regexp
//          | null
//          | true
//          | false
//          | NaN
//          | function_expression
begin
  Result := Number(lval);
  if Assigned(Result) then Exit;

  Result := QuoteString(lval);
  if Assigned(Result) then Exit;

  Result := RegExp(lval);
  if Assigned(Result) then Exit;

  Result := ConstTure(lval);
  if Assigned(Result) then Exit;

  Result := ConstFalse(lval);
  if Assigned(Result) then Exit;

  Result := ConstNull(lval);
  if Assigned(Result) then Exit;

  Result := FunctionExpression;
  if Assigned(Result) then Exit;

  Result := ConstNaN(lval);
end;

function TJParser.ConstFalse(var lval: Boolean): PJExpr;
//false
//false   : _FALSE
begin
  Result := nil;
  if Token = _FALSE then
  begin
    Result := FExpr.MakeBoolean(False);
    GetLex;
  end;
end;

function TJParser.ConstNull(var lval: Boolean): PJExpr;
//null     : _NULL
begin
  Result := nil;
  if Token = _NULL then
  begin
    Result := FExpr.MakeNull;
    GetLex;
  end;
end;

function TJParser.ConstTure(var lval: Boolean): PJExpr;
//ture
//ture   : _TRUE
begin
  Result := nil;
  if Token = _TRUE then
  begin
    Result := FExpr.MakeBoolean(True);
    GetLex;
  end;
end;

function TJParser.ContinueStatement: PJStatement;
//continue_statement : _CONTINUE sc[;]
begin
  Result := nil;
  if Token = _CONTINUE then
  begin
    GetLex;
    if Token = SC then
      Result := FStmt.MakeContinueStatement(FLex.LineNo)
    else
      Error;
  end;
end;

constructor TJParser.Create;
//�쐬
begin
  inherited Create;
  FLex := TJLex.Create;
  FExpr := TJExprFactory.Create;
  FStmt := TJStatementFactory.Create(FExpr);
  FLibPath := TStringList.Create;
  FPackages := TObjectList.Create;
  FCC := TIntegerHashTable.Create(10);
  //�X�N���v�g��
  FCC[DMS_ENGINE] := Integer(True);
  FFuncStack := TStack.Create;
end;

destructor TJParser.Destroy;
//�j������
begin
  Clear;
  FreeAndNil(FFuncStack);
  FreeAndNil(FCC);
  FreeAndNil(FPackages);
  FreeAndNil(FLibPath);
  FreeAndNil(FLex);
  FreeAndNil(FExpr);
  FreeAndNil(FStmt);
  inherited;
end;

function TJParser.EmptyStatement: PJStatement;
//8 ��
//empty_statement : sc[;]
begin
  if Token = SC then
  begin
    Result := FStmt.MakeEmptyStatement(FLex.LineNo);
    GetLex;
  end
  else
    Result := nil;
end;

function TJParser.EqualityExpression(var lval: Boolean): PJExpr;
//����
//equality_expression : equality_expression EQOP[==|!=|===|!==] relational_expression
//                    | relational_expression
var
  expr: PJExpr;
  op: ECMAChar;
begin
  Result := RelationalExpression(lval);
  while Assigned(Result) do
  begin
    if Token = EQOP then
    begin
      op := FLex.yylval.yyChar;
      GetLex;
      expr := RelationalExpression(lval);
      if Assigned(expr) then
      begin
        case op of
          '=': Result := FExpr.MakeExpr2(opEQ,Result,expr);
          '!': Result := FExpr.MakeExpr2(opNE,Result,expr);
          '3': Result := FExpr.MakeExpr2(opEQEQEQ,Result,expr);
          '2': Result := FExpr.MakeExpr2(opNEEQEQ,Result,expr);
        end;
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

procedure TJParser.Error(Msg: String);
//��O
begin
  if Msg <> '' then
    Msg := Msg + ': ';

  raise EJSyntaxError.Create(FLex.LineNo,
    Msg + 'Text( ' + FLex.yytext + ' )');
end;

function TJParser.Expression: PJExpr;
//��
//expression : assignment_expression
//           | expression COMMA[,] assignment_expression
var
  expr: PJExpr;
begin
  Result := AssignmentExpression;
  while Assigned(Result) do
  begin
    if Token = COMMA then
    begin
      GetLex;
      expr := AssignmentExpression;
      if Assigned(expr) then
        Result := FExpr.Makeexpr2(opExpr,Result,expr)
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.ExpressionStatement: PJStatement;
//9 ����
//expression_statement    : expression SC[;]
var
  expr: PJExpr;
begin
  Result := nil;
  expr := Expression;
  if Assigned(expr) then
  begin
    if Token = SC then
    begin
      Result := FStmt.MakeExprStatement(FLex.LineNo,expr);
      GetLex;
    end
    else
      Error;
  end;
end;

function TJParser.FinallyStatement: PJStatement;
//finally_statement       : _FINALLY statement
var
  stmt: PJStatement;
begin
  Result := nil;
  if Token = _FINALLY then
  begin
    GetLex;
    stmt := Statement;
    if Assigned(stmt) then
      Result := FStmt.MakeFinallyStatement(FLex.LineNo,stmt)
    else
      Error;
  end;
end;


function TJParser.ForStatement: PJStatement;
//13 for��
//for_statement  : _FOR LP[(] option_var_expression SC[;] option_expression SC[;] option_expression RP[)] statement
//forin_statement: _FOR LP[(] variable _IN postfix_expression RP[)] statement
var
  op1,op2,op3: PJExpr;
  stmt: PJStatement;
  lval: Boolean;
begin
  Result := nil;
  if Token = _FOR then
  begin
    GetLex;
    if Token = LP then
    begin
      GetLex;
      op1 := OptionVarExpression;
      if Token = SC then
      begin
        GetLex;
        op2 := OptionExpression;
        if Token = SC then
        begin
          GetLex;
          op3 := OptionExpression;
          if Token = RP then
          begin
            GetLex;
            stmt := Statement;
            if Assigned(stmt) then
              Result := FStmt.MakeForStatement(FLex.LineNo,op1,op2,op3,stmt)
            else
              Error;
          end
          else
            Error;
        end
        else
          Error;
      end
      else if Assigned(op1) and (Token = _IN) then
      begin
        GetLex;
        op2 := PostfixExpression(lval);
        //op2 := Variable(lval);
        if Assigned(op2) then
        begin
          if Token = RP then
          begin
            GetLex;
            stmt := Statement;
            if Assigned(stmt) then
            begin
              //�����R���p�C��
              Result := FStmt.MakeForInStatement(
                FLex.LineNo,op1,op2,stmt,
                (FCC.HasKey(CC_VERSION_7) and (FCC[CC_VERSION_7] <> 0)));
            end
            else
              Error;
          end
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end
    //else if
    //begin

    //end
    else
      Error;
  end;

end;

function TJParser.FunctionDeclaration: PJStatement;
//4�֐���`
//function_declaration  : _FUNCTION variable LP[(] parameter_declaration RP[)] block
//                      | _FUNCTION LP[(] parameter_declaration RP[)] block
var
  expr: PJExpr;
  param,block: PJStatement;
  templval: Boolean;
begin
  templval := False;
  Result := nil;
  if Token = _FUNCTION then
  begin
    GetLex;
    //�쐬����
    FStmt.MakeFunctionDeclPush(FFuncStack,FLex.LineNo);

    expr := Variable(templval);
    if Token = LP then
    begin
      GetLex;
      param := ParameterDeclaration;
      if Assigned(param) then
      begin
        if Token = RP then
        begin
          GetLex;
          block := BlockStatement;
          //�쐬����
          if Assigned(block) then
            Result := FStmt.MakeFunctionDeclPop(FFuncStack,expr,param,block)
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;
end;

function TJParser.FunctionExpression: PJExpr;
//function�萔
//function_expression : function_declaration
var
  decl: PJStatement;
begin
  Result := nil;
  decl := FunctionDeclaration;
  if Assigned(decl) then
  begin
    //�ϐ������݂���ꍇ�͑�����ɕϊ�
    if Assigned(decl^.Expr) then
      Result := FExpr.MakeExpr2(opAssign,decl^.Expr,FExpr.MakeFunction(decl))
    else //�����֐�
      Result := FExpr.MakeFunction(decl);
  end
end;

function TJParser.IfStatement: PJStatement;
//11 if��
//if_statement  : _IF LP[(] expression RP[)] statement
//              | _IF LP[(] expression RP[)] statement _ELSE statement
var
  expr: PJExpr;
  stmt1,stmt2: PJStatement;
begin
  Result := nil;
  if Token = _IF then
  begin
    GetLex;
    if Token = LP then
    begin
      GetLex;
      expr := Expression;
      if Assigned(expr) then
      begin
        if Token = RP then
        begin
          GetLex;
          stmt1 := Statement;
          if Assigned(stmt1) then
          begin
            if Token = _ELSE then
            begin
              GetLex;
              stmt2 := Statement;
              if Assigned(stmt2) then
                Result := FStmt.MakeIfStatement(FLex.LineNo,expr,stmt1,stmt2)
              else
                Error;
            end
            else begin
              Result := FStmt.MakeIfStatement(FLex.LineNo,expr,stmt1);
            end;
          end
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;
end;

function TJParser.LogicalAndExpression(var lval: Boolean): PJExpr;
//�_���a
//logical_and_expression : logical_and_expression OP_LOGICAL_AND[&&] or_expression
//                       | or_expression
var
  expr: PJExpr;
begin
  Result := OrExpression(lval);
  while Assigned(Result) do
  begin
    if Token = OP_LOGICAL_AND then
    begin
      GetLex;
      expr := OrExpression(lval);
      if Assigned(expr) then
      begin
        if FCC.HasKey(CC_SHORT_CIRCUIT) and (FCC[CC_SHORT_CIRCUIT] = 0) then
          Result := FExpr.MakeExpr2(opLogicalAnd2,Result,expr) //���S�]��
        else
          Result := FExpr.MakeExpr2(opLogicalAnd,Result,expr); //�Z���]��
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.LogicalOrExpression(var lval: Boolean): PJExpr;
//�_����
//logical_or_expression : logical_or_expression OP_LOGICAL_OR[\|\|] logical_and_expression
//                      | logical_and_expression
var
  expr: PJExpr;
begin
  Result := LogicalAndExpression(lval);
  while Assigned(Result) do
  begin
    if Token = OP_LOGICAL_OR then
    begin
      GetLex;
      expr := LogicalAndExpression(lval);
      if Assigned(expr) then
      begin
        if FCC.HasKey(CC_SHORT_CIRCUIT) and (FCC[CC_SHORT_CIRCUIT] = 0) then
          Result := FExpr.MakeExpr2(opLogicalOr2,Result,expr) //���S�]��
        else
          Result := FExpr.MakeExpr2(opLogicalOr,Result,expr); //�Z���]��
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.MultiplicaveExpression(var lval: Boolean): PJExpr;
//�揜��
//multiplicave_expression : multiplicave_expression MULOP[*|/|%|div] unary_expression
//                        | unary_expression
var
  expr: PJExpr;
  op: ECMAChar;
begin
  Result := UnaryExpression(lval);
  while Assigned(Result) do
  begin
    if Token = MULOP then
    begin
      op := FLex.yylval.yyChar;
      GetLex;
      expr := UnaryExpression(lval);
      if Assigned(expr) then
      begin
        case op of
          '*': Result := FExpr.MakeExpr2(opMul,Result,expr);
          '/': Result := FExpr.MakeExpr2(opDiv,Result,expr);
          '%': Result := FExpr.MakeExpr2(opMod,Result,expr);
          'd': Result := FExpr.MakeExpr2(opDivInt,Result,expr);
        end;
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.GetLex: Boolean;
//���֑���
begin
  Result := FLex.Next;
end;

function TJParser.Number(var lval: Boolean): PJExpr;
//number  : NUMBER
//        | FLOAT_NUMBER
begin
  Result := nil;
  if Token = _NUMBER then
  begin
    Result := FExpr.MakeNumberInt(FLex.yylval.yyInteger);
    GetLex;
  end
  else if Token = _FLOAT_NUMBER then
  begin
    Result := FExpr.MakeNumberFloat(FLex.yylval.yyDouble);
    GetLex;
  end
end;

function TJParser.OptionExpression: PJExpr;
//option_expression       : expression
//                        | (none)
begin
  Result := Expression;
end;

function TJParser.OrExpression(var lval: Boolean): PJExpr;
//or��
//or_expression : or_expression OP_BIT_OR[\|] xor_expression
//              | xor_expression
var
  expr: PJExpr;
begin
  Result := XorExpression(lval);
  while Assigned(Result) do
  begin
    if Token = OP_BIT_OR then
    begin
      GetLex;
      expr := XorExpression(lval);
      if Assigned(expr) then
      begin
        Result := FExpr.MakeExpr2(opBitOr,Result,expr);
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.ParameterDeclaration: PJStatement;
//5 �p�����[�^�錾
//parameter_declaration  : parameter_declaration COMMA[,] variable
//                       | variable
//                       | (none)
var
  expr: PJExpr;
  lval: Boolean;
begin
  lval := False;
  expr := Variable(lval);
  Result := FStmt.MakeParamDecl(FLex.LineNo,nil,expr);
  while Assigned(expr) do
  begin
    if Token = COMMA then
    begin
      GetLex;
      expr := Variable(lval);
      if Assigned(expr) then
        Result := FStmt.MakeParamDecl(FLex.LineNo,Result,expr)
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.Parse(ANameSpace: PJExpr): Boolean;
//��͊J�n
var
  code: PJStatement;
begin
  Result := False;
  //�N���A
  Clear;
  FLex.Input := FSourceCode;
  if GetLex then
  begin
    //�쐬����
    FStmt.MakeSourcePush(FFuncStack,ANameSpace);
    code := SourceElements;
    if Assigned(code) then
    begin
      //�\�[�X�쐬
      FRoot := FStmt.MakeSourcePop(FFuncStack,code);
      Result := True;
    end
    else
      FRoot := nil;
  end;
end;

function TJParser.PostfixExpression(var lval: Boolean): PJExpr;
//��u��
//postfix_expression : postfix_expression LSQ[\[] (arguments|null) RSQ[\]]
//                   | postfix_expression LP[(] (arguments|null) RP[)]
//                   | postfix_expression DOT[.] variable
//                   | postfix_expression DOT[.] variable LSQ[\[] (arguments|null) RSQ[\]]
//                   | postfix_expression DOT[.] variable LP[(] (arguments|null) RP[)]
//                   | postfix_expression INCDECOP[++|--]
//                   | primary_expression
var
  expr,arg: PJExpr;
  op: ECMAChar;
begin
  Result := PrimaryExpression(lval);
  while Assigned(Result) do
  begin
    //Array or Call []��()�͎��͓�������
    if (Token = LP) or (Token = LSQ) then
    begin
      GetLex;
      arg := Arguments(lval);
      if (Token = RP) or (Token = RSQ) then
      begin
        GetLex;
        Result := FExpr.MakeExpr2(opCallArray,Result,arg);
        lval := True;
      end
      else
        Error;
    end
    //�����o
    //postfix_expression DOT[.] variable
    //postfix_expression DOT[.] variable LSQ[\[] (arguments|null) RSQ[\]]
    //postfix_expression DOT[.] variable LP[(] (arguments|null) RP[)]
    else if Token = DOT then
    begin
      GetLex;
      expr := Variable(lval);
      if Assigned(expr) then
      begin
        if (Token = LP) or (Token = LSQ) then
        begin
          GetLex;
          arg := Arguments(lval);
          if (Token = RP) or (Token = RSQ) then
          begin
            GetLex;
            Result := FExpr.MakeExpr3(opMethod,Result,expr,arg);
            lval := True;
          end
          else
            Error;
        end
        else begin
          Result := FExpr.MakeExpr2(opMember,Result,expr);
          lval := True;
        end;
      end
      else
        Error;
    end
    else if Token = INCDECOP then
    begin
      op := FLex.yylval.yyChar;
      GetLex;
      case op of
        '+':  Result := FExpr.MakeExpr1(opPostInc,Result);
        '-':  Result := FExpr.MakeExpr1(opPostDec,Result);
      end;
    end
    else
      Break;
  end;

end;

function TJParser.PrimaryExpression(var lval: Boolean): PJExpr;
//�P����
//primary_expression    : this
//                      | super DOT variable
//                      | variable
//                      | constant
//                      | LP expression rp
//                      | new_expression
//typeof_expression     : _TYPEOF expression
//                      | _TYPEOF LP expression RP
//delete_expression     : _DELETE expression
//void_expression       : _VOID expression
//                      | _VOID LP expression RP
//object_expression     : LB object_elements RB
//array_expression      : LSQ arguments RSQ
var
  expr: PJExpr;
begin
  Result := nil;
  if Token = LP then
  begin
    GetLex;
    expr := Expression;
    if Assigned(expr) then
    begin
      if Token = RP then
      begin
        GetLex;
        Result := expr;
      end
      else
        Error;
    end
    else
      Error;
  end
  else if Token = _TYPEOF then
  begin
    GetLex;
    if Token = LP then
    begin
      GetLex;
      expr := Expression;
      if Assigned(expr) then
      begin
        if Token = RP then
        begin
          GetLex;
          Result := FExpr.MakeExpr1(opTypeOf,expr);
        end
        else
          Error;
      end
      else
        Error;
    end
    else begin
      expr := Expression;
      if Assigned(expr) then
        Result := FExpr.MakeExpr1(opTypeOf,expr)
      else
        Error;
    end
  end
  else if Token = _VOID then
  begin
    GetLex;
    if Token = LP then
    begin
      GetLex;
      expr := Expression;
      if Assigned(expr) then
      begin
        if Token = RP then
        begin
          GetLex;
          Result := FExpr.MakeExpr1(opVoid,expr);
        end
        else
          Error;
      end
      else
        Error;
    end
    else begin
      expr := Expression;
      if Assigned(expr) then
        Result := FExpr.MakeExpr1(opVoid,expr)
      else
        Error;
    end
  end
  else if Token = _DELETE then
  begin
    GetLex;
    expr := Expression;
    if Assigned(expr) then
      Result := FExpr.MakeExpr1(opDelete,expr)
    else
      Error;
  end
  else if Token = LB then
  begin
    //object_expression     : LB object_elements RB
    GetLex;
    expr := ObjectElements;
    //if Assigned(expr) then
    //begin
      if Token = RB then
      begin
        GetLex;
        Result := FExpr.MakeExpr1(opNewObject,expr);
      end
      else
        Error;
    //end
    //else
    //  Error;
  end
  else if Token = LSQ then
  begin
    //array_expression      : LSQ arguments RSQ
    GetLex;
    expr := Arguments(lval);
    //if Assigned(expr) then
    //begin
      if Token = RSQ then
      begin
        GetLex;
        Result := FExpr.MakeExpr1(opNewArray,expr);
      end
      else
        Error;
    //end
    //else
    //  Error;
  end
  else begin
    Result := Variable(lval);
    if Assigned(Result) then Exit;

    Result := Constant(lval);
    if Assigned(Result) then Exit;

    Result := NewExpression(lval);
    if Assigned(Result) then Exit;

    Result := This(lval);
    if Assigned(Result) then Exit;

    Result := Super(lval);
  end;
end;

function TJParser.QuoteString(var lval: Boolean): PJExpr;
//string    : QUOTE_STRING
begin
  Result := nil;
  if Token = _QUOTE_STRING then
  begin
    Result := FExpr.MakeString(FLex.yytext);
    GetLex;
  end;
end;

function TJParser.RegExp(var lval: Boolean): PJExpr;
//regexp  : _REGEXP
begin
  Result := nil;
  if Token = _REGEXP then
  begin
    Result := FExpr.MakeRegExp(FLex.yytext);
    GetLex;
  end;
end;

function TJParser.RelationalExpression(var lval: Boolean): PJExpr;
//��r��
//relational_expression : relational_expression COMPOP[<|=<|>|=>] shift_expression
//                      | shift_expression
var
  expr: PJExpr;
  op: ECMAChar;
begin
  Result := ShiftExpression(lval);
  while Assigned(Result) do
  begin
    if Token = COMPOP then
    begin
      op := FLex.yylval.yyChar;
      GetLex;
      expr := ShiftExpression(lval);
      if Assigned(expr) then
      begin
        case op of
          '(': Result := FExpr.MakeExpr2(opLSEQ,Result,expr);
          '<': Result := FExpr.MakeExpr2(opLS,Result,expr);
          ')': Result := FExpr.MakeExpr2(opGTEQ,Result,expr);
          '>': Result := FExpr.MakeExpr2(opGT,Result,expr);
        end;
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.ReturnStatement: PJStatement;
//return_statement        : _RETURN expression SC[;]
//                        | _RETURN SC[;]
var
  expr: PJExpr;
begin
  Result := nil;
  if Token = _RETURN then
  begin
    GetLex;
    expr := Expression;
    if Token = SC then
    begin
      GetLex;
      Result := FStmt.MakeReturnStatement(FLex.LineNo,expr);
    end
    else
      Error;
  end;
end;

function TJParser.ShiftExpression(var lval: Boolean): PJExpr;
//shift��
//shift_expression : shift_expression SHIFTOP[<<|>>|>>>] addtive_expression
//                 | addtive_expression
var
  expr: PJExpr;
  op: ECMAChar;
begin
  Result := AddtiveExpression(lval);
  while Assigned(Result) do
  begin
    if Token = SHIFTOP then
    begin
      op := FLex.yylval.yyChar;
      GetLex;
      expr := AddtiveExpression(lval);
      if Assigned(expr) then
      begin
        case op of
          '<': Result := FExpr.MakeExpr2(opBitLeft,Result,expr);
          '>': Result := FExpr.MakeExpr2(opBitRight,Result,expr);
          '3': Result := FExpr.MakeExpr2(opBitRightZero,Result,expr);
        end;
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.SourceElement: PJStatement;
//source_element : statement
//               | declaration
begin
  //�錾���ɒT��
  Result := Declaration;
  if Assigned(Result) then Exit;

  Result := Statement;
end;

function TJParser.SourceElements: PJStatement;
//source_elements : source_elements source_element
//                | source_element
var
  prev,next: PJStatement;
begin
  Result := SourceElement;
  if not Assigned(Result) then
    Exit;

  prev := Result;
  next := SourceElement;
  FStmt.MergeStatement(prev,next);
  //�������ԂɌq���Ă���
  while Assigned(next) do
  begin
    prev := next;
    next := SourceElement;
    FStmt.MergeStatement(prev,next);
  end;
end;

function TJParser.Statement: PJStatement;
//statement   : block
//            | expression_statement
//            | empty_statement
//            | if_statement
//            | while_statement
//            | for_statement
//            | forin_statement
//            | continue_statement
//            | break_statement
//            | return_statement
//            | print_statement
//            | try_statement
//            | catch_statement
//            | finally_statement
//            | throw_statement
//            | with_statement
//            | var_statement
//            | do_statement
//            | switch_statement
//            | var_statement
//            | conditiolan_compile
begin
  Result := FunctionDeclaration;
  if Assigned(Result) then Exit;

  Result := BlockStatement;
  if Assigned(Result) then Exit;

  Result := ExpressionStatement;
  if Assigned(Result) then Exit;

  Result := EmptyStatement;
  if Assigned(Result) then Exit;

  Result := IfStatement;
  if Assigned(Result) then Exit;

  Result := WhileStatement;
  if Assigned(Result) then Exit;

  Result := ForStatement;
  if Assigned(Result) then Exit;

  Result := ContinueStatement;
  if Assigned(Result) then Exit;

  Result := BreakStatement;
  if Assigned(Result) then Exit;

  Result := ReturnStatement;
  if Assigned(Result) then Exit;

  Result := SwitchStatement;
  if Assigned(Result) then Exit;

  Result := VarStatement;
  if Assigned(Result) then Exit;

  Result := TryStatement;
  if Assigned(Result) then Exit;

  {Result := CatchStatement;
  if Assigned(Result) then Exit;

  Result := FinallyStatement;
  if Assigned(Result) then Exit;
  }
  Result := ThrowStatement;
  if Assigned(Result) then Exit;

  Result := WithStatement;
  if Assigned(Result) then Exit;

  Result := DoStatement;
  if Assigned(Result) then Exit;

  Result := ConditionalCompile;
end;

function TJParser.StatementList: PJStatement;
//�����X�g
//statement_list       : statement_list statement
//                     | statement
var
  prev,next: PJStatement;
begin
  Result := Statement;
  if not Assigned(Result) then
    Exit;

  prev := Result;
  next := Statement;
  FStmt.MergeStatement(prev,next);
  //�������ԂɌq���Ă���
  while Assigned(next) do
  begin
    prev := next;
    next := Statement;
    FStmt.MergeStatement(prev,next);
  end;

end;

function TJParser.This(var lval: Boolean): PJExpr;
//this  : _THIS
begin
  Result := nil;
  if Token = _THIS then
  begin
    Result := Fexpr.MakeThis;
    GetLex;
  end;
end;

function TJParser.ThrowStatement: PJStatement;
//throw_statement : _THROW expression SC[;]
//                | _THROW SC[;]
var
  expr: PJExpr;
begin
  Result := nil;
  if Token = _THROW then
  begin
    GetLex;
    expr := Expression;
    if Token = SC then
    begin
      GetLex;
      Result := FStmt.MakeThrowStatement(FLex.LineNo,expr);
    end
    else
      Error;
  end;
end;

function TJParser.Token: Integer;
//���݂�token
begin
  if FLex.EOF then
    Result := 0
  else
    Result := Flex.Token;
end;

function TJParser.TryStatement: PJStatement;
//try_statement   : _TRY statement catch_statement finally_statement
var
  stmt,catch,fin: PJStatement;
begin
  Result := nil;
  if Token = _TRY then
  begin
    GetLex;
    stmt := Statement;
    if Assigned(stmt) then
    begin
      catch := CatchStatement;
      fin := FinallyStatement;
      //�ǂ���������ꍇ�̓G���[
      if (catch = nil) and (fin = nil) then
        Error('not found catch-statement')
      else
        Result := FStmt.MakeTryStatement(
          FLex.LineNo,stmt,catch,fin)
    end
    else
      Error;
  end;
end;

function TJParser.UnaryExpression(var lval: Boolean): PJExpr;
//�O�u��
//unary_expression : postfix_expression
//                 | INCDECOP[++|--] unary_expression
//                 | ADDOP[+|-]      unary_expression
//                 | UNOP[!|~]       unary_expression
var
  op: ECMAChar;
  expr: PJExpr;
begin
  Result := PostfixExpression(lval);
  if Assigned(Result) then
    Exit;

  if Token = INCDECOP then
  begin
    op := FLex.yylval.yyChar;
    GetLex;
    case op of
      '+':
      begin
        expr := UnaryExpression(lval);
        if Assigned(expr) then
          Result := FExpr.MakeExpr1(opPreInc,expr)
        else
          Error;
      end;
      '-':
      begin
        expr := UnaryExpression(lval);
        if Assigned(expr) then
          Result := FExpr.MakeExpr1(opPreDec,expr)
        else
          Error;
      end;
    end;
  end
  else if Token = ADDOP then
  begin
    op := FLex.yylval.yyChar;
    GetLex;
    case op of
      '+':
      begin
        expr := UnaryExpression(lval);
        if Assigned(expr) then
          Result := FExpr.MakeExpr1(opPlus,expr)
        else
          Error;
      end;
      '-':
      begin
        expr := UnaryExpression(lval);
        if Assigned(expr) then
          Result := FExpr.MakeExpr1(opMinus,expr)
        else
          Error;
      end;
    end;
  end
  else if Token = UNOP then
  begin
    op := FLex.yylval.yyChar;
    GetLex;
    case op of
      '!':
      begin
        expr := UnaryExpression(lval);
        if Assigned(expr) then
          Result := FExpr.MakeExpr1(opLogicalNot,expr)
        else
          Error;
      end;
      '~':
      begin
        expr := UnaryExpression(lval);
        if Assigned(expr) then
          Result := FExpr.MakeExpr1(opBitNot,expr)
        else
          Error;
      end;
    end;
  end;

end;

function TJParser.Variable(var lval: Boolean): PJExpr;
//�ϐ�
//variable   : VARIABLE
begin
  Result := nil;
  if Token = _VARIABLE then
  begin
    Result := FExpr.MakeVariable(FLex.yytext);
    lval := True;
    GetLex;
  end;
end;

function TJParser.VarStatement: PJStatement;
//var_statement : _VAR variable_declaration_list SC[;]
//              : _STATIC variable_declaration_list SC[;]
//              : _GLOBAL variable_declaration_list SC[;]
var
  stmt: PJStatement;
  vartype: TJRegistVarType;
begin
  Result := nil;
  if (Token = _VAR) or (Token = _STATIC) or (Token = _GLOBAL) then
  begin
    if Token = _VAR then
      vartype := rvLocal
    else if Token = _STATIC then
      vartype := rvStatic
    else
      vartype := rvGlobal;

    GetLex;
    stmt := VariableDeclarationList;
    if Assigned(stmt) then
    begin
      if Token = SC then
      begin
        GetLex;
        Result := FStmt.MakeVarDecl(FLex.LineNo,stmt,vartype);
      end
      else
        Error;
    end
    else
      Error;
  end;
end;

function TJParser.WhileStatement: PJStatement;
//while��
//while_statement : _WHILE LP[(] expression RP[)] statement
var
  expr: PJExpr;
  stmt: PJStatement;
begin
  Result := nil;
  if Token = _WHILE then
  begin
    GetLex;
    if Token = LP then
    begin
      GetLex;
      expr := Expression;
      if Assigned(expr) then
      begin
        if Token = RP then
        begin
          GetLex;
          stmt := Statement;
          if Assigned(stmt) then
            Result := FStmt.MakeWhileStatement(FLex.LineNo,expr,stmt)
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;
end;

function TJParser.WithStatement: PJStatement;
//with_statement : _WITH LP[(] expression RP[)] statement
var
  expr: PJExpr;
  stmt: PJStatement;
begin
  Result := nil;
  if Token = _WITH then
  begin
    GetLex;
    if Token = LP then
    begin
      GetLex;
      expr := Expression;
      if Assigned(expr) then
      begin
        if Token = RP then
        begin
          GetLex;
          stmt := Statement;
          if Assigned(stmt) then
            Result := FStmt.MakeWithStatement(FLex.LineNo,expr,stmt)
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;

end;

function TJParser.XorExpression(var lval: Boolean): PJExpr;
//xor��
//xor_expression : xor_expression OP_BIT_XOR[^] and_expression
//               | and_expression
var
  expr: PJExpr;
begin
  Result := AndExpression(lval);
  while Assigned(Result) do
  begin
    if Token = OP_BIT_XOR then
    begin
      GetLex;
      expr := AndExpression(lval);
      if Assigned(expr) then
      begin
        Result := FExpr.MakeExpr2(opBitXor,Result,expr);
      end
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.DoStatement: PJStatement;
//do - while��
//do_statement  : _DO statement _WHILE LP[(] expression RP[)] SC[;]
var
  expr: PJExpr;
  stmt: PJStatement;
begin
  Result := nil;
  if Token = _DO then
  begin
    GetLex;
    stmt := Statement;
    if Assigned(stmt) then
    begin
      if Token = _WHILE then
      begin
        GetLEx;
        if Token = LP then
        begin
          GetLex;
          expr := Expression;
          if Assigned(expr) then
          begin
            if Token = RP then
            begin
              GetLex;
              if Token = SC then
                Result := FStmt.MakeDoStatement(FLex.LineNo,expr,stmt)
              else
                Error;
            end
            else
              Error;
          end
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;

end;

function TJParser.ConstNaN(var lval: Boolean): PJExpr;
begin
  Result := nil;
  if Token = _NaN then
  begin
    Result := FExpr.MakeNaN;
    GetLex;
  end;
end;

function TJParser.ObjectElement: PJExpr;
//object_element : variable COLON[:] assignment_expression
//               | variavle
//               | string COLON[:] assignment_expression
//               | string
//               | number COLON[:] assignment_expression
//               | number
var
  va,expr: PJExpr;
  lval: Boolean;
begin
  Result := nil;
  //���ʎq
  va := Variable(lval);
  //����
  if not Assigned(va) then
    va := QuoteString(lval);
  //����
  if not Assigned(va) then
    va := Number(lval);

  if Assigned(va) then
  begin
    if Token = COLON then
    begin
      GetLex;
      expr := AssignmentExpression;
      if Assigned(expr) then
        Result := FExpr.MakeObjectElement(va,expr)
      else
        Error;
    end
    else
      Result := FExpr.MakeObjectElement(va,nil);
  end;
end;

function TJParser.ObjectElements: PJExpr;
//object_elements       : object_elements COMMA[,] object_element
//                      | object_element
var
  prev,expr: PJExpr;
begin
  Result := nil;
  prev := ObjectElement;
  if not Assigned(prev) then
    Exit
  else
   Result := FExpr.MakeArguments(nil,prev);
  //   ���ċA �������t���ɕ���
  while True do
  begin
    if Token = COMMA then
    begin
      GetLex;
      expr := ObjectElement;
      if Assigned(expr) then
        Result := FExpr.MakeArguments(Result,expr)
      else
        Error;
    end
    else
      Break;
  end;
end;

function TJParser.ClassDeclaration: PJStatement;
//class_declaration     : _CLASS variable LB[{] class_elements RB[}]
//                      | _CLASS variable LP[(] variavle RP[)] LB[{] class_elements RB[}]
//                      | _CLASS variable _EXTENDS variable LB[{] class_elements RB[}]
var
  obj,super: PJExpr;
  stmt: PJStatement;
  lval: Boolean;
begin
  Result := nil;
  if Token = _CLASS then
  begin
    GetLex;
    //�쐬����
    FStmt.MakeClassDeclPush(FFuncStack,FLex.LineNo);

    obj := Variable(lval);
    if Assigned(obj) then
    begin
      if Token = LB then
      begin
        GetLex;
        stmt := ClassElements;
        if Token = RB then
        begin
          GetLex;
          Result := FStmt.MakeClassDeclPop(FFuncStack,obj,nil,stmt);
        end
        else
          Error;
      end
      else if Token = LP then
      begin
        GetLex;
        super := Variable(lval);
        if Token = RP then
        begin
          GetLex;
          if Token = LB then
          begin
            GetLex;
            stmt := ClassElements;
            if Token = RB then
            begin
              GetLex;
              Result := FStmt.MakeClassDeclPop(FFuncStack,obj,super,stmt);
            end
            else
              Error;
          end;
        end
        else
          Error;
      end
      else if Token = _EXTENDS then
      begin
        GetLex;
        super := Variable(lval);
        if Assigned(super) then
        begin
          if Token = LB then
          begin
            GetLex;
            stmt := ClassElements;
            if Token = RB then
            begin
              GetLex;
              Result := FStmt.MakeClassDeclPop(FFuncStack,obj,super,stmt);
            end
            else
              Error;
          end;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;
end;

function TJParser.Declaration: PJStatement;
//declaration   : class_declaration
//              | import_declaration
//              | function_declaration
begin
  Result := ClassDeclaration;
  if Assigned(Result) then Exit;

  Result := ImportDeclaration;
end;

function TJParser.ClassElement: PJStatement;
//class_element : member_declaration
//              | function_declaration
begin
  Result := FunctionDeclaration;
  if not Assigned(Result) then
    Result := MemberDeclaration;
end;

function TJParser.ClassElements: PJStatement;
//class_elements        : class_elements class_element
//                      | class_element
var
  prev,next: PJStatement;
begin
  Result := ClassElement;
  if not Assigned(Result) then
    Exit;

  prev := Result;
  next := ClassElement;
  FStmt.MergeStatement(prev,next);
  //�������ԂɌq���Ă���
  while Assigned(next) do
  begin
    prev := next;
    next := ClassElement;
    FStmt.MergeStatement(prev,next);
  end;
end;

function TJParser.MemberDeclaration: PJStatement;
//member_declaration    : var_statement
//                      | variable_declaration_lsit SC
var
  stmt: PJStatement;
begin
  Result := VarStatement;
  if Assigned(Result) then
    Exit;

  stmt := VariableDeclaration;
  if Assigned(stmt) then
  begin
    if Token = SC then
    begin
      GetLex;
      Result := stmt;
    end
    else
      Error;
  end;
end;

function TJParser.Super(var lval: Boolean): PJExpr;
//super : _SUPER
//      | _SUPER DOT variable
var
  v: PJExpr;
begin
  Result := nil;
  if Token = _SUPER then
  begin
    GetLex;
    if Token = DOT then
    begin
      GetLex;
      v := Variable(lval);
      if Assigned(v) then
        Result := FExpr.MakeSuper(v)
      else
        Error;
    end
    else
      Result := FExpr.MakeThis;
  end;
end;

function TJParser.ImportDeclaration: PJStatement;
//import_declaration    : _IMPORT variable SC    ���O��Ԃ�����
//                      | _IMPORT variavle DOT OP_MUL SC ���O��Ԃ������Ȃ�
var
  expr: PJExpr;
  lval: Boolean;
  sl: TStringList;
  name,path: String;
  source: ECMAString;
  p: TJParser;
begin
  Result := nil;
  source := '';
  if Token = _IMPORT then
  begin
    GetLex;
    expr := Variable(lval);
    if Assigned(expr) then
    begin
      //�\�[�X�ǂݍ���
      sl := TStringList.Create;
      try try
        name := expr^.Symbol + DMS_EXT;
        if FindImportFilename(name,path) then
        begin
          sl.LoadFromFile(path);
          source := sl.Text;
        end
        else
          Error('file not found: ' + name);
      finally
        sl.Free;
      end;
      except
        Error('can not open: ' + name);
      end;

      if Token = SC then
      begin
        GetLex;
        //���O��Ԃ�����
        p := TJParser.Create;
        FPackages.Add(p);
        p.SourceCode := source;
        p.Parse(expr);
        Result := p.Root;
      end
      else if Token = DOT then
      begin
        GetLex;
        if (Token = MULOP) and (FLex.yylval.yyChar = '*') then
        begin
          GetLex;
          if Token = SC then
          begin
            //�������Ȃ��_�~�[
            Result := FStmt.NewStatement;
            FLex.ImportSource(source);
            GetLex;
          end;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;
end;


function TJParser.NewExpression(var lval: Boolean): PJExpr;
{ TODO : ����͕ʂ�namespace��object�����Ȃ��̂ō�蒼�� }
//new_expression        : _NEW variable
//                      | _NEW variable LP arguments rp
//                      | _NEW variable LP rp
var
  expr1,arg: PJExpr;
begin
  Result := nil;
  if Token = _NEW then
  begin
    GetLex;
    expr1 := Variable(lval);
    if Assigned(expr1) then
    begin
      if Token = LP then
      begin
        GetLex;
        arg := Arguments(lval);
        if Token = RP then
        begin
          GetLex;
          Result := FExpr.MakeExpr2(opNew,expr1,arg)
        end
        else
          Error;
      end
      else
        Result := FExpr.MakeExpr2(opNew,expr1,nil);
    end
    else
      Error;
  end
end;

function TJParser.VariableDeclarationList: PJStatement;
//variable_declaration_list     : variable_declaration
//                              | variable_declaration_list COMMA variable_declaration
var
  prev,next: PJStatement;
begin
  Result := VariableDeclaration;
  if not Assigned(Result) then
    Exit;

  prev := Result;
  while True do
  begin
    if Token = COMMA then
    begin
      GetLex;
      next := VariableDeclaration;
      if Assigned(next) then
      begin
        FStmt.MergeStatement(prev,next);
        prev := next;
      end
      else
        Error;
    end
    else
      Break;
  end;

end;

function TJParser.VariableDeclaration: PJStatement;
//variable_declaration  : variable
//                      | variable OP_ASSIGN assignement_expression
var
  lval: Boolean;
  name,value: PJExpr;
begin
  Result := nil;
  name := Variable(lval);
  if Assigned(name) then
  begin
    if Token = OP_ASSIGN then
    begin
      GetLex;
      value := AssignmentExpression;
      if Assigned(value) then
        Result := FStmt.MakeVariableDecl(FLex.LineNo,name,value)
      else
        Error;
    end
    else
      Result := FStmt.MakeVariableDecl(FLex.LineNo,name,nil);
  end;
end;

function TJParser.SwitchStatement: PJStatement;
//switch_statement  : _SWITCH LP expression rp LB labeled_statement_list RB
var
  expr: PJExpr;
  stmt: PJStatement;
begin
  Result := nil;
  //_SWITCH LP expression rp statement
  if Token = _SWITCH then
  begin
    GetLex;
    //LP
    if Token = LP then
    begin
      GetLex;
      //expression
      expr := Expression;
      if Assigned(expr) then
      begin
        if Token = RP then
        begin
          GetLex;
          if Token = LB then
          begin
            GetLex;
            //statement
            stmt := LabeledStatementList;
            if Assigned(stmt) then
            begin
              if Token = RB then
              begin
                GetLex;
                Result := FStmt.MakeSwitchStatement(FLex.LineNo,expr,stmt);
              end
              else
                Error;
            end
            else
              Error;
          end
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;
end;

function TJParser.LabeledStatement(var Default: Boolean): PJStatement;
//labeled_statement : _CASE constant_expression COLON statement_list
//                  | _CASE constant_expression COLON (none)
//                  | _DEFAULT COLON statement_list
//                  | _DEFAULT COLON (none)
var
  expr: PJExpr;
begin
  Result := nil;
  if Token = _CASE then
  begin
    GetLex;
    expr := Expression;
    if Assigned(expr) then
    begin
      //COLON
      if Token = COLON then
      begin
        GetLex;
        //statement nil�ł�OK
        Result := FStmt.MakeLabeledStatement(FLex.LineNo,expr,StatementList)
      end
      else
        Error;
    end
    else
      Error;
  end
  //_DEFAULT COLON statement
  else if Token = _DEFAULT then
  begin
    if not Default then
    begin
      Default := True;
      GetLex;
      //COLON
      if Token = COLON then
      begin
        GetLex;
        //statement nil�ł�OK
        Result := FStmt.MakeLabeledStatement(FLex.LineNo,nil,StatementList)
      end
      else
        Error;
    end
    else //default�傪�����
      Error;
  end;
end;

function TJParser.LabeledStatementList: PJStatement;
//lebeled�����X�g
//labeled_statement_list  : labeled_statement_list labeled_statement
//                        | labeled_statement
var
  prev,next: PJStatement;
  default: Boolean;
begin
  default := False;
  Result := LabeledStatement(default);
  if not Assigned(Result) then
    Exit;

  prev := Result;
  next := LabeledStatement(default);
  FStmt.MergeStatement(prev,next);
  //�������ԂɌq���Ă���
  while Assigned(next) do
  begin
    prev := next;
    next := LabeledStatement(default);
    FStmt.MergeStatement(prev,next);
  end;
end;

procedure TJParser.SerializeRoot(ARoot: PJStatement; Stream: TStream);
//Root�V���A���C�Y
begin
  //�ŏ��ɖ߂�
  Stream.Seek(0,soFromBeginning);
  //header
  Stream.WriteBuffer(DMS_ENGINE[1],Length(DMS_ENGINE));
  Stream.WriteBuffer(DMS_SERIALIZE_VER,SizeOf(DMS_SERIALIZE_VER));
  //�J�n
  if Assigned(ARoot) then
    SerializeStatement(ARoot,Stream);
  //�؂�̂�
  Stream.Size := Stream.Position;
end;

function TJParser.DeserializeRoot(Stream: TStream): PJStatement;
//Root�f�V���A���C�Y
var
  ver: Byte;
  script: String;
begin
  Result := nil;
  //�ŏ��ɖ߂�
  Stream.Seek(0,soFromBeginning);
  //header
  SetLength(script,Length(DMS_ENGINE));
  Stream.ReadBuffer(script[1],Length(DMS_ENGINE));
  if script <> DMS_ENGINE then
    Exit;
  //ver
  Stream.ReadBuffer(ver,SizeOf(ver));
  if ver <> DMS_SERIALIZE_VER then
    Exit;
  //�J�n
  if Stream.Position < Stream.Size then
    Result := DeserializeStatement(Stream);
end;

function StatementTempIsFunction(P: PJStatement): Boolean;
//P^.Temp���g�p���Ă��邩�`�F�b�N
begin
  case P^.SType of
    stSource,stFunctionDecl,stClassDecl: Result := True;
  else
    Result := False;
  end;
end;

procedure TJParser.SerializeStatement(P: PJStatement; Stream: TStream);
//���̃V���A���C�Y
//0.ok 1.expr 2.sub1 3.sub2 4.temp 5.next
var
  flags: Byte;
begin
  //flag�쐬
  flags := SetByteFlag(
    [True,
     Assigned(P^.Expr),
     Assigned(P^.Sub1),
     Assigned(p^.Sub2),
     Assigned(p^.Temp) and (not StatementTempIsFunction(P)),  //�֐��̂Ƃ��͖�������
     Assigned(P^.Next),
     False,False]);

  //��flags
  Stream.WriteBuffer(flags,SizeOf(flags));
  //�^�C�v
  Stream.WriteBuffer(P^.SType,SizeOf(P^.SType));
  //�s�ԍ�
  Stream.WriteBuffer(P^.LineNo,SizeOf(P^.LineNo));
  //��
  if Assigned(P^.Expr) then
    SerializeExpr(P^.Expr,Stream);
  //sub1
  if Assigned(P^.Sub1) then
    SerializeStatement(P^.Sub1,Stream);
  //sub2
  if Assigned(P^.Sub2) then
    SerializeStatement(P^.Sub2,Stream);
  //temp
  if Assigned(p^.Temp) and (not StatementTempIsFunction(P)) then
    SerializeStatement(P^.Temp,Stream);
  //next
  if Assigned(P^.Next) then
    SerializeStatement(P^.Next,Stream);
end;

function TJParser.DeserializeStatement(Stream: TStream): PJStatement;
//���̃f�V���A���C�Y
//0.ok 1.expr 2.sub1 3.sub2 4.temp 5.next
var
  flags: Byte;
  pushed: Boolean;
begin
  pushed := False;
  Stream.ReadBuffer(flags,SizeOf(flags));
  //���쐬
  Result := FStmt.NewStatement;
  //�^�C�v
  Stream.ReadBuffer(Result^.SType,SizeOf(Result^.SType));
  //�֐���push����
  if StatementTempIsFunction(Result) then
  begin
    pushed := True;
    //peek����
    if Result^.SType <> stSource then
      Result^.Temp := FFuncStack.Peek;
    //push����
    FFuncStack.Push(Result);
  end;

  try
    //�s�ԍ�
    Stream.ReadBuffer(Result^.LineNo,SizeOf(Result^.LineNo));
    //��
    if GetByteFlag(flags,1) then
      Result^.Expr := DeserializeExpr(Stream);
    //sub1
    if GetByteFlag(flags,2) then
      Result^.Sub1 := DeserializeStatement(Stream);
    //sub2
    if GetByteFlag(flags,3) then
      Result^.Sub2 := DeserializeStatement(Stream);
    //temp
    if GetByteFlag(flags,4) then
      Result^.Temp := DeserializeStatement(Stream);
    //next
    if GetByteFlag(flags,5) then
      Result^.Next := DeserializeStatement(Stream);
  finally
    //pop����
    if pushed then
      FFuncStack.Pop;
  end;
end;

procedure TJParser.SerializeExpr(P: PJExpr; Stream: TStream);
//���̃V���A���C�Y
//0.ok 1.symbol 2.value 3.left 4.right 5.third  6.statement
var
  len: Integer;
  flags: Byte;
begin
  //flag�쐬
  flags := SetByteFlag(
    [True,                 //0
     Length(P^.Symbol) > 0,//1
     Assigned(P^.Value),   //2
     Assigned(P^.Left),    //3
     Assigned(p^.Right),   //4
     Assigned(P^.Third),   //5
     Assigned(P^.Statement), //6
     False]);
  //��
  Stream.WriteBuffer(flags,SizeOf(flags));
  //op
  Stream.WriteBuffer(P^.Code,SizeOf(P^.Code));
  //������
  len := Length(P^.Symbol);
  if len > 0 then
  begin
    Stream.WriteBuffer(len,SizeOf(len));
    Stream.WriteBuffer(P^.Symbol[1],len);
  end;
  //TJValue
  if Assigned(p^.Value) then
    SerializeValue(P^.Value,Stream);
  //left
  if Assigned(p^.Left) then
    SerializeExpr(P^.Left,Stream);
  //right
  if Assigned(p^.Right) then
    SerializeExpr(P^.Right,Stream);
  //third
  if Assigned(p^.Third) then
    SerializeExpr(P^.Third,Stream);
  //statemnt
  if Assigned(P^.Statement) then
    SerializeStatement(P^.Statement,Stream);
end;

function TJParser.DeserializeExpr(Stream: TStream): PJExpr;
//���̃f�V���A���C�Y
//0.ok 1.symbol 2.value 3.left 4.right 5.third 6.statement
var
  len: Integer;
  flags: Byte;
begin
  Stream.ReadBuffer(flags,SizeOf(flags));
  //���쐬
  Result := FExpr.NewExpr;
  //op
  Stream.ReadBuffer(Result^.Code,SizeOf(Result^.Code));
  //������
  if GetByteFlag(flags,1) then
  begin
    Stream.ReadBuffer(len,SizeOf(len));
    SetLength(Result^.Symbol,len);
    Stream.ReadBuffer(Result^.Symbol[1],len);
  end;
  //TJValue
  if GetByteFlag(flags,2) then
    Result^.Value := DeserializeValue(Stream);
  //left
  if GetByteFlag(flags,3) then
    Result^.Left := DeserializeExpr(Stream);
  //right
  if GetByteFlag(flags,4) then
    Result^.Right := DeserializeExpr(Stream);
  //third
  if GetByteFlag(flags,5) then
    Result^.Third := DeserializeExpr(Stream);
  //statement
  if GetByteFlag(flags,6) then
    Result^.Statement := DeserializeStatement(Stream);
end;

procedure TJParser.SerializeValue(P: PJValue; Stream: TStream);
//value�̃V���A���C�Y
//0.ok 1.vstring
var
  len: Integer;
  flags: Byte;
begin
  //flag�쐬
  flags := SetByteFlag(
    [True,                   //0
     Length(P^.vString) > 0, //1
     False,False,False,False,False]);
  //value
  Stream.WriteBuffer(flags,SizeOf(flags));
  //value type
  Stream.WriteBuffer(P^.ValueType,SizeOf(P^.ValueType));
  //�l
  case P^.ValueType of
    vtUndefined,vtNull,vtInteger,
    vtBool,vtInfinity,vtNaN:
    begin  //4�o�C�g
      Stream.WriteBuffer(P^.vInteger,SizeOf(P^.vInteger));
    end;

    vtDouble:
    begin
      Stream.WriteBuffer(P^.vDouble,SizeOf(P^.vDouble));
    end;

    vtRegExp:
    begin
      //���K�\��
      Stream.WriteBuffer(P^.vRegExpOptions[0],SizeOf(P^.vRegExpOptions));
    end;

    vtFunction,
    vtString,vtObject,
    vtDispatch://�������Ȃ�;
  end;

  //������
  len := Length(P^.vString);
  if len > 0 then
  begin
    Stream.WriteBuffer(len,SizeOf(len));
    Stream.WriteBuffer(P^.vString[1],len);
  end;
end;

function TJParser.DeserializeValue(Stream: TStream): PJValue;
//value�̃f�V���A���C�Y
//0.ok 1.vstring
var
  flags: Byte;
  len: Integer;
begin
  Stream.ReadBuffer(flags,SizeOf(flags));
  //value�쐬
  New(Result);
  EmptyValue(Result^);
  //value type
  Stream.ReadBuffer(Result^.ValueType,SizeOf(Result^.ValueType));
  //�l
  case Result^.ValueType of
    vtUndefined,vtNull,vtInteger,
    vtBool,vtInfinity,vtNaN:
    begin  //4�o�C�g
      Stream.ReadBuffer(Result^.vInteger,SizeOf(Result^.vInteger));
    end;

    vtDouble:
    begin
      Stream.ReadBuffer(Result^.vDouble,SizeOf(Result^.vDouble));
    end;

    vtRegExp:
    begin
      //���K�\��
      Stream.ReadBuffer(Result^.vRegExpOptions[0],SizeOf(Result^.vRegExpOptions));
    end;

    vtFunction,
    vtString,vtObject,
    vtDispatch://�������Ȃ�;
  end;

  //������
  if GetByteFlag(flags,1) then
  begin
    Stream.ReadBuffer(len,SizeOf(len));
    SetLength(Result^.vString,len);
    Stream.ReadBuffer(Result^.vString[1],len);
  end;
end;

function TJParser.Serialize(Filename: String): Boolean;
//�V���A���C�Y
var
  fs: TFileStream;
begin
  Result := False;
  if not Assigned(FRoot) then
    Exit;

  try
    fs := TFileStream.Create(Filename,fmCreate);
    try
      SerializeRoot(FRoot,fs);
      Result := True;
    finally
      fs.Free;
    end;
  except
    on EFCreateError do
  end;
end;

function TJParser.Deserialize(Filename: String): Boolean;
//���ɖ߂�
var
  fs: TFileStream;
begin
  Result := False;
  //�N���A
  Clear;
  FSourceCode := '';
  //�I���
  if not FileExists(Filename) then
    Exit;

  try
    fs := TFileStream.Create(Filename,fmOpenRead);
    try
      FRoot := DeserializeRoot(fs);
      Result := Assigned(FRoot);
    finally
      fs.Free;
    end;
  except
    on EFOpenError do
  end;
end;

function TJParser.OptionVarExpression: PJExpr;
//�ϐ��錾���܂ގ�
//option_var_expression  : expression
//                       | _VAR expression
//                       | (null)
var
  exp: PJExpr;
begin
  Result := Expression;
  if not Assigned(Result) then
  begin
    if Token = _VAR then
    begin
      GetLex;
      exp := Expression;
      if Assigned(exp) then
        Result := FExpr.MakeExpr1(opVar,exp)
      else
        Error;
    end;
  end;
end;

function TJParser.AtSetStatement: PJStatement;
//�����R���p�C����`
//@set_statement : ATMARK[@] 'set' ATMARK[@] variable ASSIGNOP[=] constant_expression
var
  key: String;
  exp: PJExpr;
  v: PJValue;
begin
  Result := nil;
  if Token = ATMARK then
  begin
    GetLex;
    if (Token = _VARIABLE) and (FLex.yytext = 'set') then
    begin
      GetLex;
      if Token = ATMARK then
      begin
        GetLex;
        if Token = _VARIABLE then
        begin
          key := FLex.yytext;
          GetLex;
          if Token = OP_ASSIGN then
          begin
            GetLex;
            exp := Expression;
            if Assigned(exp) and (exp^.Code = opConstant) then
            begin
              v := exp^.Value;
              if IsInteger(v) or IsBool(v) then
              begin
                FCC[key] := AsInteger(v);
                //�󕶂��쐬
                Result := FStmt.MakeEmptyStatement(FLex.LineNo);
              end
              else
                Error;
            end
            else
              Error;
          end
          else
            Error;
        end
        else
          Error;
      end
      else
        Error;
    end
    else
      Error;
  end;
end;

function TJParser.ConditionalCompile: PJStatement;
//�����R���p�C��
//conditional_compile : @set_statement
//                    | @if_statement
//                    | @cc_on_statement;
begin
  Result := AtSetStatement;
end;

function TJParser.ParseEval(ACode: String): PJExpr;
//eval()�]�����s��
//var
  //lval: Boolean;
begin
  Result := nil;
  //�R�[�h���֐����ɂ���
  ACode := 'function(){return ' + ACode + ' ;}';//()';
  //lex���N���A
  FLex.Input := ACode;
  //��i�߂�
  FFuncStack.Push(nil);
  try
    if GetLex then
      Result := FunctionExpression;  //opFunc�̂�
      //Result := PostfixExpression(lval);  //opCall���܂߂�
  finally
    FFuncStack.Pop;
  end;
end;

function TJParser.FindImportFilename(Filename: String;
  var FindedFilename: String): Boolean;
//�C���|�[�g����t�@�C������T��
var
  i: Integer;
  path,tmp: String;
begin
  Result := False;
  FindedFilename := '';
  //�ŏ��͂��̂܂܃`�F�b�N
  if FileExists(Filename) then
  begin
    Result := True;
    FindedFilename := Filename;
    Exit;
  end;

  //������Ȃ��ꍇ��libpath����T��
  tmp := ExtractFilename(Filename);
  for i := 0 to FLibPath.Count - 1 do
  begin
    path := IncludeTrailingBackslash(FLibPath[i]) + tmp;
    if FileExists(path) then
    begin
      Result := True;
      FindedFilename := path;
      Break;
    end;
  end;
end;

end.
