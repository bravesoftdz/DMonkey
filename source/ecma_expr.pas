unit ecma_expr;

//���̉�͖؊֌W
//2001/04/10 ~
//by Wolfy

interface

uses
  windows,sysutils,classes,ecma_type;

type
  TJExprFactory = class(TObject)
  private
    FList: TList;

    procedure FreeExpr(P: PJExpr);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    //�V����node���쐬
    function NewExpr: PJExpr;
    //1�������쐬����
    function MakeExpr1(Code: TJOPCode;Left: PJExpr): PJExpr;
    //2�������쐬����
    function MakeExpr2(Code: TJOPCode;Left,Right: PJExpr): PJExpr;
    //3�������쐬����
    function MakeExpr3(Code: TJOPCode;Left,Right,Third: PJExpr): PJExpr;
    //�萔�����쐬
    function MakeConstant(Value: TJValue): PJExpr;
    //�ϐ������쐬
    function MakeVariable(Symbol: String): PJExpr;
    //�萔�̐������쐬
    function MakeNumberInt(Value: Integer): PJExpr;
    function MakeNumberFloat(Value: Double): PJExpr;
    function MakeNull: PJExpr;
    function MakeNaN: PJExpr;
    function MakeBoolean(Value: Boolean): PJExpr;
    function MakeString(S: String): PJExpr;
    function MakeUndefined: PJExpr;
    function MakeInfinity(Negative: Boolean): PJExpr;
    function MakeThis: PJExpr;
    function MakeSuper(Expr: PJExpr): PJExpr;
    function MakeArguments(Prev,Next: PJExpr): PJExpr;
    function MakeObjectElement(Name,Value: PJExpr): PJExpr;
    function MakeRegExp(RE: String): PJExpr;
    function MakeFunction(FuncDecl: PJStatement): PJExpr;
  end;


implementation


constructor TJExprFactory.Create;
begin
  inherited Create;
  FList := TList.Create;
end;

destructor TJExprFactory.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited;
end;

procedure TJExprFactory.FreeExpr(P: PJExpr);
begin
  //�萔�����
  if Assigned(P^.Value) then
  begin
    system.Dispose(P^.Value);
  end;

  system.Dispose(P);
end;

procedure TJExprFactory.Clear;
//�N���A
var
  i: Integer;
begin
  for i := FList.Count - 1 downto 0 do
  begin
    FreeExpr(FList[i]);
    //FList.Delete(i);
  end;
  FList.Clear;
end;

function TJExprFactory.NewExpr: PJExpr;
//�V���������쐬����
begin
{ TODO : ��������Y�ꂸ�� }
  New(Result);
  //����������
  Result^.Code := opNone;
  Result^.Left := nil;
  Result^.Third := nil;
  Result^.Right := nil;
  Result^.Value := nil;
  Result^.Symbol := '';
  Result^.Statement := nil;
  FList.Add(Result);
end;


function TJExprFactory.MakeExpr1(Code: TJOPCode; Left: PJExpr): PJExpr;
//1�������쐬����
begin
  //�萔�̐܂���
  if IsConstant(Left) and (Code in [opMinus,opPlus,opBitNot]) then
  begin
    Left^.Value^ := CalcValue1(Code,Left^.Value^);
    Result := Left;
  end
  else begin
    //�V�K�쐬����
    Result := NewExpr;
    Result^.Code := Code;
    Result^.Left := Left;
    Result^.Right := nil;
  end;
end;

function TJExprFactory.MakeExpr2(Code: TJOPCode; Left,Right: PJExpr): PJExpr;
//2�������쐬����
var
  v: TJValue;
begin
  //�萔�̐܂���
  if IsConstant(Left) and IsConstant(Right) then
  begin
    case Code of
      opAdd,opSub,opMul,opDiv,opMod,opDivInt,opBitAnd,opBitOr,opBitXor,
      opBitLeft,opBitRight,opBitRightZero:
      begin
        //object�������Ă�\�������邽�ߗ�������
        v := CalcValue2(Code,Left^.Value^,Right^.Value^);
        FList.Remove(Left);
        FList.Remove(Right);
        FreeExpr(Left);
        FreeExpr(Right);
        Result := MakeConstant(v);
      end;
      opLS,opGT,opLSEQ,opGTEQ,opEQ,opNE,opEQEQEQ,opNEEQEQ,
      opLogicalOr,opLogicalOr2,opLogicalAnd,opLogicalAnd2:
      begin
        v := CompareValue(Code,Left^.Value^,Right^.Value^);
        FList.Remove(Left);
        FList.Remove(Right);
        FreeExpr(Left);
        FreeExpr(Right);
        Result := MakeConstant(v);
      end;
      else
        //�V�K�쐬����
        Result := NewExpr;
        Result^.Code := Code;
        Result^.Left := Left;
        Result^.Right := Right;
    end;
  end
  else begin
    //�V�K�쐬����
    Result := NewExpr;
    Result^.Code := Code;
    Result^.Left := Left;
    Result^.Right := Right;
  end;
end;


function TJExprFactory.MakeExpr3(Code: TJOPCode;Left,Right,Third: PJExpr): PJExpr;
//3�������쐬����
begin
  //�V�K�쐬����
  Result := NewExpr;
  Result^.Code := Code;
  Result^.Left := Left;
  Result^.Right := Right;
  Result^.Third := Third;
end;

function TJExprFactory.MakeConstant(Value: TJValue): PJExpr;
//�萔�����쐬
begin
  Result := NewExpr;
  Result^.Code := opConstant;
  //�萔��V�K�쐬
  New(Result^.Value);
  Result^.Value^ := Value;
end;

function TJExprFactory.MakeVariable(Symbol: String): PJExpr;
//�ϐ��쐬
begin
  Result := NewExpr;
  Result^.Code := opVariable;
  Result^.Symbol := Symbol;
end;

function TJExprFactory.MakeNumberInt(Value: Integer): PJExpr;
//�萔�̐������쐬
var
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtInteger;
  v.vInteger := Value;
  Result := MakeConstant(v);
end;

function TJExprFactory.MakeNumberFloat(Value: Double): PJExpr;
//�萔�̕��������_���쐬
var
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtDouble;
  v.vDouble := Value;
  Result := MakeConstant(v)
end;

function TJExprFactory.MakeNull: PJExpr;
//null���쐬
var
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtNull;
  v.vNull := nil;
  Result := MakeConstant(v)
end;

function TJExprFactory.MakeBoolean(Value: Boolean): PJExpr;
//bool���쐬
var
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtBool;
  v.vBool := Value;
  Result := MakeConstant(v)
end;

function TJExprFactory.MakeString(S: String): PJExpr;
//��������쐬
var
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtString;
  v.vString := S;
  Result := MakeConstant(v)
end;

function TJExprFactory.MakeUndefined: PJExpr;
//����`���쐬
var
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtUndefined;
  Result := MakeConstant(v)
end;

function TJExprFactory.MakeInfinity(Negative: Boolean): PJExpr;
//��������쐬
var
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtInfinity;
  v.vBool := Negative;
  Result := MakeConstant(v)
end;

function TJExprFactory.MakeThis: PJExpr;
//this���쐬
begin
  Result := NewExpr;
  Result^.Code := opThis;
end;

function TJExprFactory.MakeRegExp(RE: String): PJExpr;
//���K�\�����쐬(��)
var
  p: Integer;
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtRegExp;
  p := Pos(#0, RE); //#0�ȍ~�Ƀt���O�������Ă���
  if p > 0 then
  begin
    v.vString := Copy(RE, 1, p - 1);
    v.vRegExpOptions := Copy(RE, p + 1, MaxInt);
  end
  else
    v.vString := RE;

  Result := MakeConstant(v);
end;   

function TJExprFactory.MakeArguments(Prev,Next: PJExpr): PJExpr;
//�������쐬
begin
  Result := NewExpr;
  Result^.Code := opArg;
  Result^.Left := Prev;
  Result^.Right := Next;
end;

function TJExprFactory.MakeNaN: PJExpr;
//NaN���쐬
var
  v: TJValue;
begin
  EmptyValue(v);
  v.ValueType := vtNaN;
  v.vNull := nil;
  Result := MakeConstant(v)
end;

function TJExprFactory.MakeObjectElement(Name, Value: PJExpr): PJExpr;
begin
  Result := NewExpr;
  Result^.Code := opObjectElement;
  Result^.Left := Name;
  Result^.Right := Value;
end;

function TJExprFactory.MakeSuper(Expr: PJExpr): PJExpr;
//super���쐬
begin
  Result := NewExpr;
  Result^.Code := opSuper;
  Result^.Right := Expr;
end;

function TJExprFactory.MakeFunction(FuncDecl: PJStatement): PJExpr;
//function�萔���쐬
begin
  Result := NewExpr;
  Result^.Code := opFunction;
  Result^.Statement := FuncDecl;
end;

end.
