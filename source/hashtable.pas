unit hashtable;

//�n�b�V���e�[�u��
//by Wolfy

interface

uses
  sysutils,windows,classes;

type
  EHashTableError = class(Exception);

const
  HASH_10 = 13;
  HASH_20 = 23;
  HASH_30 = 31;
  HASH_50 = 53;
  HASH_100 = 101;
  HASH_200 = 199;
  HASH_500 = 503;
  HASH_1000 = 1009;
  HASH_2000 = 2003;
  HASH_3000 = 3001;
  HASH_4000 = 4001;
  HASH_5000 = 5003;
  HASH_10000 = 10007;


type
  PHashItem = ^THashItem;
  THashItem = record
    Key: String;
    case Integer of
      0: (vInteger: Integer);
      1: (vPointer: Pointer);
      2: (vObject: TObject);
      3: (vCardinal: Cardinal);
  end;

  TListSortCompareObj = function(Item1, Item2: Pointer): Integer of object;
  TFreeItemEvent = procedure(Sender: TObject; P: PHashItem) of object;

  TBinaryItemList = class(TObject)
  private
    FItems: TList;
    FIgnoreCase: Boolean;
    FOnFreeItem: TFreeItemEvent;

    function Get(Index: Integer): PHashItem;
    procedure FreeItem(P: PHashItem);
    function GetCount: Integer;
  public
    constructor Create(AIgnoreCase: Boolean = False);
    destructor Destroy; override;
    procedure Add(P: PHashItem);
    procedure Insert(P: PHashItem);
    function Remove(P: PHashItem): Integer;
    procedure Delete(Index: Integer);
    procedure Clear;
    function Search(Key: String): Integer;

    property Items[Index: Integer]: PHashItem read Get; default;
    property Count: Integer read GetCount;
    property OnFreeItem: TFreeItemEvent read FOnFreeItem write FOnFreeItem;
  end;


  TCustomHashTable = class(TObject)
  protected
    FTable: array of TBinaryItemList;
    FTableSize: DWORD;
    FKeys: TStringList;
    FIgnoreCase: Boolean;
    FRaiseException: Boolean;
    FName: String;
    FOnFreeItem: TFreeItemEvent;

    function GetIndex(const Key: String): Integer;
    procedure MakeTable(ATableSize: DWord);
    function GetItem(Key: String): PHashItem;
    procedure AddItem(PItem: PHashItem);
    function NewItem: PHashItem;
    function GetKeys: String;
    function GetKeyList: TStringList;
    procedure UpdateKeys;
  protected
    FKeyUpdated: Boolean;
    function GetValuePointer(Key: String): Pointer;
    procedure SetValuePointer(Key: String; const Value: Pointer);
    //listevent
    procedure TableOnFreeItem(Sender: TObject; P: PHashItem); virtual;
  public
    constructor Create(ATableSize: DWord; AIgnoreCase: Boolean = False); virtual;
    destructor Destroy; override;
    function Remove(Key: String): Boolean;
    function HasKey(Key: String): Boolean;
    procedure Clear; virtual;   

    property RaiseException: Boolean read FRaiseException write FRaiseException;
    property Keys: String read GetKeys;
    property KeyList: TStringList read GetKeyList;
    property Name: String read FName write FName;
    property OnFreeItem: TFreeItemEvent read FOnFreeItem write FOnFreeItem;
  end;

  TStringHashTable = class(TCustomHashTable)
  private
    function GetValueString(Key: String): String;
    procedure SetValueString(Key: String; const Value: String);
  protected
    procedure TableOnFreeItem(Sender: TObject; P: PHashItem); override;
  public
    property Value[Key: String]: String read GetValueString write SetValueString; default;
  end;

  THashTable = TStringHashTable;

  TObjectHashTable = class(TCustomHashTable)
  private
    FOwnsObjects: Boolean;
    
    function GetValueObject(Key: String): TObject;
    procedure SetValueObject(Key: String; const Value: TObject);
  protected
    procedure TableOnFreeItem(Sender: TObject; P: PHashItem); override;
  public
    constructor Create(ATableSize: DWord; AIgnoreCase: Boolean = False); override;
    property Value[Key: String]: TObject read GetValueObject write SetValueObject; default;
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
  end;

  TIntegerHashTable = class(TCustomHashTable)
  private
    function GetValueInteger(Key: String): Integer;
    procedure SetValueInteger(Key: String; const Value: Integer);
  public
    property Value[Key: String]: Integer read GetValueInteger write SetValueInteger; default;
  end;

  TDoubleHashTable = class(TCustomHashTable)
  private
    function GetValueDouble(Key: String): Double;
    procedure SetValueDouble(Key: String; const Value: Double);
  protected
    procedure TableOnFreeItem(Sender: TObject; P: PHashItem); override;
  public
    property Value[Key: String]: Double read GetValueDouble write SetValueDouble; default;
  end;

  TPointerHashTable = class(TCustomHashTable)
  public
    property Value[Key: String]: Pointer read GetValuePointer write SetValuePointer; default;
  end;


function HashCodeA(S: String): Cardinal;
function HashCodeB(S: String): Cardinal;


implementation

function HashCodeA(S: String): Cardinal;
//�n�b�V���̒l�𓾂�
//s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]
var
  i,n: Integer;
begin
  Result := 0;
  n := Length(S);
  for i := 1 to n do
    Inc(Result,Byte(S[i]) * 31 xor (n - i));
end;

function HashCodeB(S: String): Cardinal;
//�n�b�V���̒l�𓾂�
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to Length(S) do
    Result := ((Result shl 2) or (Result shr (SizeOf(Result) * 8 - 2))) xor Ord(S[I]);
end;


{ TBinaryItemList }

procedure TBinaryItemList.Add(P: PHashItem);
//�|�C���^������������
begin
  Insert(P);
end;

procedure TBinaryItemList.Clear;
//���ׂč폜����
var
  i: Integer;
begin
  for i := FItems.Count - 1 downto 0 do
    Delete(i);

  FItems.Clear;
end;

constructor TBinaryItemList.Create(AIgnoreCase: Boolean);
//�쐬
begin
  inherited Create;
  FItems := TList.Create;
  //����case�𖳎����Ȃ�
  FIgnoreCase := AIgnoreCase;
end;

procedure TBinaryItemList.Delete(Index: Integer);
//�폜����
begin
  //�������
  FreeItem(Items[Index]);
  FItems.Delete(Index);
end;

destructor TBinaryItemList.Destroy;
//�j������
begin
  Clear;
  FOnFreeItem := nil;
  
  FreeAndNil(FItems);
  inherited;
end;

function TBinaryItemList.Get(Index: Integer): PHashItem;
begin
  Result := FItems[Index];
end;

function TBinaryItemList.Remove(P: PHashItem): Integer;
begin
  Result := FItems.IndexOf(P);
  if Result > -1 then
    Delete(Result);
end;

function TBinaryItemList.Search(Key: String): Integer;
//key����T��
var
  min,middle,max,r: Integer;
begin
  min := 0;
  max := FItems.Count - 1;
  //�o�C�i���T�[�`
  while min <= max do
  begin
    middle := (max + min) div 2;
    //��r
    if FIgnoreCase then
      r := AnsiCompareText(Key,Items[middle]^.Key)
    else
      r := AnsiCompareStr(Key,Items[middle]^.Key);
    //����
    if r = 0 then
    begin
      Result := middle;
      Exit;
    end
    else if r < 0 then
      //key�̕����������̂� ����T��
      max := middle - 1
    else
      //key�̕����傫�̂� �E��T��
      min := middle + 1;
  end;
  //�݂���Ȃ������I
  Result := -1;
end;

procedure TBinaryItemList.FreeItem(P: PHashItem);
//�������
begin
  //�C�x���g���N����
  if Assigned(FOnFreeItem) then
    FOnFreeItem(Self,P);
  //�������
  Dispose(P);
end;

procedure TBinaryItemList.Insert(P: PHashItem);
//2���}��
var
  min,middle,max,r: Integer;
  key: String;
begin
  key := P^.Key;
  min := 0;
  max := FItems.Count - 1;
  middle := 0;
  //�o�C�i���T�[�`
  while min <= max do
  begin
    middle := (max + min) div 2;
    //��r
    if FIgnoreCase then
      r := AnsiCompareText(key,Items[middle]^.Key)
    else
      r := AnsiCompareStr(key,Items[middle]^.Key);
    //����
    if r = 0 then
    begin
      //�������
      FreeItem(FItems[middle]);
      //����ւ�
      FItems[middle] := P;
      Exit;
    end
    else if r < 0 then
    begin
      //key�̕����������̂� ����T��
      max := middle - 1;
    end
    else begin
      //������Ȃ������Ƃ��̂��߂�middle��1���₷
      Inc(middle);
      //key�̕����傫�̂� �E��T��
      min := middle;
    end;
  end;
  //�݂���Ȃ������̂ő}��
  FItems.Insert(middle,P);
end;

function TBinaryItemList.GetCount: Integer;
begin
  Result := FItems.Count;
end;

{ TCustomHashTable }

procedure TCustomHashTable.Clear;
//���ׂĂ��N���A����
var
  i: Integer;
begin
  for i := 0 to Length(FTable) - 1 do
  begin
    if Assigned(FTable[i]) then
      FreeAndNil(FTable[i]);
  end;

  FKeys.Clear;
end;

constructor TCustomHashTable.Create(ATableSize: DWord; AIgnoreCase: Boolean);
//�쐬
begin
  inherited Create;
  FKeys := TStringList.Create;

  FTableSize := ATableSize;
  FIgnoreCase := AIgnoreCase;
  FRaiseException := False;
  MakeTable(ATableSize);

  FKeyUpdated := False;
end;

destructor TCustomHashTable.Destroy;
//�j������
begin
  Clear;
  FreeAndNil(FKeys);
  FTable := nil;
  inherited;
end;

function TCustomHashTable.GetIndex(const Key: String): Integer;
//�z��̈ʒu���o��
var
  s: String;
begin
  //??? lowercase����̂� ����case������Ă��Ă�chain�̈ʒu�𓯂��ɂ��邽��

  if FIgnoreCase then
    s := AnsiLowerCase(Key)
  else
    s := Key;
    
  //������HASH�l�����
  //res := CalcStringCRC32(Key);
  //res := HashCodeA(Key);

  //�]������߂�
  Result := HashCodeB(s) mod FTableSize;
end;

function TCustomHashTable.GetItem(Key: String): PHashItem;
//hashitem��Ԃ�
var
  index,r: Integer;
begin
  Result := nil;
  index := GetIndex(Key);
  //table�𒲂ׂ�
  if Assigned(FTable[index]) then
  begin
    r := FTable[index].Search(Key);
    if r > -1 then
      Result := FTable[index].Items[r];
  end;
  //��O���N����
  if FRaiseException and (not Assigned(Result)) then
    raise EHashTableError.Create('dont has key');
end;

function TCustomHashTable.HasKey(Key: String): Boolean;
//key���o�^����Ă��邩���ׂ�
var
  index: Integer;
begin
  Result := False;
  index := GetIndex(Key);
  //table�𒲂ׂ�
  if Assigned(FTable[index]) then
    Result := FTable[index].Search(Key) > -1;
end;

procedure TCustomHashTable.MakeTable(ATableSize: DWord);
//�e�[�u�����쐬����
var
  i: Integer;
begin
  SetLength(FTable,ATableSize);
  //ZeroMemory(@FTable[0],ATableSize * SizeOf(TObject));
  for i := 0 to ATableSize - 1 do
    FTable[i] := nil;
end;

function TCustomHashTable.NewItem: PHashItem;
//�V�K�A�C�e���쐬
begin
  New(Result);
  //0�Ŗ��߂�
  Result^.Key := '';
  Result^.vPointer := nil;
end;

function TCustomHashTable.Remove(Key: String): Boolean;
//key���폜����
var
  index,r: Integer;
begin
  Result := False;
  index := GetIndex(Key);
  //table�𒲂ׂ�
  if Assigned(FTable[index]) then
  begin
    r := FTable[index].Search(Key);
    if r > -1 then
    begin
      Result := True;
      //�폜����
      FTable[index].Delete(r);
      //count�𒲂ׂ�
      if FTable[index].Count <= 0 then         
        FreeAndNil(FTable[index]); //�������
    end;

    FKeyUpdated := True;
  end; 
end;

procedure TCustomHashTable.AddItem(PItem: PHashItem);
//�V����key&value���Z�b�g����
var
  index: Integer;
begin
  //index���v�Z����
  index := GetIndex(PItem^.Key);
  //list�����邩�ǂ������ׂ�
  if not Assigned(FTable[index]) then
  begin
    //�V����list���쐬����
    FTable[index] := TBinaryItemList.Create(FIgnoreCase);
    //item����C�x���g���Z�b�g
    FTable[index].OnFreeItem := TableOnFreeItem;
  end;
  //������
  FTable[index].Add(PItem);
  //�X�V
  FKeyUpdated := True;
end;

function TCustomHashTable.GetKeys: String;
//key��tstringlist�ɓ���ĕԂ�
begin
  UpdateKeys;
  Result := TrimRight(FKeys.Text);
end;

procedure TCustomHashTable.TableOnFreeItem(Sender: TObject;
  P: PHashItem);
//hashitem�̉�����ɌĂ΂��
//pointer��object���������
begin
  //�C�x���g1
  if Assigned(FOnFreeItem) then
    FOnFreeItem(Self,P); 
end;

function TCustomHashTable.GetKeyList: TStringList;
begin
  UpdateKeys;
  Result := FKeys;
end;        

procedure TCustomHashTable.UpdateKeys;
//key��tstringlist�ɓ���ĕԂ�
//remove,additem
var
  i,j: Integer;
begin
  //updated�̏ꍇ�̂ݍ�蒼��
  if FKeyUpdated then
  begin
    FKeys.Clear;
    for i := 0 to High(FTable) do
    begin
      if Assigned(FTable[i]) then
      begin
        for j := 0 to FTable[i].Count - 1 do
          FKeys.Add(FTable[i].Items[j]^.Key);
      end;
    end;
  end;

  FKeyUpdated := False;
end;

function TCustomHashTable.GetValuePointer(Key: String): Pointer;
//value pointer
var
  p: PHashItem;
begin
  p := GetItem(Key);
  if Assigned(p) then
    Result := p^.vPointer
  else
    Result := nil;
end;

procedure TCustomHashTable.SetValuePointer(Key: String; const Value: Pointer);
var
  pitem: PHashItem;
begin
  pitem := NewItem;
  pitem^.Key := Key;
  pitem^.vPointer := Value;
  AddItem(pitem);
end;



{ TStringHashTable }

function TStringHashTable.GetValueString(Key: String): String;
//value�𕶎��ŕԂ�
var
  p: PHashItem;
begin
  p := GetItem(Key);
  if Assigned(p) then
    Result := PString(p^.vPointer)^
  else
    Result := '';
end;

procedure TStringHashTable.SetValueString(Key: String;
  const Value: String);
//string
var
  pitem: PHashItem;
  pstr: PString;
begin
  pitem := NewItem;
  pitem^.Key := Key;
  //str
  New(pstr);
  pstr^ := Value;
  pitem^.vPointer := pstr;
  AddItem(pitem);
end;

procedure TStringHashTable.TableOnFreeItem(Sender: TObject; P: PHashItem);
begin
  inherited;
  //str�J��
  system.Dispose(PString(P^.vPointer));
  P^.vPointer := nil;
end;

{ TObjectHashTable }

constructor TObjectHashTable.Create(ATableSize: DWord;
  AIgnoreCase: Boolean);
begin
  inherited;
  FOwnsObjects := True;
end;

function TObjectHashTable.GetValueObject(Key: String): TObject;
//value object
var
  p: PHashItem;
begin
  p := GetItem(Key);
  if Assigned(p) then
    Result := p^.vObject
  else
    Result := nil;
end;

procedure TObjectHashTable.SetValueObject(Key: String;
  const Value: TObject);
var
  pitem: PHashItem;
begin
  pitem := NewItem;
  pitem^.Key := Key;
  pitem^.vObject := Value;
  AddItem(pitem);
end;

procedure TObjectHashTable.TableOnFreeItem(Sender: TObject; P: PHashItem);
begin
  inherited;
  //object�J��
  if FOwnsObjects then
    FreeAndNil(P^.vObject);
end;

{ TIntegerHashTable }

function TIntegerHashTable.GetValueInteger(Key: String): Integer;
//value integer
var
  p: PHashItem;
begin
  p := GetItem(Key);
  if Assigned(p) then
    Result := p^.vInteger
  else
    Result := 0;
end;

procedure TIntegerHashTable.SetValueInteger(Key: String;
  const Value: Integer);
var
  pitem: PHashItem;
begin
  pitem := NewItem;
  pitem^.Key := Key;
  pitem^.vInteger := Value;
  AddItem(pitem);
end;

{ TDoubleHashTable }

function TDoubleHashTable.GetValueDouble(Key: String): Double;
//value double
var
  p: PHashItem;
begin
  p := GetItem(Key);
  if Assigned(p) then
    Result := PDouble(p^.vPointer)^
  else
    Result := 0;
end;

procedure TDoubleHashTable.SetValueDouble(Key: String;
  const Value: Double);
var
  pitem: PHashItem;
  pdoub: PDouble;
begin
  pitem := NewItem;
  pitem^.Key := Key;
  //double
  new(pdoub);
  pdoub^ := Value;
  pitem^.vPointer := pdoub;
  AddItem(pitem);
end;

procedure TDoubleHashTable.TableOnFreeItem(Sender: TObject; P: PHashItem);
begin
  inherited;
  //double�J��
  system.Dispose(PDouble(P^.vPointer));
  P^.vPointer := nil;
end;


end.
