unit ecma_re;

interface

uses
  windows,sysutils,classes,regexpr;

type
  TJRegExp = class;
  TStringArray = array of String;
  TFuncReplace = function(RE: TJRegExp; Matched: String): String of object;

  //���K�\��
  TJRegExp = class(TObject)
  private
    FRegExp: TRegExpr;
    FGlobal: Boolean;
    FIndex: Integer;
    FLastIndex: Integer;
    FLastMatch: String;
    FLeftContext: String;
    FRightContext: String;
    FLastParen: String;
    FSubMatch: TStringArray;
    FInput: String;

    function GetIgnoreCase: Boolean;
    function GetMultiLine: Boolean;
    function GetSource: String;
    procedure SetIgnoreCase(const Value: Boolean);
    procedure SetMultiLine(const Value: Boolean);
    procedure SetSource(const Value: String);
    procedure SetMatchedParams(AInput: String; RetList: TStrings);
  public
    constructor Create;
    destructor Destroy; override;
    function Split(AInput: String; RetList: TStrings; Limit: Integer = MaxInt - 1): Boolean;
    function Test(AInput: String): Boolean;
    function Exec(AInput: String; RetList: TStrings = nil): Boolean;
    function Replace(AInput: String; ReplaceStr: String; FuncReplace: TFuncReplace = nil): String;
    procedure ClearMatched;
    procedure Assign(RE: TJRegExp);

    property ignoreCase: Boolean read GetIgnoreCase write SetIgnoreCase;
    property global: Boolean read FGlobal write FGlobal;
    property source: String read GetSource write SetSource;
    property multiline: Boolean read GetMultiLine write SetMultiLine;
    property input: String read FInput write FInput;
    //$1...$9 - �}�b�`�����O���[�v���i�[���Ă��܂� (ECMAScript �񏀋�)
    property index: Integer read FIndex;
    property lastIndex: Integer read FLastIndex;
    property lastMatch: String read FLastMatch;
    property lastParen: String read FLastParen;
    property leftContext: String read FLeftContext;
    property rightContext: String read FRightContext;
    property SubMatch: TStringArray read FSubMatch;
  end;


implementation

{ TJRegExp }

procedure TJRegExp.Assign(RE: TJRegExp);
//�R�s�[����
begin
  FIndex := RE.index;
  FLastIndex := RE.lastIndex;
  FLastMatch := RE.lastMatch;
  FLeftContext := RE.leftContext;
  FRightContext := RE.rightContext;
  FLastParen := RE.lastParen;
  FSubMatch := RE.SubMatch;

  IgnoreCase := RE.ignoreCase;
  Global := RE.global;
  Source := RE.source;
  MultiLine := RE.multiline;
  FInput := RE.input;   
end;

procedure TJRegExp.ClearMatched;
begin
  FIndex := -1;
  FLastIndex := -1;
  FLastMatch := '';
  FLeftContext := '';
  FRightContext := '';
  FLastParen := '';
  FSubMatch := nil;
end;

constructor TJRegExp.Create;
begin
  inherited;
  FRegExp := TRegExpr.Create;
  FRegExp.ModifierR := False;
end;

destructor TJRegExp.Destroy;
begin
  FreeAndNil(FRegExp);
  inherited;
end;

function TJRegExp.Exec(AInput: String; RetList: TStrings): Boolean;
//���K�\���}�b�`���O�����s����
begin
  FInput := AInput;
    
  if Assigned(RetList) then
    RetList.Clear;

  try
    Result := FRegExp.Exec(FInput);
    if Result then
    begin
      //�o�^����
      SetMatchedParams(FInput,RetList);
      //global�̏ꍇ�͘A���ōs��
      while FGlobal and FRegExp.ExecNext do
        SetmatchedParams(FInput,RetList);
    end;
  except
    on ERegExpr do
      Result := False;
  end;
end;

function TJRegExp.GetIgnoreCase: Boolean;
begin
  Result := FRegExp.ModifierI;
end;

function TJRegExp.GetMultiLine: Boolean;
begin
  Result := FRegExp.ModifierM;
end;

function TJRegExp.GetSource: String;
begin
  Result := FRegExp.Expression;
end;

function TJRegExp.Replace(AInput, ReplaceStr: String;
  FuncReplace: TFuncReplace): String;
//�u��������
var
  prev: integer;
begin
  FInput := AInput;
  Result := '';
  prev := 1;    
  try
    if FRegExp.Exec(FInput) then
    begin
      repeat
        //�}�b�`�̑O�܂ŃR�s�[
        Result := Result + Copy(FInput,prev,FRegExp.MatchPos[0] - prev);
        //submatch���Z�b�g
        SetMatchedParams(FInput,nil);
        //�u���֐����Ă�
        if Assigned(FuncReplace) then
          Result := Result + FuncReplace(Self,FRegExp.Match[0])
        else //submatch$n��ϊ�
          Result := Result + FRegExp.Substitute(ReplaceStr);

        //�ړ�
        prev := FRegExp.MatchPos[0] + FRegExp.MatchLen[0];

      until (not FGlobal) or (not FRegExp.ExecNext);
    end;

    Result := Result + Copy(FInput,prev,MaxInt);
  except
    on ERegExpr do
  end;

end;

procedure TJRegExp.SetIgnoreCase(const Value: Boolean);
begin
  FRegExp.ModifierI := Value;
end;

procedure TJRegExp.SetMatchedParams(AInput: String; RetList: TStrings);
//�o�^����
var
  sub: String;
  i: Integer;
begin
  ClearMatched;
  //�}�b�`����������
  if Assigned(RetList) then
    RetList.Add(FRegExp.Match[0]);

  //lastmatch
  FLastMatch := FRegExp.Match[0];
  //index
  if FRegExp.MatchPos[0] > -1 then
    FIndex := FRegExp.MatchPos[0] - 1
  else
    FIndex := -1;
  //lastindex
  if FRegExp.MatchLen[0] > -1 then
    FLastIndex := FRegExp.MatchPos[0] - 1 + FRegExp.MatchLen[0]
  else
    FLastIndex := -1;
  //leftcontext
  FLeftContext := Copy(AInput,1,FRegExp.MatchPos[0] - 1);
  //rightcontext
  FRightContext := Copy(AInput,FRegExp.MatchPos[0] + FRegExp.MatchLen[0],MaxInt);
  //$
  SetLength(FSubMatch,FRegExp.SubExprMatchCount + 1);
  //0�̓}�b�`������
  FSubMatch[0] := FRegExp.Match[0];
  for i := 1 to FRegExp.SubExprMatchCount do
  begin
    sub := FRegExp.Match[i];
    //$���Z�b�g����
    FSubMatch[i] := sub;
    //lastparen
    FLastParen := sub;
  end; 
end;

procedure TJRegExp.SetMultiLine(const Value: Boolean);
begin
  FRegExp.ModifierM := Value;
end;

procedure TJRegExp.SetSource(const Value: String);
begin
  FRegExp.Expression := Value;
end;

function TJRegExp.Split(AInput: String; RetList: TStrings; Limit: Integer): Boolean;
//��������
var
  i,del: Integer;
begin
  FInput := AInput;
  Result := True;
  RetList.Clear;
  if Limit < 0 then
    Limit := MAXINT - 1;

  try
    FRegExp.Split(FInput,RetList);
    //count�̕����傫����Ώ���
    if Limit < RetList.Count then
    begin
      del := RetList.Count - Limit;
      for i := (RetList.Count - 1) downto (RetList.Count - 1) - del do
        RetList.Delete(i);
    end;
  except
    //���s
    on ERegExpr do
      Result := False;
  end;
end;

function TJRegExp.Test(AInput: String): Boolean;
//exec���Ă�
begin
  Result := Exec(AInput);
end;

end.
