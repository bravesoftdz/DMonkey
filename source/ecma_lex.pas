unit ecma_lex;

//���L�V�J���A�i���C�U
//2001/04/19 ~
//by Wolfy

interface

uses
  sysutils,windows,classes,hashtable,ecma_type;

{$DEFINE USE_WIDE}

type
{$IFDEF USE_WIDE}
  ECMAChar = WideChar;
  PECMAChar = PWideChar;
  ECMAString = WideString;
{$ELSE}
  ECMAChar = Char;
  PECMAChar = PChar;
  ECMAString = String;
{$ENDIF}

type
  YYSType = record
    case Integer of
      0: (yyChar: ECMAChar);
      1: (yyPChar: PECMAChar);
      2: (yyInteger: Integer);
      3: (yyDouble: Double);
  end;

  TJLex = class(TObject)
  private
    FTable: TIntegerHashTable;
    FToken: Integer;
    FPrevToken: Integer;
    FInput: ECMAString;
    FOutput: ECMAString;
    FLineNo: Integer;
    FCount: Integer;
    FMaxInput: Integer;
    FEOF: Boolean;
    FUnLex: Boolean;
    FOndebug: TStringEvent;

    function LexString: Integer;
    function LexNumber: Integer;
    function LexOP: Integer;
    function LexIdent: Integer;
    function LexComment1: Integer;
    function LexComment2: Integer;
    function LexRegExp: Integer;
    procedure SetInput(const Value: ECMAString);
    function GetChar: ECMAChar;
    procedure UnGetChar;
    procedure RegistIdent;
    procedure SetToken(T: Integer);
  public
    yylval: YYSType;
    yytext: ECMAString;

    constructor Create;
    destructor Destroy; override;
    function Next: Boolean;
    procedure UnLex;
    procedure Clear;
    procedure ImportSource(S: ECMAString);

    property Token: Integer read FToken write SetToken;
    property Input: ECMAString read FInput write SetInput;
    property Output: ECMAString read FOutput;
    property LineNo: Integer read FLineNo;
    property EOF: Boolean read FEOF;
    property OnDebug: TStringEvent read FOndebug write FOnDebug;
  end;

const _VAR = 257;
const _FUNCTION = 258;
//const _PRINT = 259;
const _IF = 260;
const _ELSE = 261;
const _WHILE = 262;
const _FOR = 263;
const _CONTINUE = 264;
const _BREAK = 265;
const _RETURN = 266;
const _WITH = 267;
const _THIS = 268;
const _NULL = 269;
const _TRUE = 270;
const _FALSE = 271;
const _NEW = 272;
const _DELETE = 273;
const _VOID = 274;
const _TYPEOF = 275;
const _TRY = 276;
const _CATCH = 277;
const _FINALLY = 278;
const _THROW = 279;
const _UNDEFINED = 280;
const _INFINITY = 281;
const _IN = 282;
const _CASE = 283;
const _CLASS = 284;
const _CONST = 285;
const _DEBUGGER = 286;
const _DO = 287;
const _ENUM = 288;
const _EXPORT = 289;
const _EXTENDS = 290;
const _IMPORT = 291;
const _SUPER = 292;
const _SWITCH = 293;

const _QUOTE_STRING = 294;
const _VARIABLE = 295;
const _NUMBER = 296;
const _FLOAT_NUMBER = 297;
const LINE_TERMINATOR = 298;
const LP = 299;
const RP = 300;
const LB = 301;
const RB = 302;
const LSQ = 303;
const RSQ = 304;
const SC = 305;
const COMMA = 306;
const LF = 307;
const ADDOP = 308;
const SHIFTOP = 309;
const MULOP = 310;
const COMPOP = 311;
const EQOP = 312;
const ASSIGNOP = 313;
const INCDECOP = 314;
const UNOP = 315;
const OP_ASSIGN = 316;
const QUERY = 317;
const COLON = 318;
const OP_LOGICAL_OR = 319;
const OP_LOGICAL_AND = 320;
const OP_BIT_OR = 321;
const OP_BIT_XOR = 322;
const OP_BIT_AND = 323;
const DOT = 324;
const _REGEXP = 325;
const _DEFAULT = 326;
const ATMARK = 327;
const _STATIC = 328;
const _GLOBAL = 329;

const COMMENT = 0;
//const _DIV = 501;
const _NaN = 502;


implementation

procedure Chomp(var s: ECMAString);
begin
  Delete(s,Length(s),1);
end;

{ TJLex }

procedure TJLex.Clear;
begin
  FLineNo := 1;
  FOutput := '';
  FInput := '';
  FToken := 0;
  FCount := 1;
  FEOF := True;
  FPrevToken := 0;
end;

constructor TJLex.Create;
begin
  inherited Create;
  FTable := TIntegerHashTable.Create(100);
  RegistIdent;
end;

destructor TJLex.Destroy;
begin
  FreeAndNil(FTable);
  inherited;
end;

function TJLex.GetChar: ECMAChar;
//1�����Ԃ�
begin
  if FCount <= FMaxInput then
  begin
    Result := FInput[FCount];
    //���s���`�F�b�N
    if Result = #10 then
      Inc(FLineNo);

    Inc(FCount);
    FEOF := False;
  end
  else begin
    //eof
    FEOF := True;
    Result := #0;
    Token := 0;
  end;
end;

function TJLex.LexComment1: Integer;
//���s�܂œǂݔ�΂�
var
  c: ECMAChar;
begin
  Result := COMMENT;
  while not EOF do
  begin
    c := GetChar;
    if c = #10 then
      Break;
  end;
end;

{function TJLex.LexComment2: Integer;
// */�܂œǂݔ�΂�
var
  c: ECMAChar;
begin
  Result := COMMENT;
  while not EOF do
  begin
    c := GetChar;
    if (c = '*') and (GetChar = '/') then
      Break;
  end;
end;}

function TJLex.LexComment2: Integer;
// */�܂œǂݔ�΂�
var
  c: ECMAChar;
begin
  Result := COMMENT;
  c := GetChar;
  while not EOF do
  begin
    if c = '*' then
    begin
      c := GetChar;
      if c = '/' then
        Break;
      Continue;
    end;
    c := GetChar;
  end;
end;

function TJLex.LexIdent: Integer;
//���ʎq�����o��
var
  c: ECMAChar;
  t: Integer;
  re,member: Boolean;
begin
  yytext := '';
  re := False;
  //���ʎq�̒��O�� . �Ȃ�΃����o�ϐ��ƔF������
  member := (FPrevToken = DOT);

  while not EOF do
  begin
    c := GetChar;
    yytext := yytext + c;
    case c of
      //���ʎq
      '0'..'9','A'..'Z','a'..'z':
      begin
        //yytext := yytext + c;
      end;

      //���K�\��
      '$':
      begin
        //RegExp.$
        if member and (yytext = '$') then
          re := True;
      end;

      '_':
      begin
        //���K�\��
        if re then
        begin
          //�u������
          yytext := 'input';
          Break;
        end;
      end;

      //���K�\���̓��ꕶ��
      '&','`','"','+','*':
      begin
        //RegExp.$& RegExp.lastMatch �Ɠ��ӁB
        //RegExp.$` RegExp.leftContext �Ɠ��ӁB
        //RegExp.$" RegExp.rightContext �Ɠ��ӁB
        //RegExp.$+ RegExp.lastParen �Ɠ��ӁB
        //RegExp.$_ RegExp.input �Ɠ��ӁB
        //RegExp.$* RegExp.multiline �Ɠ��ӁB
        //���K�\��
        if re then
        begin
          //�u������
          case c of
            '&': yytext := 'lastMatch';
            '`': yytext := 'leftContext';
            '"': yytext := 'rightContext';
            '+': yytext := 'lastParen';
            '*': yytext := 'multiline';
          else
            UnGetChar;
          end;
        end
        else
          UnGetChar;

        //�I���
        Break;
      end
    else
      UnGetChar;
      Break;
    end;
  end;

  t := FTable[yytext];
  if (t <= 0) or member then
  begin
    //�ϐ�
    Result := _VARIABLE;
    yylval.yyPChar := PECMAChar(yytext);
  end
  else //�\���
    Result := t;
end;

function TJLex.LexNumber: Integer;
//���������o��
var
  c: ECMAChar;
begin
  Result := _NUMBER;
  yytext := '';
  while not EOF do
  begin
    //�܂����ׂĎ��o��
    c := GetChar;
    yytext := yytext + c;
    case c of
      '0'..'9':
      begin
        //yytext := yytext + c;
      end;
      'X', 'x':
      begin
        //yytext := yytext + c;
        while not EOF do
        begin
          c := GetChar;
          yytext := yytext + c;
          case c of
            '0'..'9', 'A'..'F', 'a'..'f':
            begin
              //yytext := yytext + c;
            end;
            else
              UnGetChar;
              Break;
          end;
        end;
        Break;
      end;
      '.':
      begin
        c := GetChar;
        yytext := yytext + c;
        case c of
          '0'..'9':
          begin
            //yytext := yytext + '.' + c;
            Result := _FLOAT_NUMBER;
          end;
          else
            UnGetChar;
            UnGetChar;
            Break;
        end;
      end;
      'e','E':
      begin
        c := GetChar;
        yytext := yytext + c;
        case c of
          '0'..'9','+','-':
          begin
            //yytext := yytext + 'e' + c;
            Result := _FLOAT_NUMBER;
          end;
          else
            UnGetChar;
            UnGetChar;
            Break;
        end;
      end;
      else
        UnGetChar;
        Break;
    end; //case
  end; //while

  //�l
  if Result = _FLOAT_NUMBER then
  begin
    try
      yylval.yyDouble := StrToFloat(yytext);
    except
      Result := _NaN;
    end;
  end
  else begin
    try
      yylval.yyInteger := StrToInt(yytext);
    except
      //�����ɂł��Ȃ������ꍇ�͕���
      try
        yylval.yyDouble := StrToInt64(yytext);
        Result := _FLOAT_NUMBER;
      except
        try
          yylval.yyDouble := StrToFloat(yytext);
          Result := _FLOAT_NUMBER;
        except
          Result := _NaN;
        end;
      end;
    end;
  end;

end;

function TJLex.LexOP: Integer;
//���Z�q�����o��
var
  c: ECMAChar;
begin
  Result := 0;
  c := GetChar;
  yytext := c;
  case c of
    '?': Result := QUERY;
    ':': Result := COLON;
    ';': Result := SC;
    '.': Result := DOT;
    ',': Result := COMMA;
    '{': Result := LB;
    '}': Result := RB;
    '(': Result := LP;
    ')': Result := RP;
    '[': Result := LSQ;
    ']': Result := RSQ;
    '@': Result := ATMARK;
    '~':
    begin
      yylval.yyChar := '~';
      Result := UNOP;
    end;
    '/':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '/' then   //�R�����g
        Result := LexComment1
      else if c = '*' then   //�R�����g
        Result := LexComment2
      else
        case FPrevToken of
          _NULL,_TRUE,_FALSE,_UNDEFINED,_INFINITY,_NaN,_QUOTE_STRING,_REGEXP,
          _VARIABLE,_NUMBER,_FLOAT_NUMBER,RP,RSQ:
          begin
            if c = '=' then   // /=
            begin
              yylval.yyChar := '/';
              Result := ASSIGNOP;
            end
            else begin
              UnGetChar;
              yylval.yyChar := '/';
              Result := MULOP;
            end;
          end;
          else
            UnGetChar;
            Result := LexRegExp;
        end;//case
    end;

    '!':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '=' then
      begin
        c := GetChar;
        yytext := yytext + c;
        if c = '=' then
        begin
          yylval.yyChar := '2';
          Result := EQOP;
        end
        else begin
          UnGetChar;
          yylval.yyChar := '!';
          Result := EQOP;
        end;
      end
      else begin
        UnGetChar;
        yylval.yyChar := '!';
        Result := UNOP;
      end;
    end;
    '>':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '=' then
      begin
        yylval.yyChar := ')';
        Result := COMPOP;
      end
      else if c = '>' then
      begin
        c := GetChar;
        yytext := yytext + c;
        if c = '>' then
        begin
          c := GetChar;
          yytext := yytext + c;
          if c = '=' then
          begin
            yylval.yyChar := '3';
            Result := ASSIGNOP;
          end
          else begin
            UnGetChar;
            yylval.yyChar := '3';
            Result := SHIFTOP;
          end;
        end
        else if c = '=' then
        begin
          yylval.yyChar := '>';
          Result := ASSIGNOP;
        end
        else begin
          UnGetChar;
          yylval.yyChar := '>';
          Result := SHIFTOP;
        end;
      end
      else begin
        UnGetChar;
        yylval.yyChar := '>';
        Result := COMPOP;
      end;
    end;
    '<':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '=' then
      begin
        yylval.yyChar := '(';
        Result := COMPOP;
      end
      else if c = '<' then
      begin
        c := GetChar;
        yytext := yytext + c;
        if c = '=' then
        begin
          yylval.yyChar := '<';
          Result := ASSIGNOP;
        end
        else begin
          UnGetChar;
          yylval.yyChar := '<';
          Result := SHIFTOP;
        end;
      end
      else begin
        UnGetChar;
        yylval.yyChar := '<';
        Result := COMPOP;
      end;
    end;
    '=':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '=' then
      begin
        c := GetChar;
        yytext := yytext + c;
        if c = '=' then
        begin
          yylval.yyChar := '3';
          Result := EQOP;
        end
        else begin
          UnGetChar;
          yylval.yyChar := '=';
          Result := EQOP;
        end;
      end
      else begin
        UnGetChar;
        Result := OP_ASSIGN;
      end;
    end;
    '&':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '&' then
      begin
        Result := OP_LOGICAL_AND;
      end
      else if c = '=' then
      begin
        yylval.yyChar := '&';
        Result := ASSIGNOP;
      end
      else begin
        UnGetChar;
        Result := OP_BIT_AND;
      end;
    end;
    '|':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '|' then
      begin
        Result := OP_LOGICAL_OR;
      end
      else if c = '=' then
      begin
        yylval.yyChar := '|';
        Result := ASSIGNOP;
      end
      else begin
        UnGetChar;
        Result := OP_BIT_OR;
      end;
    end;
    '-':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '-' then
      begin
        yylval.yyChar := '-';
        Result := INCDECOP;
      end
      else if c = '=' then
      begin
        yylval.yyChar := '-';
        Result := ASSIGNOP;
      end
      else begin
        UnGetChar;
        yylval.yyChar := '-';
        Result := ADDOP;
      end;
    end;
    '+':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '+' then
      begin
        yylval.yyChar := '+';
        Result := INCDECOP;
      end
      else if c = '=' then
      begin
        yylval.yyChar := '+';
        Result := ASSIGNOP;
      end
      else begin
        UnGetChar;
        yylval.yyChar := '+';
        Result := ADDOP;
      end;
    end;
    '*':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '=' then
      begin
        yylval.yyChar := '*';
        Result := ASSIGNOP;
      end
      else begin
        UnGetChar;
        yylval.yyChar := '*';
        Result := MULOP;
      end;
    end;
    '%':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '=' then
      begin
        yylval.yyChar := '%';
        Result := ASSIGNOP;
      end
      else begin
        UnGetChar;
        yylval.yyChar := '%';
        Result := MULOP;
      end;
    end;
    '^':
    begin
      c := GetChar;
      yytext := yytext + c;
      if c = '=' then
      begin
        yylval.yyChar := '^';
        Result := ASSIGNOP;
      end
      else begin
        UnGetChar;
        Result := OP_BIT_XOR;
      end;
    end;
  end;//case
end;

function TJLex.LexString: Integer;
//����������o��
var
  quote,c: ECMAChar;
begin
  Result := 0;
  quote := GetChar;
  yytext := '';

  while not EOF do
  begin
    c := GetChar;
    if (c = '\') and (quote = '"') then
    begin //�G�X�P�[�v;
      c := GetChar;
      case c of
        'n': yytext := yytext + #13#10;
        'f': yytext := yytext + #12;
        'b': yytext := yytext + #8;
        'r': yytext := yytext + #13;
        't': yytext := yytext + #9;
        '\': yytext := yytext + '\';
      else
        if c = quote then
          yytext := yytext + quote;
      end;
    end
    else if c = quote then
    begin
      Result := _QUOTE_STRING;
      yylval.yyPChar := PECMAChar(yytext);
      Break;
    end
    else begin//���ʂɉ�����
      yytext := yytext + c;
    end;
  end;

end;

function TJLex.Next: Boolean;
//����token�𓾂�
var
  c: ECMAChar;
begin
  if FUnLex then
  begin
    Result := True;
    FUnLex := False;
    Exit;
  end;

  Result := False;
  FPrevToken := Token; //���O��token��ۑ����Ă���

  while not FEOF do
  begin
    //Token := 0;
    c := GetChar;
    //�S�p�X�y�[�X���΂�
    if c = '�@' then
      Continue;

    case c of
      #0..' ':; //��΂�
      '0'..'9': //����
      begin
        UnGetChar;
        Token := LexNumber;
        if Token <> 0 then
        begin
          Result := True;
          Break;
        end;
      end;
      '$','_','A'..'Z','a'..'z':  //�\��ꂩ�ϐ�
      begin
        UnGetChar;
        Token := LexIdent;
        if Token <> 0 then
        begin
          Result := True;
          Break;
        end;
      end;
      '"','''': //������
      begin
        UnGetChar;
        Token := LexString;
        if Token <> 0 then
        begin
          Result := True;
          Break;
        end;
      end;
      '!','#','%'..'&','('..'/',':'..'@','['..'^','`','{'..'~':
      begin  //���̑��̋L��
        UnGetChar;
        Token := LexOP;
        if Token <> 0 then
        begin
          Result := True;
          Break;
        end;
      end;
    end;

  end;
  //�f�o�b�O
  if Assigned(FOnDebug) and (Token <> 0) then
    FOnDebug(Self,IntToStr(Token) + '( ' + yytext + ' )');
end;

procedure TJLex.RegistIdent;
//�\����o�^����
begin
  FTable['var'] := _VAR;
  FTable['function'] := _FUNCTION;
  //FTable['print'] := _PRINT;
  FTable['if'] := _IF;
  FTable['else'] := _ELSE;
  FTable['while'] := _WHILE;
  FTable['for'] := _FOR;
  FTable['continue'] := _CONTINUE;
  FTable['break'] := _BREAK;
  FTable['return'] := _RETURN;
  FTable['with'] := _WITH;
  FTable['this'] := _THIS;
  FTable['null'] := _NULL;
  FTable['true'] := _TRUE;
  FTable['false'] := _FALSE;
  FTable['new'] := _NEW;
  FTable['delete'] := _DELETE;
  FTable['void'] := _VOID;
  FTable['typeof'] := _TYPEOF;
  FTable['try'] := _TRY;
  FTable['catch'] := _CATCH;
  FTable['finally'] := _FINALLY;
  FTable['throw'] := _THROW;
  FTable['undefined'] := _UNDEFINED;
  FTable['infinity'] := _INFINITY;
  FTable['in'] := _IN;
  FTable['case'] := _CASE;
  FTable['class'] := _CLASS;
  FTable['const'] := _CONST;
  FTable['debugger'] := _DEBUGGER;
  FTable['do'] := _DO;
  FTable['enum'] := _ENUM;
  FTable['export'] := _EXPORT;
  FTable['extends'] := _EXTENDS;
  FTable['import'] := _IMPORT;
  FTable['super'] := _SUPER;
  FTable['switch'] := _SWITCH;
  FTable['default'] := _DEFAULT;
  FTable['static'] := _STATIC;
  FTable['global'] := _GLOBAL;


  //FTable['div'] := _DIV;
  FTable['NaN'] := _NaN;
end;

procedure TJLex.SetInput(const Value: ECMAString);
//��������Z�b�g����
begin
  Clear;
  FInput := Value;
  FCount := 1;
  FMaxInput := Length(Value);
  if FMaxInput <= 0 then
    FEOF := True
  else
    FEOF := False;
end;

procedure TJLex.SetToken(T: Integer);
//token���Z�b�g
begin
  FToken := T;
end;

procedure TJLex.UnGetChar;
//�P�����߂�
begin
  Dec(FCount);
  //eof�`�F�b�N
  FEOF := (FCount > FMaxInput);
  //�P�������
  Chomp(yytext);
end;

procedure TJLex.UnLex;
begin
  FUnLex := True;
end;

function TJLex.LexRegExp: Integer;
//������
var
  c: ECMAChar;
begin
  Result := 0;
  yytext := '';

  while not EOF do
  begin
    c := GetChar;
    case c of
      '\':
      begin //�G�X�P�[�v;
        c := GetChar;
        case c of
          #0 : ; //EOF
          'n': yytext := yytext + #13#10; //������Ǝd�l�����킹��
          'f': yytext := yytext + #12;
          'b': yytext := yytext + #8;
          'r': yytext := yytext + #13;
          't': yytext := yytext + #9;
          '/': yytext := yytext + '/';
        else
          yytext := yytext + '\' + c; //���̂܂ܓn��
        end;
      end;
      '/':
      begin
        yytext := yytext + #0; //#0������
        while not EOF do
        begin
          c := GetChar;
          yytext := yytext + c;
          case c of
            'g','i','m': ;//yytext := yytext + c;
          else
            UnGetChar;
            Break;
          end;
        end;
        {c := GetChar;
        yytext := yytext + c;
        UnGetChar;
        case c of
          'g', 'i':
          begin
            yytext := yytext + #0; //#0������
            while not EOF do
            begin
              c := GetChar;
              yytext := yytext + c;
              case c of
                'g', 'i': ;//yytext := yytext + c;
              else
                UnGetChar;
                Break;
              end;
            end;
          end;
        end;}

        Result := _REGEXP;
        yylval.yyPChar := PECMAChar(yytext);
        Break;
      end;
      else //���ʂɉ�����
        yytext := yytext + c;
    end;//case
  end;//while
end;

procedure TJLex.ImportSource(S: ECMAString);
//�\�[�X��}��
begin
  if S <> '' then
  begin
    Insert(S,FInput,FCount);
    FMaxInput := Length(FInput);
    FEOF := False;
  end;
end;


end.
