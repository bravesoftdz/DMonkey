unit ecma_type;

//�^���`
//2001/04/10 ~
//by Wolfy


{$IFDEF VER130}
  {$DEFINE DELPHI4_5}
{$ENDIF}
{$IFDEF VER125}
  {$DEFINE DELPHI4_5}
{$ENDIF}

{$IFDEF CONSOLE}
  {$DEFINE NO_VCL}
  {$DEFINE NO_GUI}
{$ENDIF}

interface

uses
  windows,sysutils,classes,hashtable,typinfo,
  myclasses,contnrs,dynamiccall,ecma_interface
{$IFNDEF NO_ACTIVEX}
  ,activex
{$ENDIF}
{$IFDEF DELPHI4_5}
  ;
{$ELSE}
  ,variants;
{$ENDIF}

const //�o�[�W�������`����
  DMS_ENGINE = 'DMScript';
  DMS_BUILD = 42;
  DMS_MAJOR = 0;
  DMS_MINOR = 3.9;
  DMS_VERSION = '0.3.9';
  //�V���A���C�Yver
  DMS_SERIALIZE_VER: Byte = 18;
  //�g���q��`
  DMS_EXT = '.dms';
  DMS_COMPILED_EXT = '.dmc';

  CR = #13;
  LF = #10;
  CRLF = #13#10;

  //�����R���p�C��
  CC_VERSION_7 = 'VERSION7';
  CC_SHORT_CIRCUIT = 'SHORT_CIRCUIT';

  __MAIN__ = '__MAIN__';

{$IFDEF DELPHI4_5}
type
  PPWideChar = ^PWideChar;
  PPChar     = ^PChar;
{$ENDIF}

type
  PJStatement = ^TJStatement;
  PJValue = ^TJValue;
  PJExpr = ^TJExpr;
  IJFunction = interface;
  TJObject = class;
  TJHash = class;
  TJValueList = class;
  TJObjectFactory = class;
  PJObjectClass = ^TJObjectClass;
  TJObjectClass = class of TJObject;
  TJBaseEngine = class;
  TJBaseDMonkey = class(TComponent);
  TJRootSymbolTable = class;
  TJGlobalSymbolTable = class;
  TJFunctionSymbolTable = class;
  TJLocalSymbolTable = class;
  TJNotify = class;

  //�C�x���g
  TStringEvent = procedure(Sender: TObject; S: String) of object;
  TRefStringEvent = procedure(Sender: TObject; var S: String) of object;
  TReadStringEvent = procedure(Sender: TObject; var S: String; var Success: Boolean;
    Count: Integer; Line: Boolean) of object;
  TStepEvent = procedure(Sender: TObject; var Abort: Boolean) of object;
  TNewObjectEvent = procedure(Sender: TObject; JObject: TJObject) of object;
  TErrorEvent = procedure(Sender: TObject; LineNo: Integer; Msg: String) of object;

  //�l�̌^
  TJValueType = (vtUndefined,vtNull,vtInteger,vtDouble,
                 vtString,vtObject,vtBool,vtFunction,vtInfinity,vtNaN,
                 vtDispatch,vtRegExp,vtEvent);
  TJValueTypeSet = set of TJValueType;

  TJValueAttribute = (vaReadOnly,vaDontEnum,vaDontDelete,
                      vaInternal,vaPrivate,vaReference);
  TJValueAttributes = set of TJValueAttribute;

  //�l��ۑ����郌�R�[�h
  TJValue = record
    ValueType: TJValueType;       //�l�̎��
    //Attributes: TJValueAttributes; //�l�̑���

    vString: String;              //�ȉ��l�̒��g
    vDispatch: IDispatch;
    vFunction: IJFunction;
    case Integer of
      0: (vInteger: Integer);
      1: (vDouble: Double);
      2: (vBool: Boolean);
      3: (vNull: Pointer);
      4: (vObject: TJObject);
      6: (vRegExpOptions: String[7]); //igm
      7: (vEvent: TMethod);
  end;

  //�֐��^
  TJFuncType = (ftStatement,
                ftMethod,
                ftActiveX,
                ftClass,ftImport,
                ftDynaCall);

  TJMethod = function (Param: TJValueList): TJValue of object;
  TJActivexMethodFlag = (axfMethod,axfGet,axfPut);

  PJActiveXMethod = ^TJActiveXMethod;
  TJActiveXMethod = record
    Parent: IDispatch;
    Dispid: Integer;
    Flag: TJActivexMethodFlag;
  end;

  TJFunctionCallFlag = (fcfNone,fcfApply,fcfCall);

  __TJFunction = record
    Symbol: String;
    FuncType: TJFuncType;
    Parameter: PJStatement;
    Flag: TJFunctionCallFlag;
    FunctionTable: TJFunctionSymbolTable;

    vActiveX: TJActiveXMethod;
    vDynaCall: TDynaDeclare;
    case Integer of
      0: (vStatement: PJStatement);
      1: (vMethod: TJMethod);
  end;

  TVarRecArray = array of TVarRec;

  //�A�N�V����
  TJOPCode = (opNone,
              opExpr,
              opAdd,opSub,opDiv,opMul,opMod,opDivInt,
              opAssign,
              opMulAssign,opDivAssign,opAddAssign,opSubAssign,opModAssign,
              opBitLeftAssign,opBitRightAssign,opBitRightZeroAssign,
              opBitAndAssign,opBitXorAssign,opBitOrAssign,
              opConstant,opVariable,
              opPlus,opMinus,
              opThis,opMember,opObjectElement,opSuper,
              opNew,opNewObject,opNewArray,
              opCallArray,opArg,
              opPreInc,opPreDec,opPostInc,opPostDec,
              opDelete,opVoid,opTypeof,
              opLogicalNot,opLogicalOr,opLogicalOr2,opLogicalAnd,opLogicalAnd2,
              opBitLeft,opBitRight,opBitRightZero,
              opLS,opGT,opLSEQ,opGTEQ,
              opEQ,opNE,opEQEQEQ,opNEEQEQ,
              opBitAnd,opBitXor,opBitOr,opBitNot,
              opConditional,
              opFunction,opMethod,
              opVar);

  TJEvalExprFlag = (eefDelete,eefVar);
  TJEvalExprFlags = set of TJEvalExprFlag;

  //��͖�
  TJExpr = record
    Code: TJOPCode;            //���������
    Left,                       //����
    Right: PJExpr;              //�E��
    Third: PJExpr;              //�R��
    Value: PJValue;             //�萔�l
    Symbol: String;             //�ϐ���
    Statement: PJStatement;
  end;

  TJRegistVarType = (rvGlobal,rvLocal,rvStatic);

  TJStatementType = (stNone,stSource,
                     stBlock,
                     stExpr,
                     stIf,stWhile,stDo,
                     stFor,stForIn,stForInArrayElement,
                     stFunctionDecl,stParamDecl,stClassDecl,stVariableDecl,
                     stBreak,stContinue,stReturn,
                     stTry,stCatch,stFinally,stThrow,
                     stWith,
                     stVar,
                     stLabeled,stSwitch,
                     stStatic,stGlobal);

  TJEvalStatementFlag = (esfVar,esfIteration,esfStaticVar,esfGlobalVar);
  TJEvalStatementFlags = set of TJEvalStatementFlag;

  //�� linked list
  TJStatement = record
    SType: TJStatementType;
    Expr: PJExpr;
    Prev: PJStatement;
    Next: PJStatement;
    Sub1,Sub2: PJStatement;
    Temp: PJStatement;
    LineNo: Integer;
  end;

  //switch�p
  PJSwitchValue = ^TJSwitchValue;
  TJSwitchValue = record
    Value: PJValue;
    Default: PJStatement;
    Match: Boolean;
  end;

  IJFunction = interface
    function GetFunc: __TJFunction;
    function GetFunctionTable: TJFunctionSymbolTable;
    function GetLocalTable: TJLocalSymbolTable;
    function GetFlag: TJFunctionCallFlag;
    function GetFuncType: TJFuncType;
    function GetParameter: PJStatement;
    function GetSymbol: String;
    function GetvActiveX: PJActiveXMethod;
    function GetvDynaCall: PDynaDeclare;
    function GetvMethod: TJMethod;
    function GetvStatement: PJStatement;
    procedure SetFunctionTable(const Value: TJFunctionSymbolTable);
    procedure SetLocalTable(const Value: TJLocalSymbolTable);
    procedure SetFlag(const Value: TJFunctionCallFlag);
    procedure SetFuncType(const Value: TJFuncType);
    procedure SetParameter(const Value: PJStatement);
    procedure SetSymbol(const Value: String);
    procedure SetvMethod(const Value: TJMethod);
    procedure SetvStatement(const Value: PJStatement);
    function GetMethodOwner: TJObject;
    procedure SetMethodOwner(const Value: TJObject);

    procedure Assign(Source: IJFunction);

    property Symbol: String read GetSymbol write SetSymbol;
    property FuncType: TJFuncType read GetFuncType write SetFuncType;
    property Parameter: PJStatement read GetParameter write SetParameter;
    property Flag: TJFunctionCallFlag read GetFlag write SetFlag;
    property FunctionTable: TJFunctionSymbolTable read GetFunctionTable write SetFunctionTable;
    property LocalTable: TJLocalSymbolTable read GetLocalTable write SetLocalTable;
    property MethodOwner: TJObject read GetMethodOwner write SetMethodOwner;

    property vActiveX: PJActiveXMethod read GetvActiveX;
    property vDynaCall: PDynaDeclare read GetvDynaCall;
    property vStatement: PJStatement read GetvStatement write SetvStatement;
    property vMethod: TJMethod read GetvMethod write SetvMethod;
  end;

  TJFunctionImpl = class(TInterfacedObject,IJFunction)
  private
    FFunc: __TJFunction;
    FLocalTable: TJLocalSymbolTable;
    FMethodOwner: TJObject;
    FNotify: TJNotify;
    procedure NotifyOnNotifycation(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: IJFunction);

    function GetMethodOwner: TJObject;
    procedure SetMethodOwner(const Value: TJObject);
    function GetFunc: __TJFunction;
    function GetFunctionTable: TJFunctionSymbolTable;
    function GetLocalTable: TJLocalSymbolTable;
    function GetFlag: TJFunctionCallFlag;
    function GetFuncType: TJFuncType;
    function GetParameter: PJStatement;
    function GetSymbol: String;
    function GetvActiveX: PJActiveXMethod;
    function GetvDynaCall: PDynaDeclare;
    function GetvMethod: TJMethod;
    function GetvStatement: PJStatement;
    procedure SetFunctionTable(const Value: TJFunctionSymbolTable);
    procedure SetLocalTable(const Value: TJLocalSymbolTable);
    procedure SetFlag(const Value: TJFunctionCallFlag);
    procedure SetFuncType(const Value: TJFuncType);
    procedure SetParameter(const Value: PJStatement);
    procedure SetSymbol(const Value: String);
    procedure SetvMethod(const Value: TJMethod);
    procedure SetvStatement(const Value: PJStatement);
  end;

  { TODO : interface�ɂ���H }
  //
  TJNotify = class(TPersistent)
  private
    FFreeNotifies: TBinList;
    FOnNotification: TNotifyEvent;
  protected
    procedure Notification(AObject: TJNotify); virtual;
  public
    destructor Destroy; override;
    procedure FreeNotification(AObject: TJNotify);
    procedure RemoveFreeNotification(AObject: TJNotify);

    property OnNotification: TNotifyEvent read FOnNotification write FOnNotification;
  end;


  //hash object
  TJHash = class(TCustomHashTable)
  private
    FNotify: TJNotify;
    procedure HashOnItemDispose(Sender: TObject; P: PHashItem);
    procedure NotifyOnNotifycation(Sender: TObject);
  public
    constructor Create(ATableSize: DWord; AIgnoreCase: Boolean = False); override;
    destructor Destroy; override;
    function GetValue(Key: String; var Value: TJValue): Boolean;
    procedure SetValue(Key: String; Value: TJValue);
    procedure ClearValue(Target,Ignore: TJValueTypeSet);
    procedure GetKeyList(List: TStrings; Need,Ignore: TJValueTypeSet);

    property Value[Key: String]: TJValue write SetValue;
  end;

  TJValueList = class(TObject)
  private
    FItems: TListPlus;
    FNotify: TJNotify;
    function GetItems(Index: Integer): TJValue;
    procedure SetItems(Index: Integer; const Value: TJValue);
    function GetCount: Integer;
    procedure SetCount(const Value: Integer);
    function GetSortType: TSortType;
    procedure SetSortType(const Value: TSortType);

    procedure NotifyOnNotifycation(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Delete(Index: Integer);
    function Add(Value: TJValue; IncRef: Boolean = True): Integer; overload;
    function Add(Value: TJObject; IncRef: Boolean = True): Integer; overload;
    function Add(Value: Integer): Integer; overload;
    function Add(Value: Boolean): Integer; overload;
    function Add(Value: Double): Integer; overload;
    function Add(Value: String): Integer; overload;
    function Add(Value: IDispatch): Integer; overload;
    procedure Insert(Index: Integer; Value: TJValue);
    procedure Sort(Compare: TListSortCompareObj);
    procedure Assign(Source: TJValueList);

    property Items[Index: Integer]: TJValue read GetItems write SetItems; default;
    property Count: Integer read GetCount write SetCount;
    property SortType: TSortType read GetSortType write SetSortType;
  end;

  //��{�I�u�W�F�N�g
  //TJObject.Free�͐�΂ɌĂ΂Ȃ��ł�������
  //
  //Object���g�p����ꍇ��IncRef
  //Object������������Ƃ���DecRef���g���܂�
  //
  //TJObject�����S�ɏ��L�ł���R���e�i��TJHash,TJValueList�݂̂ł�
  //
  //TJMethod�^���N���X�����Ŏg������A
  //�Ԓl��Object�Ȃ��DecRef���Ă�������
  //TJMethod��public�ɂ��Ȃ����Ƃ𐄏����܂�
  TJObject = class(TJNotify)
  private
    FRefCount: Integer;
    FName: String;
    FMembers: TJHash;
    FEvents: TStringList;

  protected
    FEngine: TJBaseEngine;
    FDefaultProperties: TStringList;

    procedure RegistMethod(MethodName: String; Method: TJMethod);
    //���\�b�h��o�^����
    //�ł���΂�����RegistMethod���g���ė~���������݂͕K�{�ł͂Ȃ�
    procedure RegistMethods; virtual;
    procedure Registproperties; virtual;

    procedure RegistEventName(EventName: String);

    procedure GetKeyList(List: TStringList; Need,Ignore: TJValueTypeSet);
    function HasDefaultProperty(Prop: String): Boolean;

    procedure ClearMembers;
    procedure ClearProperties;
    procedure ClearValue(Target,Ignore: TJValueTypeSet);

    function DoHasKey(Param: TJValueList): TJValue;
    function DoRemoveKey(Param: TJValueList): TJValue;
    function DoToString(Param: TJValueList): TJValue;
    function DoValueOf(Param: TJValueList): TJValue;
    function DoGetKeys(Param: TJValueList): TJValue;
    function DoGetProperties(Param: TJValueList): TJValue;
    function DoGetMethods(Param: TJValueList): TJValue;
    function DoGetEvents(Param: TJValueList): TJValue;

    function GetValueImpl(S: String; var RetVal: TJValue; Param: TJValueList = nil): Boolean; virtual;
    function SetValueImpl(S: String; var Value: TJValue; Param: TJValueList = nil): Boolean; virtual;
    //���Lobject�̏I���ʒm
    procedure Notification(AObject: TJNotify); override;
  public
    //RegisteringFactory = true�Ŏ��g��Factory�ɓo�^���܂�(�ʏ�)
    //�����o��object�����L����ꍇ�ɂ̂݁A���Lobject��false�ɂ��č쐬���܂�(_test.pas�Q��)
    constructor Create(AEngine: TJBaseEngine; Param: TJValueList = nil; RegisteringFactory: Boolean = True); virtual;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure Clear; virtual;

    procedure RegistProperty(PropName: String; Value: TJValue);
    procedure RegistName(AName: String);
    function CallEvent(Prefix,EventName: String; Param: TJValueList): TJValue;
    function IsCallEvent(EventName: String = ''): Boolean;

    function IncRef: Integer; virtual;
    function DecRef: Integer; virtual;
    function HasKey(S: String): Boolean; virtual;
    function RemoveKey(S: String): Boolean; virtual;
    function GetValue(S: String; ArrayStyle: Boolean; Param: TJValueList = nil): TJValue; virtual;
    procedure SetValue(S: String; Value: TJValue; ArrayStyle: Boolean; Param: TJValueList = nil); virtual;
    function ToString(Value: PJValue = nil): String; virtual;
    function ValueOf: TJValue; virtual;
    function ToNumber: Double; virtual;
    function ToBool: Boolean; virtual;
    function ToChar: Char; virtual;
    function Equal(Obj: TJObject): Boolean; virtual;
    procedure GetPropertyList(List: TStringList); virtual;
    procedure GetMethodList(List: TStringList); virtual;
    procedure GetEventList(List: TStrings); virtual;

    //class function Name: String; virtual;
    property Name: String read FName;
    //GlobalInstance���G���W���ɍ쐬���邩�ǂ���
    //constructor�ŗ�O���N�����\���̂���object��False�ɂ��Ă�������
    class function IsMakeGlobalInstance: Boolean; virtual;
    //�z��A�N�Z�X�p���z���\�b�h for..in���Ŏg�p���܂�
    class function IsArray: Boolean; virtual;
    function GetCount: Integer; virtual;
    function GetItem(Index: Integer): TJValue; virtual;
  end;

  TJPrototypeObject = class(TJObject)
  private
    FPrototype: TJObject;
    function GetPrototype: TJObject;
    procedure SetPrototype(const Value: TJObject);
  protected
    procedure RegistMethods; override;
    procedure Notification(AObject: TJNotify); override;
  public
    constructor Create(AEngine: TJBaseEngine; Param: TJValueList = nil; RegisteringFactory: Boolean = True); override;
    destructor Destroy; override;
    procedure GetPropertyList(List: TStringList); override;

    property Prototype: TJObject read GetPrototype write SetPrototype;
  end;

  TJVCLPersistent = class(TJObject)
  private
    function GetVCLClassName: String;
   protected
    FVCL: TPersistent;
    FCanDestroy: Boolean;

    function DoAssign(Param: TJValueList): TJValue; virtual;

    procedure RegistEvents; virtual;
    procedure CreateVCL; virtual;
    procedure DestroyVCL; virtual;
    procedure CreateObjects; virtual;
    procedure Error(Msg: String = ''); virtual;
    procedure ArgsError; virtual;
    procedure CheckVCL(Param: TJValueList = nil; ArgCount: Integer = 0); virtual;

    function GetValueImpl(S: String; var RetVal: TJValue; Param: TJValueList = nil): Boolean; override;
    function SetValueImpl(S: String; var Value: TJValue; Param: TJValueList = nil): Boolean; override;
  public
    constructor Create(AEngine: TJBaseEngine; Param: TJValueList = nil; RegisteringFactory: Boolean = True); override;
    destructor Destroy; override;
    class function IsMakeGlobalInstance: Boolean; override;
    procedure GetPropertyList(List: TStringList); override;

    function RegistVCL(AVCL: TPersistent; ACanDestroy: Boolean): Boolean; virtual;
    class function VCLClassType: TClass; virtual;
    function IsVCL: Boolean;
    property GetVCL: TPersistent read FVCL;
  published
    property VCLclassName: String read GetVCLClassName;
  end;

  TJObjectList = class(TBinList)
  public
    procedure Clear; override;
  end;

  //object�쐬�N���X
  TJObjectFactory = class(TJNotify)
  private
    FEngine: TJBaseEngine;
    FHash: TPointerHashTable;
    FItems: TJObjectList;
    FProto: TJHash;

    FOnNewObject: TNewObjectEvent;

    procedure HashOnItemDispose(Sender: TObject; P: PHashItem);
    function GetObjectCount: Integer;
    function GetObjectNameList: TStringList;
  protected
    procedure Notification(AObject: TJNotify); override;
  public
    constructor Create(AEngine: TJBaseEngine);
    destructor Destroy; override;

    function HasObject(ObjectName: String): Boolean;
    procedure ImportObject(ObjectName: String; ObjectClass: TJObjectClass);
    procedure DeleteObject(ObjectName: String);
    function GetObject(ObjectName: String): PJObjectClass;

    procedure Add(Obj: TJObject);
    procedure Clear;

    function GetPrototype(ObjectName: String): TJObject;
    function SetPrototype(ObjectName: String; Obj: TJObject): Boolean;

    property ObjectCount: Integer read GetObjectCount;
    property ObjectNameList: TStringList read GetObjectNameList;
    property OnNewObject: TNewObjectEvent read FOnNewObject write FOnNewObject;
  end;

  //���[�J���X�^�b�N
  TJLocalSymbolTable = class(TJNotify)
  private
    FParent: TJLocalSymbolTable;
    FLocal: TJHash;
    FThis: TJObject;
    FTables: TObjectList;
    FTempObjects: TJValueList;

    function GetGlobalTable: TJGlobalSymbolTable;
    function GetThis: TJObject;
    procedure SetThis(const Value: TJObject);
    procedure SetParent(Value: TJLocalSymbolTable);
  protected
    procedure Notification(AObject: TJNotify); override;
    function SetValueImpl(Caller: TJLocalSymbolTable; Symbol: String; var Value: TJValue): Boolean; virtual;
    function GetValueImpl(Caller: TJLocalSymbolTable; Symbol: String; var Value: TJValue): Boolean; virtual;
  public
    constructor Create(AParent: TJLocalSymbolTable); virtual;
    destructor Destroy; override;
    procedure Clear; virtual;
    procedure LocalCopy(Source: TJLocalSymbolTable); virtual;

    function GetValue(Symbol: String; var Value: TJValue): Boolean;
    procedure SetValue(Symbol: String; Value: TJValue; RegistType: TJRegistVarType);
    procedure RegistValue(Symbol: String; Value: TJValue);

    function GetGlobalValue(Symbol: String; var Value: TJValue): Boolean;
    procedure RegistGlobalValue(Symbol: String; Value: TJValue);
    procedure RegistStaticValue(Symbol: String; Value: TJValue);

    procedure AddTemporaryObject(AObject: TJObject; IncRef: Boolean = True);
    procedure ClearTemporaryObject;

    function PushLocalTable(ATable: TJLocalSymbolTable; AThis: TJObject): TJLocalSymbolTable; virtual;
    procedure PopLocalTable;
    function GetNodeTable: TJFunctionSymbolTable;

    property Parent: TJLocalSymbolTable read FParent write SetParent;
    property This: TJObject read GetThis write SetThis;
  end;

  //��{�I�Ɋ֐��̐ړ_���Ǘ�
  //���[�J������������h������A��ԍŌ�ɍ쐬�������[�J�����{��
  TJFunctionSymbolTable = class(TJLocalSymbolTable)
  protected
    function SetValueImpl(Caller: TJLocalSymbolTable; Symbol: String; var Value: TJValue): Boolean; override;
    function GetValueImpl(Caller: TJLocalSymbolTable; Symbol: String; var Value: TJValue): Boolean; override;
  end;

  TJGlobalSymbolTable = class(TJFunctionSymbolTable)
  end;

  TJRootSymbolTable = class(TJGlobalSymbolTable)
  private
    FFunctions: TObjectHashTable;
    FGlobals: TStringList;
  public
    constructor Create(AParent: TJLocalSymbolTable); override;
    destructor Destroy; override;
    procedure Clear; override;

    function GetFunctionTable(AParent,AFunc: PJStatement): TJFunctionSymbolTable; overload;
    function GetFunctionTable(AParent: TJFunctionSymbolTable; AFunc: PJStatement): TJFunctionSymbolTable; overload;
    function FindGlobalTable(AName: String): TJGlobalSymbolTable;
    function MakeGlobalTable(AName: String; AFunc: PJStatement): TJGlobalSymbolTable;
  end;

  TJBaseEngine = class(TObject)
  public
    function MakeObject(Name: String; Param: TJValueList): TJObject; virtual; abstract;
    procedure ImportObject(ObjectName: String; ObjectClass: TJObjectClass); virtual; abstract;
    function GetScriptFilename: String; virtual; abstract;
    function FindImportFilename(Filename: String; var FindedFilename: String): Boolean; virtual; abstract;
  end;



  //��{��O
  EJException = class(Exception)
  private
    FExceptName: String;
  public
    property ExceptName: String read FExceptName;
  end;


  EJAbort = class(EJException);
  EJStatement = class(EJException);
  EJBreak = class(EJStatement);
  EJContinue = class(EJStatement);
  //�֐������return
  EJReturn = class(EJStatement)
  private
    FValue: TJValue;
  public
    constructor Create(AValue: TJValue);
    property Value: TJValue read FValue;
  end;

  EJExit = class(EJStatement)
  private
    FStatus: Integer;
  public
    constructor Create(AStatus: Integer);
    property Status: Integer read FStatus;
  end;

  EJError = class(EJException);
  EJRefCountError = class(EJError);
  //���s���G���[
  EJRuntimeError = class(EJError)
  private
    FValue: TJValue;
  public
    constructor Create(AExceptName,AErrorMsg: String; AValue: PJValue = nil);
    property Value: TJValue read FValue;
  end;

  EJThrow = class(EJRuntimeError);

  EJSyntaxError = class(EJRuntimeError)
  private
    FLineNo: Integer;
  public
    constructor Create(ALineNo: Integer; AMsg: String; AValue: PJValue = nil);
    property LineNo: Integer read FLineNo;
  end;


const
  //��O��
  E_EXCEPTION = 'Exception';
  E_THROW = 'EThrow';
  E_CALL = 'ECallError';
  E_INDEX = 'EIndexError';
  E_KEY = 'EKeyError';
  E_IO = 'EIOError';
  E_FILE = 'EFileError';
  E_DIR = 'EDirectoryError';
  E_NAME = 'ENameError';
  E_TYPE = 'ETypeError';
  E_MATHR = 'EMathError';
  E_ZD = 'EZDError';
  E_EOF = 'EEOFError';
  E_SOCKET = 'ESocketError';
  E_REGEXP = 'ERegExp';
  E_STRINGS = 'EStringsError';
  E_WIN32 = 'EWin32Error';
  E_INI = 'EIniError';
  E_CRC = 'ECRCError';
  E_BASE64 = 'EBase64Error';
  E_PROP = 'EPropertyError';
  E_ACTIVEX = 'EActiveXError';
  E_SYNTAX = 'ESyntaxError';
  E_DLL = 'EDLLLoadError';
  E_DYNACALL = 'EDynaCallError';
  E_STRING = 'EStringError';
  E_DELETE = 'EDeleteError';
  E_ENUMERATOR = 'EEnumeratorError';
  E_CONVERT = 'EConvertError';
  E_VCL = 'EVCLError';
  E_STRUCT = 'EStructError';

  E_UNKNOWN_LINE_NO = -1;


//�⏕�֐�
function IsConstant(P: PJExpr): Boolean;
function IsVariable(P: PJExpr): Boolean;
function ConstantValueInt(P: PJExpr): Integer;

procedure EmptyValue(var V: TJValue);
procedure EmptyFunction(var Func: IJFunction);
function TypeOf(P: PJValue): String;

function IsUndefined(P: PJValue): Boolean;
function IsNull(P: PJValue): Boolean;
function IsInteger(P: PJValue): Boolean;
function IsDouble(P: PJValue): Boolean;
function IsNumber(P: PJValue): Boolean;
function IsString(P: PJValue): Boolean;
function IsRegExp(P: PJValue): Boolean;
function IsObject(P: PJValue): Boolean;
function IsNumberObject(P: PJValue): Boolean;
function IsStringObject(P: PJValue): Boolean;
function IsRegExpObject(P: PJValue): Boolean;
function IsArrayObject(P: PJValue): Boolean;
function IsVCLObject(P: PJValue): Boolean;

function IsBool(P: PJValue): Boolean;
function IsFunction(P: PJValue): Boolean;
function IsInfinity(P: PJValue): Boolean;
function IsNaN(P: PJValue): Boolean;
function IsDispatch(P: PJValue): Boolean;
function IsNameSpace(P: PJValue): Boolean;
function IsConstructor(P: PJValue): Boolean;
function IsClass(P: PJValue): Boolean;
function IsEvent(P: PJValue): Boolean;

function TryAsNumber(P: PJValue): Boolean;
function EqualFunction(L,R: PJValue): Boolean;
function EqualType(L,R: PJValue): Boolean;

function AsInteger(P: PJValue): Integer;
function AsDouble(P: PJValue): Double;
function AsString(P: PJValue): String;
function AsBool(P: PJValue): Boolean;
function AsDispatch(P: PJValue): IDispatch;
function AsSingle(P: PJValue): Single;
function AsChar(P: PJValue): Char;

function BuildUndefined: TJValue;
function BuildString(const V: String): TJValue;
function BuildNull: TJValue;
function BuildInteger(V: Integer): TJValue;
function BuildDouble(V: Double): TJValue;
function BuildObject(V: TJObject): TJValue;
function BuildBool(V: Boolean): TJValue;
function BuildInfinity(Negative: Boolean): TJValue;
function BuildNaN: TJValue;
function BuildDispatch(V: IDispatch): TJValue;
function BuildEvent(V: TMethod): TJValue;
function BuildFunction(V: IJFunction): TJValue;

{$IFNDEF NO_ACTIVEX}
function VariantToValue(const V: OleVariant; const Engine: TJBaseEngine): TJValue;
function ValueToVariant(const V: TJValue): OleVariant;
{$ENDIF}

function VarRecToValue(const V: TVarRec): TJValue;
function ValueToVarRec(const V: TJValue): TVarRec;
procedure DisposeVarRec(Rec: TVarRecArray);

function GetParamCount(const Param: TJValueList): Integer;
function IsParam1(const Param: TJValueList): Boolean;
function IsParam2(const Param: TJValueList): Boolean;
function IsParam3(const Param: TJValueList): Boolean;
function IsParam4(const Param: TJValueList): Boolean;

procedure HashToJObject(Hash: TStringHashTable; JObject: TJObject);
procedure JObjectToHash(JObject: TJObject; Hash: TStringHashTable);

{$IFNDEF NO_ACTIVEX}
function AXMethodFlagToDisp(A: TJActiveXMethodFlag): Word;
function AXMethodFlagToString(A: TJActiveXMethodFlag): String;
{$ENDIF}

function ValueListToDynaValueArray(Format: String; const Param: TJValueList): TDynaValueArray;
function DynaResultToValue(Format: String; const DynaResult: TDynaResult): TJValue;
procedure SetRefDynaValue(const DynaValueArray: TDynaValueArray; Param: TJValueList);

//L��R�̌v�Z���ʂ�Ԃ�
function CalcValue1(Code: TJOPCode; const L: TJValue): TJValue;
function CalcValue2(Code: TJOPCode; const L,R: TJValue): TJValue;
function CalcValue3(Code: TJOPCode; const L,R,T: TJValue): TJValue;
function AssignValue(Code: TJOPCode; const Variable,Value: TJValue): TJValue;
function CompareValue(Code: TJOPCode; const L,R: TJValue): TJValue;

//Object
function GetDefaultProperty(Obj: TObject; const Prop: String; var Value: TJValue; Engine: TJBaseEngine): Boolean;
function SetDefaultProperty(Obj: TObject; const Prop: String; Value: TJValue; ValueTypeInfo: PTypeInfo = nil): Boolean;
procedure GetDefaultProperties(Obj: TObject; PropNames: TStrings; Event: Boolean = False);
procedure SetDefaultMethodNil(Obj: TObject);
procedure EnumMethodNames(Obj: TObject; List: TStrings);

//�W���^
procedure EnumSetNames(Info: PTypeInfo; List: TStrings);
procedure SetToJObject(Info: PTypeInfo; Obj: TJObject; const Value);
procedure JObjectToSet(Info: PTypeInfo; Obj: TJObject; var RetValue);
function JObjectToSetStr(Info: PTypeInfo; Obj: TJObject): String;
function SetToStr(Info: PTypeInfo; const Value): string;
procedure StrToSet(Info: PTypeInfo; const S: String; var RetValue);
//�񋓌^
function ValueToEnum(Info: PTypeInfo; var Value: TJValue; var Enum: Integer): Boolean;
function EnumToValue(Info: PTypeInfo; var Value: TJValue; Enum: Integer): Boolean;



implementation

uses
  ecma_engine,
{$IFNDEF NO_ACTIVEX}
  ecma_activex,
{$ENDIF}
{$IFNDEF NO_EXTENSION}
  ecma_extobject,
{$ENDIF}
{$IFNDEF NO_VCL}
  ecma_vcl,
{$ENDIF}
  ecma_object;


function GetParamCount(const Param: TJValueList): Integer;
begin
  if Assigned(Param) then
    Result := Param.Count
  else
    Result := 0;
end;

function IsParam1(const Param: TJValueList): Boolean;
begin
  Result := (Assigned(Param) and (Param.Count > 0))
end;

function IsParam2(const Param: TJValueList): Boolean;
begin
  Result := (Assigned(Param) and (Param.Count > 1))
end;

function IsParam3(const Param: TJValueList): Boolean;
begin
  Result := (Assigned(Param) and (Param.Count > 2))
end;

function IsParam4(const Param: TJValueList): Boolean;
begin
  Result := (Assigned(Param) and (Param.Count > 3))
end;

function IsConstant(P: PJExpr): Boolean;
//�萔���ǂ����H
begin
  Result := (Assigned(P) and (P^.Code = opConstant))
end;

function IsVariable(P: PJExpr): Boolean;
//�ϐ����ǂ����H
begin
  Result := (Assigned(P) and (P^.Code = opVariable))
end;

function ConstantValueInt(P: PJExpr): Integer;
//�萔�̐����l�𓾂�
begin
  Result := 0;
  if IsConstant(P) and (P^.Value.ValueType = vtInteger) then
    Result := P^.Value.vInteger;
end;

procedure EmptyValue(var V: TJValue);
//�ϐ���������
begin
  V.ValueType := vtUndefined;
  //V.Attributes := [];
  V.vDouble := 0;
  V.vInteger := 0;
  V.vString := '';
  V.vDispatch := nil;
  V.vFunction := nil;
end;

procedure EmptyFunction(var Func: IJFunction);
begin
  //�쐬����
  Func := TJFunctionImpl.Create;
  {
  Func.Symbol := '';
  Func.FuncType := ftStatement;
  Func.Parameter := nil;
  Func.vStatement := nil;
  Func.Flag := fcfNone;
  Func.vActiveX.Parent := nil;
  Func.vActiveX.Dispid := 0;
  Func.vActiveX.Flag := axfMethod;
  ClearDynaDeclare(Func.vDynaCall^);
  Func.FunctionTable := nil;
  Func.LocalTable := nil;
  Func.MethodOwner := nil;
  }
end;

function AsInteger(P: PJValue): Integer;
//�����l��Ԃ�
begin
  Result := 0;
  if not Assigned(P) then
    Exit;

  case P^.ValueType of
    vtUndefined: Result := 0;
    vtInteger: Result := P^.vInteger;
    vtDouble: Result := Round(P^.vDouble);
    vtString: Result := StrToIntDef(P^.vString,0);
    vtBool: Result := Integer(P^.vBool);
    vtNull: Result := 0;
    vtObject: Result := Round(P^.vObject.ToNumber);
    vtFunction:;
  end;
end;

function AsChar(P: PJValue): Char;
begin
  Result := #0;
  if not Assigned(P) then
    Exit;

  case P^.ValueType of
    vtUndefined: Result := #0;
    vtInteger: Result := Char(P^.vInteger);
    vtDouble: Result := Char(Trunc(P^.vDouble));
    vtBool: Result := Char(P^.vBool);
    vtNull: Result := #0;
    vtString:
    begin
      if Length(P^.vString) > 0 then
        Result := P^.vString[1];
    end;
    vtObject: Result := P^.vObject.ToChar;
  end;
end;

function AsSingle(P: PJValue): Single;
begin
  Result := AsDouble(P);
end;

function AsDouble(P: PJValue): Double;
//double��Ԃ�
var
  i: Integer;
begin
  Result := 0;
  if not Assigned(P) then
    Exit;

  case P^.ValueType of
    vtInteger: Result := P^.vInteger;
    vtDouble: Result := P^.vDouble;
    vtBool: Result := Integer(P^.vBool);
    vtString:
    begin
      try
        Result := StrToFloat(P^.vString);
      except
        try
          i := StrToInt(P^.vString);
          Result := i;
        except
        end;
      end;
    end;

    vtObject: Result := P^.vObject.ToNumber;
  end;

end;

function TryAsNumber(P: PJValue): Boolean;
//���l�ɏo����H
var
  s: string;
begin
  Result := False;
  if not Assigned(P) then
    Exit;

  case P^.ValueType of
    vtInteger: Result := True;
    vtDouble: Result := True;
    vtBool: Result := True;
  else
    if IsString(P) then
    begin
      s := AsString(P);
      try
        StrToFloat(s);
        Result := True;
      except
        try
          StrToInt(s);
          Result := True;
        except
        end;
      end;
    end
    else
      Result := IsNumberObject(P);
  end;//case
end;

function AsString(P: PJValue): String;
//�����ɂ��ĕԂ�
begin
  Result := '';
  if not Assigned(P) then
    Exit;

  case P^.ValueType of
    vtUndefined: Result := 'undefined';
    vtInteger: Result := IntToStr(P^.vInteger);
    vtDouble: Result := FloatToStr(P^.vDouble);
    vtString: Result := P^.vString;
    vtRegExp: Result := '/' + P^.vString + '/' + P^.vRegExpOptions;
    vtNull: Result := 'null';
    vtBool:
    begin
      if P^.vBool then
        Result := 'true'
      else
        Result := 'false';
    end;
    vtObject: Result := P^.vObject.ToString;
    vtFunction:
    begin
      Result := 'function ' + P^.vFunction.Symbol
    end;
    vtInfinity:
    begin
      if P^.vBool then
        Result := '-infinity'
      else
        Result := 'infinity';
    end;
    vtNaN: Result := 'NaN';
    vtDispatch: Result := 'dispatch' + IntToStr(Integer(P^.vDispatch));
  end;
end;

function AsBool(P: PJValue): Boolean;
//bool�l��Ԃ�
begin
  Result := False;
  if not Assigned(P) then
    Exit;

  case P^.ValueType of
    vtUndefined: Result := False;
    vtInteger: Result := (P^.vInteger <> 0);
    vtDouble: Result := (Trunc(P^.vDouble) <> 0);
    vtString: Result := (P^.vString <> '');
    vtRegExp: Result := (P^.vString <> '');
    vtNull: Result := False;
    vtBool: Result := P^.vBool;
    vtFunction: Result := True;
    vtInfinity: Result := True;
    vtNaN: Result := True;
    vtObject: Result := P^.vObject.ToBool;
    vtDispatch: Result := Assigned(P^.vDispatch);
  end;
end;

function AsDispatch(P: PJValue): IDispatch;
begin
  Result := nil;
  if not Assigned(P) then
    Exit;

  if IsDispatch(P) then
    Result := P^.vDispatch;
end;

function TypeOf(P: PJValue): String;
begin
  if IsInteger(P) or IsDouble(P) or IsNaN(P) or IsInfinity(P) then
    Result := 'number'
  else if IsObject(P) then //string���object���ɂ���
    Result := 'object'
  else if IsString(P) then
    Result := 'string'
  else if IsRegExp(P) then
    Result := 'regexp'
  else if IsBool(P) then
    Result := 'boolean'
  else if IsFunction(P) then
    Result := 'function'
  else if IsUndefined(P) then
    Result := 'undefined'
  else if IsNull(P) then
    Result := 'null'
  else if IsDispatch(P) then
    Result := 'dispatch'
  else if IsEvent(P) then
    Result := 'event'
  else
    Result := '';
end;

function IsUndefined(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtUndefined));
end;

function IsNull(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtNull));
end;

function IsInteger(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtInteger));
end;

function IsDouble(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtDouble));
end;

function IsNumber(P: PJValue): Boolean;
//���ۂɐ��l�����l���ǂ���
begin
  //NaN,infinity��False��Ԃ�
  Result := Assigned(P) and
            ((P^.ValueType in [vtInteger,vtDouble]) or IsNumberObject(P));
end;

function IsString(P: PJValue): Boolean;
begin
  Result := Assigned(P) and ((P^.ValueType = vtString) or
{$IFNDEF NO_EXTENSION}
                             IsStringBufferObject(P) or
{$ENDIF}
                             IsStringObject(P));
end;

function IsRegExp(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtRegExp));
end;

function IsObject(P: PJValue): Boolean;
begin
  Result := Assigned(P) and
            (P^.ValueType = vtObject) and
            Assigned(P^.vObject);
end;

function IsNumberObject(P: PJValue): Boolean;
begin
  Result := IsObject(P) and (P^.vObject is TJNumberObject);
end;

function IsStringObject(P: PJValue): Boolean;
begin
  Result := IsObject(P) and (P^.vObject is TJStringObject);
end;

function IsRegExpObject(P: PJValue): Boolean;
begin
  Result := IsObject(P) and (P^.vObject is TJRegExpObject);
end;

function IsArrayObject(P: PJValue): Boolean;
begin
  Result := IsObject(P) and P^.vObject.IsArray;
end;

function IsVCLObject(P: PJValue): Boolean;
begin
  Result := IsObject(P) and (P^.vObject is TJVCLPersistent);
end;

function IsBool(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtBool));
end;

function IsFunction(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtFunction));
end;

function IsNameSpace(P: PJValue): Boolean;
begin
  Result := IsFunction(P) and (P^.vFunction.FuncType = ftImport);
end;

function IsConstructor(P: PJValue): Boolean;
begin
  Result := IsFunction(P) and(P^.vFunction.FuncType = ftStatement);
end;

function IsClass(P: PJValue): Boolean;
begin
  Result := IsFunction(P) and(P^.vFunction.FuncType = ftClass);
end;

function IsInfinity(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtInfinity));
end;

function IsNaN(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtNaN));
end;

function IsDispatch(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtDispatch));
end;

function IsEvent(P: PJValue): Boolean;
begin
  Result := (Assigned(P) and (P^.ValueType = vtEvent));
end;

function BuildUndefined: TJValue;
begin
  EmptyValue(Result);
end;

function BuildString(const V: String): TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtString;
  Result.vString := V;
end;

function BuildNull: TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtNull;
  Result.vNull := nil;
end;

function BuildInteger(V: Integer): TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtInteger;
  Result.vInteger := V;
end;

function BuildDouble(V: Double): TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtDouble;
  Result.vDouble := V;
end;

function BuildObject(V: TJObject): TJValue;
begin
  EmptyValue(Result);
  if Assigned(V) then
  begin
    Result.ValueType := vtObject;
    Result.vObject := V;
  end
  else
    Result := BuildNull;
end;

function BuildBool(V: Boolean): TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtBool;
  Result.vBool := V;
end;

function BuildInfinity(Negative: Boolean): TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtInfinity;
  Result.vBool := Negative; // ���̖�����Ȃ�True
end;

function BuildNaN: TJValue;
begin
  Emptyvalue(Result);
  Result.ValueType := vtNaN;
end;

function BuildDispatch(V: IDispatch): TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtDispatch;
  Result.vDispatch := V;
end;

function BuildEvent(V: TMethod): TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtEvent;
  Result.vEvent := V;
end;

function BuildFunction(V: IJFunction): TJValue;
begin
  EmptyValue(Result);
  Result.ValueType := vtFunction;
  Result.vFunction := V;
end;

{$IFNDEF NO_ACTIVEX}
function VariantToValue(const V: OleVariant; const Engine: TJBaseEngine): TJValue;
//variant����ϊ�
var
  act: TJActiveXObject;
  date: TJDateObject;
begin
  EmptyValue(Result);
  case VarType(V) of
    varNull: Result := BuildNull;
    varSmallint,varInteger,varByte: Result := BuildInteger(V);
    varSingle,varDouble: Result := BuildDouble(V);
    varOleStr,varString,varVariant: Result := BuildString(V);
    varBoolean: Result := BuildBool(V);
    varDispatch:
    begin
      //ActiveXObject�ɕϊ�
      if Assigned(Engine) then
      begin
        act := TJActiveXObject.Create(Engine);
        act.disp := V;
        Result := BuildObject(act);
      end
      else
        Result := BuildDispatch(V);
    end;
    varDate:
    begin
      //Date�ɕϊ�
      if Assigned(Engine) then
      begin
        date := TJDateObject.Create(Engine);
        date.LocalTime := V;
        Result := BuildObject(date);
      end;
    end;
  end;
end;

function ValueToVariant(const V: TJValue): OleVariant;
//variant�֕ϊ�
var
  ws: WideString;
  tmp: TJValue;
begin
  //VarClear(Result);  varClear�̓o�O���Ă���
  VariantInit(Result);
  case V.ValueType of
    vtNull: Result := VarAsType(Result,varNull);
    vtInteger: Result := V.vInteger;
    vtDouble: Result := V.vDouble;
    vtBool: Result := V.vBool;
    vtString:
    begin
      ws := V.vString;
      Result := ws;
    end;
    vtDispatch: Result := V.vDispatch;
    vtObject:
    begin
      if V.vObject is TJActiveXObject then
      begin
        Result := (V.vObject as TJActiveXObject).disp;
      end
      else if (V.vObject is TJStringObject)
      {$IFNDEF NO_EXTENSION}
           or (V.vObject is TJStringBufferObject)
      {$ENDIF}
           then
      begin
        ws := V.vObject.ToString;
        Result := ws;
      end
      else if V.vObject is TJDateObject then
      begin
        Result := (V.vObject as TJDateObject).LocalTime;
      end
      else if V.vObject is TJNumberObject then
      begin
        tmp := (V.vObject as TJNumberObject).ValueOf;
        if tmp.ValueType = vtInteger then
          Result := tmp.vInteger
        else
          Result := tmp.vDouble;
      end
      else if V.vObject is TJBooleanObject then
      begin
        Result := V.vObject.ToBool;
      end;
    end;
  end;
end;
{$ENDIF}

function VarRecToValue(const V: TVarRec): TJValue;
//TVarRec��ϊ�����
begin
  EmptyValue(Result);
  case V.VType of
    system.vtInteger: Result := BuildInteger(V.VInteger);
    system.vtInt64: Result := BuildDouble(V.VInt64^);

    system.vtBoolean: Result := BuildBool(V.VBoolean);

    system.vtExtended: Result := BuildDouble(V.VExtended^);

    system.vtString: Result := BuildString(V.VString^);
    system.vtChar: Result := BuildString(V.VChar);
    system.vtWideChar: Result := BuildString(V.VWideChar);
    system.vtAnsiString: Result := BuildString(AnsiString(V.VAnsiString));
    system.vtWideString: Result := BuildString(WideString(V.VWideString));
    system.vtPChar: Result := BuildString(V.VPChar);
    system.vtPWideChar: Result := BuildString(V.VWideChar);

    system.vtObject:
    begin
      if V.VObject is TJObject then
        Result := BuildObject(V.VObject as TJObject);
    end;
{$IFNDEF NO_ACTIVEX}
    system.vtVariant: Result := VariantToValue(V.VVariant^,nil);
{$ENDIF}

    //system.vtInterface:
    //system.vtPointer:
    //system.vtClass:
    //system.vtCurrency:
  end;
end;

function ValueToVarRec(const V: TJValue): TVarRec;
//TVarRec����ϊ�����
var
  p: PChar;
  s: String;
begin
  case V.ValueType of
    vtInteger:
    begin
      Result.VType := system.vtInteger;
      Result.VInteger := AsInteger(@V);
    end;

    vtDouble:
    begin
      Result.VType := system.vtExtended;
      New(Result.VExtended);
      Result.VExtended^ := AsDouble(@V);
    end;

    vtString,vtObject,vtBool,vtNull,vtUndefined,
    vtDispatch,vtNaN,vtInfinity,vtFunction,vtRegExp:
    begin
      Result.VType := system.vtPChar;
      s := AsString(@v);
      GetMem(p,Length(s) + 1);
      FillChar(p^,Length(s) + 1,0);
      StrPLCopy(p,s,Length(s));
      Result.VPChar := p;
    end;
  else
    Result.VType := system.vtInteger;
    Result.VInteger := 0;
  end;
  sleep(0);
end;

procedure DisposeVarRec(Rec: TVarRecArray);
//TVarRec���J������
var
  i: Integer;
begin
  for i := 0 to Length(Rec) - 1 do
    case Rec[i].VType of
      system.vtExtended: Dispose(Rec[i].VExtended);
      system.vtPChar: FreeMem(Rec[i].VPChar);
    end;
end;

function EqualFunction(L,R: PJValue): Boolean;
//�����֐����ǂ���
begin
  Result := False;
  if IsFunction(L) and IsFunction(R) then
    Result := L^.vFunction  = R^.vFunction;
end;

function EqualType(L,R: PJValue): Boolean;
//�����^���ǂ���
begin
  Result := False;
  if Assigned(L) and Assigned(R) then
    Result := L^.ValueType = R^.ValueType;
end;

procedure HashToJObject(Hash: TStringHashTable; JObject: TJObject);
//hash����object��
var
  keys: TStringList;
  i: Integer;
begin
  keys := Hash.KeyList;
  JObject.ClearProperties;
  for i := 0 to keys.Count - 1 do
    JObject.RegistProperty(keys[i],BuildString(Hash[keys[i]]));
end;

procedure JObjectToHash(JObject: TJObject; Hash: TStringHashTable);
//object����hash��
var
  keys: TStringList;
  i: Integer;
  v: TJValue;
begin
  keys := TStringList.Create;
  try
    JObject.GetPropertyList(keys);
    Hash.Clear;
    for i := 0 to keys.Count - 1 do
    begin
      v := JObject.GetValue(keys[i],True);
      Hash[keys[i]] := AsString(@v);
    end;
  finally
    keys.Free;
  end;
end;

{$IFNDEF NO_ACTIVEX}

function AXMethodFlagToDisp(A: TJActiveXMethodFlag): Word;
//ActveX�̃��\�b�h�t���O��ϊ�
begin
  Result := DISPATCH_METHOD or DISPATCH_PROPERTYGET;
  case A of
    axfGet: Result := DISPATCH_PROPERTYGET or DISPATCH_METHOD;
    axfPut: Result := DISPATCH_PROPERTYPUT;
  end;
end;

function AXMethodFlagToString(A: TJActiveXMethodFlag): String;
//activex�̕������Ԃ�
begin
  Result := 'DISPATCH_METHOD';
  case A of
    axfGet: Result := 'DISPATCH_PROPERTYGET';
    axfPut: Result := 'DISPATCH_PROPERTYPUT';
  end;
end;
{$ENDIF}

function ValueListToDynaValueArray(
  Format: String; const Param: TJValueList): TDynaValueArray;
//valuelsit��ϊ�����
var
  len,i: Integer;
  v: TJValue;

  function IsRefNull(P: PJValue): Boolean;
  //null���ǂ���
  begin
    if Assigned(P) then
      Result := P^.ValueType in [vtUndefined,vtNull]
    else
      Result := True;
  end;

begin
  len := Length(Format);
  if len > 0 then
  begin
    Format := LowerCase(Format);
    SetLength(Result,len);
    for i := 1 to len do
    begin
      try
        v := Param[i - 1];
      except
        on EListError do
          v := BuildNull;
      end;

      case Format[i] of
        'c':
        begin
          Result[i - 1].VType := dvtChar;
          Result[i - 1]._char := AsChar(@v);
        end;

        '1':
        begin
          if IsRefNull(@v) then
          begin
            Result[i - 1].VType := dvtPointer;
            Result[i - 1]._long := 0;
          end
          else begin
            Result[i - 1].VType := dvtRefChar;
            Result[i - 1]._char := AsChar(@v);
          end;
        end;

        't':
        begin
          Result[i - 1].VType := dvtShort;
          Result[i - 1]._short := AsInteger(@v);
        end;

        '2':
        begin
          if IsRefNull(@v) then
          begin
            Result[i - 1].VType := dvtPointer;
            Result[i - 1]._long := 0;
          end
          else begin
            Result[i - 1].VType := dvtRefShort;
            Result[i - 1]._short := AsInteger(@v);
          end;
        end;

        'l','h','p','u','b':
        begin
          Result[i - 1].VType := dvtLong;
          Result[i - 1]._long := AsInteger(@v);
        end;

        '4':
        begin
          if IsRefNull(@v) then
          begin
            Result[i - 1].VType := dvtPointer;
            Result[i - 1]._long := 0;
          end
          else begin
            Result[i - 1].VType := dvtRefLong;
            Result[i - 1]._long := AsInteger(@v);
          end;
        end;

        'i':
        begin
          Result[i - 1].VType := dvtInt64;
          Result[i - 1]._int64 := Round(AsDouble(@v));
        end;

        '8':
        begin
          if IsRefNull(@v) then
          begin
            Result[i - 1].VType := dvtPointer;
            Result[i - 1]._long := 0;
          end
          else begin
            Result[i - 1].VType := dvtRefInt64;
            Result[i - 1]._int64 := Round(AsDouble(@v));
          end;
        end;

        's':
        begin
          if IsRefNull(@v) then
          begin
            Result[i - 1].VType := dvtPointer;
            Result[i - 1]._long := 0;
          end
          else begin
            Result[i - 1].VType := dvtString;
            Result[i - 1]._string := AsString(@v);
          end;
        end;

        'w':
        begin
          if IsRefNull(@v) then
          begin
            Result[i - 1].VType := dvtPointer;
            Result[i - 1]._long := 0;
          end
          else begin
            Result[i - 1].VType := dvtWideString;
            Result[i - 1]._widestring := AsString(@v);
          end;
        end;

        'f':
        begin
          Result[i - 1].VType := dvtFloat;
          Result[i - 1]._float := AsSingle(@v);
        end;

        'd':
        begin
          Result[i - 1].VType := dvtDouble;
          Result[i - 1]._double := AsDouble(@v);
        end;

        'a':
        begin
          Result[i - 1].VType := dvtIDispatch;
          Result[i - 1]._idispatch := AsDispatch(@v);
        end;

        'k':
        begin
          Result[i - 1].VType := dvtIUnknown;
          Result[i - 1]._iunknown := AsDispatch(@v);
        end;
      else
        //���Ă͂܂�Ȃ��ꍇ�͗�O
        raise EJThrow.Create(E_DYNACALL,'arguments flag error');
      end;
    end;
  end
  else
    Result := nil;
end;

function DynaResultToValue(Format: String; const DynaResult: TDynaResult): TJValue;
//dynacall�̖߂�l
var
  len: Integer;
begin
  Result := BuildNull;

  len := Length(Format);
  if len > 0 then
  begin
    Format := LowerCase(Format);
    case Format[1] of
      'c','t','l','h','p','u': Result := BuildInteger(DynaResult._long);
      'b': Result := BuildBool(DynaResult._long <> 0);
      'i': Result := BuildDouble(DynaResult._int64);
      'a','k': Result := BuildDispatch(IDispatch(DynaResult._long));
      's': Result := BuildString(PChar(DynaResult._pointer));
      'w': Result := BuildString(PWideChar(DynaResult._pointer));
      'd': Result := BuildDouble(DynaResult._double);
      'f': Result := BuildDouble(DynaResult._float);
    end;
  end;
end;

procedure SetRefDynaValue(const DynaValueArray: TDynaValueArray; Param: TJValueList);
//�Q�Ɠn���̒l�𔽉f����
var
  cnt,i: Integer;
  v: TJValue;
begin
  cnt := GetParamCount(Param);
  //���������ɍ��킹��
  if cnt > Length(DynaValueArray) then
    cnt := Length(DynaValueArray);

  for i := 0 to cnt - 1 do
  begin
    v := Param[i];
    //�l�𔽉f����̂�Number�I�u�W�F�N�g����
    if IsNumberObject(@v) then
      case DynaValueArray[i].VType of
        dvtRefChar:
          (v.vObject as TJNumberObject).int := Integer(DynaValueArray[i]._char);
        dvtRefShort:
          (v.vObject as TJNumberObject).int := DynaValueArray[i]._short;
        dvtRefLong:
          (v.vObject as TJNumberObject).int := DynaValueArray[i]._long;
        dvtRefInt64:
          (v.vObject as TJNumberObject).number := DynaValueArray[i]._int64;
      end;
  end;
end;

function CalcValue1(Code: TJOPCode; const L: TJValue): TJValue;
//�P����
//L�̌v�Z���ʂ�Ԃ�
//�^�ɂ���Ă͌v�Z�ł��Ȃ��ꍇ������
begin
  EmptyValue(Result);
  //�^�`�F�b�N������
  //����`�G���[
  if IsUndefined(@L) then
    raise EJThrow.Create(E_NAME,'')
  //�^�G���[
  else if IsFunction(@L) or IsNaN(@L) then
    raise EJThrow.Create(E_TYPE,GetEnumName(TypeInfo(TJValueType),Ord(L.ValueType)));
  //�v�Z
  case Code of
    opMinus:
    begin
      if IsDouble(@L) then
        Result := BuildDouble(0 - AsDouble(@L))
      else if IsInfinity(@L) then
        Result := BuildInfinity(not L.vBool)
      else
        Result := BuildInteger(0 - (AsInteger(@L)));
    end;
    opPlus:
    begin
      if IsDouble(@L) or IsInfinity(@L) then
        Result := L //���̂܂ܕԂ�
      else
        Result := BuildInteger(AsInteger(@L));
    end;
    opBitNot:
    begin
      if IsInfinity(@L) then
        raise EJThrow.Create(E_TYPE,GetEnumName(TypeInfo(TJValueType),Ord(L.ValueType)))
      else
        Result := BuildInteger(not (AsInteger(@L)));
    end;
  end;
end;

function CalcValue2(Code: TJOPCode; const L,R: TJValue): TJValue;
//�Q����
//L��R�̌v�Z���ʂ�Ԃ�
//�^�ɂ���Ă͌v�Z�ł��Ȃ��ꍇ������
var
  dl,dr: Double;
  il,ir: Integer;
begin
  EmptyValue(Result);
  //�^�`�F�b�N������
  //����`�G���[
  if IsUndefined(@L) or
     IsUndefined(@R) then
    raise EJThrow.Create(E_NAME,'');
  //�^�G���[
  if IsFunction(@L) or IsInfinity(@L) or IsNaN(@L) or
     IsFunction(@R) or IsInfinity(@R) or IsNaN(@R) then
    raise EJThrow.Create(E_TYPE,
      GetEnumName(TypeInfo(TJValueType),Ord(L.ValueType)) + ' - ' +
      GetEnumName(TypeInfo(TJValueType),Ord(R.ValueType))
      );
  //�v�Z
  case Code of
    opAdd: //���Z    +
    begin
      //�ǂ��炩�������̏ꍇ�͕����ɕϊ�
      if IsString(@L) or IsString(@R) then
        Result := BuildString(AsString(@L) + AsString(@R))
{ TODO : integer��double�̂ǂ����D�悷�邩 }
      {
      else
        try
          Result := BuildDouble(AsDouble(@L) + AsDouble(@R));
          if IsInteger(@L) and IsInteger(@R) and
             (Result.vDouble <= MaxInt) and (Result.vDouble >= Low(Integer)) then
            Result := BuildInteger(AsInteger(@Result));
        except
          Result := BuildInfinity(AsDouble(@L) < 0);
        end;
      }
      {
      //�ǂ��炩��double�̏ꍇ�͕ϊ�
      else if IsDouble(@L) or IsDouble(@R) then
        try
          Result := BuildDouble(AsDouble(@L) + AsDouble(@R))
        except
          Result := BuildInfinity(AsDouble(@L) < 0);
        end
      else //������
        Result := BuildInteger(AsInteger(@L) + AsInteger(@R));
      }
      //{
      else
        try
          //if IsInteger(@L) and IsInteger(@R) then
          //  Result := BuildInteger(L.vInteger + R.vInteger)
          //else
            Result := BuildDouble(AsDouble(@L) + AsDouble(@R));
        except
          Result := BuildInfinity(AsDouble(@L) < 0);
        end;
      //}
    end;
    opSub: //���Z       -
    begin
      {
      try
        Result := BuildDouble(AsDouble(@L) - AsDouble(@R));
        if IsInteger(@L) and IsInteger(@R) and
           (Result.vDouble <= MaxInt) and (Result.vDouble >= Low(Integer)) then
          Result := BuildInteger(AsInteger(@Result));
      except
        Result := BuildInfinity(AsDouble(@L) < 0);
      end;
      }
      {
      if IsDouble(@L) or IsDouble(@R) then
        try
          Result := BuildDouble(AsDouble(@L) - AsDouble(@R))
        except
          Result := BuildInfinity(AsDouble(@L) < 0);
        end
      else //������
        Result := BuildInteger(AsInteger(@L) - AsInteger(@R));
      }
      //{
      try
        //if IsInteger(@L) and IsInteger(@R) then
        //  Result := BuildInteger(L.vInteger - R.vInteger)
        //else
          Result := BuildDouble(AsDouble(@L) - AsDouble(@R));
      except
        Result := BuildInfinity(AsDouble(@L) < 0);
      end;
      //}
    end;
    opMul: //�|���Z    *
    begin
      {
      try
        Result := BuildDouble(AsDouble(@L) * AsDouble(@R));
        if IsInteger(@L) and IsInteger(@R) and
           (Result.vDouble <= MaxInt) and (Result.vDouble >= Low(Integer)) then
          Result := BuildInteger(AsInteger(@Result));
      except
        Result := BuildInfinity((AsDouble(@L) < 0) xor (AsDouble(@R) < 0));
      end;
      }
      {
      if IsDouble(@L) or IsDouble(@R) then
        try
          Result := BuildDouble(AsDouble(@L) * AsDouble(@R))
        except
          Result := BuildInfinity((AsDouble(@L) < 0) xor (AsDouble(@R) < 0));
        end
      else //������
        Result := BuildInteger(AsInteger(@L) * AsInteger(@R));
      }
      //{
      try
        //if IsInteger(@L) and IsInteger(@R) then
        //  Result := BuildInteger(L.vInteger * R.vInteger)
        //else
          Result := BuildDouble(AsDouble(@L) * AsDouble(@R));
      except
        Result := BuildInfinity((AsDouble(@L) < 0) xor (AsDouble(@R) < 0));
      end;
      //}
    end;
    opDiv: //����Z   /  0���Z�`�F�b�N
    begin
      {dbl := AsDouble(@R);
      if dbl = 0 then
        raise EJThrow.Create(E_ZD,'');

      try
        Result := BuildDouble(AsDouble(@L) / dbl);
      except
        Result := BuildInfinity((AsDouble(@L) < 0) xor (dbl < 0));
      end;}
      try
        Result := BuildDouble(AsDouble(@L) / AsDouble(@R));
      except
        dl := AsDouble(@L);
        dr := AsDouble(@R);
        if (dl = 0) and (dr = 0) then
          //����0�Ȃ�NaN
          Result := BuildNaN
        else
          //0���Z�̏ꍇ��Infinity��Ԃ�
          Result := BuildInfinity((dl < 0) xor (dr < 0));
      end;
    end;
    opDivInt: //����Z  div  0���Z�`�F�b�N
    begin
      {i := AsInteger(@R);
      if i = 0 then
        raise EJThrow.Create(E_ZD,'');

      Result := BuildInteger(AsInteger(@L) div i);}
      try
        Result := BuildInteger(AsInteger(@L) div AsInteger(@R));
      except
        il := AsInteger(@L);
        ir := AsInteger(@R);
        if (il = 0) and (ir = 0) then
          //����0�Ȃ�NaN
          Result := BuildNaN
        else
          //0���Z�̏ꍇ��Infinity��Ԃ�
          Result := BuildInfinity((il < 0) xor (ir < 0));
      end;
    end;
    opMod: //���܂� %     0���Z�`�F�b�N
    begin
      {i := AsInteger(@R);
      if i = 0 then
        raise EJThrow.Create(E_ZD,'');

      Result := BuildInteger(AsInteger(@L) mod AsInteger(@R));}
      try
        Result := BuildInteger(AsInteger(@L) mod AsInteger(@R));
      except
        //��O����NaN��Ԃ�
        Result := BuildNaN;
      end;
    end;
    opBitAnd: // &
    begin
      Result := BuildInteger(AsInteger(@L) and AsInteger(@R));
    end;
    opBitOr:  // |
    begin
      Result := BuildInteger(AsInteger(@L) or AsInteger(@R));
    end;
    opBitXor: // ^
    begin
      Result := BuildInteger(AsInteger(@L) xor AsInteger(@R));
    end;
    opBitLeft: // <<
    begin
      Result := BuildInteger(AsInteger(@L) shl AsInteger(@R));
    end;
    opBitRight: // >>
    begin
      Result := BuildInteger(AsInteger(@L) shr AsInteger(@R));
    end;
    opBitRightZero: // >>>
    begin
      Result := BuildInteger(Cardinal(AsInteger(@L)) shr AsInteger(@R));
    end;
  end;
end;

function CalcValue3(Code: TJOPCode; const L,R,T: TJValue): TJValue;
//3����
begin
  EmptyValue(Result);
  case Code of
    opConditional:  //  l ? r : t
    begin
      if AsBool(@L) then
        Result := R
      else
        Result := T;
    end;
  end;
end;

function AssignValue(Code: TJOPCode; const Variable,Value: TJValue): TJValue;
//�����
begin
  EmptyValue(Result);
  case Code of
    opMulAssign:
    begin
      Result := CalcValue2(opMul,Variable,Value);
    end;
    opDivAssign:
    begin
      Result := CalcValue2(opDiv,Variable,Value);
    end;
    opAddAssign:
    begin
      Result := CalcValue2(opAdd,Variable,Value);
    end;
    opSubAssign:
    begin
      Result := CalcValue2(opSub,Variable,Value);
    end;
    opModAssign:
    begin
      Result := CalcValue2(opMod,Variable,Value);
    end;
    opBitLeftAssign:
    begin
      Result := CalcValue2(opBitLeft,Variable,Value);
    end;
    opBitRightAssign:
    begin
      Result := CalcValue2(opBitRight,Variable,Value);
    end;
    opBitRightZeroAssign:
    begin
      Result := CalcValue2(opBitRightZero,Variable,Value);
    end;
    opBitAndAssign:
    begin
      Result := CalcValue2(opBitAnd,Variable,Value);
    end;
    opBitXorAssign:
    begin
      Result := CalcValue2(opBitXor,Variable,Value);
    end;
    opBitOrAssign:
    begin
      Result := CalcValue2(opBitOr,Variable,Value);
    end;
  end;

end;

function CompareValue(Code: TJOPCode; const L,R: TJValue): TJValue;
//��r�����쐬
  function IsEqual: Boolean;
  begin
    if IsInteger(@L) and IsInteger(@R) then
      Result := L.vInteger = R.vInteger
    else if IsDouble(@L) and IsDouble(@R) then
      Result := L.vDouble = R.vDouble
    else if IsUndefined(@L) and IsUndefined(@R) then
      Result := True
    else if IsNull(@L) and IsNull(@R) then
      Result := True
    else if IsString(@L) and IsString(@R) then
      Result := L.vString = R.vString
    else if IsObject(@L) and IsObject(@R) then
      Result := L.vObject = R.vObject
    else if IsBool(@L) and IsBool(@R) then
      Result := L.vBool = R.vBool
    else if IsFunction(@L) and IsFunction(@R) then
      Result := EqualFunction(@L,@R)
    else if IsInfinity(@L) and IsInfinity(@R) then
      Result := L.vBool = R.vBool
    else if IsDispatch(@L) and IsDispatch(@R) then
      Result := L.vDispatch = R.vDispatch
    else
      Result := False;
  end;

begin
  Result := BuildBool(False);
  case Code of
    //�_����r
    opLogicalOr,opLogicalOr2: Result := BuildBool(AsBool(@L) or AsBool(@R));

    opLogicalAnd,opLogicalAnd2: Result := BuildBool(AsBool(@L) and AsBool(@R));

    opLogicalNot: Result := BuildBool(not AsBool(@L));

    opLS,opLSEQ,opGT,opGTEQ:
    begin
      //�܂����l�Ŕ�r
      if IsInteger(@L) and IsInteger(@R) then
      begin
        case Code of //�����Ŕ�r
          opLS: Result := BuildBool(L.vInteger < R.vInteger);
          opLSEQ: Result := BuildBool(L.vInteger <= R.vInteger);
          opGT: Result := BuildBool(L.vInteger > R.vInteger);
          opGTEQ: Result := BuildBool(L.vInteger >= R.vInteger);
        end;
      end
      else if IsDouble(@L) and IsDouble(@R) then
      begin
        case Code of //�����Ŕ�r
          opLS: Result := BuildBool(L.vDouble < R.vDouble);
          opLSEQ: Result := BuildBool(L.vDouble <= R.vDouble);
          opGT: Result := BuildBool(L.vDouble > R.vDouble);
          opGTEQ: Result := BuildBool(L.vDouble >= R.vDouble);
        end;
      end
      else if (TryAsNumber(@L) or (L.ValueType = vtInfinity)) and
              (TryAsNumber(@R) or (R.ValueType = vtInfinity)) then
      begin
        if L.ValueType = vtInfinity then
        begin
          if R.ValueType = vtInfinity then
          begin
            case Code of //�ǂ�����Infinity
              opLS: Result := BuildBool(L.vBool and not R.vBool);
              opLSEQ: Result := BuildBool(L.vBool);
              opGT: Result := BuildBool(not L.vBool and R.vBool);
              opGTEQ: Result := BuildBool(R.vBool);
            end;
          end
          else begin
            case Code of //Infinity�Ɛ��l
              opLS,opLSEQ: Result := BuildBool(L.vBool);
              opGT,opGTEQ: Result := BuildBool(not L.vBool);
            end;
          end;
        end
        else if R.ValueType = vtInfinity then
        begin
          case Code of //���l��Infinity
            opLS,opLSEQ: Result := BuildBool(not R.vBool);
            opGT,opGTEQ: Result := BuildBool(R.vBool);
          end;
        end
        else begin
          case Code of //�����Ŕ�r(�������l���ł���)
            opLS: Result := BuildBool(AsDouble(@L) < AsDouble(@R));
            opLSEQ: Result := BuildBool(AsDouble(@L) <= AsDouble(@R));
            opGT: Result := BuildBool(AsDouble(@L) > AsDouble(@R));
            opGTEQ: Result := BuildBool(AsDouble(@L) >= AsDouble(@R));
          end;
        end;
      end
      else if (L.ValueType <> vtNaN) and (R.ValueType <> vtNaN) then
      begin
        case Code of //������ɂ��Ĕ�r
          opLS: Result := BuildBool(AsString(@L) < AsString(@R));
          opLSEQ: Result := BuildBool(AsString(@L) <= AsString(@R));
          opGT: Result := BuildBool(AsString(@L) > AsString(@R));
          opGTEQ: Result := BuildBool(AsString(@L) >= AsString(@R));
        end;
      end
      //NaN���܂ޔ�r�͏��false
      {else begin
        raise EJThrow.Create(E_TYPE,'cannot compare "NaN"');
      end};
    end;
    opEQEQEQ,opNEEQEQ:
    begin
      if EqualType(@L,@R) then
      begin
        case Code of
          opEQEQEQ: Result := BuildBool(IsEqual);
          opNeEQEQ: Result := BuildBool(not IsEqual);
        end;
      end
    end;
    opEQ,opNE:
    begin
      if EqualType(@L,@R) then
      begin
        case Code of
          opEQ: Result := BuildBool(IsEqual);
          opNe: Result := BuildBool(not IsEqual);
        end;
      end
      else if IsString(@L) and IsString(@R) then
      begin
        case Code of
          opEQ: Result := BuildBool(AsString(@L) = AsString(@R));
          opNE: Result := BuildBool(AsString(@L) <> AsString(@R));
        end;
      end
      else if TryAsNumber(@L) and TryAsNumber(@R) then
      begin
        case Code of
          opEQ: Result := BuildBool(AsDouble(@L) = AsDouble(@R));
          opNE: Result := BuildBool(AsDouble(@L) <> AsDouble(@R));
        end;
      end
      else if (IsNull(@L) and IsUndefined(@R)) or
              (IsNull(@R) and IsUndefined(@L)) then
      begin
        case Code of
          opEQ: Result := BuildBool(True);
          opNe: Result := BuildBool(False);
        end;
      end
      else if IsNaN(@L) or IsNaN(@R) then
      begin
        case Code of
          opEQ: Result := BuildBool(False);
          opNe: Result := BuildBool(True);
        end;
      end
      else begin
        //������ɂ��Ĕ�r
        case Code of
          opEQ: Result := BuildBool(AsString(@L) = AsString(@R));
          opNE: Result := BuildBool(AsString(@L) <> AsString(@R));
        end;
      end;
    end;
  end;//case
end;

procedure GetDefaultProperties(Obj: TObject; PropNames: TStrings; Event: Boolean);
//property���𒲂ׂ�
//�v���p�e�B�̒l��Ԃ�
var
  Count, i: Integer;
  PropInfo: PPropInfo;
  PropList: PPropList;
begin
  PropNames.Clear;
  // �v���p�e�B�̐����擾
  Count := GetTypeData(Obj.ClassInfo)^.PropCount;
  if Count > 0 then
  begin
    GetMem(PropList, Count * SizeOf(Pointer));
    try
      // �S�Ẵv���p�e�B�����擾
      GetPropInfos(Obj.ClassInfo, PropList);
      // ���ꂼ��̃v���p�e�B����������ׂ�
      for i := 0 to Count - 1 do
      begin
        PropInfo := PropList^[i];
        if not Event then
        begin
          if PropInfo^.PropType^.Kind <> tkMethod then
            PropNames.Add(PropInfo^.Name);
        end
        else begin
          if PropInfo^.PropType^.Kind = tkMethod then
            PropNames.Add(PropInfo^.Name);
        end;
      end;
    finally
      FreeMem(PropList, Count * SizeOf(Pointer));
    end;
  end;
end;

function GetDefaultProperty(Obj: TObject; const Prop: String;
  var Value: TJValue; Engine: TJBaseEngine): Boolean;
//�v���p�e�B�̒l��Ԃ�
var
  Count, i: Integer;
  PropInfo: PPropInfo;
  PropList: PPropList;
  o: TObject;
  //jo: TJObject;
  //setval: TIntegerSet;
  enum: Integer;
  vcl: TJVCLPersistent;
begin
  Result := False;
  // �v���p�e�B�̐����擾
  Count := GetTypeData(Obj.ClassInfo)^.PropCount;
  if Count > 0 then
  begin
    GetMem(PropList, Count * SizeOf(Pointer));
    try
      // �S�Ẵv���p�e�B�����擾
      GetPropInfos(Obj.ClassInfo, PropList);
      // ���ꂼ��̃v���p�e�B����������ׂ�
      for i := 0 to Count - 1 do
      begin
        PropInfo := PropList^[i];
        //���O����v������(�����P�[�X�𖳎�����)
        if AnsiSameText(PropInfo^.Name,Prop) then
        begin
          //�A�N�Z�X���\�b�h�������ꍇ�͗�O
          if not Assigned(PropInfo^.GetProc) then
            Break;

          case PropInfo^.PropType^.Kind of
            //����
            tkInteger,tkChar:
            begin
              Value := BuildInteger(GetOrdProp(Obj,PropInfo));
              Result := True;
            end;
            //�񋓌^ �܂��� boolean
            tkEnumeration:
            begin
              enum := GetOrdProp(Obj,PropInfo);
              Result := EnumToValue(PropInfo^.PropType^,Value,Enum);
              //true false�𒲂ׂ�
              if Result then
              begin
                if AnsiSameText(Value.vString,'True') then
                  Value := BuildBool(True)
                else if AnsiSameText(Value.vString,'False') then
                  Value := BuildBool(False);
              end;
            end;
            //�W���^
            tkSet:
            begin
              {Integer(setval) := GetOrdProp(Obj,PropInfo);
              //object���쐬���ĕϊ�
              jo := TJObject.Create(Factory,nil);
              SetToJObject(PropInfo^.PropType^,jo,setval);
              Value := BuildObject(jo);}
              //������ɂ��ĕԂ�
              Value := BuildString(GetSetProp(Obj,Prop,False));
              Result := True;
            end;

            //������
            tkString,tkLString,tkWString:
            begin
              Value := BuildString(GetStrProp(Obj,PropInfo));
              Result := True;
            end;
            //object
            tkClass:
            begin
              o := GetObjectProp(Obj,PropInfo);
              //nil�̏ꍇ������
              if not Assigned(o) then
                Value := BuildNull
              else if o is TJObject then
                Value := BuildObject(TJObject(o))
              //TPersistent���Z�b�g
              else if o is TPersistent then
              begin
{$IFNDEF NO_VCL}
                //�^�ϊ�����
                vcl := VCLCaster.Cast(o as TPersistent,Engine);
{$ELSE}
                //�^�ϊ����Ȃ�
                vcl := TJVCLPersistent.Create(Engine);
                vcl.RegistVCL(o as TPersistent,False);
{$ENDIF}
                Value := BuildObject(vcl);
              end
              else begin
                Result := False;
                Break;
              end;

              Result := True;
            end;
            //double
            tkFloat:
            begin
              Value := BuildDouble(GetFloatProp(Obj,PropInfo));
              Result := True;
            end;

            tkInterface:
            begin
              Value := BuildDispatch(IDispatch(GetOrdProp(Obj,PropInfo)));
              Result := True;
            end;
{$IFNDEF NO_ACTIVEX}
            tkVariant:
            begin
              Value := VariantToValue(GetVariantProp(Obj,PropInfo),nil);
              Result := True;
            end;
{$ENDIF}
            tkInt64:
            begin
              Value := BuildDouble(GetInt64Prop(Obj,PropInfo));
              Result := True;
            end;
            //�C�x���g
            tkMethod:
            begin
              Value := BuildEvent(GetMethodProp(Obj,PropInfo));
              Result := True;
            end;

            tkUnknown,
            //tkChar,
            tkWChar,
            tkArray,
            tkRecord,
            tkDynArray:
            begin

            end;
          end;
          //�I���
          Break;
        end;
      end;
    finally
      FreeMem(PropList, Count * SizeOf(Pointer));
    end;
  end;

end;

function SetDefaultProperty(Obj: TObject; const Prop: String; Value: TJValue;
  ValueTypeInfo: PTypeInfo): Boolean;
//�v���p�e�B�ɒl���Z�b�g����
var
  Count, i: Integer;
  PropInfo: PPropInfo;
  PropList: PPropList;
  o: TObject;
  i64: Int64;
  enum: Integer;
  setstr: String;
  pd: PTypeData;
  meth: TMethod;
begin
  Result := False;
  // �v���p�e�B�̐����擾
  Count := GetTypeData(Obj.ClassInfo)^.PropCount;
  if Count > 0 then
  begin
    GetMem(PropList, Count * SizeOf(Pointer));
    try
      // �S�Ẵv���p�e�B�����擾
      GetPropInfos(Obj.ClassInfo, PropList);
      // ���ꂼ��̃v���p�e�B����������ׂ�
      for i := 0 to Count - 1 do
      begin
        PropInfo := PropList^[i];
        //���O����v������
        if AnsiSameText(PropInfo^.Name,Prop) then
        begin
          //�A�N�Z�X���\�b�h�������ꍇ�͏I��
          if not Assigned(PropInfo^.SetProc) then
            Break;

          case PropInfo^.PropType^.Kind of
            //����
            tkInteger:
            begin
              SetOrdProp(Obj,PropInfo,AsInteger(@Value));
              Result := True;
            end;
            //�����^
            tkChar:
            begin
              SetOrdProp(Obj,PropInfo,Ord(AsChar(@Value)));
              Result := True;
            end;
            //�񋓌^ �܂��� boolean
            tkEnumeration:
            begin
              if ValueToEnum(PropInfo^.PropType^,Value,enum) then
              begin
                SetOrdProp(Obj,PropInfo,enum);
                Result := True;
              end;
            end;
            //�W���^
            tkSet:
            begin
              //�����Ȃ��
              if IsString(@Value) then
                setstr := AsString(@Value)
              else if IsObject(@Value) then
                setstr := JObjectToSetStr(PropInfo^.PropType^,Value.vObject);

              if setstr <> '' then
              begin
                SetSetProp(Obj,PropInfo,setstr);
                Result := True;
              end
            end;

            //������
            tkString,tkLString,tkWString:
            begin
              SetStrProp(Obj,PropInfo,AsString(@Value));
              Result := True;
            end;
            //object
            tkClass:
            begin
              //�^�𓾂�
              pd := GetTypeData(PropInfo^.PropType^);
              //jobject
              if IsObject(@Value) and pd.ClassType.InheritsFrom(TJObject) then
              begin
                o := Value.vObject;
                SetObjectProp(Obj,PropInfo,o);
                Result := True;
              end
              //TPersistent���Z�b�g
              else if IsVCLObject(@Value) and
                      (Value.vObject as TJVCLPersistent).IsVCL then
              begin
                o := (Value.vObject as TJVCLPersistent).FVCL;
                //�^�`�F�b�N���ăZ�b�g
                if o is pd.ClassType then
                begin
                  SetObjectProp(Obj,PropInfo,o);
                  Result := True;
                end;
              end
              //null�̏ꍇ������
              else if IsNull(@Value) then
              begin
                SetObjectProp(Obj,PropInfo,nil);
                Result := True;
              end
              else
                Break;
            end;
            //double
            tkFloat:
            begin
              SetFloatProp(Obj,PropInfo,AsDouble(@Value));
              Result := True;
            end;
            //IDispatch
            tkInterface:
            begin
              if IsDispatch(@Value) then
              begin
                SetOrdProp(Obj,PropInfo,Integer(AsDispatch(@Value)));
                Result := True;
              end
{$IFNDEF NO_ACTIVEX}
              else if IsObject(@Value) and (Value.vObject is TJActiveXObject) then
              begin
                SetOrdProp(Obj,PropInfo,
                  Integer((Value.vObject as TJActiveXObject).Disp));
                Result := True;
              end
{$ENDIF}
              else
                Break;
            end;
{$IFNDEF NO_ACTIVEX}
            tkVariant:
            begin
              SetVariantProp(Obj,PropInfo,ValueToVariant(Value));
              Result := True;
            end;
{$ENDIF}
            tkInt64:
            begin
              i64 := Trunc(AsDouble(@Value));
              SetInt64Prop(Obj,PropInfo,i64);
              Result := True;
            end;
            //�C�x���g
            tkMethod:
            begin
              //�^�`�F�b�N
              if IsEvent(@Value) and (PropInfo^.PropType^ = ValueTypeInfo) then
              begin
                SetMethodProp(Obj,PropInfo,Value.vEvent);
                Result := True;
              end
              else if IsNull(@Value) then
              begin
                meth.Code := nil;
                meth.Data := nil;
                SetMethodProp(Obj,PropInfo,meth);
                Result := True;
              end;
            end;

            tkUnknown,
            //tkChar,
            tkWChar,
            tkArray,
            tkRecord,
            tkDynArray:
            begin

            end;
          end;
          //�I���
          Break;
        end;
      end;

    finally
      FreeMem(PropList, Count * SizeOf(Pointer));
    end;
  end;

end;

procedure SetDefaultMethodNil(Obj: TObject);
//���ׂẴC�x���g�𖳌��ɂ���
var
  Count, i: Integer;
  PropInfo: PPropInfo;
  PropList: PPropList;
  method: TMethod;
begin
  // �v���p�e�B�̐����擾
  Count := GetTypeData(Obj.ClassInfo)^.PropCount;
  if Count > 0 then
  begin
    method.Code := nil;
    method.Data := nil;

    GetMem(PropList, Count * SizeOf(Pointer));
    try try
      // �S�Ẵv���p�e�B�����擾
      GetPropInfos(Obj.ClassInfo, PropList);
      // ���ꂼ��̃v���p�e�B����������ׂ�
      for i := 0 to Count - 1 do
      begin
        PropInfo := PropList^[i];
        //�A�N�Z�X���\�b�h�������ꍇ�͏I��
        if not Assigned(PropInfo^.SetProc) then
          Break;

        if PropInfo^.PropType^.Kind = tkMethod then
          SetMethodProp(Obj,PropInfo,method);
      end;

    finally
      FreeMem(PropList, Count * SizeOf(Pointer));
    end;

    except
    end;
  end;
end;

type
  TMethodTableEntry = packed record  // �ϒ����R�[�h
    Size: Word;        // �G���g���̑傫��
    Address: Pointer;  // ���\�b�h�̃G���g���|�C���g
    Name: ShortString; // ���\�b�h��
   // ���̑�
  end;

  PMethodTableEntry = ^TMethodTableEntry;

  TMethodTable = packed record
    MethodCount: Word;             // ���\�b�h��
    FirstEntry: TMethodTableEntry; //�ϒ�
    // 2�ԖځA3�Ԗ�
  end;

  PMethodTable = ^TMethodTable;

  PPointer = ^Pointer;

procedure EnumMethodNames(Obj: TObject; List: TStrings);
var ClassRef: TClass;         //�N���X�Q��=VMT�|�C���^
    pTable: PMethodTable;     //���\�b�h�e�[�u���ւ̃|�C���^
    pEntry: PMethodTableEntry;//���\�b�h�e�[�u���G���g���ւ̃|�C���^
    i: Integer;
begin
  List.Clear;

  ClassRef := Obj.ClassType; // �N���X�Q�Ƃ𓾂�

  while ClassRef <> Nil do begin // �e�N���X�������Ȃ�܂�
    // ���\�b�h�e�[�u���𓾂�
    pTable := PPointer(LongInt(ClassRef) + vmtMethodTable)^;

    if pTable <> Nil then begin // �e�[�u�����L��Ƃ͌���Ȃ�
      //�e�[�u���̍ŏ��̃G���g���𓾂�
      pEntry := @pTable.FirstEntry;
      // �N���X�̑S���\�b�h���̎擾
      for i := 1 to pTable^.MethodCount do
      begin
        List.Add(pEntry^.Name);
        // ���̃G���g���Ƀ|�C���^�����炷�B
        pEntry := PMethodTableEntry(LongInt(pEntry) + pEntry^.Size);
      end;
    end;

    // �e�N���X�ֈړ�
    ClassRef := ClassRef.ClassParent;
  end;
end;

procedure EnumSetNames(Info: PTypeInfo; List: TStrings);
//�W���^�̖��O�𓾂�
var
  pd: PTypeData;
  CompType: PTypeInfo;
  i: Integer;
begin
  List.Clear;
  pd := GetTypeData(Info);
  if Assigned(pd) and Assigned(pd.CompType^) then
  begin
    CompType := pd.CompType^;
    pd := GetTypeData(CompType);
    if Assigned(pd) then
    begin
      for i := pd.MinValue to pd.MaxValue do
        List.Add(GetEnumName(CompType,i));
    end;
  end;
end;

procedure SetToJObject(Info: PTypeInfo; Obj: TJObject; const Value);
//�W���^��object�ɃZ�b�g����
var
  pd: PTypeData;
  CompType: PTypeInfo;
  i: Integer;
  pi: PInteger;
begin
  pd := GetTypeData(Info);
  if Assigned(pd) and Assigned(pd.CompType^) then
  begin
    CompType := pd.CompType^;
    pd := GetTypeData(CompType);
    if Assigned(pd) then
    begin
      pi := @Value;
      for i := pd.MinValue to pd.MaxValue do
        Obj.RegistProperty(
          GetEnumName(CompType,i),
          BuildBool((pi^ and (1 shl i)) <> 0));
    end;
  end;
end;

procedure JObjectToSet(Info: PTypeInfo; Obj: TJObject; var RetValue);
//oject����W���^��
var
  pd: PTypeData;
  CompType: PTypeInfo;
  i: Integer;
  pdw: PDWORD;
  pw: PWORD;
  pb: PByte;
  EnumName: string;
  ENumValue: Integer;
  v: TJValue;
begin
  pd := GetTypeData(Info);
  if Assigned(pd) and Assigned(pd.CompType^) then
  begin
    CompType := pd.CompType^;
    pd := GetTypeData(CompType);
    if Assigned(pd) then
    begin
      pdw := @RetValue;
      pw  := @RetValue;
      pb  := @RetValue;

      case pd.OrdType of
        otSByte, otUByte: pb^ := 0;
        otSWord, otUWord: pw^ := 0;
        otSLong, otULong: pdw^ := 0;
      end;

      for i := pd.MinValue to pd.MaxValue do
      begin
        EnumName := GetEnumName(CompType,i);
        //obj�����L���Ă���true�Ȃ��
        if Obj.FMembers.GetValue(EnumName,v) and AsBool(@v) then
        begin
          EnumValue := GetEnumValue(CompType,EnumName);
          //�Z�b�g
          if EnumValue > -1 then
            case pd.OrdType of
              otSByte, otUByte: pb^ := pb^ or (1 shl EnumValue);
              otSWord, otUWord: pw^ := pw^ or (1 shl EnumValue);
              otSLong, otULong: pdw^ := pdw^ or (1 shl EnumValue);
            end;
        end;
      end;

    end;
  end;
end;

function JObjectToSetStr(Info: PTypeInfo; Obj: TJObject): String;
//oject����W���^�̕������
var
  pd: PTypeData;
  CompType: PTypeInfo;
  i: Integer;
  EnumName: string;
  v: TJValue;
begin
  Result := '';
  pd := GetTypeData(Info);
  if Assigned(pd) and Assigned(pd.CompType^) then
  begin
    CompType := pd.CompType^;
    pd := GetTypeData(CompType);
    if Assigned(pd) then
    begin
      for i := pd.MinValue to pd.MaxValue do
      begin
        EnumName := GetEnumName(CompType,i);
        //obj�����L���Ă���true�Ȃ��
        if Obj.FMembers.GetValue(EnumName,v) and AsBool(@v) then
          if Result = '' then
            Result := EnumName
          else
            Result := Result + ',' + EnumName;
      end;
    end;
  end;

  //Result := '[' + Result + ']';
end;

function SetToStr(Info: PTypeInfo; const Value): string;
//�W�����當����
var
  pd: PTypeData;
  CompType: PTypeInfo;
  i: Integer;
  pi: PInteger;
begin
  Result := '';
  pd := GetTypeData(Info);
  if Assigned(pd) and Assigned(pd.CompType^) then
  begin
    CompType := pd.CompType^;
    pd := GetTypeData(CompType);
    if Assigned(pd) then
    begin
      pi := @Value;
      for i := pd.MinValue to pd.MaxValue do
        if (pi^ and (1 shl i)) <> 0 then
          if Result = '' then
            Result := GetEnumName(CompType, i)
          else
            Result := Result + ',' + GetEnumName(CompType, i);
    end;
  end;

  //Result := '[' + Result + ']';
end;

procedure StrToSet(Info: PTypeInfo; const S: String; var RetValue);
var
  pd: PTypeData;
  CompType: PTypeInfo;
  i: Integer;
  pdw: PDWORD;
  pw: PWORD;
  pb: PByte;
  p: PChar;
  EnumName: string;
  ENumValue: Integer;
begin
  pd := GetTypeData(Info);
  if Assigned(pd) and Assigned(pd.CompType^) then
  begin
    CompType := pd.CompType^;
    pd := GetTypeData(CompType);
    if Assigned(pd) then
    begin
      pdw := @RetValue;
      pw  := @RetValue;
      pb  := @RetValue;

      case pd.OrdType of
        otSByte, otUByte: pb^ := 0;
        otSWord, otUWord: pw^ := 0;
        otSLong, otULong: pdw^ := 0;
      end;

      p := PChar(S);

      // '[' �� ' ' ���X�L�b�v
      while p^ in ['[',' '] do
        Inc(p);

      // ','  ' ' #0 ']' �܂ł�v�f���Ƃ��Ď��o��
      i := 0;
      while not (p[i] in [',', ' ', #0,']']) do
        Inc(i);

      SetString(EnumName, p, i);
      // ���̌�̐擪�܂Ń|�C���^��i�߂�
      while p[i] in [',', ' ',']'] do
        Inc(i);

      Inc(p, i);

      while EnumName <> '' do
      begin
        EnumValue := GetEnumValue(CompType, EnumName);
        if EnumValue > -1 then
        begin
          case pd.OrdType of
            otSByte, otUByte: pb^ := pb^ or (1 shl EnumValue);
            otSWord, otUWord: pw^ := pw^ or (1 shl EnumValue);
            otSLong, otULong: pdw^ := pdw^ or (1 shl EnumValue);
          end;
        end;
        // ','  ' ' #0 ']' �܂ł�v�f���Ƃ��Ď��o��
        i := 0;
        while not (p[i] in [',', ' ', #0,']']) do
          Inc(i);

        SetString(EnumName, p, i);
        // ���̌�̐擪�܂Ń|�C���^��i�߂�
        while p[i] in [',', ' ',']'] do
          Inc(i);

        Inc(p, i);
      end;

    end;
  end;
end;

function ValueToEnum(Info: PTypeInfo; var Value: TJValue;
  var Enum: Integer): Boolean;
//�񋓌^��ϊ�����
begin
  //���l�ɂł��Ȃ��ꍇ
  if not TryAsNumber(@Value) then
    Enum := GetEnumValue(Info,AsString(@Value))
  else
    Enum := AsInteger(@Value);

  Result := (Enum > -1);
end;

function EnumToValue(Info: PTypeInfo; var Value: TJValue;
  Enum: Integer): Boolean;
var
  s: String;
begin
  s := GetEnumName(Info,Enum);
  Result := (s <> '');
  if Result then
    Value := BuildString(s)
  else
    EmptyValue(Value);
end;


{ TJHash }

procedure TJHash.ClearValue(Target, Ignore: TJValueTypeSet);
//��ނ�I��ŃN���A
var
  i: Integer;
  sl: TStringList;
  v: TJValue;
begin
  //���ׂď���
  if (Target = []) and (Ignore = []) then
    Clear
  else begin
    //�I��ŏ���
    sl := KeyList;
    for i := sl.Count - 1 downto 0 do
      if GetValue(sl[i],v) then
      begin
        if Target <> []  then
        begin
          //target�Ȃ�Ώ���
          if v.ValueType in Target then
            Remove(sl[i]);
        end
        else begin
          //ignore�łȂ��Ȃ�Ώ���
          if not (v.ValueType in Ignore) then
            Remove(sl[i]);
        end;
      end;
  end;

end;

constructor TJHash.Create(ATableSize: DWord; AIgnoreCase: Boolean);
//�쐬
begin
  inherited;
  FNotify := TJNotify.Create;
  FNotify.OnNotification := NotifyOnNotifycation;
  OnFreeItem := HashOnItemDispose;
end;

destructor TJHash.Destroy;
//�J������
begin
  Clear;
  FreeAndNil(FNotify);
  inherited;
end;

procedure TJHash.GetKeyList(List: TStrings; Need,
  Ignore: TJValueTypeSet);
var
  i: Integer;
  v: TJValue;
  sl: TStringList;
begin
  List.Clear;

  sl := KeyList;
  //������
  for i := 0 to sl.Count - 1 do
    if GetValue(sl[i],v) then
    begin
      if Need <> [] then
      begin
        //Need�������������
        if v.ValueType in Need then
          List.Add(sl[i]);
      end
      else {if Ignore <> [] then}
      begin
        //Ignore�łȂ��Ȃ�Ή�����
        if not (v.ValueType in Ignore) then
          List.Add(sl[i]);
      end;
    end;
end;

function TJHash.GetValue(Key: String; var Value: TJValue): Boolean;
var
  p: PJValue;
begin
  p := GetValuePointer(Key);
  if Assigned(p) then
  begin
    Result := True;
    Value := p^;
  end
  else begin
    Result := False;
    EmptyValue(Value);
  end;
end;

procedure TJHash.HashOnItemDispose(Sender: TObject; P: PHashItem);
//value���������
var
  value: PJValue;
begin
  value := P^.vPointer;
  if IsObject(value) then
  begin
    //notifycation������
    value^.vObject.RemoveFreeNotification(FNotify);
    FNotify.RemoveFreeNotification(value^.vObject);
    //�Q�ƃJ�E���g�����炷
    value^.vObject.DecRef;
  end;

  Dispose(value);
  P^.vPointer := nil;
end;

procedure TJHash.NotifyOnNotifycation(Sender: TObject);
//object�̍폜�C�x���g
var
  i,ii: Integer;
  pv: PJValue;
begin
  //���̎��_��sender��notify�̓o�^�͉�������Ă�
  //hash����폜���Ȃ��ŁA�����ɂ��邾��
  for i := Length(FTable) - 1 downto 0 do
  begin
    if Assigned(FTable[i]) then
    begin
      //pointer����v����΍폜
      for ii := FTable[i].Count - 1 downto 0 do
      begin
        pv := FTable[i][ii].vPointer;
        //�����ɂ���
        if IsObject(pv) and (pv^.vObject = Sender) then
          EmptyValue(pv^);
      end;
    end;
  end;
end;

procedure TJHash.SetValue(Key: String; Value: TJValue);
//�V��������ăZ�b�g����
var
  p: PJValue;
begin
  if IsObject(@Value) then
  begin
    //notifycation���Z�b�g
    Value.vObject.FreeNotification(FNotify);
    //�Q�ƃJ�E���g�𑝂₷
    Value.vObject.IncRef;
  end;

  New(p);
  p^ := Value;
  SetValuePointer(Key,p);
end;

{ TJObject }

procedure TJObject.RegistName(AName: String);
begin
  FName := AName;
end;

procedure TJObject.ClearMembers;
//�f�[�^���N���A
begin
  FMembers.ClearValue([],[]);
end;

constructor TJObject.Create(AEngine: TJBaseEngine;
  Param: TJValueList; RegisteringFactory: Boolean);
//object�쐬
var
  fact: TJObjectFactory;
begin
  inherited Create;
  //�Q�ƃJ�E���g���ꎞ�I�ɑ��₷
  FRefCount := 1;

  FEngine := AEngine;

  FMembers := TJHash.Create(HASH_20);
  FDefaultProperties := TStringList.Create;
  FDefaultProperties.Sorted := True;
  FDefaultProperties.Duplicates := dupIgnore;
  GetDefaultProperties(Self,FDefaultProperties);

  RegistName('Object');
  RegistMethods;
  RegistProperties;

  if Assigned(AEngine) and RegisteringFactory then
  begin
    fact := TJEngine(AEngine).Factory;
    //�C�x���g���N����
    if Assigned(fact.FOnNewObject) then
      fact.FOnNewObject(fact,Self);
    //factory�։�����
    fact.Add(Self);
  end;
end;

destructor TJObject.Destroy;
//�j��
begin
  FreeAndNil(FEvents);
  FreeAndNil(FDefaultProperties);
  //���ȎQ�Ƃ𖳌��ɂ��邽��
  //FMembers���J����������notification���N����
  inherited;
  FreeAndNil(FMembers);
end;

function TJObject.GetValue(S: String; ArrayStyle: Boolean; Param: TJValueList = nil): TJValue;
//�����o�𓾂�
begin
  if not GetValueImpl(S,Result,Param) then
  begin
    //�z��
    if ArrayStyle then
      raise EJThrow.Create(E_KEY,S)
    else //�����o
      raise EJThrow.Create(E_NAME,S);
  end;
end;

procedure TJObject.GetPropertyList(List: TStringList);
//�S�Ă�property�𓾂�
begin
  GetKeyList(List,[],[vtFunction]);
  List.AddStrings(FDefaultProperties);
end;

function TJObject.HasKey(S: String): Boolean;
//member�������Ă�H
var
  v: TJValue;
begin
  if HasDefaultProperty(S) then
    Result := True
  else begin
    Result := FMembers.GetValue(S,v);
  end;
end;

function TJObject.HasDefaultProperty(Prop: String): Boolean;
//property�������Ă��邩�`�F�b�N
var
  i: Integer;
begin
  Result := FDefaultProperties.Find(Prop,i);
end;

procedure TJObject.RegistMethod(MethodName: String; Method: TJMethod);
//�֐���o�^����
var
  f: IJFunction;
begin
  EmptyFunction(f);
  f.Symbol := MethodName;
  f.FuncType := ftMethod;
  f.vMethod := Method;
  f.MethodOwner := Self;
  FMembers.SetValue(MethodName,BuildFunction(f));
end;

procedure TJObject.SetValue(S: String; Value: TJValue; ArrayStyle: Boolean; Param: TJValueList = nil);
//�����o���Z�b�g
begin
  //false�ł��������œo�^
  if not SetValueImpl(S,Value,Param) then
    FMembers.SetValue(S,Value);
end;

procedure TJObject.RegistProperty(PropName: String; Value: TJValue);
//proeprty��o�^����
begin
  FMembers.SetValue(PropName,Value);
end;

function TJObject.DoHasKey(Param: TJValueList): TJValue;
var
  v: TJValue;
begin
  Result := BuildBool(False);
  if IsParam1(Param) then
  begin
    v := Param[0];
    Result := BuildBool(HasKey(AsString(@v)));
  end;
end;

function TJObject.DoToString(Param: TJValueList): TJValue;
var
  v: TJValue;
begin
  if IsParam1(Param) then
  begin
    v := Param[0];
    Result := BuildString(ToString(@v));
  end
  else
    Result := BuildString(ToString);
end;

function TJObject.ToString(Value: PJValue): String;
begin
  Result := '[object ' + Name + ']';
end;

procedure TJObject.GetMethodList(List: TStringList);
//�S�Ă�method�𓾂�
begin
  GetKeyList(List,[vtFunction],[]);
end;

function TJObject.DoGetKeys(Param: TJValueList): TJValue;
var
  sl: TStringList;
  i: Integer;
  ary: TJArrayObject;
begin
  sl := TStringList.Create;
  try
    GetKeyList(sl,[],[]);
    sl.AddStrings(FDefaultProperties);
    //Result := BuildString(Trim(sl.Text));
    //�z��ɓ���ĕԂ�
    ary := TJArrayObject.Create(FEngine);
    Result := BuildObject(ary);
    for i := 0 to sl.Count - 1 do
      ary.Items.Add(sl[i]);
  finally
    sl.Free;
  end;
end;

function TJObject.DoGetMethods(Param: TJValueList): TJValue;
var
  sl: TStringList;
  i: Integer;
  ary: TJArrayObject;
begin
  sl := TStringList.Create;
  try
    GetMethodList(sl);
    //Result := BuildString(Trim(sl.Text));
    //�z��ɓ���ĕԂ�
    ary := TJArrayObject.Create(FEngine);
    Result := BuildObject(ary);
    for i := 0 to sl.Count - 1 do
      ary.Items.Add(sl[i]);
  finally
    sl.Free;
  end;
end;

function TJObject.DoGetProperties(Param: TJValueList): TJValue;
var
  sl: TStringList;
  i: Integer;
  ary: TJArrayObject;
begin
  sl := TStringList.Create;
  try
    GetPropertyList(sl);
    //Result := BuildString(Trim(sl.Text));
    //�z��ɓ���ĕԂ�
    ary := TJArrayObject.Create(FEngine);
    Result := BuildObject(ary);
    for i := 0 to sl.Count - 1 do
      ary.Items.Add(sl[i]);
  finally
    sl.Free;
  end;
end;

procedure TJObject.RegistMethods;
//���\�b�h��o�^����
begin
  RegistMethod('hasKey',DoHasKey);
  RegistMethod('hasOwnProperty',DoHasKey);
  RegistMethod('removeKey',DoRemoveKey);
  RegistMethod('toString',DoToString);
  RegistMethod('getKeys',DoGetKeys);
  RegistMethod('getProperties',DoGetProperties);
  RegistMethod('getMethods',DoGetMethods);
  RegistMethod('valueOf',DoValueOf);
  RegistMethod('getEvents',DoGetEvents);
end;

procedure TJObject.ClearProperties;
//property��������(�֐��������Ȃ�)
begin
  //�����͍̂���property����
  FMembers.ClearValue([],[vtFunction]);
end;

function TJObject.Equal(Obj: TJObject): Boolean;
begin
  Result := Obj = Self;
end;

function TJObject.ToNumber: Double;
begin
  Result := 0;
end;

function TJObject.ToBool: Boolean;
begin
  Result := True;
end;

function TJObject.ToChar: Char;
begin
  Result := #0;
end;

function TJObject.RemoveKey(S: String): Boolean;
//key���폜����
begin
  Result := FMembers.Remove(S);
end;

function TJObject.DoRemoveKey(Param: TJValueList): TJValue;
var
  v: TJValue;
begin
  Result := BuildBool(False);
  if IsParam1(Param) then
  begin
    v := Param[0];
    Result := BuildBool(RemoveKey(AsString(@v)));
  end;
end;

procedure TJObject.AfterConstruction;
//�R���X�g���N�^��
begin
  inherited;
  //�Q�ƃJ�E���g�����炷
  FRefCount := 0;
end;

function TJObject.DecRef: Integer;
begin
  //0�ɂȂ�����������
  Dec(FRefCount);
  Result := FRefCount;

  if FRefCount <= 0 then
    Free;
end;

function TJObject.IncRef: Integer;
begin
  Inc(FRefCount);
  REsult := FRefCount;
end;

function TJObject.ValueOf: TJValue;
begin
  Result := BuildObject(Self);
end;

function TJObject.DoValueOf(Param: TJValueList): TJValue;
begin
  Result := ValueOf;
end;

procedure TJObject.GetKeyList(List: TStringList; Need,
  Ignore: TJValueTypeSet);
begin
  FMembers.GetKeyList(List,Need,Ignore);
  //List.AddStrings(FDefaultProperties);
end;

procedure TJObject.Notification(AObject: TJNotify);
//���Lobject�̏I���ʒm
begin
  inherited;
end;

class function TJObject.IsMakeGlobalInstance: Boolean;
//GlobalInstance���G���W���ɍ쐬���邩�ǂ���
begin
  Result := True;
end;

function TJObject.CallEvent(Prefix,EventName: String;
  Param: TJValueList): TJValue;
//�C�x���g���Ă�
var
  v: TJValue;
  eng: TJEngine;
begin
  EmptyValue(Result);
  if not Assigned(FEngine) then
    Exit;

  eng := FEngine as TJEngine;

  //prefix������ꍇ�̓X�N���v�g���̊֐�
  if (Prefix <> '') then
  begin
    if eng.GetVariable(Prefix + EventName,v) then
      Result := eng.CallEvent(v,Param,Self);
  end
  else begin
    //�v���p�e�B����T��
    v := GetValue(EventName,True);
    Result := eng.CallEvent(v,Param,Self);
  end;
end;

function TJObject.IsCallEvent(EventName: String): Boolean;
//�\���`�F�b�N
var
  v: TJValue;
begin
  Result := Assigned(FEngine) and (FEngine as TJEngine).AllowEvent;
  if Result and (EventName <> '') then
    Result := GetValueImpl(EventName,v);
end;

function TJObject.GetValueImpl(S: String;
  var RetVal: TJValue; Param: TJValueList): Boolean;
var
  fact: TJObjectFactory;
begin
  if GetDefaultProperty(Self,S,RetVal,FEngine) then
    Result := True
  else if FMembers.GetValue(S,RetVal) then
    Result := True
  else if (not (Self is TJPrototypeObject)) and Assigned(FEngine) then
  begin
    //prototype
    fact := TJEngine(FEngine).Factory;
    Result := fact.GetPrototype(Name).GetValueImpl(S,RetVal,Param);
  end
  else
   Result := False;
end;

function TJObject.SetValueImpl(S: String;
  var Value: TJValue; Param: TJValueList): Boolean;
begin
  Result := False;
  if SetDefaultProperty(Self,S,Value) then
    Result := True
  else begin
    if FMembers.HasKey(S) then
    begin
      FMembers.SetValue(S,Value);
      Result := True;
    end;
  end;
end;

procedure TJObject.Clear;
//�폜����
begin
  ClearValue([],[]);
  RegistMethods;
  Registproperties;
end;

procedure TJObject.ClearValue(Target, Ignore: TJValueTypeSet);
begin
  FMembers.ClearValue(Target,Ignore);
end;

procedure TJObject.Registproperties;
begin
//�������p�����ă����o�v���p�e�B��o�^����
end;

function TJObject.GetCount: Integer;
begin
  Result := 0;
end;

function TJObject.GetItem(Index: Integer): TJValue;
begin
  EmptyValue(Result);
end;

class function TJObject.IsArray: Boolean;
begin
  //for..in���ŗv�f��ϐ��ɓ����ꍇ��true�ɂ���
  Result := False;
end;

procedure TJObject.GetEventList(List: TStrings);
begin
//�C�x���g��
  if Assigned(FEvents) then
    List.Assign(FEvents)
  else
    List.Clear;
end;

function TJObject.DoGetEvents(Param: TJValueList): TJValue;
var
  sl: TStringList;
  i: Integer;
  ary: TJArrayObject;
begin
  sl := TStringList.Create;
  try
    GetEventList(sl);
    //�z��ɓ���ĕԂ�
    ary := TJArrayObject.Create(FEngine);
    Result := BuildObject(ary);
    for i := 0 to sl.Count - 1 do
      ary.Items.Add(sl[i]);
  finally
    sl.Free;
  end;
end;

procedure TJObject.RegistEventName(EventName: String);
begin
  if not Assigned(FEvents) then
  begin
    FEvents := TStringList.Create;
    FEvents.Sorted := True;
    FEvents.Duplicates := dupIgnore;
  end;

  FEvents.Add(EventName);
end;


{ TJVCLPersistent }

constructor TJVCLPersistent.Create(AEngine: TJBaseEngine;
  Param: TJValueList; RegisteringFactory: Boolean);
begin
  inherited;
  RegistName('VCL');
  //�쐬����
  CreateObjects;
  CreateVCL;

  RegistMethod('assign',DoAssign);
end;

procedure TJVCLPersistent.CreateObjects;
begin
  //�������Ȃ�
end;

procedure TJVCLPersistent.CreateVCL;
begin
  //������override����VCL���쐬����
  //RegistVCL(T.Create(nil),True);
end;

destructor TJVCLPersistent.Destroy;
begin
  //VCL��j������
  DestroyVCL;
  inherited;
end;

procedure TJVCLPersistent.DestroyVCL;
//VCL���N���A
begin
  if not Assigned(FVCL) then
    Exit;

  //�J������
  if FCanDestroy then
    FreeAndNil(FVCL);

  FVCL := nil;
end;

procedure TJVCLPersistent.GetPropertyList(List: TStringList);
//VCL.property�̂�
begin
  List.BeginUpdate;
  try
    List.Clear;
    List.AddStrings(FDefaultProperties);
  finally
    List.EndUpdate;
  end;
end;

function TJVCLPersistent.GetValueImpl(S: String;
  var RetVal: TJValue; Param: TJValueList): Boolean;
//�l�𓾂�
begin
  //self��D�悷��
  if inherited GetValueImpl(S,RetVal) then
    Result := True
  //VCL����T�� published
  else if Assigned(FVCL) and
          HasDefaultProperty(S) and
          GetDefaultProperty(FVCL,S,RetVal,FEngine) then
  begin
    Result := True;
    //object�̏ꍇ�͓o�^����
    if IsVCLObject(@RetVal) then
      RegistProperty(S,RetVal);
  end
  else
    Result := False;
end;

function TJVCLPersistent.GetVCLClassName: String;
begin
  Result := VCLClassType.ClassName;
end;

function TJVCLPersistent.IsVCL: Boolean;
begin
  Result := Assigned(FVCL);
end;

class function TJVCLPersistent.IsMakeGlobalInstance: Boolean;
begin
  Result := False;
end;

procedure TJVCLPersistent.RegistEvents;
//�C�x���g��o�^����
{ TODO : �����ŕʂ̌^�̃C�x���g���������ꍇ�̓��삪�s�� }
{ TODO : �蓮�œo�^������������ }
//var
  //sl: TSTringList;
  //i: Integer;
  //v: TJValue;
  //meth: TMethod;
begin
  {if not Assigned(FVCL) then
    Exit;

  sl := TStringList.Create;
  try
    sl.Sorted := True;
    sl.Duplicates := dupIgnore;
    //���g�̃C�x���g����T��
    EnumMethodNames(Self,sl);
    //�C�x���g���Z�b�g����
    for i := 0 to sl.Count - 1 do
    begin
      //TMethod�𓾂�
      meth.Data := Self;
      meth.Code := Self.MethodAddress(sl[i]);
      v := BuildEvent(meth);
      //VCL�ɃZ�b�g����
      SetDefaultProperty(FVCL,sl[i],v);
    end;
  finally
    sl.Free;
  end;}
end;

function TJVCLPersistent.RegistVCL(AVCL: TPersistent;
  ACanDestroy: Boolean): Boolean;
//VCL��o�^
var
  sl: TStringList;
begin
  //�ȑO��j��
  DestroyVCL;
  //�^�`�F�b�N
  if not (AVCL is VCLClassType) then
  begin
    Result := False;
    Exit;
  end
  else
    Result := True;

  FCanDestroy := ACanDestroy;
  FVCL := AVCL;
  if Assigned(FVCL) then
  begin
    sl := TStringList.Create;
    try
      //property��o�^
      GetDefaultProperties(FVCL,sl);
      FDefaultProperties.Assign(sl);
      //����
      sl.Clear;
      GetDefaultProperties(Self,sl);
      FDefaultProperties.AddStrings(sl);
    finally
      sl.Free;
    end;
    //�C�x���g�o�^
    RegistEvents;
  end;
end;

function TJVCLPersistent.SetValueImpl(S: String;
  var Value: TJValue; Param: TJValueList): Boolean;
begin
  //self��D�悷��
  if inherited SetValueImpl(S,Value) then
    Result := True
  else if Assigned(FVCL) and
          HasDefaultProperty(S) and
          SetDefaultProperty(FVCL,S,Value) then
  begin
    Result := True;
  end
  else
    Result := False;
end;

class function TJVCLPersistent.VCLClassType: TClass;
begin
  Result := TPersistent;
end;

procedure TJVCLPersistent.Error(Msg: String);
begin
  raise EJThrow.Create(E_VCL,
    VCLClassType.ClassName + ' - ' + Msg);
end;

procedure TJVCLPersistent.CheckVCL(Param: TJValueList; ArgCount: Integer);
//��O���N����
begin
  if not IsVCL then
    Error('VCL is null')
  else begin
    //�����`�F�b�N
    if ArgCount > 0 then
    begin
      if not Assigned(Param) then
        ArgsError
      else if Assigned(Param) and (Param.Count < ArgCount) then
        ArgsError;
    end;
  end;
end;

function TJVCLPersistent.DoAssign(Param: TJValueList): TJValue;
//VCL�̃R�s�[
var
  v: TJValue;
begin
  CheckVCL(Param,1);
  Result := BuildObject(Self);

  v := Param[0];
  if IsVCLObject(@v) and (v.vObject as TJVCLPersistent).IsVCL then
    FVCL.Assign((v.vObject as TJVCLPersistent).FVCL);
end;

procedure TJVCLPersistent.ArgsError;
begin
  Error('arguments error');
end;

{ EJReturn }

constructor EJReturn.Create(AValue: TJValue);
begin
  inherited Create('return');
  FValue := AValue;
end;

{ TJValueList }

function TJValueList.Add(Value: TJValue; IncRef: Boolean): Integer;
//������
var
  p: PJValue;
begin
  New(p);
  p^ := Value;

  if IsObject(p) then
  begin
    //notification���Z�b�g
    p^.vObject.FreeNotification(FNotify);
    //�Q�ƃJ�E���g
    if IncRef then
      p^.vObject.IncRef;
  end;

  Result := FItems.Add(p);
end;

procedure TJValueList.Clear;
//�N���A
var
  i: Integer;
begin
  for i := FItems.Count - 1 downto 0 do
    Delete(i);

  FItems.Clear;
end;

function TJValueList.GetCount: Integer;
//�J�E���g
begin
  Result := FItems.Count;
end;

constructor TJValueList.Create;
//�쐬
begin
  inherited Create;
  FItems := TListPlus.Create;
  FItems.SortType := stMerge;//stQuick;
  FNotify := TJNotify.Create;
  FNotify.OnNotification := NotifyOnNotifycation;
end;

procedure TJValueList.Delete(Index: Integer);
//�폜
var
  p: PJValue;
begin
  p := FItems[Index];

  if IsObject(p) then
  begin
    //notification������
    p^.vObject.RemoveFreeNotification(FNotify);
    FNotify.RemoveFreeNotification(p^.vObject);
    //�Q�ƃJ�E���g
    p^.vObject.DecRef;
  end;

  Dispose(p);
  FItems.Delete(Index);
end;

destructor TJValueList.Destroy;
//�j��
begin
  Clear;
  FreeAndNil(FNotify);
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TJValueList.GetItems(Index: Integer): TJValue;
//�Q�b�g
var
  p: PJValue;
begin
  EmptyValue(Result);
  p := FItems[Index];
  if Assigned(p) then
    Result := p^;
end;

procedure TJValueList.Insert(Index: Integer; Value: TJValue);
//�}��
var
  p: PJValue;
begin
  New(p);
  p^ := Value;
  if IsObject(p) then
  begin
    //notification���Z�b�g
    p^.vObject.FreeNotification(FNotify);
    //�Q�ƃJ�E���g
    p^.vObject.IncRef;
  end;

  FItems.Insert(Index,p);
end;

procedure TJValueList.SetItems(Index: Integer; const Value: TJValue);
//�Z�b�g
var
  p: PJValue;
begin
  //�Q�ƃJ�E���g�𑝂₷
  if IsObject(@Value) then
    Value.vObject.IncRef;

  p := FItems[Index];

  if IsObject(p) then
  begin
    //�ʒm������
    p^.vObject.RemoveFreeNotification(FNotify);
    FNotify.RemoveFreeNotification(p^.vObject);
    //�ȑO�̒l�̎Q�ƃJ�E���g�����炷
    p^.vObject.DecRef;
  end;
  //����ւ�
  p^ := Value;
  //�ʒm���Z�b�g
  if IsObject(p) then
    p^.vObject.FreeNotification(FNotify);
end;

procedure TJValueList.Sort(Compare: TListSortCompareObj);
begin
  FItems.Sort(Compare);
end;

procedure TJValueList.SetCount(const Value: Integer);
var
  i,cnt: Integer;
  v: TJValue;
begin
  if Value > FItems.Count then
  begin
    //�傫������
    EmptyValue(v);
    cnt := Value - FItems.Count;
    for i := 0 to cnt - 1 do
      Add(v);
  end
  else if Value < FItems.Count then
  begin
    //����������
    for i := FItems.Count - 1 downto Value do
      Delete(i);
  end;
end;

function TJValueList.GetSortType: TSortType;
begin
  Result := FItems.SortType;
end;

procedure TJValueList.SetSortType(const Value: TSortType);
begin
  FItems.SortType := Value;
end;

procedure TJValueList.Assign(Source: TJValueList);
//�R�s�[
var
  i: Integer;
begin
  Clear;
  if Assigned(Source) then
    for i := 0 to Source.Count - 1 do
      Add(Source[i]);
end;

function TJValueList.Add(Value: Boolean): Integer;
begin
  Result := Add(BuildBool(Value));
end;

function TJValueList.Add(Value: Integer): Integer;
begin
  Result := Add(BuildInteger(Value));
end;

function TJValueList.Add(Value: TJObject; IncRef: Boolean): Integer;
begin
  Result := Add(BuildObject(Value),IncRef);
end;

function TJValueList.Add(Value: Double): Integer;
begin
  Result := Add(BuildDouble(Value));
end;

function TJValueList.Add(Value: IDispatch): Integer;
begin
  Result := Add(BuildDispatch(Value));
end;

function TJValueList.Add(Value: String): Integer;
begin
  Result := Add(BuildString(Value));
end;

procedure TJValueList.NotifyOnNotifycation(Sender: TObject);
//object�̍폜�C�x���g
var
  i: Integer;
  p: PJValue;
begin
  for i := FItems.Count - 1 downto 0 do
  begin
    p := FItems[i];
    //�����ɂ��邾��
    if IsObject(p) and (p^.vObject = Sender) then
      EmptyValue(p^);
  end;
end;

{ TJObjectFactory }

procedure TJObjectFactory.ImportObject(ObjectName: String;
  ObjectClass: TJObjectClass);
//objectclass��o�^����
var
  p: PJObjectClass;
begin
  New(p);
  p^ := ObjectClass;
  FHash[ObjectName] := p;
end;

constructor TJObjectFactory.Create(AEngine: TJBaseEngine);
//�쐬
begin
  inherited Create;
  FEngine := AEngine;
  FHash := TPointerHashTable.Create(HASH_50);
  FHash.OnFreeItem := HashOnItemDispose;
  FItems := TJObjectList.Create;
  //prototype
  FProto := TJHash.Create(HASH_20);
end;

destructor TJObjectFactory.Destroy;
//�j��
begin
  Clear;
  FreeAndNil(FProto);
  FreeAndNil(FItems);
  FreeAndNil(FHash);
  inherited;
end;

procedure TJObjectFactory.HashOnItemDispose(Sender: TObject; P: PHashItem);
//��item�̔j��
var
  obj: PJObjectClass;
begin
  obj := P^.vPointer;
  Dispose(obj);
  P^.vPointer := nil;
end;

function TJObjectFactory.HasObject(ObjectName: String): Boolean;
//object������H
begin
  Result := FHash.HasKey(ObjectName);
end;

procedure TJObjectFactory.DeleteObject(ObjectName: String);
//object class���폜����
begin
  FHash.Remove(ObjectName);
end;

procedure TJObjectFactory.Add(Obj: TJObject);
begin
  FItems.Add(Obj);
  Obj.FreeNotification(Self);
end;

procedure TJObjectFactory.Clear;
begin
  //�K��prototype���ɊJ������
  FProto.Clear;
  FItems.Clear;
end;

function TJObjectFactory.GetObjectCount: Integer;
begin
  Result := FItems.Count;
end;

function TJObjectFactory.GetObjectNameList: TStringList;
begin
  Result := FHash.KeyList;
end;

function TJObjectFactory.GetObject(ObjectName: String): PJObjectClass;
begin
  Result := FHash[ObjectName];
end;

function TJObjectFactory.GetPrototype(ObjectName: String): TJObject;
//prototype���쐬
var
  v: TJValue;
begin
  //�Ԃ��̂�.Prototype
  if FProto.GetValue(ObjectName,v) then
    Result := (v.vObject as TJPrototypeObject).Prototype
  else begin
    //���̂܂ܕԂ�
    Result := TJPrototypeObject.Create(FEngine);
    //�Z�b�g
    FProto.SetValue(ObjectName,BuildObject(Result));
  end;
end;

function TJObjectFactory.SetPrototype(ObjectName: String; Obj: TJObject): Boolean;

  function CheckPrototype: Boolean;
  //�������[�v���`�F�b�N����
  var
    p: TJObject;
  begin
    Result := True;
    //null��������I���
    if not Assigned(Obj) then
      Exit;

    //Obj.Name��prototype�𓾂�
    p := GetPrototype(Obj.Name);
    while not(p is TJPrototypeObject) do
    begin
      //�������[�v�ɂȂ�̂ŃG���[
      if p.Name = ObjectName then
      begin
        Result := False;
        Break;
      end
      else begin //���`�F�b�N
        p := GetPrototype(p.Name);
        Result := True;
      end;
    end;
  end;

var
  v: TJValue;
begin
  //check
  Result := CheckPrototype;
  if Result then
  begin
    //�쐬����
    GetPrototype(ObjectName);
    //�Z�b�g
    if FProto.GetValue(ObjectName,v) then
      (v.vObject as TJPrototypeObject).Prototype := Obj;
  end;
end;

procedure TJObjectFactory.Notification(AObject: TJNotify);
//object�폜�C�x���g
begin
  inherited;
  FItems.Remove(AObject);
end;

{ EJRuntimeError }

constructor EJRuntimeError.Create(AExceptName,AErrorMsg: String;
  AValue: PJValue);
begin
  inherited Create(AExceptName);
  FExceptName := AExceptName;
  Message := AErrorMsg;
  FValue := BuildNull;
  if Assigned(AValue) then
    FValue := AValue^;
end;

{ EJExit }

constructor EJExit.Create(AStatus: Integer);
begin
  FStatus := AStatus;
end;

{ TJObjectList }

procedure TJObjectList.Clear;
//var
//  s: String;
begin
  { if Count > 0 then
   begin
     s := Format('%d��object���������܂���ł���',[Count]);
     MessageBox(0,PChar(s),'DMonkey',MB_OK);
     sleep(0); //�u���[�N�|�C���g�̂��߂ŁA���ɈӖ��͂Ȃ�
   end;
  }
  //�擪�������
  while (Count > 0) do
    TObject(Items[0]).Free;

  inherited;
end;

{ TJLocalSymbolTable }

procedure TJLocalSymbolTable.Clear;
//�N���A����
begin
  //���ʂ��N���A
  FTables.Clear;
  //this���N���A
  SetThis(nil);
  //temp���N���A
  FTempObjects.Clear;
  //local���N���A
  FLocal.Clear;
end;

constructor TJLocalSymbolTable.Create(AParent: TJLocalSymbolTable);
//�쐬
begin
  inherited Create;
  FParent := AParent;
  FLocal := TJHash.Create(HASH_30);
  FTables := TObjectList.Create;
  FTempObjects := TJValueList.Create;
end;

destructor TJLocalSymbolTable.Destroy;
//�j��
begin
  Clear;
  FreeAndNil(FTempObjects);
  FreeAndNil(FTables);
  FreeAndNil(FLocal);
  inherited;
end;

function TJLocalSymbolTable.GetGlobalTable: TJGlobalSymbolTable;
//global�e�[�u���𓾂�
var
  table: TJLocalSymbolTable;
begin
  Result := nil;
  table := Self;
  while Assigned(table) do
  begin
    if table is TJGlobalSymbolTable then
    begin
      Result := table as TJGlobalSymbolTable;
      Break;
    end
    else //�e�ֈړ�
      table := table.FParent;
  end;
end;

function TJLocalSymbolTable.GetValueImpl(Caller: TJLocalSymbolTable;
  Symbol: String; var Value: TJValue): Boolean;
//�l�𓾂������
begin
  //���[�J����T��
  if FLocal.GetValue(Symbol,Value) then
  begin
    Result := True;
    Exit;
  end;

  //this��T��
  if Assigned(FThis) then
  begin
{$IFNDEF NO_ACTIVEX}
    if FThis is TJActiveXObject then
    begin
      try
        Value := FThis.GetValue(Symbol,False);
        Result := True;
        Exit;
      except
        on EJThrow do
      end;
    end else
{$ENDIF}
    if FThis.HasKey(Symbol) then
    begin
      Value := FThis.GetValue(Symbol,False);
      Result := True;
      Exit;
    end;
  end;

  //�e��T��
  if Assigned(FParent) then
    Result := FParent.GetValueImpl(Self,Symbol,Value)
  else
    Result := False;
end;

function TJLocalSymbolTable.GetGlobalValue(Symbol: String;
  var Value: TJValue): Boolean;
//global table�̒l�𓾂�
begin
  Result := GetGlobalTable.GetValue(Symbol,Value);
end;

function TJLocalSymbolTable.GetThis: TJObject;
//this��T��
begin
  Result := FThis;
  //�e����T��
  if (not Assigned(Result)) and Assigned(FParent) then
    Result := FParent.GetThis
end;

function TJLocalSymbolTable.GetValue(Symbol: String;
  var Value: TJValue): Boolean;
//�l�𓾂�
begin
  Result := GetValueImpl(Self,Symbol,Value);
end;

function TJLocalSymbolTable.PushLocalTable(
  ATable: TJLocalSymbolTable; AThis: TJObject): TJLocalSymbolTable;
//local�e�[�u�����쐬
begin
  Result := TJLocalSymbolTable.Create(Self);
  FTables.Insert(0,Result);
  //�l���R�s�[
  if Assigned(ATable) then
    Result.LocalCopy(ATable);
  //this
  Result.SetThis(AThis);
end;

procedure TJLocalSymbolTable.RegistGlobalValue(Symbol: String;
  Value: TJValue);
//�O���[�o���ɓo�^����
begin
  GetGlobalTable.RegistValue(Symbol,Value);
end;

procedure TJLocalSymbolTable.RegistValue(Symbol: String; Value: TJValue);
//local�ɓo�^����
begin
  FLocal.SetValue(Symbol,Value);
end;

procedure TJLocalSymbolTable.PopLocalTable;
//table���폜
begin
  //�ŏ�������
  FTables.Delete(0);
end;

procedure TJLocalSymbolTable.SetValue(Symbol: String;
  Value: TJValue; RegistType: TJRegistVarType);
begin
  if not SetValueImpl(Self,Symbol,Value) then
    case RegistType of
      //�����ꍇ�̓��[�J���ɓo�^
      rvLocal:  RegistValue(Symbol,Value);
      //�����ꍇ�͊֐�static�ɓo�^
      rvStatic: RegistStaticValue(Symbol,Value);
    else //rvGlobal:
      //�����ꍇ�̓O���[�o���ɓo�^
      RegistGlobalValue(Symbol,Value);
    end;
end;

function TJLocalSymbolTable.SetValueImpl(Caller: TJLocalSymbolTable;
  Symbol: String; var Value: TJValue): Boolean;
//�o�^����Ă���e�[�u����T���ēo�^����
begin
  //���[�J����T��
  if FLocal.HasKey(Symbol) then
  begin
    FLocal.SetValue(Symbol,Value);
    Result := True;
    Exit;
  end;

  //this��T��
  if Assigned(FThis) and FThis.HasKey(Symbol) then
  begin
    FThis.SetValue(Symbol,Value,False);
    Result := True;
    Exit;
  end;

  //�e��T��
  if Assigned(FParent) then
    Result := FParent.SetValueImpl(Self,Symbol,Value)
  else
    Result := False;
end;

procedure TJLocalSymbolTable.LocalCopy(Source: TJLocalSymbolTable);
//source����R�s�[����
var
  i: Integer;
  sl: TStringList;
  v: TJValue;
begin
  if not Assigned(Source) then
    Exit;

  //��̒l��D�悷��i�㏑�����Ȃ�)
  sl := Source.FLocal.KeyList;
  for i := 0 to sl.Count - 1 do
  begin
    if not FLocal.HasKey(sl[i]) then
    begin
      if Source.FLocal.GetValue(sl[i],v) then
        FLocal.SetValue(sl[i],v);
    end;
  end;
end;

procedure TJLocalSymbolTable.AddTemporaryObject(AObject: TJObject;
  IncRef: Boolean = True);
//temp object�������邾��
begin
  FTempObjects.Add(AObject,IncRef);
end;

function TJLocalSymbolTable.GetNodeTable: TJFunctionSymbolTable;
//function�e�[�u���𓾂�
var
  table: TJLocalSymbolTable;
begin
  Result := nil;
  table := Self;
  while Assigned(table) do
  begin
    if table is TJFunctionSymbolTable then
    begin
      Result := table as TJFunctionSymbolTable;
      Break;
    end
    else //�e�ֈړ�
      table := table.FParent;
  end;
end;

procedure TJLocalSymbolTable.SetParent(Value: TJLocalSymbolTable);
//�e���Đݒ�
begin
  FParent := Value;
end;

procedure TJLocalSymbolTable.SetThis(const Value: TJObject);
begin
  if Assigned(FThis) then
  begin
    //�I���ʒm������
    FThis.RemoveFreeNotification(Self);
    RemoveFreeNotification(FThis);
  end;
  //�ʒm��t����
  if Assigned(Value) then
    Value.FreeNotification(Self);
  //����ւ�
  FThis := Value;
end;

procedure TJLocalSymbolTable.Notification(AObject: TJNotify);
//�I���ʒm
begin
  inherited;
  if AObject = FThis then
    FThis := nil
  else if AObject = FParent then
    FParent := nil;
end;

procedure TJLocalSymbolTable.RegistStaticValue(Symbol: String;
  Value: TJValue);
//�֐���node��static�o�^����
var
  table: TJFunctionSymbolTable;
begin
  table := GetNodeTable;
  //�l�̏㏑����h�����ߓo�^�͂P�񂾂�
  if not table.FLocal.HasKey(Symbol) then
    table.RegistValue(Symbol,Value);
end;

procedure TJLocalSymbolTable.ClearTemporaryObject;
begin
  FTempObjects.Clear;
end;

{ TJFunctionSymbolTable }

function TJFunctionSymbolTable.GetValueImpl(Caller: TJLocalSymbolTable;
  Symbol: String; var Value: TJValue): Boolean;
//�l�𓾂�
begin
  Result := False;
  //�Ăяo�������ʂ�������Ȃɂ����Ȃ�
  if FTables.IndexOf(Caller) > -1 then
  //���ʃ��[�J���e�[�u���������
  else if FTables.Count > 0 then
  begin
    //�ŏ��̃e�[�u��������
    Result :=
        (FTables[0] as TJLocalSymbolTable).GetValueImpl(Self,Symbol,Value);
  end;
  //������Ύ���
  if not Result then
    Result := inherited GetValueImpl(Self,Symbol,Value);
end;

function TJFunctionSymbolTable.SetValueImpl(Caller: TJLocalSymbolTable;
  Symbol: String; var Value: TJValue): Boolean;
//�l���Z�b�g
begin
  Result := False;
  //�Ăяo�������ʂ�������Ȃɂ����Ȃ�
  if FTables.IndexOf(Caller) > -1 then
  //���ʃ��[�J���e�[�u���������
  else if FTables.Count > 0 then
  begin
    //�ŏ��̃e�[�u��������
    Result :=
        (FTables[0] as TJLocalSymbolTable).SetValueImpl(Self,Symbol,Value);
  end;
  //������Ύ���
  if not Result then
    Result := inherited SetValueImpl(Self,Symbol,Value);
end;


{ TJRootSymbolTable }

procedure TJRootSymbolTable.Clear;
begin
  inherited;
  FFunctions.Clear;
  FGlobals.Clear;
end;

constructor TJRootSymbolTable.Create(AParent: TJLocalSymbolTable);
begin
  inherited;
  FFunctions := TObjectHashTable.Create(HASH_50);
  FGlobals := TStringList.Create;
  FGlobals.Sorted := True;
  FGlobals.Duplicates := dupIgnore;
end;

destructor TJRootSymbolTable.Destroy;
begin
  inherited;
  FreeAndNil(FFunctions);
  FreeAndNil(FGlobals);
end;

function TJRootSymbolTable.GetFunctionTable(
  AParent,AFunc: PJStatement): TJFunctionSymbolTable;
//function table���쐬����
var
  patable: TJFunctionSymbolTable;
  pastr,fustr: String;
begin
  //������T��
  fustr := IntToStr(Integer(AFunc));
  if FFunctions.HasKey(fustr) then
    Result := FFunctions[fustr] as TJFunctionSymbolTable
  else begin //�쐬
    //�e�e�[�u����{��
    pastr := IntToStr(Integer(AParent));
    if FFunctions.HasKey(pastr) then
      patable := FFunctions[pastr] as TJFunctionSymbolTable
    else
      patable := nil;
    //�e�[�u�����쐬
    Result := TJFunctionSymbolTable.Create(patable);
    FFunctions[fustr] := Result;
  end;
end;

function TJRootSymbolTable.GetFunctionTable(AParent: TJFunctionSymbolTable;
  AFunc: PJStatement): TJFunctionSymbolTable;
//�e�[�u�����쐬
//function table���쐬����
var
  fustr: String;
begin
  //������T��
  fustr := IntToStr(Integer(AFunc));
  if FFunctions.HasKey(fustr) then
    Result := FFunctions[fustr] as TJFunctionSymbolTable
  else begin
    //�e�[�u�����쐬
    Result := TJFunctionSymbolTable.Create(AParent);
    FFunctions[fustr] := Result;
  end;
end;

function TJRootSymbolTable.FindGlobalTable(AName: String): TJGlobalSymbolTable;
//global�e�[�u����T��
var
  index: Integer;
begin
  if FGlobals.Find(AName,index) then
    Result := FGlobals.Objects[index] as TJGlobalSymbolTable
  else
    raise EJThrow.Create(E_NAME,'namespace not found: ' + AName);
end;

function TJRootSymbolTable.MakeGlobalTable(AName: String;
  AFunc: PJStatement): TJGlobalSymbolTable;
//GlobalTable���쐬����
begin
  //�쐬
  Result := TJGlobalSymbolTable.Create(Self);
  FGlobals.AddObject(AName,Result);
  FFunctions[IntToStr(Integer(AFunc))] := Result;
end;


{ EJSyntaxError }

constructor EJSyntaxError.Create(ALineNo: Integer; AMsg: String;
  AValue: PJValue = nil);
begin
  inherited Create(E_SYNTAX,AMsg,AValue);
  FLineNo := ALineNo;
end;

{ TJPrototypeObject }

constructor TJPrototypeObject.Create(AEngine: TJBaseEngine;
  Param: TJValueList; RegisteringFactory: Boolean);
begin
  inherited;
  RegistName('Prototype');
end;

destructor TJPrototypeObject.Destroy;
begin
  //���炷
  if Assigned(FPrototype) then
    FPrototype.DecRef;

  inherited;
end;

procedure TJPrototypeObject.GetPropertyList(List: TStringList);
begin
  //�S�Ẵ����o�[
  GetKeyList(List,[],[]);
end;

function TJPrototypeObject.GetPrototype: TJObject;
begin
  if Assigned(FPrototype) then
    Result := FPrototype
  else //������Ύ���
    Result := Self;
end;

procedure TJPrototypeObject.Notification(AObject: TJNotify);
//object�̏I���ʒm
begin
  inherited;
  if AObject = FPrototype then
    FPrototype := nil;
end;

procedure TJPrototypeObject.RegistMethods;
begin
  //�������Ȃ�
end;

procedure TJPrototypeObject.SetPrototype(const Value: TJObject);
begin
  //���₷
  if Assigned(Value) then
    Value.IncRef;

  if Assigned(FPrototype) then
  begin
    //�ʒm���폜
    FPrototype.RemoveFreeNotification(Self);
    RemoveFreeNotification(FPrototype);
    //���炷
    FPrototype.DecRef;
  end;

  //����ւ�
  FPrototype := Value;
  //�ʒm���Z�b�g
  if Assigned(FPrototype) then
    FPrototype.FreeNotification(Self);
end;


{ TJFunctionImpl }

constructor TJFunctionImpl.Create;
begin
  inherited Create;
  FNotify := TJNotify.Create;
  FNotify.OnNotification := NotifyOnNotifycation;
end;

destructor TJFunctionImpl.Destroy;
begin
  FMethodOwner := nil;
  //���݂���΍폜
  FreeAndNil(FLocalTable);
  FreeAndNil(FNotify);
  inherited;
end;

function TJFunctionImpl.GetFunctionTable: TJFunctionSymbolTable;
begin
  Result := FFunc.FunctionTable;
end;

function TJFunctionImpl.GetFlag: TJFunctionCallFlag;
begin
  Result := FFunc.Flag;
end;

function TJFunctionImpl.GetFuncType: TJFuncType;
begin
  Result := FFunc.FuncType;
end;

function TJFunctionImpl.GetParameter: PJStatement;
begin
  Result := FFunc.Parameter;
end;

function TJFunctionImpl.GetSymbol: String;
begin
  Result := FFunc.Symbol;
end;

function TJFunctionImpl.GetvActiveX: PJActiveXMethod;
begin
  Result := @FFunc.vActiveX;
end;

function TJFunctionImpl.GetvDynaCall: PDynaDeclare;
begin
  Result := @FFunc.vDynaCall;
end;

function TJFunctionImpl.GetvMethod: TJMethod;
begin
  Result := FFunc.vMethod;
end;

function TJFunctionImpl.GetvStatement: PJStatement;
begin
  Result := FFunc.vStatement;
end;

procedure TJFunctionImpl.SetFunctionTable(const Value: TJFunctionSymbolTable);
begin
  FFunc.FunctionTable := Value;
end;

procedure TJFunctionImpl.SetFlag(const Value: TJFunctionCallFlag);
begin
  FFunc.Flag := Value;
end;

procedure TJFunctionImpl.SetFuncType(const Value: TJFuncType);
begin
  FFunc.FuncType := Value;
end;

procedure TJFunctionImpl.SetParameter(const Value: PJStatement);
begin
  FFunc.Parameter := Value;
end;

procedure TJFunctionImpl.SetSymbol(const Value: String);
begin
  FFunc.Symbol := Value;
end;

procedure TJFunctionImpl.SetvMethod(const Value: TJMethod);
begin
  FFunc.vMethod := Value;
end;

procedure TJFunctionImpl.SetvStatement(const Value: PJStatement);
begin
  FFunc.vStatement := Value;
end;

function TJFunctionImpl.GetLocalTable: TJLocalSymbolTable;
//local table��Ԃ�
begin
  Result := FLocalTable
end;

procedure TJFunctionImpl.SetLocalTable(const Value: TJLocalSymbolTable);
begin
  if Assigned(FLocalTable) then
    FreeAndNil(FLocalTable);

  FLocalTable := Value;
end;

procedure TJFunctionImpl.Assign(Source: IJFunction);
//�R�s�[����
begin
  FFunc := Source.GetFunc;
  if FMethodOwner <> Source.MethodOwner then
    SetMethodOwner(Source.MethodOwner);

  //local���R�s�[
  if Assigned(Source.LocalTable) then
  begin
    if not Assigned(FLocalTable) then
      FLocalTable := TJLocalSymbolTable.Create(nil);
    //�R�s�[
    FLocalTable.LocalCopy(Source.LocalTable);
  end;
end;

function TJFunctionImpl.GetFunc: __TJFunction;
begin
  Result := FFunc;
end;

function TJFunctionImpl.GetMethodOwner: TJObject;
//�֐��̏��L�N���X
begin
  Result := FMethodOwner;
end;

procedure TJFunctionImpl.SetMethodOwner(const Value: TJObject);
begin
  //�ʒm������
  if Assigned(FMethodOwner) then
  begin
    FMethodOwner.RemoveFreeNotification(FNotify);
    FNotify.RemoveFreeNotification(FMethodOwner);
  end;
  //����ւ�
  FMethodOwner := Value;
  //�I���ʒm���Z�b�g
  if Assigned(FMethodOwner) then
    FMethodOwner.FreeNotification(FNotify);
end;

procedure TJFunctionImpl.NotifyOnNotifycation(Sender: TObject);
//owner object�̔j��
begin
  FMethodOwner := nil;
end;

{ TJNotify }

destructor TJNotify.Destroy;
//notify�����ׂċN��
var
  i: Integer;
begin
  if Assigned(FFreeNotifies) then
  begin
    for i := FFreeNotifies.Count - 1 downto 0 do
    begin
      TJNotify(FFreeNotifies[i]).Notification(Self);
      if not Assigned(FFreeNotifies) then
        Break;
    end;

    FreeAndNil(FFreeNotifies);
  end;

  inherited;
end;

procedure TJNotify.FreeNotification(AObject: TJNotify);
//notify��o�^����
begin
  //�쐬
  if not Assigned(FFreeNotifies) then
    FFreeNotifies := TBinList.Create;
  //���łɓo�^���ĂȂ����
  if FFreeNotifies.IndexOf(AObject) < 0 then
  begin
    //���݂��ɓo�^
    FFreeNotifies.Add(AObject);
    AObject.FreeNotification(Self);
  end;
end;

procedure TJNotify.Notification(AObject: TJNotify);
begin
  if Assigned(AObject) then
  begin
    //AObject�������������
    RemoveFreeNotification(AObject);
    //�C�x���g������΃C�x���g
    if Assigned(FOnNotification) then
      FOnNotification(AObject); //AObject�𑗂�
  end;
end;

procedure TJNotify.RemoveFreeNotification(AObject: TJNotify);
//�o�^������
begin
  if Assigned(FFreeNotifies) then
  begin
    FFreeNotifies.Remove(AObject);
    if FFreeNotifies.Count = 0 then
      FreeAndNil(FFreeNotifies);
  end;
end;

end.
