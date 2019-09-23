unit hashtbl;

interface

uses
  Windows,Sysutils,Classes;

const
  HASH_10 = 11;
  HASH_20 = 23;
  HASH_30 = 31;
  HASH_50 = 53;
  HASH_100 = 101;

  MAX_DENSITY = 16;  //�������قǑ���
  SLOT_EXTEND = 1.5;
  ENTRY_CACHE = 9;   //��ɂ���

type
  THashOperation = (hoNone,hoNew,hoFree,hoInsert,hoDelete);

  PHashEntry = ^THashEntry;
  THashEntry = packed record
    Key: Pointer;
    Value: Pointer;
    Next: PHashEntry;
  end;

  THashEntries = array of PHashEntry;

  //Entry��8�o�C�g���E�����ɂȂ�̂ŃL���b�V��
  PHashEntryCache = ^THashEntryCache;  
  THashEntryCache = packed record
    Next: PHashEntryCache;
    Entries: array[0..pred(ENTRY_CACHE)] of THashEntry;
  end;

  TBaseHashTable = class(TObject)
  protected
    FSlotCount: Cardinal;
    FEntryCount: Cardinal;
    FEntries: THashEntries;
    FForEachIndex: Cardinal;

    FFreeEntryList: PHashEntry;
    FEntryCacheList: PHashEntryCache;

    procedure Rehash;
    procedure MakeTable(var Table: THashEntries; Count: Cardinal);
    function MoreEntry: PHashEntry;

    function Compare(Key1,Key2: Pointer): Boolean; virtual;
    function DoHash(Key: Pointer): Cardinal; virtual;
    procedure NewEntry(Key,Value: Pointer; var Entry: THashEntry; Operation: THashOperation); virtual;
    procedure FreeEntry(var Entry: THashEntry; Operation: THashOperation); virtual;

    procedure AddKey(Key: Pointer); virtual;
    procedure DeleteKey(Key: Pointer); virtual;
    procedure ClearKey; virtual;
  public
    constructor Create(DefaultSlotCount: Integer = HASH_10); 
    destructor Destroy; override;

    procedure Clear; virtual;
    function Lookup(Key: Pointer; var Entry: PHashEntry; Operation: THashOperation = hoNone): Boolean;
    procedure AddDirect(Key,Value: Pointer);
    function Insert(Key,Value: Pointer): Boolean;
    function Delete(Key: Pointer): Boolean;

    procedure Foreach(var Entry: PHashEntry);
    function Next(var Entry: PHashEntry): Boolean;
  end;

  TKeyListHashTable = class(TBaseHashTable)
  private
    function GetKeys: String;
    function GetKeyList: TStringList;
  protected
    FKeyList: TStringList;
    FUpdated: Boolean;
    procedure AddKey(Key: Pointer); override;
    procedure DeleteKey(Key: Pointer); override;
    procedure ClearKey; override;
    procedure UpdateKey; virtual;
  public
    constructor Create;
    destructor Destroy; override;

    property Keys: String read GetKeys;
    property KeyList: TStringList read GetKeyList;
  end;

  TIntegerIntegerHashTable = class(TBaseHashTable)
  public
    function GetValue(Key: Integer; var Value: Integer): Boolean;
    function SetValue(Key: Integer; Value: Integer): Boolean;
    function Remove(Key: Integer): Boolean;
    function HasKey(Key: Integer): Boolean;
  end;

  TStringIntegerHashTable = class(TKeyListHashTable)
  protected
    function Compare(Key1,Key2: Pointer): Boolean; override;
    function DoHash(Key: Pointer): Cardinal; override;
    procedure NewEntry(Key,Value: Pointer; var Entry: THashEntry; Operation: THashOperation); override;
    procedure FreeEntry(var Entry: THashEntry; Operation: THashOperation); override;
    procedure UpdateKey; override;
  public
    function GetValue(Key: String; var Value: Integer): Boolean;
    function SetValue(Key: String; Value: Integer): Boolean;
    function Remove(Key: String): Boolean;
    function HasKey(Key: String): Boolean;
  end;

  TStringStringHashTable = class(TKeyListHashTable)
  protected
    function Compare(Key1,Key2: Pointer): Boolean; override;
    function DoHash(Key: Pointer): Cardinal; override;
    procedure NewEntry(Key,Value: Pointer; var Entry: THashEntry; Operation: THashOperation); override;
    procedure FreeEntry(var Entry: THashEntry; Operation: THashOperation); override;
    procedure UpdateKey; override;
  public
    function GetValue(Key: String; var Value: String): Boolean;
    function SetValue(Key: String; Value: String): Boolean;
    function Remove(Key: String): Boolean;
    function HasKey(Key: String): Boolean;
  end;

  TIntegerStringHashTable = class(TBaseHashTable)
  protected
    function Compare(Key1,Key2: Pointer): Boolean; override;
    function DoHash(Key: Pointer): Cardinal; override;
    procedure NewEntry(Key,Value: Pointer; var Entry: THashEntry; Operation: THashOperation); override;
    procedure FreeEntry(var Entry: THashEntry; Operation: THashOperation); override;
  public
    function GetValue(Key: Integer; var Value: String): Boolean;
    function SetValue(Key: Integer; Value: String): Boolean;
    function Remove(Key: Integer): Boolean;
    function HasKey(Key: Integer): Boolean;
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


{ TBaseHashTable }

procedure TBaseHashTable.AddDirect(Key, Value: Pointer);
//�������o�^
var
  hashval,index: Cardinal;
  entry: PHashEntry;
begin
  //�v�f����������ꍇ��Slot�𑝂₷
  if (FEntryCount div FSlotCount) > MAX_DENSITY then
    Rehash;

  hashval := DoHash(Key);
  index := hashval mod FSlotCount;

  entry := MoreEntry;
  NewEntry(Key,Value,entry^,hoNew);
  entry^.Next := FEntries[index];
  FEntries[index] := entry;
  Inc(FEntryCount);
  AddKey(Key);
end;

function TBaseHashTable.Compare(Key1, Key2: Pointer): Boolean;
//��r�֐�
//�Ē�`����
begin
  Result := Key1 = Key2;
end;

constructor TBaseHashTable.Create(DefaultSlotCount: Integer);
//�쐬����
begin
  inherited Create;
  FSlotCount := DefaultSlotCount;
  MakeTable(FEntries,FSlotCount);
end;

function TBaseHashTable.Delete(Key: Pointer): Boolean;
//�v�f���폜����
var
  entry: PHashEntry;
begin
  Result := Lookup(Key,entry,hoDelete);
  //�J��
  if Result then
  begin
    FreeEntry(entry^,hoFree);
    entry.Next := FFreeEntryList;
    FFreeEntryList := entry;
    
    Dec(FEntryCount);
    DeleteKey(Key);
  end;
end;

destructor TBaseHashTable.Destroy;
//�j������
begin
  Clear;
  inherited;
end;

function TBaseHashTable.DoHash(Key: Pointer): Cardinal;
//�n�b�V���֐�
//�Ē�`����
begin
  Result := Cardinal(Key);
end;

procedure TBaseHashTable.Clear;
//���ׂĊJ������

  procedure ClearSlot(var Slot: PHashEntry);
  var
    cur,nxt: PHashEntry;
  begin
    cur := Slot;
    while Assigned(cur) do
    begin
      nxt := cur.Next;
      //�J������
      FreeEntry(cur^,hoFree); 
      cur := nxt;
    end;
    //nil���Z�b�g
    Slot := nil;
  end;

  procedure ClearCache;
  var
    cur,nxt: PHashEntryCache;
  begin
    cur := FEntryCacheList;
    while Assigned(cur) do
    begin
      nxt := cur.Next;
      Dispose(cur);
      cur := nxt;
    end;
  end;

var
  i: Integer;
begin
  for i := 0 to Length(FEntries) - 1 do
    ClearSlot(FEntries[i]);

  ClearCache;
  FEntryCount := 0;
  ClearKey;
end;

procedure TBaseHashTable.MakeTable(var Table: THashEntries; Count: Cardinal);
//�e�[�u����������
begin
  SetLength(Table,Count);
{ TODO : �s�v�����H }
  //FillChar(Table[0],SizeOf(PHashEntry) * Count,0);
end;

function TBaseHashTable.Insert(Key, Value: Pointer): Boolean;
//�}������
//���݂��Ă����ꍇ��true
var
  entry: PHashEntry;
begin
  Result := Lookup(Key,entry);
  //���݂��Ă���
  if Result then
  begin
    //insert
    FreeEntry(entry^,hoInsert);
    NewEntry(Key,Value,entry^,hoInsert);
  end
  else //���݂��Ă��Ȃ�����
    AddDirect(Key,Value);
end;

function TBaseHashTable.Lookup(Key: Pointer;
  var Entry: PHashEntry; Operation: THashOperation): Boolean;
//�T��
var
  cur,prev: PHashEntry;
  idx: Cardinal;
begin
  Result := False;
  Entry := nil;

  idx := DoHash(Key) mod FSlotCount;
  cur := FEntries[idx];
  prev := nil;

  while Assigned(cur) do
  begin
    //���S��r
    if Compare(Key,cur^.Key) then
    begin
      Result := True;
      Entry := cur;
      //delete�̎��͌q���ς�
      if Operation = hoDelete then
      begin
        //top�����鎞
        if Assigned(prev) then
          prev^.Next := cur^.Next
        else //top���Ȃ��Ƃ�
          FEntries[idx] := cur^.Next;
      end;

      Break;
    end;

    prev := cur;
    cur := cur.Next;
  end;
end;

procedure TBaseHashTable.Rehash;
//slot���𑝂₷

  procedure Sort(NewEntries: THashEntries; NewCount: Cardinal; Entry: PHashEntry);
  //�U�蕪��
  var
    cur,nxt: PHashEntry;
    index: Integer;
  begin
    cur := Entry;
    while Assigned(cur) do
    begin
      nxt := cur^.Next;

      index := DoHash(cur^.Key) mod NewCount;
      cur^.Next := NewEntries[index];
      NewEntries[index] := cur;

      cur := nxt;
    end;
  end;

var
  newent: THashEntries;
  i: Integer;
begin
  FSlotCount := Trunc(FSlotCount * SLOT_EXTEND);
  MakeTable(newent,FSlotCount);

  for i := 0 to Length(FEntries) - 1 do
    Sort(newent,FSlotCount,FEntries[i]);

  //����ւ� 
  FEntries := newent;
end;

procedure TBaseHashTable.FreeEntry(var Entry: THashEntry;
  Operation: THashOperation);
//entry���J������
//�Ē�`����
begin
end;

procedure TBaseHashTable.NewEntry(Key,Value: Pointer;
  var Entry: THashEntry; Operation: THashOperation);
//entry���쐬����
//�Ē�`����
begin
  Entry.Key := Key;
  Entry.Value := Value;
end;

procedure TBaseHashTable.Foreach(var Entry: PHashEntry);
//foreach����������
begin
  FForeachIndex := 0;
  Entry := nil;
end;

function TBaseHashTable.Next(var Entry: PHashEntry): Boolean;
begin
  Result := False;
  while FForeachIndex < FSlotCount do
  begin
    //�Ȃ��ꍇ�͍ŏ�
    if not Assigned(Entry) then
      Entry := FEntries[FForeachIndex]
    else //����ꍇ�͎�
      Entry := Entry^.Next;
    //�Ōォ�ǂ����`�F�b�N
    if Assigned(Entry) then
    begin
      //����
      Result := True;
      Break;
    end
    else //����
      Inc(FForeachIndex);
  end;
end;

procedure TBaseHashTable.AddKey(Key: Pointer);
begin
end;

procedure TBaseHashTable.ClearKey;
begin
end;

procedure TBaseHashTable.DeleteKey(Key: Pointer);
begin
end;

function TBaseHashTable.MoreEntry: PHashEntry;
var
  p: PHashEntryCache;
  i: Integer;
begin
  if Assigned(FFreeEntryList) then
  begin
    Result := FFreeEntryList;
    FFreeEntryList := FFreeEntryList.Next;
  end
  else begin
    New(p);
    p.Next := FEntryCacheList;
    FEntryCacheList := p;

    Result := @p.Entries[0];
    for i := 1 to pred(ENTRY_CACHE) do
    begin
      p.Entries[i].Next := FFreeEntryList;
      FFreeEntryList := @p.Entries[i];
    end;    
  end;
end;

{ TIntegerIntegerHashTable }

function TIntegerIntegerHashTable.GetValue(Key: Integer;
  var Value: Integer): Boolean;
var
  ent: PHashEntry;
begin
  Result := Lookup(Pointer(Key),ent);
  if Result then
    Value := Integer(ent^.Value);
end;

function TIntegerIntegerHashTable.HasKey(Key: Integer): Boolean;
var
  i: Integer;
begin
  Result := GetValue(Key,i);
end;

function TIntegerIntegerHashTable.Remove(Key: Integer): Boolean;
begin
  Result := Delete(Pointer(Key));
end;

function TIntegerIntegerHashTable.SetValue(Key, Value: Integer): Boolean;
begin
  Result := Insert(Pointer(Key),Pointer(Value));
end;

{ TStringIntegerHashTable }

function TStringIntegerHashTable.Compare(Key1, Key2: Pointer): Boolean;
begin
  Result := AnsiSameStr(PString(Key1)^,PString(Key2)^);
end;

function TStringIntegerHashTable.DoHash(Key: Pointer): Cardinal;
begin
  Result := HashCodeB(PString(Key)^);
end;

procedure TStringIntegerHashTable.FreeEntry(var Entry: THashEntry;
  Operation: THashOperation);
begin
  case Operation of
    hoFree:
    begin
      //��������J��
      Dispose(PString(Entry.Key));
    end;
    hoInsert:;
  end;
end;

function TStringIntegerHashTable.GetValue(Key: String;
  var Value: Integer): Boolean;
var
  ent: PHashEntry;
begin
  Result := Lookup(@Key,ent);
  if Result then
    Value := Integer(ent^.Value);
end;

function TStringIntegerHashTable.HasKey(Key: String): Boolean;
var
  i: Integer;
begin
  Result := GetValue(Key,i);
end;

procedure TStringIntegerHashTable.NewEntry(Key, Value: Pointer;
  var Entry: THashEntry; Operation: THashOperation);
begin
  case Operation of
    hoNew:
    begin
      //��������쐬
      New(PString(Entry.Key));
    end;
    hoInsert:;
  end;
  //��������R�s�[
  PString(Entry.Key)^ := PString(Key)^;
  Entry.Value := Value; 
end;

function TStringIntegerHashTable.Remove(Key: String): Boolean;
begin
  Result := Delete(@Key);
end;

function TStringIntegerHashTable.SetValue(Key: String;
  Value: Integer): Boolean;
begin
  Result := Insert(@Key,Pointer(Value));
end;

procedure TStringIntegerHashTable.UpdateKey;
var
  e: PHashEntry;
begin
  if FUpdated then
  begin
    ClearKey;
    Foreach(e);
    while Next(e) do
      FKeyList.Add(PString(e.key)^);
  end;
end;

{ TStringStringHashTable }

function TStringStringHashTable.Compare(Key1, Key2: Pointer): Boolean;
begin
  Result := AnsiSameStr(PString(Key1)^,PString(Key2)^);
end;

function TStringStringHashTable.DoHash(Key: Pointer): Cardinal;
begin
  Result := HashCodeB(PString(Key)^);
end;

procedure TStringStringHashTable.FreeEntry(var Entry: THashEntry;
  Operation: THashOperation);
begin
  case Operation of
    hoFree:
    begin
      //��������J��
      Dispose(PString(Entry.Key));
      Dispose(PString(Entry.Value));
    end;
    hoInsert:;
  end;
end;

function TStringStringHashTable.GetValue(Key: String;
  var Value: String): Boolean;
var
  ent: PHashEntry;
begin
  Result := Lookup(@Key,ent);
  if Result then
    Value := PString(ent^.Value)^;
end;

function TStringStringHashTable.HasKey(Key: String): Boolean;
var
  s: String;
begin
  Result := GetValue(Key,s);
end;

procedure TStringStringHashTable.NewEntry(Key, Value: Pointer;
  var Entry: THashEntry; Operation: THashOperation);
begin
  case Operation of
    hoNew:
    begin
      //��������쐬
      New(PString(Entry.Key));
      New(PString(Entry.Value));
    end;
    hoInsert:;
  end;
  //��������R�s�[
  PString(Entry.Key)^ := PString(Key)^;
  PString(Entry.Value)^ := PString(Value)^;
end;

function TStringStringHashTable.Remove(Key: String): Boolean;
begin
  Result := Delete(@Key);
end;

function TStringStringHashTable.SetValue(Key, Value: String): Boolean;
begin
  Result := Insert(@Key,@Value);
end;

procedure TStringStringHashTable.UpdateKey;
var
  e: PHashEntry;
begin
  if FUpdated then
  begin
    ClearKey;
    Foreach(e);
    while Next(e) do
      FKeyList.Add(PString(e.key)^);
  end;
end;

{ TIntegerStringHashTable }

function TIntegerStringHashTable.Compare(Key1, Key2: Pointer): Boolean;
begin
  Result := Key1 = Key2;
end;

function TIntegerStringHashTable.DoHash(Key: Pointer): Cardinal;
begin
  Result := Cardinal(Key);
end;

procedure TIntegerStringHashTable.FreeEntry(var Entry: THashEntry;
  Operation: THashOperation);
begin
  case Operation of
    hoFree:
    begin
      //��������J��
      Dispose(PString(Entry.Value));
    end;
    hoInsert:;
  end;
end;

function TIntegerStringHashTable.GetValue(Key: Integer;
  var Value: String): Boolean;
var
  ent: PHashEntry;
begin
  Result := Lookup(Pointer(Key),ent);
  if Result then
    Value := PString(ent^.Value)^;
end;

function TIntegerStringHashTable.HasKey(Key: Integer): Boolean;
var
  s: String;
begin
  Result := GetValue(Key,s);
end;

procedure TIntegerStringHashTable.NewEntry(Key, Value: Pointer;
  var Entry: THashEntry; Operation: THashOperation);
begin
  case Operation of
    hoNew:
    begin
      //��������쐬
      New(PString(Entry.Value));
    end;
    hoInsert:;
  end;
  Entry.Key := Key;
  //��������R�s�[
  PString(Entry.Value)^ := PString(Value)^;
end;

function TIntegerStringHashTable.Remove(Key: Integer): Boolean;
begin
  Result := Delete(Pointer(Key));
end;

function TIntegerStringHashTable.SetValue(Key: Integer;
  Value: String): Boolean;
begin
  Result := Insert(Pointer(Key),@Value);
end;

{ TKeyListHashTable }

procedure TKeyListHashTable.AddKey(Key: Pointer);
begin
  FUpdated := True;
end;

procedure TKeyListHashTable.ClearKey;
begin
  FKeyList.Clear;
  FUpdated := False;
end;

constructor TKeyListHashTable.Create;
begin
  inherited Create;
  FKeyList := TStringList.Create;
end;

procedure TKeyListHashTable.DeleteKey(Key: Pointer);
begin
  FUpdated := True;
end;

destructor TKeyListHashTable.Destroy;
begin
  inherited;
  FreeAndNil(FKeyList);
end;

function TKeyListHashTable.GetKeyList: TStringList;
begin
  UpdateKey;
  Result := FKeyList;
end;

function TKeyListHashTable.GetKeys: String;
begin
  UpdateKey;
  Result := TrimRight(FKeyList.Text);
end;

procedure TKeyListHashTable.UpdateKey;
begin
end;



end.
