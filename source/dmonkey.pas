unit DMonkey;

(*
  DMS(DMonkey Script) by Project DMonkey
  License: BSD
           ���̃��C�u�����͖��ۏ؂ł��B
           �g�p�A���ρA�z�z�Ɉ�؂̐����͂���܂���B
           ��҂ɒʒm�⃉�C�Z���X�\�����K�v����܂���B
  History:
  2010/04/29 ver.0.3.9.1 (Unicode�Ή�) m.matsubara
          Unicode�Ή�
          Bytes, Encoding, FileReader, FileWriter�^�̒ǉ�
          String�^��ShiftJIS��EUC, JIS�R�[�h�̑��ݕϊ����\�b�h��p�~
          File�^�̓o�C�i���݂̂������d�l�ɕύX
            readln(), writeln()�̔p�~
            read() �̖߂�l��String����Bytes�ɕύX
            write() �̈�����String����Bytes�ɕύX
          ������Unicode�Ή��łł�String�^������̕����R�[�h�ł��邱�ƂɈˑ�����悤�ȃR�[�h���������Ƃ͐�������܂���B

  2005/08/07 ver.0.3.9.1
          COM�I�u�W�F�N�g�ɃI�u�W�F�N�g�̒l���n��Ȃ����Ƃ�����̂��C��
          ���b�Z�[�W�{�b�N�X��t�H�[����\�����郁�\�b�h�̈������g��
          TJValueList.SetCount�ŗv�f�������炵���Ƃ�1�v�f�]�v�ɍ폜���Ă��̂��C��
          TJDynaCall.SendMessageImpl�ň�����null�̂Ƃ����Q�Ƃ�n���Ă��̂��C��
          DynaCall.register()�ŎQ�Ǝw��(1,2,4,8)�̈�����null��n�����Ƃ���0(NULL)��n���悤�ύX

  2005/07/29 ver.0.3.9
          Global.nameOf()�ŃI�u�W�F�N�g�����擾(�R���X�g���N�^�Ɠ����Ƃ͌���Ȃ�)
          DynaCall.sendMessage() .postMessage()�̈����̌^�𖾎��w�肷��d�l�ɕύX
          StringBuffer.substr()�̏C��
          String.substring() StringBuffer.substring()�ň����ȗ����͍Ō�܂Ŏ��o���悤�ɕύX
          ecma_misc.pas MB�֐��Q���C��

  2005/07/24 ver.0.3.8.1
          TJEngine.Run(), TJEngine.CallFunction()�̏C��

  2005/07/23 ver.0.3.8
          StringBuffer.indexOf() .lastIndexOf()��AnsiPos���g��Ȃ��悤�ύX
          TJStringBufferObject�̓Y���ł̑���𕶎��񂩂當���ɕύX
          String.multiply()
          String.charAt() .charCodeAt()�ŃC���f�b�N�X�͈̔̓`�F�b�N����悤�C��
          Math.max() .min()��3�ȏ����������悤�ύX
          StringBuffer.charCodeAt()�ŃC���f�b�N�X�͈̔̓`�F�b�N����悤�C��
          VCLListBox.clearSelection() .deleteSelected() .selectAll()
          Global.isFinite()
          TJActiveXObject.GetValue��2�ȏ�̈�����n����悤�C��(Excel.cells�΍�)
          DynaCall�̎Q�Ɠn���p�����[�^(1,2,4,8)��Number�I�u�W�F�N�g��n���ƒl�����f
          Number.asChar�Ő��l(�����R�[�h)�𕶎��Ŏ擾/�ݒ�
          ��O�A���~���ɂ��C�x���g���[�v�ɓ����Ă��܂��ꍇ������̂��C��

  2005/07/08 ver.0.3.7
          DynaCall.copyMemory() .fillMemory()
          StringBuffer.fill()
          DynaCall.sendMessage() .postMessage()��Struct���|�C���^��n���悤�C��
          String.slice()�̏C��

  2005/07/05 ver.0.3.6.1
          Object.getKeys() .getMethods() .getProperties()�̏C��

  2005/06/26 ver.0.3.6
          TJHTTPObject.DoResponse()�Ńv���g�R���G���[�̏ꍇ�ł��w�b�_���擾����悤�C��
          Strings.caseSensitive .duplicates
          regexpr.pas��ver0.952��
          StringBuffer.indexOf() .lastIndexOf() .slice() .substr()
          StringBuffer.substring()���C��
          VCLListView.ItemIndex
          Dialog.filters
          ecma_type.Get/SetDefaultProperty��Char�^��������悤�C��
          @VERSION7�K�p����for..in�ŃA�N�Z�X�ᔽ���N���邱�Ƃ��������̂��C��
          File,Directory�̈ꕔ���\�b�h���������Ƃ��悤��
           (�ȗ����͍��܂Œʂ�filename,dirname�v���p�e�B�̕����񂪑Ώ�)
          Keyboard.isDown()�ɉ��z�L�[�R�[�h��n����悤�ɕύX
          TJRegExpObject.ToString()
          ���K�\�����e������ecma_type.AsString(),TypeOf()�ŕԂ��l��ύX
          String.charCodeAt() .fromCharCode()��2�o�C�g������������悤��
          Struct.clear() .define()
          Number.toString()��8�i���ɂ��ϊ��ł���悤��

  2003/05/20 ver.0.3.5
          WScript.Arguments�ɑO����s���̈������n���Ă��̂��C��
          ������Z�q^=���g���Ȃ������̂��C��
          Global.platform��OS���� 'win32s'|'windows'|'nt'
          TJEngine.EvalStatement�̍Ō��temporary object���J������悤�ɏC��

  2003/04/11 ver.0.3.4
          String.lastIndexOf()�̏C��
          TJStruct�̏C��
          VCLMemo.text�v���p�e�B

  2003/04/09 ver.0.3.3
          TJEngine.CallArrayExpr()�̏C��

  2003/04/08 ver.0.3.2
          �֐��̃V���A���C�Y���������������̂��C��

  2003/04/07 ver.0.3.1
          �P�����Z�q+���C��
          �l�^������̎Q�ƕ�����ւ̕ϊ����C��
          Date.format�ŏ����w��('ggee yyyy/mm/dd(aaaa) ampm hh:nn:ss')
          �z��̏��Z��syntax�G���[�ɂȂ��Ă����̂��C��
          /*...**/���ƃR�����g���I�����Ȃ��̂��C���B
          DynaCall�œo�^�����֐���'s'�p�����[�^��null���w�肵���Ƃ���NULL(0)��n���悤�ɂ����B
          DynaCall�I�u�W�F�N�g��sendMessage()���\�b�h��ǉ��B
          DynaCall�I�u�W�F�N�g��postMessage()���\�b�h��ǉ��B
          Struct�I�u�W�F�N�g��ǉ��B
          StringBuffer�I�u�W�F�N�g�̍쐬���������g���B
          Struct�I�u�W�F�N�g�̌^��'i','w'��ǉ��B
          Number�I�u�W�F�N�g�̔�r���������������̂��C���B
          NaN�̈����������ύX�B
          Global.msgBox()�̈������g���B

  2003/02/23 ver.0.3.0
          �T���v�����C��
          TJObject�̃f�t�H���g�v���p�e�B��Name��Tag�𖳎����Ă����̂��C��
          �֐���
          HTTPS���܂Ƃ��ɓ����ĂȂ������̂��C��
          LibraryPath�ɃJ�����g�f�B���N�g����ǉ�
          object�쐬����QuoteString��Number���g����悤�C�� { "a" : 0 }
          String�I�u�W�F�N�g����蒼��
          StringBuffer�I�u�W�F�N�g ������String
          Number.toChar()�Ő����̕����R�[�h�𕶎��ɕύX
          ()��[]�̈����𓯂��ɂ���
          �֐��ւ̑��...�����̍Ō�ɑ���l��ǉ����܂�
          new�ł�Objecy�쐬�Ŋ֐������w�肷��ƃR���X�g���N�^
          OnError�C�x���g
          �I�����̃G���[���C��
          $��ϐ��Ɏg����悤�C��
          TJCookieObject���C��
          TJArrayObject.GetValue��ύX
          prototype
          Date.getTime()���~���b�P�ʂɏC��
          delete�����C��
          TJStringsObject.ToString���C��
          Directory.clear() .findfiles() .files .directories
          Global.format() .formatFloat()
          CheckListBox.index
          ecma_expr.pas��CalcValue����ecma_type.pas�ֈړ�
          function.call() .apply() .callee()
          Array.assign()
          File.path
          Directory.path
          undefined��Ԃ����\�b�h��this�I�u�W�F�N�g��Ԃ��悤�ɏC��
          TJObject.ToInteger .ToDouble���폜���� .ToNumber�ɓ���
          CalcValue2�ŃI�u�W�F�N�g�̉��Z���C��
          �ϐ��錾��var������ƃ��[�J���A�����ꍇ�̓O���[�o��(TDMonkey.DeclareLocalVar)
          ActiveX�̃C�x���g
          VCL�I�u�W�F�N�g
          OnDoEvents�C�x���g
          GarbageCollect�v���p�e�B���폜�����̂ŃR���|�[�l���g���ēo�^���Ă�������
          �W���^�Ɨ񋓌^�v���p�e�B�͕�����ɕϊ�����
          TJObject.Create�̈�����ύX
          RegExp�̓����������ύX
          eval()���܂Ƃ��ɓ����悤�C��
          TJNotify���g����Object�̏I���ʒm���󂯂邱�Ƃ��ł��܂�
          static�Eglobal�錾�ŐÓI�ϐ�(���@��var�Ɠ���)
          try catch finally���C��
          �\�P�b�g�I�u�W�F�N�g�ɃC�x���g
          TJIniObject.update() write���g������ini���X�V���邽�߂�update�����Ă��������i�C���t���܂���ł����c�j
          TJBaseArrayObject�̉��z���\�b�h��TJObject�ֈړ�
          String.replace()�ŃT�u�}�b�`$n�̒u���A�u��������Ɋ֐����w��
          ���K�\���̃I�u�W�F�N�g�̏ȗ������o  $& $' $* $+ $_ $`
          Object.getKeys() .getProperties() .getMethods()��Array��Ԃ��悤�ɕύX

  2002/12/29 ver.0.2.1
          case���C��
          �����R���p�C���� @set @xxx = [bool|int]
          for..in���ł�Array���f�t�H���g�ŃC���f�b�N�X�ɐݒ� �u@set @VERSION7 = true�v �ŗv�f
          ���ɍs�ԍ����܂߂�
          ���K�\�����e���������������[�N���鎖���������̂��C��
          @set @SHORT_CIRCUIT = false �ŏ������̊��S�]��
          Global.encodeURI,encodeURIComponent,decodeURI,decodeURIComponent

  2002/12/26 ver.0.2.0.3
          case��A���ŕ��ׂ��Ȃ������̂��C��

  2002/12/26 ver.0.2.0.2
          ���x���ɕ����t�������g���Ȃ������̂��C��

  2002/12/25 ver.0.2.0.1
          ActiveX��PropertyGet���C��

  2002/12/23 ver.0.2.0
          shobohn���̃R�[�h���}�[�W
          �g���q�̒�`(ecma_type.pas)
          �g��Object��I���C���|�[�g���邽�߂�$DEFINE
          Complie����LibPath��ǉ�����
          eval�C��
          �Q�ƃJ�E���g�̃R�[�h������
          e�̑O�������̂Ƃ��e���Ă��̂��C���B(ecma_lex.pas)
          ���b�Z�[�W�{�b�N�X�̃I�[�i�[�̗L�����w�肷��$DEFINE��ǉ��B(ecma_misc.pas)
          String.crypt([salt]) Unix����DES crypt(3)�BPerl�݊��ł��B
          OnStdin�C�x���g��Global.read() Global.readln()
          ���K�\�����e���� /patern/ig
          switch��������
          Global.scriptEngineVersion()
          constructor�ŗ�O���N����object�̃A�N�Z�X�ᔽ���C��
          �R���p�C���ς݃o�C�i��(�g���q .dmc)
          for(var i=0; ... ���G���[�ɂȂ�Ȃ��悤�C��
          �V�����Q�ƃJ�E���g
          FTP�I�u�W�F�N�g
          RegExp.replace���C��
          Global.isConsole()
          �z���()�ŃA�N�Z�X  a = [1]; println(a(0));
          Global.args���폜
          WScript�I�u�W�F�N�g�i�s���S�j
          ActiveXObject�̃v���p�e�B�Ăяo�����C��
          RegExp.multiline �� m�I�v�V����
          Enumerator�I�u�W�F�N�g
          for..in���ŃR���N�V������Array�̏ꍇ�͗v�f��Ԃ��悤�ɏC��
          ����Array�I�u�W�F�N�g��TJBaseArrayObject���`(count,length������for..in���g��Object�͌p�����邱�Ƃ𐄏�)
          TJStrings��TJBaseArrayObject�p���ɕύX
          TJHtmlParserObject��TJBaseArrayObject�p���ɕύX
          String.trim() trimLeft() trimRight() ����E�󔒕������폜
          TJStringObject��TJBaseArrayObject�p���ɕύX
          �֐�����var���G���[�ɂȂ��Ă����̂��C��
          �z��v�f��1�̎��A�z�񐔂ɂȂ��Ă����̂��C�� a = [5]

  2002/05/25 ver.0.1.7
          scriptEngine()�Ȃǂ��`

  2002/05/20 ver.0.1.6
          HtmlParser
          RegExp.test()�̏C��
          ���̑�

  2002/05/15 ver.0.1.5
          Date�̏C��

  2002/05/11 ver.0.1.4
          �X�N���v�g�̑S�p�󔒂𖳎�����悤�ɏC��
          RegIni
          Date�̏C��

  2002/04/23 Ver.0.1.3
          Object�̂Q�������C��

  2002/04/14 Ver.0.1.2
          TJObjectFactory�̎d�l��ύX�i�d�v�j����ɂ��TJObject�̓R���X�g���N�^������TJObjectFactory�Ɏ����I�ɏ��L����܂��BNewObject���\�b�h�͎g�p���Ȃ��ł��������B
          �v���p�e�B��Factory��ǉ�
          �Q�ƃJ�E���g�̏C���iUSE_GC�������K�v�j
          CheckListBox
  2002/03/21 Ver.0.1.1
          DynaCall�̏C��
  2002/03/20 Ver.0.1.0
          �C�x���g�̓o�^��ύX
          DynaCall�I�u�W�F�N�g
  2002/03/10 Ver.0.0.15
          Date�̌���0�`11�ɕύX
          Array�I�u�W�F�N�g�̏�����
          OnStep�C�x���g��ǉ�(�X�N���v�g�̒��f�ȂǂɎg�p)
          ���K�\�����C�u�����̕ύX
          String.toUTF8()��ǉ�
          String.fromUTF8toSJIS()��ǉ�
  2002/03/06 Ver.0.0.14
          Object�����o�̎Q�ƃJ�E���g���C��
          �z�񎮂̏C��
          Array�I�u�W�F�N�g�̏C��
  2002/02/07 Ver.0.0.13
          �����o�����C��
  2002/02/06 Ver.0.0.12
          IDispatch�̌Ăяo�����C��
  2002/02/02 Ver.0.0.11
          Clipboard�I�u�W�F�N�g
  2002/02/01 Ver.0.0.10
          ActiveX���\�b�h�ƃv���p�e�B�Ăяo�����C��
  2002/01/28 Ver.0.0.9
            Keyboard��Mouse�I�u�W�F�N�g
  2002/01/27 Ver.0.0.8
            �o�O�C��
  2001/11/16 Ver.0.0.7
            �G���[�o��
          published property�̕����P�[�X�𖳎�
  2001/05/09 Ver.0.0.6
            var
  2001/05/06 Ver.0.0.5
            import
  2001/05/04 Ver.0.0.4
            �N���X��`
  2001/05/04 Ver.0.0.3
            ActiveXObject
  2001/05/02 Ver.0.0.2
          break��continue���C��
  2001/04/30 Ver.0.0.1
          ����
*)


{$IFDEF CONSOLE}
  {$DEFINE NO_VCL}
  {$DEFINE NO_GUI}
{$ENDIF}

{$IFDEF UNICODE}
  // ���̂�Unicode�Ή�DMonkey�̓\�P�b�g�֘A�̌^��Unicode�Ή����Ă��܂���B
  {$DEFINE NO_SOCKET}
{$ENDIF}


interface

uses
  Windows, SysUtils, Classes,
  ecma_lex,ecma_parser,ecma_type,ecma_engine,
{$IFNDEF NO_EXTENSION}
  ecma_extobject,
{$ENDIF}
{$IFNDEF NO_SOCKET}
  ecma_sockobject,
{$ENDIF}
{$IFNDEF NO_ACTIVEX}
  ecma_activex,
{$ENDIF}
{$IFNDEF NO_DYNACALL}
  ecma_dynacall,
{$ENDIF}
{$IFNDEF NO_GUI}
  ecma_guiobject,
{$ENDIF}
{$IFNDEF NO_VCL}
  ecma_vcl,
{$ENDIF}
  ecma_object,ecma_misc;

type
  TDMonkey = class(TJBaseDMonkey)
  private
    FEngine: TJEngine;

    FErrorText: String;
    FTookTimeToCompile: Cardinal;
    FTookTimeToRun: Cardinal;
    FTookTimeToCallFunction: Cardinal;
    FCompiledBinary: Boolean;
    //�C�x���g
    FOnStdout: TStringEvent;
    FOnDebugout: TStringEvent;
    FOnNewObject: TNewObjectEvent;
    FOnStderr: TStringEvent;
    FOnRun: TNotifyEvent;
    FOnDone: TNotifyEvent;
    FOnStep: TStepEvent;
    FOnStdin: TReadStringEvent;
    FOnError: TErrorEvent;
    FOnDoEvents: TStepEvent;
    //
    procedure EngineOnDebug(Sender: TObject; S: String);
    procedure EngineOnStdout(Sender: TObject; S: String);
    procedure EngineOnStderr(Sender: TObject; S: String);
    procedure EngineOnNewObject(Sender: TObject; JObject: TJObject);
    procedure EngineOnRun(Sender: TObject);
    procedure EngineOnDone(Sender: TObject);
    procedure EngineOnStep(Sender: TObject; var AbortScript: Boolean);
    procedure EngineOnStdin(Sender: TObject; var S: String; var Success: Boolean;
      Count: Integer; Line: Boolean);
    procedure EngineOnError(Sender: TObject; LineNo: Integer; Msg: String);
    procedure EngineOnDoEvents(Sender: TObject; var AbortScript: Boolean);

    function GetLibraryPath: TStrings;
    procedure SetLibraryPath(const Value: TStrings);
    function GetObjectCount: Integer;
    procedure SetOnDone(const Value: TNotifyEvent);
    procedure SetOnNewObject(const Value: TNewObjectEvent);
    procedure SetOnRun(const Value: TNotifyEvent);
    procedure SetOnStderr(const Value: TStringEvent);
    procedure SetOnStep(const Value: TStepEvent);
    procedure SetOnStdout(const Value: TStringEvent);
    procedure SetOnStdin(const Value: TReadStringEvent);
    function GetLineNumber: Integer;
    procedure SetOnError(const Value: TErrorEvent);
    procedure SetOnDebugout(const Value: TStringEvent);
    function GetFilename: String;
    procedure SetOnDoEvents(const Value: TStepEvent);
    function GetFactory: TJObjectFactory;
    function GetRegistVar: TJRegistVarType;
    procedure SetRegistVar(const Value: TJRegistVarType);

  protected
    procedure RegistDMSObjects; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Compile(SourceCode: String): Boolean;
    function CompileFile(AFilename: String): Boolean;
    function Run(Args: array of const): Integer; overload;
    function Run(Args: TJValueList): Integer; overload;
    function Run: Integer; overload;
    function CallFunction(Symbol: String; Param: array of const; var RetValue: TJValue): Boolean; overload;
    function CallFunction(Symbol: String; Param: TJValueList; var RetValue: TJValue): Boolean; overload;
    procedure Clear;
    procedure Abort;
    procedure ImportObject(ObjectName: String; ObjectClass: TJObjectClass);
    function IsRunning: Boolean;
    class function ScriptBuild: Integer;
    class function ScriptEngine: String;
    class function ScriptVersion: String;

    property ObjectCount: Integer read GetObjectCount;
    property Factory: TJObjectFactory read GetFactory;
    property TookTimeToCompile: Cardinal read FTookTimeToCompile write FTookTimeToCompile;
    property TookTimeToRun: Cardinal read FTookTimeToRun write FTookTimeToRun;
    property TookTimeToCallFunction: Cardinal read FTookTimeToCallFunction write FTookTimeToCallFunction;
    property ScriptFilename: String read GetFilename;
    property LineNumber: Integer read GetLineNumber;
    //var�錾�Ȃ��ϐ��o�^�̓���
    property RegistVar: TJRegistVarType read GetRegistVar write SetRegistVar;
  published
    property LibraryPath: TStrings read GetLibraryPath write SetLibraryPath;
    property CompiledBinary: Boolean read FCompiledBinary write FCompiledBinary;
    //�C�x���g
    property OnStdout: TStringEvent read FOnStdout write SetOnStdout;
    property OnStderr: TStringEvent read FOnStderr write SetOnStderr;
    property OnDebugout: TStringEvent read FOnDebugout write SetOnDebugout;
    property OnNewObject: TNewObjectEvent read FOnNewObject write SetOnNewObject;
    property OnRun: TNotifyEvent read FOnRun write SetOnRun;
    property OnDone: TNotifyEvent read FOnDone write SetOnDone;
    property OnStep: TStepEvent read FOnStep write SetOnStep;
    property OnStdin: TReadStringEvent read FOnStdin write SetOnStdin;
    property OnError: TErrorEvent read FOnError write SetOnError;
    property OnDoEvents: TStepEvent read FOnDoEvents write SetOnDoEvents;
  end;

  TDMS = class(TDMonkey);


procedure ShowDMonkeyException(DMonkey: TDMonkey);


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Samples', [TDMS]);
end;


procedure ShowDMonkeyException(DMonkey: TDMonkey);
//�G���[��\��
var
  caption,text: String;
begin
  caption := GetApplicationTitle;
  if DMonkey.ScriptFilename <> '' then
    caption := caption + ' - ' + ExtractFilename(DMonkey.ScriptFilename);

  text := DMonkey.FErrorText;
  MsgBox(PChar(text), PChar(caption), MB_OK or MB_ICONHAND);
end;


{ TDMonkey }

procedure TDMonkey.Abort;
//���~����
begin
  FEngine.Abort;
end;

function TDMonkey.CallFunction(Symbol: String; Param: TJValueList; var RetValue: TJValue): Boolean;
//�֐��Ăяo��
var
  tmp: Cardinal;
begin
  //���Ԍv��
  tmp := GetTickCount;
  try
    Result := FEngine.CallFunction(Symbol,Param,RetValue);
  finally
    FTookTimeToCallFunction := GetTickCount - tmp;
  end;
end;

function TDMonkey.CallFunction(Symbol: String;
  Param: array of const; var RetValue: TJValue): Boolean;
//�֐��Ăяo��
var
  list: TJValueList;
  i: Integer;
  v: TJValue;
begin
  list := TJValueList.Create;
  try
    //�ϊ�
    for i := 0 to High(Param) do
    begin
      v := VarRecToValue(Param[i]);
      //�Q�ƃJ�E���g�𑝂₷
      if IsObject(@v) then
        v.vObject.IncRef;

      list.Add(v);
    end;

    Result := CallFunction(Symbol,list,RetValue);
  finally
    list.Free;
  end;
end;

procedure TDMonkey.Clear;
//�f�[�^���N���A
begin
  FEngine.Clear;
end;

function TDMonkey.Compile(SourceCode: String): Boolean;
//��͖؂����
var
  tmp: Cardinal;
begin
  //�R���p�C������
  tmp := GetTickCount;
  try
    Result := FEngine.Compile(SourceCode);
  finally
    //�R���p�C������
    FTookTimeToCompile := GetTickCount - tmp;
  end;
end;

function TDMonkey.CompileFile(AFilename: String): Boolean;
var
  tmp: Cardinal;
begin
  tmp := GetTickCount;
  try
    Result := FEngine.CompileFile(AFilename,FCompiledBinary);
  finally
    //�R���p�C������
    FTookTimeToCompile := GetTickCount - tmp;
  end;
end;

constructor TDMonkey.Create(AOwner: TComponent);
//�쐬
begin
  inherited;
  FEngine := TJEngine.Create(Self);
  //�g��object���C���|�[�g����
  RegistDMSObjects;
end;

destructor TDMonkey.Destroy;
//�j��
begin
  Clear;
  FreeAndNil(FEngine);
  inherited;
end;

procedure TDMonkey.EngineOnDone(Sender: TObject);
begin
 if Assigned(FOnDone) then
   FOnDone(Self);
end;

procedure TDMonkey.EngineOnNewObject(Sender: TObject; JObject: TJObject);
//object �쐬�C�x���g
begin
  if Assigned(FOnNewObject) then
    FOnNewObject(Self,JObject);
end;

procedure TDMonkey.EngineOnRun(Sender: TObject);
begin
  if Assigned(FOnRun) then
    FOnRun(Self);
end;

procedure TDMonkey.EngineOnStderr(Sender: TObject; S: String);
//�W���G���[
begin
  FErrorText := S;
  if Assigned(FOnStderr) then
    FOnStderr(Self,S);
end;

procedure TDMonkey.EngineOnStdout(Sender: TObject; S: String);
//�W���o��
begin
  if Assigned(FOnStdout) then
    FOnStdout(Self,S);
end;

procedure TDMonkey.EngineOnStep(Sender: TObject; var AbortScript: Boolean);
begin
  if Assigned(FOnStep) then
    FOnStep(Self,AbortScript);
end;

function TDMonkey.GetLibraryPath: TStrings;
begin
  Result := FEngine.Parser.LibPath;
end;

function TDMonkey.GetObjectCount: Integer;
begin
  Result := FEngine.ObjectCount;
end;

procedure TDMonkey.ImportObject(ObjectName: String;
  ObjectClass: TJObjectClass);
//�g���݃I�u�W�F�N�g���C���|�[�g
begin
  FEngine.ImportObject(ObjectName,ObjectClass);
end;

function TDMonkey.IsRunning: Boolean;
begin
  Result := FEngine.IsRunning;
end;

procedure TDMonkey.EngineOnDebug(Sender: TObject; S: String);
//�f�o�b�O
begin
  if Assigned(FOnDebugout) then
    FOnDebugout(Self,S);
end;

function TDMonkey.Run(Args: array of const): Integer;
//script�����s
var
  i: Integer;
  param: TJValueList;
begin
  param := TJValueList.Create;
  try
    for i := 0 to High(Args) do
      param.Add(VarRecToValue(Args[i]));

    Result := Run(param);
  finally
    param.Free;
  end;
end;

function TDMonkey.Run(Args: TJValueList): Integer;
//���s
var
  tmp: Cardinal;
begin
  //���s����
  tmp := GetTickCount;
  try
    Result := FEngine.Run(nil,Args);
  finally
    FTookTimeToRun := GetTickCount - tmp;
  end;
end;

function TDMonkey.Run: Integer;
//���s��������
begin
  Result := Run([]);
end;

procedure TDMonkey.SetLibraryPath(const Value: TStrings);
begin
  FEngine.Parser.LibPath.Assign(Value);
end;

procedure TDMonkey.SetOnDone(const Value: TNotifyEvent);
begin
  FOnDone := Value;
  if Assigned(Value) then
    FEngine.OnDone := EngineOnDone
  else
    FEngine.OnDone := nil;
end;

procedure TDMonkey.SetOnNewObject(const Value: TNewObjectEvent);
begin
  FOnNewObject := Value;
  if Assigned(Value) then
    FEngine.OnNewObject := EngineOnNewObject
  else
    FEngine.OnNewObject := nil;
end;

procedure TDMonkey.SetOnRun(const Value: TNotifyEvent);
begin
  FOnRun := Value;
  if Assigned(Value) then
    FEngine.OnRun := EngineOnRun
  else
    FEngine.OnRun := nil;
end;

procedure TDMonkey.SetOnStderr(const Value: TStringEvent);
begin
  FOnStderr := Value;
  if Assigned(Value) then
    FEngine.OnStdErr := EngineOnStdErr
  else
    FEngine.OnStdErr := nil;
end;

procedure TDMonkey.SetOnStep(const Value: TStepEvent);
begin
  FOnStep := Value;
  if Assigned(Value) then
    FEngine.OnStep := EngineOnStep
  else
    FEngine.OnStep := nil;
end;

procedure TDMonkey.SetOnStdout(const Value: TStringEvent);
begin
  FOnStdout := Value;
  if Assigned(Value) then
    FEngine.OnStdOut := EngineOnStdOut
  else
    FEngine.OnStdOut := nil;
end;

class function TDMonkey.ScriptBuild: Integer;
begin
  Result := DMS_BUILD;
end;

class function TDMonkey.ScriptEngine: String;
begin
  Result := DMS_ENGINE;
end;

class function TDMonkey.ScriptVersion: String;
begin
  Result := DMS_VERSION;
end;

procedure TDMonkey.EngineOnStdin(Sender: TObject; var S: String; var Success: Boolean;
  Count: Integer; Line: Boolean);
//�W������
begin
  if Assigned(FOnStdin) then
    FOnStdin(Self,S,Success,Count,Line);
end;

procedure TDMonkey.SetOnStdin(const Value: TReadStringEvent);
begin
  FOnStdin := Value;
  if Assigned(Value) then
    FEngine.OnStdin := EngineOnStdin
  else
    FEngine.OnStdin := nil;
end;

function TDMonkey.GetLineNumber: Integer;
begin
  Result := FEngine.LineNo;
end;

procedure TDMonkey.SetOnError(const Value: TErrorEvent);
begin
  FOnError := Value;
  if Assigned(Value) then
    FEngine.OnError := EngineOnError
  else
    FEngine.OnError := nil;
end;

procedure TDMonkey.EngineOnError(Sender: TObject; LineNo: Integer;
  Msg: String);
begin
  if Assigned(FOnError) then
    FOnError(Self,LineNo,Msg);
end;

procedure TDMonkey.RegistDMSObjects;
//�g��object���C���|�[�g����
begin
{$IFNDEF NO_EXTENSION}
  ecma_extobject.RegisterDMS(FEngine);
{$ENDIF}
{$IFNDEF NO_SOCKET}
  ecma_sockobject.RegisterDMS(FEngine);
{$ENDIF}
{$IFNDEF NO_ACTIVEX}
  ecma_activex.RegisterDMS(FEngine);
{$ENDIF}
{$IFNDEF NO_DYNACALL}
  ecma_dynacall.RegisterDMS(FEngine);
{$ENDIF}
{$IFNDEF NO_GUI} {$IFNDEF CONSOLE}
  ecma_guiobject.RegisterDMS(FEngine);
{$ENDIF}         {$ENDIF}
{$IFNDEF NO_VCL} {$IFNDEF CONSOLE}
  ecma_vcl.RegisterDMS(FEngine);
{$ENDIF}         {$ENDIF}
end;

procedure TDMonkey.SetOnDebugout(const Value: TStringEvent);
begin
  FOnDebugout := Value;
  if Assigned(Value) then
    FEngine.OnDebugout := EngineOnDebug
  else
    FEngine.OnDebugout := nil;
end;

function TDMonkey.GetFilename: String;
begin
  Result := FEngine.ScriptFilename;
end;

procedure TDMonkey.EngineOnDoEvents(Sender: TObject;
  var AbortScript: Boolean);
begin
  if Assigned(FOnDoEvents) then
    FOnDoEvents(Self,AbortScript);
end;

procedure TDMonkey.SetOnDoEvents(const Value: TStepEvent);
begin
  FOnDoEvents := Value;
  if Assigned(Value) then
    FEngine.OnDoEvents := EngineOnDoEvents
  else
    FEngine.OnDoEvents := nil;
end;

function TDMonkey.GetFactory: TJObjectFactory;
begin
  Result := FEngine.Factory;
end;

function TDMonkey.GetRegistVar: TJRegistVarType;
begin
  Result := FEngine.RegistVar;
end;

procedure TDMonkey.SetRegistVar(const Value: TJRegistVarType);
begin
  FEngine.RegistVar := Value;
end;

end.
