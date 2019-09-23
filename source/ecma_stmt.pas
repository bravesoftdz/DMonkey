unit ecma_stmt;

//�����`����
//2001/04/13 ~
//by Wolfy

interface

uses
  windows,sysutils,classes,ecma_type,ecma_expr,contnrs;

//procedure InitProgram(var P: PJStatement);
//procedure FreeStatement(P: PJStatement);

type
  TJStatementFactory = class(TObject)
  private
    FList: TList;
    FExprFactory: TJExprFactory;
    procedure FreeStatement(P: PJStatement);
  public
    constructor Create(AExprFactory: TJExprFactory);
    destructor Destroy; override;
    procedure Clear;

    function NewStatement: PJStatement;

    procedure MakeSourcePush(FuncStack: TStack ;Name: PJExpr);
    function MakeSourcePop(FuncStack: TStack ;SourceElements: PJStatement): PJStatement;
    procedure MakeFunctionDeclPush(FuncStack: TStack ;LineNo: Integer);
    function MakeFunctionDeclPop(FuncStack: TStack ;ID: PJExpr; ParamDecl,Block: PJStatement): PJStatement;
    procedure MakeClassDeclPush(FuncStack: TStack ;LineNo: Integer);
    function MakeClassDeclPop(FuncStack: TStack ;Name,Super: PJExpr; Block: PJStatement): PJStatement;

    function MakeExprStatement(LineNo: Integer; Expr: PJExpr): PJStatement;
    function MakeBlockStatement(LineNo: Integer; Statements: PJStatement): PJStatement;
    function MakeReturnStatement(LineNo: Integer; Expr: PJExpr): PJStatement;
    function MoveStart(P: PJStatement): PJStatement;
    function MoveLast(P: PJStatement): PJStatement;
    procedure MergeStatement(Prev,Next: PJStatement);
    function MakeIfStatement(LineNo: Integer; Expr: PJExpr; TrueBlock: PJStatement; FalseBlock: PJStatement = nil): PJStatement;
    function MakeWhileStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
    function MakeDoStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
    function MakeForStatement(LineNo: Integer; Expr1,Expr2,Expr3: PJExpr; Block: PJStatement): PJStatement;
    function MakeForInStatement(LineNo: Integer; Expr1,Expr2: PJExpr; Block: PJStatement; ArrayElement: Boolean = False): PJStatement;
    function MakeContinueStatement(LineNo: Integer): PJStatement;
    function MakeBreakStatement(LineNo: Integer): PJStatement;
    function MakeWithStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
    function MakeTryStatement(LineNo: Integer; Block,ACatch,AFinally: PJStatement): PJStatement;
    function MakeCatchStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
    function MakeFinallyStatement(LineNo: Integer; Block: PJStatement): PJStatement;
    function MakeThrowStatement(LineNo: Integer; Expr: PJExpr): PJStatement;
    function MakeEmptyStatement(LineNo: Integer): PJStatement;
    function MakeVarDecl(LineNo: Integer; Stmt: PJStatement; VarType: TJRegistVarType): PJStatement;
    function MakeParamDecl(LineNo: Integer; Prev: PJStatement; ID: PJExpr): PJStatement;
    function MakeVariableDecl(LineNo: Integer; Name,Value: PJExpr): PJStatement;
    function MakeLabeledStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
    function MakeSwitchStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
  end;

implementation


{ TJStatementFactory }

procedure TJStatementFactory.Clear;
//�N���A
var
  i: Integer;
begin
  for i := FList.Count - 1 downto 0 do
    FreeStatement(FList[i]);

  FList.Clear;
end;

constructor TJStatementFactory.Create(AExprFactory: TJExprFactory);
begin
  inherited Create;
  FList := TList.Create;
  FExprFactory := AExprFactory;
end;

destructor TJStatementFactory.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited;
end;

procedure TJStatementFactory.FreeStatement(P: PJStatement);
begin
  Dispose(P);
end;  

function TJStatementFactory.NewStatement: PJStatement;
//����V�K�쐬
begin
  New(Result);
  FillChar(Result^,SizeOf(TJStatement),0);
  Result^.SType := stNone;
  FList.Add(Result);
end;

function TJStatementFactory.MakeExprStatement(LineNo: Integer; Expr: PJExpr): PJStatement;
//�����̍쐬
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.Expr := Expr;
  Result^.SType := stExpr;
end;

function TJStatementFactory.MakeBlockStatement(LineNo: Integer; Statements: PJStatement): PJStatement;
//�u���b�N���쐬
// block - next(...)
// |-sub1(statements) - next(...)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stBlock;
  Result^.Sub1 := MoveStart(Statements);
end;

function TJStatementFactory.MakeParamDecl(LineNo: Integer; Prev: PJStatement; ID: PJExpr): PJStatement;
//�֐��p�����[�^�錾
// param_decl(ID) - next(param_decl) - next(...)
//var
//  e: TJExpr;
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stParamDecl;
  Result^.Expr := ID;
  //e := ID^;
  MergeStatement(Prev,Result);
end;

function TJStatementFactory.MakeReturnStatement(LineNo: Integer; Expr: PJExpr): PJStatement;
//return�����쐬
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stReturn;
  Result^.Expr := Expr;
end;

function TJStatementFactory.MoveStart(P: PJStatement): PJStatement;
//�ŏ��Ɉړ�����
begin
  Result := P;
  while Assigned(Result) do
  begin
    //�e�������Ȃ�ΏI��
    if not Assigned(Result^.Prev) then
      Break
    else
      Result := Result^.Prev;
  end;
end;

function TJStatementFactory.MoveLast(P: PJStatement): PJStatement;
//�Ō�Ɉړ�����
begin
  Result := P;
  while Assigned(Result) do
  begin
    //�����Ȃ��Ȃ�I��
    if not Assigned(Result^.Next) then
      Break
    else
      Result := Result^.Next;
  end;
end;

procedure TJStatementFactory.MergeStatement(Prev,Next: PJStatement);
//���݂ɂ�������  next <-> parent�̂�
begin
  if Assigned(Prev) then
    Prev^.Next := Next;

  if Assigned(Next) then
    Next^.Prev := Prev;
end;

function TJStatementFactory.MakeIfStatement(LineNo: Integer; Expr: PJExpr; TrueBlock,FalseBlock: PJStatement): PJStatement;
//if�����쐬
// if   - next(...)
// |-sub1(trueblock)
// |-sub2(falseblock)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stIf;
  Result^.Expr := Expr;
  Result^.Sub1 := TrueBlock;
  Result^.Sub2 := FalseBlock;
end;

function TJStatementFactory.MakeWhileStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
//while�����쐬
// while(expr)  - next(...)
// |-sub1(block)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stWhile;
  Result^.Expr := Expr;
  Result^.Sub1 := Block;
end;

function TJStatementFactory.MakeForStatement(LineNo: Integer; Expr1,Expr2,Expr3: PJExpr; Block: PJStatement): PJStatement;
//for�����쐬
// for(expr1) --- next(...)
// |-sub1(block)
// |-sub2(expr2) --- next(expr3)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stFor;
  Result^.Expr := Expr1;
  Result^.Sub1 := Block;

  Result^.Sub2 := NewStatement;
  Result^.Sub2^.Expr := Expr2;

  Result^.Sub2^.Next := NewStatement;
  Result^.Sub2^.Next^.Expr := Expr3;
end;

function TJStatementFactory.MakeForInStatement(LineNo: Integer; Expr1,Expr2: PJExpr;
  Block: PJStatement; ArrayElement: Boolean): PJStatement;
//for (in)�����쐬
// forin(expr1 - variable) --- next(...)
// |-sub1(block)
// |-sub2(expr2 - object)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  if ArrayElement then
    Result^.SType := stForInArrayElement
  else
    Result^.SType := stForIn;

  Result^.Expr := Expr1;
  Result^.Sub1 := Block;
  //�I�u�W�F�N�g
  Result^.Sub2 := NewStatement;
  Result^.Sub2^.Expr := Expr2;
end;

function TJStatementFactory.MakeContinueStatement(LineNo: Integer): PJStatement;
//contnue���쐬
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stContinue;
end;

function TJStatementFactory.MakeBreakStatement(LineNo: Integer): PJStatement;
//break���쐬
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stBreak;
end;

function TJStatementFactory.MakeWithStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
//with�����쐬
// with(expr)  - next(...)
//  |
// sub1(block)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stWith;
  Result^.Expr := Expr;
  Result^.Sub1 := Block;
end;

function TJStatementFactory.MakeTryStatement(LineNo: Integer;
  Block,ACatch,AFinally: PJStatement): PJStatement;
//try�����쐬
// try - next(...)
//  |
// sub1(block)
// sub2(catch)
// sub3(finally)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stTry;
  Result^.Sub1 := Block;
  Result^.Sub2 := ACatch;
  Result^.Temp := AFinally;
end;

function TJStatementFactory.MakeCatchStatement(LineNo: Integer; Expr: PJExpr; Block: PJStatement): PJStatement;
//catch�����쐬
// catch(variable) - next(...)
//  |
// sub1(block)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stCatch;
  Result^.Expr := Expr;
  Result^.Sub1 := Block;
end;

function TJStatementFactory.MakeFinallyStatement(LineNo: Integer; Block: PJStatement): PJStatement;
//finally�����쐬
// finally - next(...)
//  |
// sub1(block)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stFinally;
  Result^.Sub1 := Block;
end;

function TJStatementFactory.MakeThrowStatement(LineNo: Integer; Expr: PJExpr): PJStatement;
//trow�����쐬
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stThrow;
  Result^.Expr := Expr;
end;

function TJStatementFactory.MakeEmptyStatement(LineNo: Integer): PJStatement;
//�󕶂��쐬
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
end;

function TJStatementFactory.MakeVarDecl(LineNo: Integer;
  Stmt: PJStatement; VarType: TJRegistVarType): PJStatement;
//var��static�����쐬
//var( ) - next(...)
// |- sub1(variable_declaration_list)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;    
  Result^.Sub1 := Stmt;
  case VarType of
    rvGlobal: Result^.SType := stGlobal;
    rvStatic: Result^.SType := stStatic;
  else
    Result^.SType := stVar;
  end;
end;

function TJStatementFactory.MakeDoStatement(LineNo: Integer; Expr: PJExpr;
  Block: PJStatement): PJStatement;
//do - while�����쐬
// do(expr)  - next(...)
// |-sub1(block)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stDo;
  Result^.Expr := Expr;
  Result^.Sub1 := Block;
end;

function TJStatementFactory.MakeVariableDecl(LineNo: Integer;
  Name,Value: PJExpr): PJStatement;
// memberdecl(expr: name,expr.left: value) - next(...)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stVariableDecl;
  Result^.Expr := Name;
  Result^.Expr^.Left := Value;
end;

function TJStatementFactory.MakeLabeledStatement(LineNo: Integer; Expr: PJExpr;
  Block: PJStatement): PJStatement;
//labeled�����쐬
// case(const) - next(...)
// default
//  |
// sub1(block)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stLabeled;
  //expr��nil�̏ꍇ��default
  Result^.Expr := Expr;
  Result^.Sub1 := Block;
end;

function TJStatementFactory.MakeSwitchStatement(LineNo: Integer; Expr: PJExpr;
  Block: PJStatement): PJStatement;
//switch�����쐬
// switch(expr) - next(...)
//  |
// sub1(block)
begin
  Result := NewStatement;
  Result^.LineNo := LineNo;
  Result^.SType := stSwitch;
  Result^.Expr := Expr;
  Result^.Sub1 := Block;
end;

procedure TJStatementFactory.MakeFunctionDeclPush(FuncStack: TStack ;
  LineNo: Integer);
//�֐��錾�J�n
var
  p: PJStatement;
begin
  p := NewStatement;
  p^.LineNo := LineNo;
  p^.SType := stFunctionDecl;
  //���݂̐e�֐�
  p^.Temp := FuncStack.Peek;
  //push
  FuncStack.Push(p);
end;

function TJStatementFactory.MakeFunctionDeclPop(FuncStack: TStack ;
  ID: PJExpr; ParamDecl, Block: PJStatement): PJStatement;
//�֐��錾�I��
// function_decl - next(...)
// |-sub1(paramdecl) - next(param_decl) - next(...)
// |-sub2(block)
//   |-sub1(statements) - next(...)
// |-temp(parent function)
var
  ret: PJStatement;
begin
  //pop
  Result := FuncStack.Pop;
  Result^.Sub1 := MoveStart(ParamDecl);
  Result^.Sub2 := MoveStart(Block);
  Result^.Expr := ID;
  //block�̍Ō��return��t����
  ret := MakeReturnStatement(E_UNKNOWN_LINE_NO,FExprFactory.NewExpr);
  MergeStatement(MoveLast(Block),ret);
end;

procedure TJStatementFactory.MakeSourcePush(FuncStack: TStack ;Name: PJExpr);
//�\�[�X�p�b�P�[�W�̍쐬�J�n
var
  p: PJStatement;
begin
  p := NewStatement;
  p^.LineNo := 1;
  p^.SType := stSource;
  p^.Expr := Name;
  //push
  FuncStack.Push(p);
end;

function TJStatementFactory.MakeSourcePop(FuncStack: TStack ;
  SourceElements: PJStatement): PJStatement;
//�\�[�X�p�b�P�[�W�̍쐬
// source_elements(expr: name)
//  | sub1(source_elements)
begin
  //pop
  Result := FuncStack.Pop;
  Result^.Sub1 := SourceElements;
end;

procedure TJStatementFactory.MakeClassDeclPush(FuncStack: TStack; LineNo: Integer);
//�N���X�쐬�J�n
var
  p: PJStatement;
begin
  p := NewStatement;
  p^.LineNo := LineNo;
  p^.SType := stClassDecl;
  //���݂̐e
  p^.Temp := FuncStack.Peek;
  //push
  FuncStack.Push(p);
end;

function TJStatementFactory.MakeClassDeclPop(FuncStack: TStack;
  Name, Super: PJExpr; Block: PJStatement): PJStatement;
//classdecl(expr: name,expr.left: super)  ... next(...)
// |- sub1(block)
// |- temp(parent function)
begin
  //pop
  Result := FuncStack.Pop;
  Result^.Expr := Name;
  Result^.Expr^.Left := Super;
  Result^.Sub1 := Block;
end;



end.
