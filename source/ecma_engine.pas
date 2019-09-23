unit ecma_engine;

//��͖؂̎��s
//2001/04/10 ~
//by Wolfy

{$DEFINE REFCOUNT_DEBUG}

interface

uses
  windows,classes,sysutils,ecma_type,hashtable,ecma_object,
{$IFNDEF NO_SOCKET}
  ecma_sockobject,
{$ENDIF}
{$IFNDEF NO_ACTIVEX}
  activex,ComObj,ecma_activex,
{$ENDIF}
{$IFNDEF NO_DYNACALL}
  dynamiccall,
{$ENDIF}
{$IFNDEF NO_WSH}
  ecma_wsh,
{$ENDIF}
{$IFNDEF CONSOLE}
  forms,
{$ENDIF}
  ecma_parser;

type
  TJEngine = class(TJBaseEngine)
  private
    FParent: TJBaseDMonkey;
    FParser: TJParser;
    FRootTable: TJRootSymbolTable;
    FCurrentTable: TJLocalSymbolTable;
    FFactory: TJObjectFactory;

    FIsRan: Boolean;
    FAbort: Boolean;
    FIsRunning: Boolean;
    FLineNo: Integer;
    FAllowEvent: Boolean;
    FFilename: String;
    FRegistVar: TJRegistVarType;
    //event
    FOnNewObject: TNewObjectEvent;
    FOnStdout: TStringEvent;
    FOnStderr: TStringEvent;
    FOnRun: TNotifyEvent;
    FOnDone: TNotifyEvent;
    FOnStep: TStepEvent;
    FOnStdin: TReadStringEvent;
    FOnError: TErrorEvent;
    FOnDoEvents: TStepEvent;

    //global object
    FGlobalObject: TJGlobalObject;
    FRegExpObject: TJRegExpObject;
{$IFNDEF NO_WSH}
    FWScriptObject: TJWScriptObject;
{$ENDIF}
    procedure Println(S: String);
    procedure PrintlnError(S: String);

    function EvalExpr(P: PJExpr; Flags: TJEvalExprFlags = []): TJValue;
    procedure EvalStatement(P: PJStatement; Flags: TJEvalStatementFlags; SwitchValue: PJSwitchValue = nil);

    function MemberExpr(Parent: TJValue; Member: String; Deleting: Boolean = False): TJValue;
    procedure MemberAssign(Parent: TJValue; Member: String; Value: TJValue);
    function CallArrayExpr(Parent: TJValue; Arguments: PJExpr): TJValue;
    procedure CallArrayAssign(Parent: TJValue; Arguments: PJExpr; Value: TJValue);
    function MethodExpr(P: PJExpr): TJValue;
    procedure MethodAssign(P: PJExpr; Value: TJValue);

    function ArgumentsToList(Arg: PJExpr): TJValueList;
    function ArgumentsToValue(Arg: PJExpr): TJValue;
    function ArgumentsCount(Arg: PJExpr): Integer;
    procedure ObjectExpr(Obj: TJObject; Elements: PJExpr);

    procedure MakeInstance(Obj: TJObject; Members: PJStatement);
    procedure RegistGlobalObjects(ASymbolTable: TJLocalSymbolTable);
    procedure ClearGlobalObjects;

    function GetThisFromValue(Value: TJValue): TJObject;

    procedure BeforeRun(Main: Boolean = False);
    procedure AfterRun;

    //object event
    procedure RegExpOnMatchStart(Sender: TObject);
    procedure RegExpOnMatchEnd(Sender: TObject);
    procedure RegExpOnExecInput(Sender: TObject; var Input: String);

    procedure FactoryOnNewObject(Sender: TObject; JObject: TJObject);

    procedure GlobalObjectOnPrint(Sender: TObject; S: String);
    procedure GlobalObjectOnPrintError(Sender: TObject; S: String);
    procedure GlobalObjectOnRead(Sender: TObject; var S: String; var Success: Boolean;
      Count: Integer; Line: Boolean);

    function GetObjectCount: Integer;
    function GetOnDebugout: TStringEvent;
    procedure SetOnDebugout(const Value: TStringEvent);
  public
    constructor Create(AParent: TJBaseDMonkey);
    destructor Destroy; override;
    procedure Clear;
    procedure Abort;

    function Compile(SourceCode: String): Boolean;
    function CompileFile(AFilename: String; UseBinary: Boolean): Boolean;
    function Run(Root: PJStatement; Args: TJValueList): Integer; overload;
    function Run: Integer; overload;
    function CallExpr(Func: IJFunction; Param: TJValueList; This: TJObject = nil): TJValue;
    function CallFunction(Root: PJStatement; Symbol: String;
      Param: TJValueList; var RetValue: TJValue): Boolean; overload;
    function CallFunction(Symbol: String;
      Param: TJValueList; var RetValue: TJValue): Boolean; overload;
    function CallEvent(var Event: TJValue; Param: TJValueList; This: TJObject = nil): TJValue;
    function Eval(SourceCode: String; This: TJObject = nil): TJValue;

    function MakeObject(Name: String; Param: TJValueList): TJObject; override;
    procedure ImportObject(ObjectName: String; ObjectClass: TJObjectClass); override;
    function IsRunning: Boolean;
    function GetVariable(Symbol: String; var RetVal: TJValue): Boolean;
    function DoEvents: Boolean;
    function GetScriptFilename: String; override;
    function FindImportFilename(Filename: String; var FindedFilename: String): Boolean; override;

    property GlobalObject: TJGlobalObject read FGlobalObject;
    property ObjectCount: Integer read GetObjectCount;
    property Factory: TJObjectFactory read FFactory;
    property Parent: TJBaseDMonkey read FParent;
    property LineNo: Integer read FLineNo write FLineNo;
    property AllowEvent: Boolean read FAllowEvent;
    property ScriptFilename: String read GetScriptFilename;
    property Parser: TJParser read FParser;
    property CurrentTable: TJLocalSymbolTable read FCurrentTable;
    property RegistVar: TJRegistVarType read FRegistVar write FRegistVar;
    //event
    property OnNewObject: TNewObjectEvent read FOnNewObject write FOnNewObject;
    property OnStdout: TStringEvent read FOnStdout write FOnStdout;
    property OnStderr: TStringEvent read FOnStderr write FOnStderr;
    property OnRun: TNotifyEvent read FOnRun write FOnRun;
    property OnDone: TNotifyEvent read FOnDone write FOnDone;
    property OnStep: TStepEvent read FOnStep write FOnStep;
    property OnStdin: TReadStringEvent read FOnStdin write FOnStdin;
    property OnError: TErrorEvent read FOnError write FOnError;
    property OnDebugout: TStringEvent read GetOnDebugout write SetOnDebugout;
    property OnDoEvents: TStepEvent read FOnDoEvents write FOnDoEvents;
  end;

implementation


{ TJEngine }

procedure TJEngine.Println(S: String);
//stdout
begin
  GlobalObjectOnPrint(Self,S + CRLF);
end;

constructor TJEngine.Create(AParent: TJBaseDMonkey);
//�쐬
begin
  inherited Create;
  FParent := AParent;
  FParser := TJParser.Create;
  FFactory := TJObjectFactory.Create(Self);
  FFactory.OnNewObject := FactoryOnNewObject;
  FRootTable := TJRootSymbolTable.Create(nil);
  FCurrentTable := FRootTable;

  //�g���݃I�u�W�F�N�g��o�^
  ImportObject('Object',TJObject);
  ImportObject('Global',TJGlobalObject);
  ImportObject('Array',TJArrayObject);
  ImportObject('String',TJStringObject);
  ImportObject('Number',TJNumberObject);
  ImportObject('Boolean',TJBooleanObject);
  ImportObject('RegExp',TJRegExpObject);
  ImportObject('Math',TJMathObject);
  ImportObject('Date',TJDateObject);

  //�f�t�H���g�I�u�W�F�N�g
  FGlobalObject := TJGlobalObject.Create(Self,nil,False);
  FGlobalObject.OnPrint := GlobalObjectOnPrint;
  FGlobalObject.OnRead := GlobalObjectOnRead;
  FRegExpObject := TJRegExpObject.Create(Self,nil,False);
{$IFNDEF NO_WSH}
  FWScriptObject := TJWScriptObject.Create(Self,nil,False);
  FWScriptObject.OnStdOut := GlobalObjectOnPrint;
  FWScriptObject.OnStdErr := GlobalObjectOnPrintError;
  FWScriptObject.OnStdIn := GlobalObjectOnRead;
{$ENDIF}
  //�Q�ƃJ�E���g
  FGlobalObject.IncRef;
  FRegExpObject.IncRef;
{$IFNDEF NO_WSH}
  FWScriptObject.IncRef;
{$ENDIF}
end;

destructor TJEngine.Destroy;
//�j��
begin
  Clear;
  //�Q�ƃJ�E���g
  FreeAndNil(FGlobalObject);
  FreeAndNil(FRegExpObject);
{$IFNDEF NO_WSH}
  FreeAndNil(FWScriptObject);
{$ENDIF}

  FreeAndNil(FRootTable);
  FreeAndNil(FFactory);
  FreeAndNil(FParser);
  inherited;
end;

function TJEngine.Run(Root: PJStatement; Args: TJValueList): Integer;
//���s����
begin
  Result := 0;
  //���s���̏ꍇ�I���
  if IsRunning then
    Exit;
  //root�������ꍇ
  if not Assigned(Root) then
    Root := FParser.Root;
  //�����root��������ΏI���
  if not Assigned(Root) then
    Exit;

  //���s��
  FIsRunning := True;
  try
    Clear;
    FAbort := False;
    FAllowEvent := True;
    //Global���Z�b�g
    FGlobalObject.arguments.Items.Assign(Args);
    //terminated���Z�b�g
    FGlobalObject.Terminate;
    BeforeRun(True);
    try
      //���s
      FCurrentTable := FRootTable;
      EvalStatement(Root,[]);
      //����I��
      FIsRan := True;
      //�����I�u�W�F�N�g���g�p���邽�߂�currenttable��__MAIN__�ɕύX����
      FCurrentTable := FRootTable.FindGlobalTable(__MAIN__);
    except
      //Exit,Return�͐���I������
      on E:EJExit do
      begin
        FIsRan := True;
        Result := E.Status;
      end;
      on E:EJReturn do
      begin
        FIsRan := True;
        Result := AsInteger(@E.Value);
      end;
      //��O�A���~�̂Ƃ��̓C�x���g���[�v�ɓ���Ȃ�
      on E:EJThrow do
      begin
        FAllowEvent := False;
        PrintlnError('Exception: ' +
          E.ExceptName + '(' + IntToStr(FLineNo) + ') => ' + E.Message);
      end;
      on E:EJAbort do
      begin
        FAllowEvent := False;
        PrintlnError('Abort Script(' + IntToStr(FLineNo) + ')');
      end;
      on E:EJSyntaxError do
      begin
        FAllowEvent := False;
        PrintlnError('SyntaxError: ' +
          'Line(' + IntToStr(FLineNo) + ') => ' + E.Message);
      end;
    end;

    //�C�x���g���[�v�ɓ���
    while ((not FGlobalObject.Terminated) and DoEvents) do
    begin
      Sleep(5);
    end;

    AfterRun;
  finally
    FIsRunning := False;
  end;
end;

procedure TJEngine.EvalStatement(P: PJStatement;
  Flags: TJEvalStatementFlags; SwitchValue: PJSwitchValue);
//�������ԂɎ��s����
var
  current,catch: PJStatement;
  v,compared: TJValue;
  abrt,ebreak: Boolean;
  element: String;
  sl: TStringList;
  i: Integer;
  func: IJFunction;
  switch: TJSwitchValue;
{$IFNDEF NO_ACTIVEX}
  enum: TJEnumeratorObject;
  param: TJValueList;
{$ENDIF}
  arry: TJObject;
  blocktable,
  oldtable: TJLocalSymbolTable;
begin
  current := P;
  while Assigned(current) do
  begin
    //abort
    if FAbort then
      raise EJAbort.Create('script abort');

    //�s�ԍ�
    FLineNo := current^.LineNo;
    //�C�x���g
    if Assigned(FOnStep) then
    begin
      abrt := False;
      FOnStep(Self,abrt);
      //���~����
      if abrt then
        raise EJAbort.Create('script abort');
    end;

    case current^.SType of
      stNone:;

      //source�C���|�[�g
      stSource:
      begin
        //Root�e�[�u���ɒl�Ƃ��ēo�^
        EmptyFunction(func);
        func.FuncType := ftImport;
        func.vStatement := current^.Sub1;
        //���O��� expr���Ȃ�����Global
        if not Assigned(current^.Expr) then
          func.Symbol := __MAIN__
        else
          func.Symbol := current^.Expr^.Symbol;

        //�e�[�u�����쐬 pointer��n�� this��o�^
        func.FunctionTable := FRootTable.MakeGlobalTable(func.Symbol,current);
        func.FunctionTable.This := FGlobalObject;
        //�O���[�o���ϐ���o�^
        RegistGlobalObjects(func.FunctionTable);
        //Namespace��o�^
        FRootTable.RegistGlobalValue(func.Symbol,BuildFunction(func));
        //�V�����e�[�u���Ŏ��s
        oldtable := FCurrentTable;
        FCurrentTable := func.FunctionTable;
        try
          EvalStatement(func.vStatement,[]);
        finally
          FCurrentTable := oldtable;
          //global table�͍폜���Ȃ�
        end;
      end;
      //�ϐ��錾�J�n
      stVar:
      begin
        //stVarDecl��
        EvalStatement(current^.Sub1,Flags + [esfVar]);
      end;
      //static�ϐ��錾�J�n
      stStatic:
      begin
        //stVarDecl��
        EvalStatement(current^.Sub1,Flags + [esfStaticVar]);
      end;
      //Global�ϐ��錾�J�n
      stGlobal:
      begin
        //stVarDecl��
        EvalStatement(current^.Sub1,Flags + [esfGlobalVar]);
      end;
      stVariableDecl:
      begin  //�ϐ��錾�o�^
        if Assigned(current^.Expr^.Left) then
          v := EvalExpr(current^.Expr^.Left)
        else  //0������
          v := BuildInteger(0);

        //�ϐ��o�^
        if esfVar in Flags then
          FCurrentTable.RegistValue(current^.Expr^.Symbol,v)
        else if esfStaticVar in Flags then
          FCurrentTable.RegistStaticValue(current^.Expr^.Symbol,v)
        else
          FCurrentTable.RegistGlobalValue(current^.Expr^.Symbol,v)
      end;
      //�֐���`
      stFunctionDecl:
      begin
        //�֐����Z�b�g
        EmptyFunction(func);
        func.FuncType := ftStatement;
        func.vStatement := current;
        //�p�����[�^�Z�b�g
        func.Parameter := current^.Sub1;
        //�V���{���e�[�u�����쐬
        //�e�֐�����p������
        func.FunctionTable :=
          FRootTable.GetFunctionTable(current^.Temp,current);
        //�ϐ��������݂��Ȃ��ꍇ������
        if Assigned(current^.Expr) then
        begin
          //�֐���
          func.Symbol := current^.Expr^.Symbol;
          //�e�[�u���ɓo�^����
          FCurrentTable.RegistValue(func.Symbol,BuildFunction(func));
        end;
      end;
      //�N���X��`
      stClassDecl:
      begin
        EmptyFunction(func);
        func.Symbol := current^.Expr^.Symbol;
        func.FuncType := ftClass;
        func.vStatement := current;
        //�V���{���e�[�u�����쐬
        //�e�֐�����p������
        func.FunctionTable :=
          FRootTable.GetFunctionTable(current^.Temp,current);
        //�o�^
        FCurrentTable.RegistValue(func.Symbol,BuildFunction(func));
      end;
      //����
      stExpr: EvalExpr(current^.Expr);
      //block�����s
      stBlock:
      begin
        EvalStatement(current^.Sub1,Flags);
      end;
      //for��
      stFor:
      begin
        //��������
        EvalExpr(current^.Expr);
        while True do
        begin
          //�����������݂���ꍇ�̂�
          if Assigned(current^.Sub2^.Expr) then
          begin
            v := EvalExpr(current^.Sub2^.Expr);
            if not AsBool(@v) then
              Break;
          end;

          ebreak := False;
          try
            try
              //�u���b�N�����s
              EvalStatement(current^.Sub1,[esfIteration]);
            except
              //��O�Ƃ��Ď�������
              on EJBreak do
              begin
                ebreak := True;
                Break;
              end;
              on EJContinue do
                Continue;
            end;
          finally
            //��n���� break�̏ꍇ�͎��s���Ȃ�
            if not ebreak then
              EvalExpr(current^.Sub2^.Next^.Expr);
          end;
        end;
      end;
      //if��
      stIf:
      begin
        v := EvalExpr(current^.Expr);
        if AsBool(@v) then
          EvalStatement(current^.Sub1,Flags)
        else begin
          EvalStatement(current^.Sub2,Flags);
        end;
      end;
      //while ��
      stWhile:
      begin
        while True do
        begin
          v := EvalExpr(current^.Expr);
          if not AsBool(@v) then
            Break;

          try
            //�������s
            EvalStatement(current^.Sub1,[esfIteration]);
          except
            //��O�Ƃ��Ď�������
            on EJBreak do
              Break;
            on EJContinue do
              Continue;
          end;
        end;
      end;
      //for in��
      stForIn,stForInArrayElement:
      begin
        //var����
        if current^.Expr^.Code = opVariable then
          element := current^.Expr^.Symbol
        //var����
        else if Assigned(current^.Expr^.Left) and
               (current^.Expr^.Left^.Code = opVariable) then
        begin
          element := current^.Expr^.Left^.Symbol;
          //���[�J���ɕϐ���o�^
          EmptyValue(v);
          FCurrentTable.RegistValue(element,v);
        end
        else //�ϐ��Ŗ����ꍇ�͗�O
          raise EJThrow.Create(E_TYPE,'need variable - for..in');

        v := EvalExpr(current^.Sub2^.Expr);
        //�z��
        if IsArrayObject(@v) then
        begin
          arry := v.vObject;
          case current^.SType of
            //�v�f������
            stForInArrayElement:
            begin
              arry.IncRef;
              try
                for i := 0 to arry.GetCount - 1 do
                begin
                  FCurrentTable.SetValue(element,arry.GetItem(i),FRegistVar);
                  try
                    //�u���b�N�����s
                    EvalStatement(current^.Sub1,[esfIteration]);
                  except
                    //��O�Ƃ��Ď�������
                    on EJBreak do
                      Break;
                    on EJContinue do
                      Continue;
                  end;
                end;
              finally
                arry.DecRef;
              end;
            end;
            //index������
            stForIn:
            begin
              for i := 0 to arry.GetCount - 1 do
              begin
                FCurrentTable.SetValue(element,BuildInteger(i),FRegistVar);
                try
                  //�u���b�N�����s
                  EvalStatement(current^.Sub1,[esfIteration]);
                except
                  //��O�Ƃ��Ď�������
                  on EJBreak do
                    Break;
                  on EJContinue do
                    Continue;
                end;
              end;
            end;
          end;
        end
{$IFNDEF NO_ACTIVEX}
        else if IsCollection(@v) then //Enumerator���s
        begin
          param := TJValueList.Create;
          try
            param.Add(v);
            enum := TJEnumeratorObject.Create(Self,param);
            try
              enum.IncRef;

              while not enum.AtEnd do
              begin
                FCurrentTable.SetValue(element,enum.Item,FRegistVar);
                try try
                  //�u���b�N�����s
                  EvalStatement(current^.Sub1,[esfIteration]);
                finally
                  enum.MoveNext;
                end;
                except
                  //��O�Ƃ��Ď�������
                  on EJBreak do
                    Break;
                  on EJContinue do
                    Continue;
                end;
              end;
            finally
              enum.DecRef;
            end;
          finally
            param.Free;
          end;
        end
{$ENDIF}
        else if IsObject(@v) then
        begin
          //�S�Ă�key�𓾂�
          sl := TStringList.Create;
          try
            v.vObject.GetPropertyList(sl);
            for i := 0 to sl.Count - 1 do
            begin
              //key��ϐ��ɓ����
              FCurrentTable.SetValue(element,BuildString(sl[i]),FRegistVar);
              try
                //�u���b�N�����s
                EvalStatement(current^.Sub1,[esfIteration]);
              except
                //��O�Ƃ��Ď�������
                on EJBreak do
                  Break;
                on EJContinue do
                  Continue;
              end;
            end;
          finally
            sl.Free;
          end;
        end
        else //�I�u�W�F�N�g�łȂ��Ȃ��O
          raise EJThrow.Create(E_TYPE,'need object,array or collection - for..in');
      end;

      //switch��
      stSwitch:
      begin
        //����]��
        v := EvalExpr(current^.Expr);
        try
          //labeled�������s���� SwitchValue�t��
          switch.Match := False;
          switch.Default := nil;
          switch.Value := @v;
          //iteration��true
          //�܂���xdefault��𖳎����Ď��s���Ă݂�
          EvalStatement(current^.Sub1,[esfIteration],@switch);
          //match���Ȃ���default�傪���݂����default�傩����s
          if not switch.Match and Assigned(switch.Default) then
          begin
            switch.Match := True;
            EvalStatement(switch.Default,[esfIteration],@switch);
          end;
        except //break���󂯂�
          on EJBreak do
        end;
      end;
      //case default��
      stLabeled:
      begin
        //switch value�����鎞�̂ݎ��s
        if Assigned(SwitchValue) then
        begin
          //match���Ă��鎞�͖������Ŏ��s����
          if SwitchValue^.Match then
            EvalStatement(current^.Sub1,Flags,nil)
          else begin
            //case:
            if Assigned(current^.Expr) then
            begin
              //�萔�l�𓾂�
              v := EvalExpr(current^.Expr);
              //���K�\�����e�����Ŕ�r����
              if IsRegExpObject(@v) then
              begin
                compared :=
                  BuildBool((v.vObject as TJRegExpObject).Test(SwitchValue^.Value^));
              end
              else if IsRegExp(@v) then
              begin
                FRegExpObject.SetRegExpValue(v);
                compared :=
                  BuildBool(FRegExpObject.Test(SwitchValue^.Value^));
              end
              else //�����Ŕ�r����
                compared := CompareValue(opEQ,v,SwitchValue^.Value^);

              if AsBool(@compared) then
              begin
                EvalStatement(current^.Sub1,Flags,nil);
                //��v������ȍ~�͖������Ŏ��s
                SwitchValue^.Match := True;
              end;
            end
            //default:
            else
              SwitchValue^.Default := current; //default��̏ꏊ��ۑ����Ƃ�
          end;
        end
        else //�ςȏꏊ��label��������
          raise EJThrow.Create(E_SYNTAX,'switch case: or default:');
      end;

      stDo: //do - while��
      begin
        while True do
        begin
          try
            //�������s
            EvalStatement(current^.Sub1,[esfIteration]);
          except
            //��O�Ƃ��Ď�������
            on EJBreak do
              Break;
            on EJContinue do
              Continue;
          end;

          //���𔻒f
          v := EvalExpr(current^.Expr);
          if not AsBool(@v) then
            Break;
        end;
      end;
      //break��  for,while do��switch���~�߂�
      stBreak:
      begin
        if esfIteration in Flags then
          raise EJBreak.Create('break')
        else
          raise EJThrow.Create(E_SYNTAX,'break');
      end;
      //continue��
      stContinue:
      begin
        if esfIteration in Flags then
          raise EJContinue.Create('continue')
        else
          raise EJThrow.Create(E_SYNTAX,'continue');
      end;
      //return��
      stReturn:
      begin
        //return��O
        v := EvalExpr(current^.Expr);
        //�Q�ƃJ�E���g������₷
        if IsObject(@v) then
          v.vObject.IncRef
        //�֐��Ȃ�Εϐ����R�s�[
        else if IsFunction(@v) then
        begin
          //�V�K�쐬
          EmptyFunction(func);
          //copy
          func.Assign(v.vFunction);
          //localtable�쐬
          if not Assigned(func.LocalTable) then
            func.LocalTable := TJLocalSymbolTable.Create(nil);

          //�J�����g�ϐ���copy
          func.LocalTable.LocalCopy(FCurrentTable);
          //v��ύX
          v := BuildFunction(func);
        end;

        raise EJReturn.Create(v);
      end;
      //throw��
      stThrow:
      begin
        v := EvalExpr(current^.Expr);
        //�Q�ƃJ�E���g������₷
        if IsObject(@v) then
          v.vObject.IncRef
        else if IsUndefined(@v) then
          v := BuildString(''); //�󕶎���
        //throw��O
        raise EJThrow.Create(E_THROW,'',@v);
      end;
      //try��
      stTry:
      begin
        //try - sub1(block)
        //    - sub2(catch)
        //    - sub3(finally)
        try try
          EvalStatement(current^.Sub1,Flags);
        except
          //catch��
          on E:EJRuntimeError do
          begin
            //�Đ���
            if not Assigned(current^.Sub2) then
              raise;

            catch := current^.Sub2;
            //�ϐ��o�^
            if IsVariable(catch^.Expr) then
            begin
              //user��O
              if E.ExceptName = E_THROW then
              begin
                //temp�ɎQ�ƃJ�E���g��ω������Ȃ��œo�^
                if IsObject(@E.Value) then
                  FCurrentTable.AddTemporaryObject(E.Value.vObject,False);
                //�o�^
                FCurrentTable.RegistValue(catch^.Expr^.Symbol,E.Value);
              end
              else //��O����o�^
                FCurrentTable.RegistValue(
                  catch^.Expr^.Symbol,BuildString(E.ExceptName));
            end;
            //catch�����s
            EvalStatement(catch^.Sub1,Flags);
          end;
        end;

        finally
          //finally�����s
          if Assigned(current^.Temp) then
            EvalStatement(current^.Temp^.Sub1,Flags);
        end;
      end;
      //with��
      stWith:
      begin
        v := EvalExpr(current^.Expr);
        //object�łȂ��Ȃ��O
        if not IsObject(@v) then
          raise EJThrow.Create(E_TYPE,'need object - with');

        //�V�����u���b�N����� this��push
        blocktable := FCurrentTable.PushLocalTable(nil,v.vObject);
        oldtable := FCurrentTable;
        FCurrentTable := blocktable;
        try
          EvalStatement(current^.Sub1,Flags);
        finally
          FCurrentTable := oldtable;
          FCurrentTable.PopLocalTable;
        end;
      end;

    end;

    //temp object���N���A
    FCurrentTable.ClearTemporaryObject;
    //����
    current := current^.Next;
  end;
end;

function TJEngine.EvalExpr(P: PJExpr; Flags: TJEvalExprFlags): TJValue;
//����]������
var
  l,r,t: PJExpr;
  v: TJValue;
  param: TJValueList;
  name: String;
  func: IJFunction;
begin
  EmptyValue(Result);
  if not Assigned(P) then
    Exit;

  l := P^.Left;
  r := P^.Right;
  t := P^.Third;

  case P^.Code of
    opExpr:
    begin
      EvalExpr(l);
      Result := EvalExpr(r);
    end;

    //�萔�c���̂܂ܕԂ�
    opConstant:
    begin
      Result := P^.Value^;
    end;

    //���[�J���ϐ��錾(for�Ŏg����)
    opVar:
    begin
      //����
      Result := EvalExpr(l,Flags + [eefVar]);
    end;

    //�ϐ��c�e�[�u�����猟������
    opVariable:
    begin
      //�ϐ��錾
      {if eefVar in Flags then
      //  FCurrentTable.RegistLocal(P^.Symbol,Result)
      //�ʏ�
      else
      }
      if FCurrentTable.GetValue(P^.Symbol,Result) then
      begin
        {if eefDelete in Flags then
        begin
        end;}
      end
      else //�ϐ�������`�Ȃ̂ŗ�O
        raise EJThrow.Create(E_NAME,'undefined - ' + P^.Symbol);
    end;

    //����� variable = expr
    opAssign:
    begin
      Result := EvalExpr(r);
      //����ł���̂�4��ނ̂�
      case l^.Code of
        opVariable:
        begin
          if eefVar in Flags then //opVar(for��)�Ŏg�p
            FCurrentTable.RegistValue(l^.Symbol,Result)
          else
            FCurrentTable.SetValue(l^.Symbol,Result,FRegistVar);
        end;

        opMember: MemberAssign(EvalExpr(l^.Left),l^.Right^.Symbol,Result);
        opCallArray: CallArrayAssign(EvalExpr(l^.Left),l^.Right,Result);
        opMethod: MethodAssign(l,Result);
      else
        raise EJThrow.Create(E_TYPE,'can not assign - ' + l^.Symbol);
      end;
    end;

    //���Z�����
    opMulAssign,opDivAssign,opAddAssign,opSubAssign,opModAssign,
    opBitLeftAssign,opBitRightAssign,opBitRightZeroAssign,
    opBitAndAssign,opBitXorAssign,opBitOrAssign:
    begin
      Result := AssignValue(P^.Code,EvalExpr(l),EvalExpr(r));
      //����ł���̂�4��ނ̂�
      case l^.Code of
        opVariable: FCurrentTable.SetValue(l^.Symbol,Result,FRegistVar);
        opMember: MemberAssign(EvalExpr(l^.Left),l^.Right^.Symbol,Result);
        opCallArray: CallArrayAssign(EvalExpr(l^.Left),l^.Right,Result);
        opMethod: MethodAssign(l,Result);
      else
        raise EJThrow.Create(E_TYPE,'can not assign - ' + l^.Symbol);
      end;
    end;

    //�����o�Ăяo�� L ... object  R ... variable
    opMember: Result := MemberExpr(EvalExpr(l),r^.Symbol,eefDelete in Flags);

    //�z��           L ... object|function  R ... arguments
    opCallArray: Result := CallArrayExpr(EvalExpr(l),r);

    //���\�b�h L..object R..variable T..arg
    opMethod: Result := MethodExpr(P);

    opMinus,opPlus,opBitNot:
    begin
      Result := CalcValue1(P^.Code,EvalExpr(l));
    end;
    opPreInc:
    begin
      Result := EvalExpr(l);
      Result := BuildInteger(AsInteger(@Result) + 1);
      if l^.Code = opVariable then
        FCurrentTable.SetValue(l^.Symbol,Result,FRegistVar);
    end;
    opPreDec:
    begin
      Result := EvalExpr(l);
      Result := BuildInteger(AsInteger(@Result) - 1);
      if l^.Code = opVariable then
        FCurrentTable.SetValue(l^.Symbol,Result,FRegistVar);
    end;
    opPostInc:
    begin
      Result := EvalExpr(l);
      if l^.Code = opVariable then
        FCurrentTable.SetValue(l^.Symbol,BuildInteger(AsInteger(@Result) + 1),FRegistVar);
    end;
    opPostDec:
    begin
      Result := EvalExpr(l);
      if l^.Code = opVariable then
        FCurrentTable.SetValue(l^.Symbol,BuildInteger(AsInteger(@Result) - 1),FRegistVar);
    end;
    //�Q����
    opAdd,opSub,opMul,opDiv,opMod,opDivInt,opBitAnd,opBitOr,opBitXor,
    opBitLeft,opBitRight,opBitRightZero:
    begin
      Result := CalcValue2(P^.Code,EvalExpr(l),EvalExpr(r));
    end;

    //��r
    opLS,opGT,opLSEQ,opGTEQ,opEQ,opNE,opEQEQEQ,opNEEQEQ,
    opLogicalOr2,opLogicalAnd2:
    begin
      Result := CompareValue(P^.Code,EvalExpr(l),EvalExpr(r));
    end;
    //�V���[�g�T�[�L�b�g�]��
    opLogicalOr:
    begin
      v := EvalExpr(l);
      if AsBool(@v) then
        Result := BuildBool(True) //right�͕]�����Ȃ�
      else begin
        v := EvalExpr(r);
        Result := BuildBool(AsBool(@v));
      end;
    end;
    opLogicalAnd:
    begin
      v := EvalExpr(l);
      if not AsBool(@v) then
        Result := BuildBool(False) //right�͕]�����Ȃ�
      else begin
        v := EvalExpr(r);
        Result := BuildBool(AsBool(@v));
      end;
    end;
    opLogicalNot:
    begin
      Result := CompareValue(P^.Code,EvalExpr(l),v);
    end;
    //�R����
    opConditional:
    begin
      v := EvalExpr(l);
      if AsBool(@v) then //�Е��̂ݕ]������
        Result := EvalExpr(r)
      else
        Result := EvalExpr(t);
      //Result := CalcValue3(opConditional,Evalexpr(l),EvalExpr(r),EvalExpr(t));
    end;
    //�֐���
    opFunction:
    begin
      //�֐����Z�b�g
      EmptyFunction(func);
      func.FuncType := ftStatement;
      func.vStatement := P^.Statement;
      //�p�����[�^�Z�b�g
      func.Parameter := P^.Statement^.Sub1;
      //���O
      if Assigned(P^.Statement^.Expr) then
        func.Symbol := P^.Statement^.Expr^.Symbol;

      //�V���{���e�[�u�����쐬
      //�e�֐�����p������
      func.FunctionTable :=
        FRootTable.GetFunctionTable(P^.Statement^.Temp,P^.Statement);
      {//localtable�쐬
      if not Assigned(func.LocalTable) then
        func.LocalTable := TJLocalSymbolTable.Create(nil);
      //�J�����g�ϐ���copy
      func.LocalTable.LocalCopy(FCurrentTable);
      }
      Result := BuildFunction(func);
    end;

    //object�쐬
    opNew:      //L..Object�� R..����
    begin
      name := l^.Symbol;
      param := ArgumentsToList(r);
      try
        //object�쐬
        Result := BuildObject(MakeObject(name,param));
      finally
        param.Free;
      end;

      //temp�ɓ����
      //FCurrentTable.AddTemporaryObject(Result.vObject);
    end;
    //Object�쐬
    opNewObject:
    begin
      Result := BuildObject(TJObject.Create(Self));
      ObjectExpr(Result.vObject,l);
      //temp�ɓ����
      FCurrentTable.AddTemporaryObject(Result.vObject);
    end;
    //�z��쐬
    opNewArray:
    begin
      param := ArgumentsToList(l);
      try
        //�����l�Z�b�g
        Result.ValueType := vtObject;
        if IsParam1(param) and (param.Count = 1) then //�������ЂƂ̂Ƃ�����ɗv�f�Ƃ��Ĉ���
        begin
          Result.vObject := TJArrayObject.Create(Self);
          (Result.vObject as TJArrayObject).Add(param[0]);
        end
        else
          Result.vObject := TJArrayObject.Create(Self,param);
      finally
        param.Free;
      end;

      //temp�ɓ����
      FCurrentTable.AddTemporaryObject(Result.vObject);
    end;
    //���݂̃J�����gobject��Ԃ�
    opThis:
    begin
      Result := BuildObject(FCurrentTable.This);
    end;
    opSuper:
    begin
      raise EJThrow.Create(E_SYNTAX,'super');
      //Result := MemberExpr(P,FTables.This);
      //Result.ValueType := vtObject;
      //Result.vObject := FTable.This;
    end;
    opDelete:
    begin
      //�폜����
      Result := EvalExpr(l,[eefDelete]);
    end;
    opVoid:
    begin
      Result := Evalexpr(l);
      Result := BuildNull;
    end;
    opTypeOf:
    begin
      try
        v := EvalExpr(l);
      except
        on E:EJThrow do
        begin
          //undefine
          if (E.ExceptName = E_NAME) or (E.ExceptName = E_KEY) then
            EmptyValue(v)
          else //�Đ���
            raise;
        end;
      end;
      Result := BuildString(TypeOf(@v));
    end;
    else begin
      EvalExpr(l);
      EvalExpr(r);
    end;
  end;

end;

function TJEngine.CallFunction(Root: PJStatement; Symbol: String;
  Param: TJValueList; var RetValue: TJValue): Boolean;
//�O������̊֐��Ăяo��
var
  v: TJValue;
  old,table: TJLocalSymbolTable;
begin
  Result := False;
  EmptyValue(RetValue);
  //���s���̏ꍇ�I���
  if IsRunning then
    Exit;
  //���s�ς݂łȂ��ꍇ
  if not FIsRan then
    Exit;
  //���s��
  FIsRunning := True;

  try
    FAbort := False;
    //root������Ύ��s
    //if Assigned(Root) then
    //  Run(Root,nil);

    //�֐������s����
    table := FRootTable.FindGlobalTable(__MAIN__);
    if table.GetValue(Symbol,v) and
       IsFunction(@v) then
    begin
      old := FCurrentTable;
      FCurrentTable := table;
      BeforeRun;
      try try
        RetValue := CallExpr(v.vFunction,Param);
        Result := True;
      except
        on E:EJThrow do
          PrintlnError('Exception: ' +
            E.ExceptName + '(' + IntToStr(FLineNo) + ') => ' + E.Message);
        on E:EJAbort do
          PrintlnError('Abort Script(' + IntToStr(FLineNo) + ')');
        on E:EJSyntaxError do
          PrintlnError('SyntaxError: ' +
            'Line(' + IntToStr(FLineNo) + ') => ' + E.Message);
      end;

      finally
        AfterRun;
        FCurrentTable := old;
      end;
    end;
  finally
    FIsRunning := False;
  end;
end;

function TJEngine.CallExpr(Func: IJFunction; Param: TJValueList;
  This: TJObject): TJValue;
//�֐��Ăяo��
var
  paramdecl: PJStatement;
  i,index: Integer;
  args: TJArrayObject;
  table,oldtable: TJLocalSymbolTable;
  v: TJValue;
{$IFNDEF NO_ACTIVEX}
  oleret: OleVariant;
  dispparams: TDispParams;
  arglist: PVariantArgList;
  diput: TDispId;
{$ENDIF}
{$IFNDEF NO_DYNACALL}
  dynavalues: TDynaValueArray;
{$ENDIF}
begin
  EmptyValue(Result);
{$IFNDEF NO_DYNACALL}
  dynavalues := nil;
{$ENDIF}

  try
    case Func.FuncType of
      //�\����
      ftStatement:
      begin
        //��Param�̒l�͍폜�����肵�Ȃ�

        //method owner���`�F�b�N
        if Assigned(Func.MethodOwner) then
          This := Func.MethodOwner;

        //�e�[�u���쐬
        table := Func.FunctionTable.PushLocalTable(Func.LocalTable,This);
        oldtable := FCurrentTable;
        FCurrentTable := table;
        try
          //flag��fcfCall fcfApply�̏ꍇ��Param[0]��this�ɂȂ�
          if (Func.Flag = fcfCall) and IsParam1(Param) then
          begin
            //arguments���쐬
            args := TJArrayObject.Create(Self);

            table.This := GetThisFromValue(Param[0]);

            for i := 1 to Param.Count - 1 do
              args.Add(Param[i]);
          end
          //apply�̏ꍇ��Param[0]��this Param[1]��arguments
          else if (Func.Flag = fcfApply) and IsParam1(Param) then
          begin
            table.This := GetThisFromValue(Param[0]);

            if IsParam2(Param) then
            begin
              v := Param[1];
              if IsObject(@v) and (v.vObject is TJArrayObject) then
              begin
                //Param�����ւ�
                args := v.vObject as TJArrayObject;
              end
              else
                raise EJThrow.Create(E_TYPE,Func.Symbol + '.apply arguments error');
            end
            else //arguments���쐬
              args := TJArrayObject.Create(Self);
          end
          else begin
            //�ʏ�
            //arguments���쐬
            args := TJArrayObject.Create(Self);

            if IsParam1(Param) then
              for i := 0 to Param.Count - 1 do
                args.Add(Param[i]);
          end;

          //arguments��callee������
          EmptyValue(v);
          v.ValueType := vtFunction;
          v.vFunction := Func;
          //�z���arraystyle=false�œo�^���Ȃ��ƃG���[
          args.SetValue('callee',v,False);
          //arguments�o�^
          table.RegistValue('arguments',BuildObject(args));
          //�p�����[�^�o�^
          i := 0;
          paramdecl := Func.Parameter;
          while Assigned(paramdecl) do
          begin
            EmptyValue(v);
            //v := BuildNull;
            //���ԂɃ��[�J���ϐ��ɓo�^
            if Assigned(paramdecl^.Expr) then
            begin
              if i < args.Count then
                table.RegistValue(paramdecl^.Expr^.Symbol,args.GetItem(i))
              else //undifined��o�^
                table.RegistValue(paramdecl^.Expr^.Symbol,v);
            end;

            paramdecl := paramdecl^.Next;
            Inc(i);
          end;

          try
            EvalStatement(Func.vStatement^.Sub2,[]);
          except
            on E:EJReturn do
              Result := E.Value;
          end;
        finally
          //�e�[�u�����폜
          Func.FunctionTable.PopLocalTable;
          //���ɖ߂�
          FCurrentTable := oldtable;
        end;
      end;
      //Delphi���\�b�h
      ftMethod: Result := Func.vMethod(Param);

  {$IFNDEF NO_ACTIVEX}
      //ActiveX���\�b�h
      ftActiveX:
      begin
        //VarClear(oleret); VarClear�̓o�O���Ă���
        VariantInit(oleret);
        //�p�����[�^�쐬
        if IsParam1(Param) then
        begin
          GetMem(arglist,SizeOf(TVariantArg) * Param.Count);
          //�t���ɂ���
          index := 0;
          for i := Param.Count - 1 downto 0 do
          begin
            //tagVariant��OleVariant�͓���
            arglist^[index] := TVariantArg(ValueToVariant(Param[i]));
            Inc(Index);
          end;
          dispparams.rgvarg := arglist;
          dispparams.cArgs := Param.Count;
          dispparams.rgdispidNamedArgs := nil;
          dispparams.cNamedArgs := 0;
        end
        else begin
          arglist := nil;
          dispparams.rgvarg := nil;
          dispparams.cArgs := 0;
          dispparams.rgdispidNamedArgs := nil;
          dispparams.cNamedArgs := 0;
        end;

        try
          //property put�̏ꍇ
          if Func.vActiveX.Flag = axfPut then
          begin
            diput := DISPID_PROPERTYPUT;
            dispparams.rgdispidNamedArgs := @diput;
            dispparams.cNamedArgs := 1;
          end;

          //�Ăяo��
          try
            //���\�b�h�Ăяo���̃o�O��VarClear��VariantInit�ɑウ��ƒ�����
            OleCheck(Func.vActiveX.Parent.Invoke(
              Func.vActiveX.Dispid,
              GUID_NULL,
              GetUserDefaultLCID,
              AXMethodFlagToDisp(Func.vActiveX.Flag),
              dispparams,
              @oleret,nil,nil));

            Result := VariantToValue(oleret,Self);
          except
            //��O
            raise EJThrow.Create(E_ACTIVEX,
              AXMethodFlagToString(Func.vActiveX.Flag) + ' error: ' + Func.Symbol);
          end;
        finally
          if Assigned(arglist) then
            FreeMem(arglist);
        end;
      end;
    {$ENDIF}

    {$IFNDEF NO_DYNACALL}
      //DLL�֐��̌Ăяo��
      ftDynaCall:
      begin
        //SynaValue���X�g���쐬����
        dynavalues := ValueListToDynaValueArray(Func.vDynaCall.Arguments,Param);
        //�Ăяo��
        Result :=
          DynaResultToValue(
            Func.vDynaCall.ReturnValue,
            DynaCall(
              MakeCallFlags(Func.vDynaCall.Call),
              Func.vDynaCall.Procaddr,
              DynaValueArrayToDynaParmArray(dynavalues),
              nil,
              0
            )
          );
        //�Q�Ɠn���̒l�𔽉f����
        SetRefDynaValue(dynavalues,Param);
      end;
    {$ENDIF}
    else
      raise EJThrow.Create(E_CALL,'not support function type');
    end;
  finally
    //result object��temp�ɓo�^����
    if IsObject(@Result) then
      FCurrentTable.AddTemporaryObject(
        Result.vObject,
        //ftStatement�̎��͎Q�ƃJ�E���g��ω������Ȃ��̂�false
        Func.FuncType <> ftStatement);
  end;
end;

function TJEngine.MemberExpr(Parent: TJValue; Member: String; Deleting: Boolean): TJValue;
//�����o��
var
  ax,vcl: Boolean;
  obj: TJObject;
begin
  EmptyValue(Result);
  ax := False;
  vcl := False;

  if IsObject(@parent) then
  begin
{$IFNDEF NO_ACTIVEX}
    //activex�ł�member expr�ŐV�Kobject���A���Ă���
    if (parent.vObject is TJActiveXObject) then
      ax := True
    else
{$ENDIF}
    //vcl�ł�member expr�ŐV�Kobject���A���Ă���
    if (parent.vObject is TJVCLPersistent) then
      vcl := True;

    //property�폜
    if Deleting then
      Result := BuildBool(parent.vObject.RemoveKey(Member))
    //prototype
    else if Member = 'prototype' then
      Result := BuildObject(FFactory.GetPrototype(parent.vObject.Name))
    else
      Result := parent.vObject.GetValue(Member,False);
  end
  else if IsString(@parent) then //������̃v���p�e�B
  begin
    obj := MakeObject('String',nil);
    (obj as TJStringObject).text := AsString(@parent);
    Result := obj.GetValue(Member,False);

{ TODO : ���ꕶ����炵�� }
// "$$" $ �Ƃ����������̂���
// "$&" �O���v���������ł�
// "$`" �O���v�����������O���̕�����ł�
// "$'" �O���v��������������̕�����ł�
// "$n" �O���v����n�Ԗ�(1-9,01-99)�̕����ł�
  end
  else if IsRegExp(@parent) then //���K�\��
  begin
    obj := MakeObject('RegExp',nil);
    (obj as TJRegExpObject).SetRegExpValue(parent);
    Result := obj.GetValue(Member,False);
  end
  else if TryAsNumber(@parent) then //����
  begin
    obj := MakeObject('Number',nil);
    (obj as TJNumberObject).FValue := parent;
    Result := obj.GetValue(Member,False);
  end
  else if IsConstructor(@parent) then //�֐�
  begin
    //prototype
    if Member = 'prototype' then
      Result := BuildObject(FFactory.GetPrototype(parent.vFunction.Symbol))
    else if Member = 'call' then
    begin
      //�R�s�[
      Result := parent;
      //call flag���Z�b�g
      Result.vFunction.Flag := fcfCall;
    end
    else if Member = 'apply' then
    begin
      //�R�s�[
      Result := parent;
      //call flag���Z�b�g
      Result.vFunction.Flag := fcfApply;
    end
    else //�G���[
      raise EJThrow.Create(E_NAME,'member error ' + Member);
  end
  else if IsBool(@parent) then //bool
  begin
    obj := MakeObject('Boolean',nil);
    (obj as TJBooleanObject).FBool := AsBool(@parent);
    Result := obj.GetValue(Member,False);
  end
{$IFNDEF NO_ACTIVEX}
  else if IsDispatch(@parent) then
  begin
    ax := True;
    obj := MakeObject('ActiveXObject',nil);
    (obj as TJActiveXObject).disp := AsDispatch(@parent);
    Result := obj.GetValue(Member,False);
  end
{$ENDIF}
  else if IsNameSpace(@parent) then
  begin
    //���O��Ԃ���
    FRootTable.FindGlobalTable(parent.vFunction.Symbol).GetValue(Member,Result);
  end
  else
    raise EJThrow.Create(E_NAME,'member error ' + Member);
{$IFNDEF NO_ACTIVEX}
  //activexObject�̏ꍇ��temp�ɓo�^����
  if ax and IsObject(@Result) and (Result.vObject is TJActiveXObject) then
    FCurrentTable.AddTemporaryObject(Result.vObject)
  else
{$ENDIF}
  if vcl and IsVCLObject(@Result) then
    FCurrentTable.AddTemporaryObject(Result.vObject);
end;

procedure TJEngine.MemberAssign(Parent: TJValue; Member: String; Value: TJValue);
//�����o�֑��
//member ... object.variable
begin
  if IsObject(@parent) then
  begin
    //protoype
    if (Member = 'prototype') and (IsObject(@Value) or IsNull(@Value)) then
    begin
      //object��������
      if not FFactory.SetPrototype(parent.vObject.Name,Value.vObject) then
        raise EJThrow.Create(E_NAME,'prototype assign error ' + Value.vObject.Name);
    end
    else
      parent.vObject.SetValue(Member,Value,False);
  end
  //�֐� prototype
  else if IsConstructor(@parent) and (Member = 'prototype') and
          (IsObject(@Value) or IsNull(@Value)) then
  begin
    //object��������
    if not FFactory.SetPrototype(parent.vFunction.Symbol,Value.vObject) then
      raise EJThrow.Create(E_NAME,'prototype assign error ' + Value.vObject.Name);
  end
  //���O���
  else if IsNameSpace(@parent) then
    FRootTable.FindGlobalTable(parent.vFunction.Symbol).SetValue(Member,Value,FRegistVar)
  else
    raise EJThrow.Create(E_NAME,'member assign error ' + Member);
end;

procedure TJEngine.Clear;
//�e�[�u�����N���A����
begin
  FAllowEvent := False;
  FIsRan := False;
  ClearGlobalObjects;
  FRootTable.Clear;
  FFactory.Clear;
  FLineNo := E_UNKNOWN_LINE_NO;
end;

procedure TJEngine.Abort;
begin
  FAbort := True;
  FAllowEvent := False;
end;

procedure TJEngine.FactoryOnNewObject(Sender: TObject;
  JObject: TJObject);
var
  re: TJRegExpObject;
begin
  if JObject is TJRegExpObject then
  begin
    //���K�\���ɍ׍H
    re := TJRegExpObject(JObject);
    re.OnMatchStart := RegExpOnMatchStart;
    re.OnMatchEnd := RegExpOnMatchEnd;
    re.OnExecInput := RegExpOnExecInput;
  end;

{$IFNDEF NO_SOCKET}
  //socket�֌W�ɍ׍H
  if JObject is TJBaseSocketObject then
  begin
    TJBaseSocketObject(JObject).OnPrint := FGlobalObject.Println;
  end;
{$ENDIF}

  if Assigned(FOnNewObject) then
    FOnNewObject(Self,JObject);
end;

procedure TJEngine.ObjectExpr(Obj: TJObject; Elements: PJExpr);
//L(�ϐ�)
//R(�l)
var
  current: PJExpr;
  s: String;
begin
  current := Elements;
  while Assigned(current) do
  begin
    //quoteString
    if IsString(current^.Right^.Left^.Value) then
      s := current^.Right^.Left^.Value^.vString
    else if TryAsNumber(current^.Right^.Left^.Value) then
      s := AsString(current^.Right^.Left^.Value)
    else //variable
      s := current^.Right^.Left^.Symbol;

    Obj.SetValue(s,EvalExpr(current^.Right^.Right),True);
    current := current^.Left;
  end;
end;

procedure TJEngine.MakeInstance(Obj: TJObject; Members: PJStatement);
//object�Ƀ����o���Z�b�g����
var
  current: PJStatement;
  func: IJFunction;
  v: TJValue;
  exp: PJExpr;
begin
  //���O��o�^
  Obj.RegistName(Members^.Expr^.Symbol);
  current := Members^.Sub1;
  while Assigned(current) do
  begin
    case current^.SType of
      stFunctionDecl:
      begin
        //�֐����Z�b�g �ϐ��������݂��Ȃ��ꍇ������
        if Assigned(current^.Expr) then
        begin
          EmptyFunction(func);
          func.Symbol := current^.Expr^.Symbol;
          func.FuncType := ftStatement;
          func.vStatement := current;
          //�p�����[�^�Z�b�g
          func.Parameter := current^.Sub1;
          //�V���{���e�[�u�����쐬
          //�e�֐�����p������
          func.FunctionTable :=
            FRootTable.GetFunctionTable(current^.Temp,current);
          func.MethodOwner := Obj;
          //�����o�ɓo�^����
          Obj.RegistProperty(current^.Expr^.Symbol,BuildFunction(func));
        end
      end;
      //var���ƕϐ��錾
      stVar,stVariableDecl:
      begin
        exp := nil;
        case current^.SType of
          stVar: exp := current^.Sub1^.Expr;
          stVariableDecl: exp := current^.Expr;
        end;

        if Assigned(exp) then
        begin
          if Assigned(exp^.Left) then
            v := EvalExpr(exp^.Left)
          else
            v := BuildNull;

          Obj.RegistProperty(exp^.Symbol,v);
        end;
      end;
    end;
    current := current^.Next;
  end;
end;

function TJEngine.MakeObject(Name: String; Param: TJValueList): TJObject;
{ TODO : ������ւ񌩒��� }
var
  v,con: TJValue;
  objclass: PJObjectClass;
begin
  //���[�U��`�����邩�H
  if FCurrentTable.GetValue(Name,v) and
    (IsConstructor(@v) or IsClass(@v)) then
  begin
    case v.vFunction.FuncType of
      //�N���X
      ftClass:
      begin
        //super object�������ꍇ��object
        if not Assigned(v.vFunction.vStatement^.Expr^.Left) then
          Result := TJObject.Create(Self,Param)
        else //���֍ċA
          Result := MakeObject(v.vFunction.vStatement^.Expr^.Left^.Symbol,Param);

        //�����o�쐬
        MakeInstance(Result,v.vFunction.vStatement);
        //�R���X�g���N�^���Ă�
        if Result.HasKey(Name) then
        begin
          con := Result.GetValue(Name,False);
          if IsConstructor(@con) then
          begin
            //temp�ɓ����
            FCurrentTable.AddTemporaryObject(Result);
            CallExpr(con.vFunction,Param,Result);
          end;
        end;

      end;
      //�֐�
      ftStatement:
      begin
        //object���쐬����
        Result := TJObject.Create(Self);
        //���O��o�^
        Result.RegistName(Name);
        //constructor
        Result.RegistProperty('constructor',v);

        //temp�ɓ����
        FCurrentTable.AddTemporaryObject(Result);
        //constructor���Ă�
        CallExpr(v.vFunction,Param,Result);
      end
    else
      //�����͎��ۂɂ͎��s����Ȃ�
      raise EJThrow.Create(E_NAME,'create object constructor error ' + Name);
    end;
  end
  //�g���݃I�u�W�F�N�g������ΕԂ�
  else if FFactory.HasObject(Name) then
  begin
    objclass := FFactory.GetObject(Name);
    Result := objclass^.Create(Self,Param);
    //temp�ɓ����
    FCurrentTable.AddTemporaryObject(Result);
  end
  else //object�������̂ŗ�O
    raise EJThrow.Create(E_NAME,'create object error ' + Name);
end;

procedure TJEngine.ImportObject(ObjectName: String;
  ObjectClass: TJObjectClass);
begin
  FFactory.ImportObject(ObjectName,ObjectClass);
end;

procedure TJEngine.RegExpOnMatchStart(Sender: TObject);
//�}�b�`�J�n �O���[�o���X�V
begin
  FRegExpObject.ClearMatch;
end;

procedure TJEngine.RegExpOnMatchEnd(Sender: TObject);
//�}�b�`�I�� �O���[�o���X�V
begin
  FRegExpObject.Assign(Sender as TJRegExpObject);
end;

procedure TJEngine.GlobalObjectOnPrint(Sender: TObject; S: String);
begin
  if Assigned(FOnStdout) then
    FOnStdout(Self,S);
end;

procedure TJEngine.RegistGlobalObjects(ASymbolTable: TJLocalSymbolTable);
//global�I�u�W�F�N�g��o�^����
var
  names: TStringList;
  i: Integer;
  objclass: PJObjectClass;
begin
  //���ׂĂ�o�^����
  names := FFactory.ObjectNameList;
  for i := 0 to names.Count - 1 do
  begin
    objclass := FFactory.GetObject(names[i]);
    if objclass^.IsMakeGlobalInstance then
    begin
{ TODO : except���������� }
      try
        ASymbolTable.RegistGlobalValue(names[i],BuildObject(objclass^.Create(Self)));
      except
        on EJThrow do
      end;
    end;
  end;
  //�d�v���㏑��
  ASymbolTable.RegistGlobalValue('Global',BuildObject(FGlobalObject));
  ASymbolTable.RegistGlobalValue('RegExp',BuildObject(FRegExpObject));
{$IFNDEF NO_WSH}
  ASymbolTable.RegistGlobalValue('WScript',BuildObject(FWScriptObject));
{$ENDIF}
end;

procedure TJEngine.PrintlnError(S: String);
//stderr
begin
  GlobalObjectOnPrintError(Self,S + CRLF);
  //event
  if Assigned(FOnError) then
    FOnError(Self,FLineNo,S);
end;

procedure TJEngine.GlobalObjectOnPrintError(Sender: TObject; S: String);
begin
  if Assigned(FOnStderr) then
    FOnStderr(Self,S);
end;

function TJEngine.IsRunning: Boolean;
//���s�����ǂ���
begin
  Result := FIsRunning;
end;

function TJEngine.DoEvents: Boolean;
//�ҋ@����
var
{$IFNDEF CONSOLE}
  tid: DWORD;
{$ENDIF}
  abrt: Boolean;
begin
  Result := IsRunning and FAllowEvent;
  //���s���̏ꍇ
  if Result then
  begin
    abrt := False;
    //���~�`�F�b�N
    if Assigned(FOnDoEvents) then
      FOnDoEvents(Self,abrt);
    //���~
    if abrt then
    begin
      Result := False;
      Exit;
    end;
{$IFNDEF CONSOLE}
    //���s�X���b�h���`�F�b�N
    tid := GetCurrentThreadId;
    //���C���̏ꍇ�̓��b�Z�[�W������
    if tid = MainThreadId then
    begin
      Result := not Application.Terminated;
      if Result then
        Application.ProcessMessages;
    end;
{$ENDIF}
    //�ҋ@
    Sleep(10);
  end;
end;

procedure TJEngine.CallArrayAssign(Parent: TJValue;
  Arguments: PJExpr; Value: TJValue);
//�z�� or �֐�Call�֑��
// parent(arguments)
// parent[arguments]
var
  s: TJValue;
  param: TJValueList;
begin
  //object�ꍇ �z��
  if IsObject(@parent) then
  begin
    //�Ō�̈����𓾂�
    s := ArgumentsToValue(Arguments);
    //������1���傫���Ƃ���param���Z�b�g����
    if ArgumentsCount(Arguments) > 1 then
    begin
      //�����Z�b�g
      param := ArgumentsToList(Arguments);
      try
        //param�̍Ō��v�͓���
        parent.vObject.SetValue(AsString(@s),Value,True,param);
      finally
        param.Free;
      end;
    end
    else //�����
      parent.vObject.SetValue(AsString(@s),Value,True);
  end
  //�֐��̏ꍇ
  else if IsFunction(@parent) then
  begin
    //�����Z�b�g
    param := ArgumentsToList(Arguments);
    if not Assigned(param) then
      param := TJValueList.Create;
    try
      //�l��������
      param.Add(Value);
      //activex�̏ꍇflag���Z�b�g
      if parent.vFunction.FuncType = ftActiveX then
        parent.vFunction.vActiveX.Flag := axfPut;
      //�֐����Ă�
      CallExpr(parent.vFunction,param);
    finally
      param.Free;
    end;
  end
  else
    raise EJThrow.Create(E_CALL,'call function error,need function or object');
end;

function TJEngine.CallArrayExpr(Parent: TJValue; Arguments: PJExpr): TJValue;
//�z�� or �֐�Call
// parent(arguments)
// parent[arguments]
var
  s: TJValue;
  param: TJValueList;
  obj: TJObject;
begin
  EmptyValue(Result);
  //�֐��̏ꍇ
  if IsFunction(@parent) then
  begin
    //�����Z�b�g
    param := ArgumentsToList(Arguments);
    try
      //activex�̏ꍇflag���Z�b�g
      if parent.vFunction.FuncType = ftActiveX then
        parent.vFunction.vActiveX.Flag := axfGet;
      //�֐����Ă� this���p��
      Result := CallExpr(parent.vFunction,param,FCurrentTable.This);
    finally
      param.Free;
    end;
  end
  //object�̏ꍇ �z��
  else if IsObject(@parent) or IsString(@parent) then
  begin
    if IsObject(@parent) then
      obj := parent.vObject
    else begin
      obj := MakeObject('String',nil);
      (obj as TJStringObject).text := AsString(@parent);
    end;
    //�Ō�̈����𓾂�
    s := ArgumentsToValue(Arguments);
    //������1���傫���Ƃ���param���Z�b�g����
    if ArgumentsCount(Arguments) > 1 then
    begin
      //�����Z�b�g
      param := ArgumentsToList(Arguments);
      try
        //param�̍Ō��v�͓���
        Result := obj.GetValue(AsString(@s),True,param);
      finally
        param.Free;
      end;
    end
    else //�����
      Result := obj.GetValue(AsString(@s),True);
  end
  else
    raise EJThrow.Create(E_CALL,'call function error,need function or object');
end;

procedure TJEngine.GlobalObjectOnRead(Sender: TObject; var S: String; var Success: Boolean;
  Count: Integer; Line: Boolean);
begin
  if Assigned(FOnStdin) then
    FOnStdin(Self,S,Success,Count,Line);
end;

function TJEngine.GetObjectCount: Integer;
begin
  Result := FFactory.ObjectCount;
end;

procedure TJEngine.AfterRun;
//���s��
begin
  if Assigned(FOnDone) then
    FOnDone(Self);
end;

procedure TJEngine.BeforeRun(Main: Boolean);
//���s�O
begin
{$IFNDEF NO_WSH}
  //WScript�̈���������
  if Main then
    FWScriptObject.Arguments.Parse(FGlobalObject.arguments);
{$ENDIF}
  if Assigned(FOnRun) then
    FOnRun(Self);
end;

procedure TJEngine.MethodAssign(P: PJExpr;
  Value: TJValue);
//���\�b�h���
//L ... ParentObject
//R ... Member
//T ... Arguments
var
  l,r,t: PJExpr;
  parent,member: TJValue;
  param: TJValueList;
begin
  if not Assigned(P) then
    Exit;

  l := P^.Left;
  r := P^.Right;
  t := P^.Third;

  //�eobject
  parent := EvalExpr(l);
  //member�𓾂�
  member := MemberExpr(parent,r^.Symbol);
  //�֐���������call
  if IsFunction(@member) then
  begin
    //�����Z�b�g
    param := ArgumentsToList(t);
    if not Assigned(param) then
      param := TJValueList.Create;
    try
      //������ɑ���l���Ō�ɉ�����
      param.Add(Value);
      //activex�̏ꍇflag���Z�b�g
      if member.vFunction.FuncType = ftActiveX then
        member.vFunction.vActiveX.Flag := axfPut;
      //�֐����Ă�
      CallExpr(member.vFunction,param,GetThisFromValue(parent));
    finally
      param.Free;
    end;
  end
  else if IsObject(@member) then
  begin
    //Object�̏ꍇ�͔z��
    CallArrayAssign(member,t,Value);
  end
  else
    raise EJThrow.Create(E_CALL,'call function error,need function or object');
end;

function TJEngine.MethodExpr(P: PJExpr): TJValue;
//���\�b�h��
//postfix_expression DOT[.] variable LSQ[\[] (arguments|null) RSQ[\]]
//postfix_expression DOT[.] variable LP[(] (arguments|null) RP[)]
//L ... ParentObject
//R ... Member
//T ... Arguments
var
  l,r,t: PJExpr;
  parent,member: TJValue;
  param: TJValueList;
begin
  EmptyValue(Result);
  if not Assigned(P) then
    Exit;

  l := P^.Left;
  r := P^.Right;
  t := P^.Third;

  //�eobject
  parent := EvalExpr(l);
  //member�𓾂�
  member := MemberExpr(parent,r^.Symbol);
  //�֐���������call
  if IsFunction(@member) then
  begin
    //�����Z�b�g
    param := ArgumentsToList(t);
    try
      //activex�̏ꍇflag���Z�b�g
      if member.vFunction.FuncType = ftActiveX then
        member.vFunction.vActiveX.Flag := axfGet;
      //�֐����Ă�
      Result := CallExpr(member.vFunction,param,GetThisFromValue(parent));
    finally
      param.Free;
    end;
  end
  else if IsObject(@member) then
  begin
    //Object�̏ꍇ�͔z��
    Result := CallArrayExpr(member,t);
  end
  else
    raise EJThrow.Create(E_CALL,'call function error,need function or object');
end;

function TJEngine.ArgumentsCount(Arg: PJExpr): Integer;
//arg�̐��𓾂�
var
  current: PJExpr;
begin
  Result := 0;
  current := Arg;
  while Assigned(current) do
  begin
    Inc(Result);
    current := current^.Left;
  end;
end;

function TJEngine.ArgumentsToList(Arg: PJExpr): TJValueList;
//List������Ċ֐��p�����[�^���Z�b�g
var
  current: PJExpr;
  v: TJValue;
begin
  if not Assigned(Arg) then
  begin
    Result := nil;
    Exit;
  end;

  Result := TJValueList.Create;
  try
    current := Arg;
    while Assigned(current) do
    begin
      v := EvalExpr(current^.Right);
      Result.Insert(0,v);
      current := current^.Left;
    end;
  except
    //��O�̂Ƃ��͊J������
    FreeAndNil(Result);
    raise;
  end;
end;

function TJEngine.ArgumentsToValue(Arg: PJExpr): TJValue;
//�Ō�̈�𓾂�
begin
  //Right�ōŌ�̒l�𓾂邱�Ƃ��ł���
  if Assigned(Arg) then
    Result := EvalExpr(Arg^.Right)
  else
    Result := BuildString('');
end;

function TJEngine.GetThisFromValue(Value: TJValue): TJObject;
//this�𓾂�
begin
  if IsObject(@Value) then
    Result := Value.vObject
  else if IsString(@Value) then  //����
  begin
    Result := MakeObject('String',nil);
    (Result as TJStringObject).Text := AsString(@Value);
  end
  else if IsRegExp(@Value) then //���K�\��
  begin
    Result := MakeObject('RegExp',nil);
    (Result as TJRegExpObject).SetRegExpValue(Value);
  end
  else if TryAsNumber(@Value) then //����
  begin
    Result := MakeObject('Number',nil);
    (Result as TJNumberObject).FValue := Value;
  end
  else if IsBool(@Value) then //bool
  begin
    Result := MakeObject('Boolean',nil);
    (Result as TJBooleanObject).FBool := AsBool(@Value);
  end
{$IFNDEF NO_ACTIVEX}
  else if IsDispatch(@Value) then
  begin
    Result := MakeObject('ActiveXObject',nil);
    (Result as TJActiveXObject).disp := AsDispatch(@Value);
  end
{$ENDIF}
  else
    Result := nil;
    //Result := FCurrentTable.This;
end;

function TJEngine.GetVariable(Symbol: String;
  var RetVal: TJValue): Boolean;
//�O���[�o���ϐ��𓾂�
begin
  Result := FCurrentTable.GetValue(Symbol,RetVal);
end;

function TJEngine.CallEvent(var Event: TJValue; Param: TJValueList;
  This: TJObject): TJValue;
begin
  try
    //�֐��̏ꍇ
    if IsFunction(@Event) then
      Result := CallExpr(Event.vFunction,Param,This)
    //������̏ꍇ��eval
    else if IsString(@Event) then
      Result := Eval(AsString(@Event),This)
    else
      EmptyValue(Result);
  except
    on E:EJException do
    begin
      //���s���̏ꍇ�͍Đ�������
      if not FIsRan then
        raise
      else begin
        //��O�A���~�̂Ƃ��̓C�x���g���[�v���甲����
        if E is EJThrow then
        begin
          FAllowEvent := False;
          PrintlnError('Exception: ' +
            E.ExceptName + '(' + IntToStr(FLineNo) + ') => ' + E.Message)
        end
        else if E is EJAbort then
        begin
          FAllowEvent := False;
          PrintlnError('Abort Script(' + IntToStr(FLineNo) + ')')
        end
        else if E is EJSyntaxError then
        begin
          FAllowEvent := False;
          PrintlnError('SyntaxError: ' +
            'Line(' + IntToStr(FLineNo) + ') => ' + E.Message);
        end;
      end;
    end;
  end;
end;

function TJEngine.Run: Integer;
begin
  Result := Run(FParser.Root,nil);
end;

function TJEngine.CallFunction(Symbol: String; Param: TJValueList;
  var RetValue: TJValue): Boolean;
begin
  Result := CallFunction(FParser.Root,Symbol,Param,RetValue);
end;

function TJEngine.Compile(SourceCode: String): Boolean;
//��͖؂����
begin
  Result := False;
  //���s���̏ꍇ�I���
  if IsRunning then
    Exit;

  //���s�ς݃t���O���N���A
  FIsRan := False;

  FParser.SourceCode := SourceCode;
  //exe path��ǉ�
  FParser.LibPath.Add(ExtractFilePath(ParamStr(0)));
  FParser.LibPath.Add(GetCurrentDir);
  try try
    Result := FParser.Parse;
  except
    on E:EJSyntaxError do
    begin
      FLineNo := E.LineNo;
      //event
      PrintlnError('SyntaxError: ' +
          'Line(' + IntToStr(FLineNo) + ') => ' + E.Message);
    end;
    on E:EJThrow do
      PrintlnError('Exception: ' + E.ExceptName + ' => ' + E.Message);
  end;
  finally
    //libpath���폜����
    FParser.LibPath.Delete(FParser.LibPath.Count - 1);
    FParser.LibPath.Delete(FParser.LibPath.Count - 1);
  end;
end;

function TJEngine.CompileFile(AFilename: String; UseBinary: Boolean): Boolean;
//�t�@�C�����w�肵�Ď��s(lib path��ǉ�����)

  function GetTempDmc(dmc: String): String;
  var
    path: array[0..MAX_PATH] of Char;
  begin
    GetTempPath(MAX_PATH,path);
    Result := String(path) + ExtractFilename(dmc);
  end;

var
  sl: TStringList;
  dmc,tmpdmc: String;
  ok: Boolean;
begin
  Result := False;
  //���s���̏ꍇ�I���
  if IsRunning then
    Exit;

  FFilename := AFilename;
  if not FileExists(AFilename) then
    Exit;

  //���s�ς݃t���O���N���A
  FIsRan := False;

  //�R���p�C���ς݃o�C�i�������[�h
  dmc := ChangeFileExt(AFilename,DMS_COMPILED_EXT);
  if UseBinary then
  begin
    //���t���r���ĐV�������
    if FileExists(dmc) and (FileAge(dmc) >= FileAge(AFilename)) then
      Result := FParser.Deserialize(dmc);
    //�ǂݍ��݂Ɏ��s������e���|��������ǂ�
    if not Result then
    begin
      tmpdmc := GetTempDmc(dmc);
      if FileExists(tmpdmc) and (FileAge(tmpdmc) >= FileAge(AFilename)) then
        Result := FParser.Deserialize(tmpdmc);
    end;
  end;

  if not Result then
  begin
    //lib path��ǉ�����
    FParser.LibPath.Add(ExtractFilePath(AFilename));
    sl := TStringList.Create;
    try
      sl.LoadFromFile(AFilename);
      Result := Compile(sl.Text);
      //�����Ȃ�΃V���A���C�Y
      if Result and UseBinary then
      begin
        ok := FParser.Serialize(dmc);
        //�t�@�C���쐬�Ɏ��s������e���|�����ɍ��
        if not ok then
        begin
          tmpdmc := GetTempDmc(dmc);
          FParser.Serialize(tmpdmc);
        end;
       end;
    finally
      sl.Free;
      //libpath���폜����
      FParser.LibPath.Delete(FParser.LibPath.Count - 1);
    end;
  end;
end;

function TJEngine.GetOnDebugout: TStringEvent;
//�C�x���g
begin
  Result := FParser.Lex.OnDebug
end;

procedure TJEngine.SetOnDebugout(const Value: TStringEvent);
begin
  FParser.Lex.OnDebug := Value;
end;

procedure TJEngine.ClearGlobalObjects;
begin
  FGlobalObject.Clear;
  FRegExpObject.Clear;
{$IFNDEF NO_WSH}
  FWScriptObject.Clear;
{$ENDIF}
end;

function TJEngine.Eval(SourceCode: String; This: TJObject): TJValue;
//eval()
//��������֐����ɕϊ����Ď��s����
//function(){return eval�R�[�h;}
var
  v: TJValue;
  expr: PJExpr;
  line: Integer;
  //parser: TJParser;
begin
  EmptyValue(Result);
  //�s�ԍ��ۑ�
  line := FLineNo;
  try
    //parser := TJParser.Create;
    //FParser.Packages.Add(parser);
    //�֐����𓾂�
    expr := FParser.ParseEval(SourceCode);
    if Assigned(expr) then
    begin
      //�֐�����]��
      v := EvalExpr(expr);
      if IsFunction(@v) then
      begin
        //current��e�ɐݒ�
        v.vFunction.FunctionTable.Parent := CurrentTable.GetNodeTable;
        //���s
        Result := CallExpr(v.vFunction,nil,This);
      end;
    end;
  finally
    FLineNo := line;
  end;
end;

procedure TJEngine.RegExpOnExecInput(Sender: TObject; var Input: String);
begin
  Input := FRegExpObject.input;
end;

function TJEngine.GetScriptFilename: String;
begin
  Result := FFilename;
end;

function TJEngine.FindImportFilename(Filename: String;
  var FindedFilename: String): Boolean;
begin
  Result := FParser.FindImportFilename(Filename,FindedFilename);
end;

end.

