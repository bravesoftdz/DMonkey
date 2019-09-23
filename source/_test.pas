unit _test;

interface

uses
  Windows, Messages, SysUtils, Classes,
  ecma_type,ecma_object;

type
  //TJObject���p�����܂�
  TTestObject = class(TJObject) 
  private
    FCells: array[0..10] of array[0..10] of String;
    FDate: TJDateObject;      
    function GetApplicationFilename: String;
    //���\�b�h�� TJMethod�^�ł���K�v������܂�
    function DoAdd(Param: TJValueList): TJValue;
    function DoCells(Param: TJValueList): TJValue;
  protected
    procedure Notification(AObject: TJNotify); override;
  public
    constructor Create(AEngine: TJBaseEngine; Param: TJValueList; RegisteringFactory: Boolean = True); override;
    destructor Destroy; override;
  published
    //property��published�ɐݒ肵�܂�
    property applicationFilename: String read GetApplicationFilename;
    property date: TJDateObject read FDate;
  end;   

implementation

{ TTestObject }

constructor TTestObject.Create(AEngine: TJBaseEngine;
  Param: TJValueList; RegisteringFactory: Boolean);
begin
  inherited;
  //object�̖��O��ݒ肵�܂�
  RegistName('Test');
  //���\�b�h��o�^���܂�
  RegistMethod('add',DoAdd);
  RegistMethod('Cells',DoCells);

  //Date Object���쐬���܂�
  //��RegisteringFactory��False�ɂ���Factory�ɓo�^���Ȃ�
  FDate := TJDateObject.Create(AEngine,nil,False);
  {�܂��́A�o�^����ꍇ�ɂ͏I���ʒm���󂯂�
  FDate := TJDateObject.Create(AEngine);
  FDate.FreeNotification(Self);
  }
  //�Q�ƃJ�E���g�𑝂₷
  FDate.IncRef;    
end;

procedure TTestObject.Notification(AObject: TJNotify);
//�I���ʒm���󂯂�
begin
  inherited;
  {�I���ʒm���󂯂��ꍇ��FDate��nil�ɂ���
  if AObject = FDate then
    FDate := nil;
  }
end;

destructor TTestObject.Destroy;
begin
  //�Q�ƃJ�E���g�����炷(����͂��Ȃ�)
  FDate.DecRef;
  {�I���ʒm���󂯂��ꍇ��FDate��nil�ɂȂ��Ă���\��������
  if Assigned(FDate) then
    FDate.DecRef;
  }
  inherited;
end;

function TTestObject.DoAdd(Param: TJValueList): TJValue;
var
  v: TJValue;
  i,ret: Integer;
begin
  //�S�Ă̈��������Z����
  ret := 0;
  if IsParam1(Param) then
    for i := 0 to Param.Count - 1 do
    begin
      v := Param[i];
      //TJValue�𐮐��ɕϊ����ĉ��Z
      Inc(ret,AsInteger(@v));
    end;
  //������TJValue�ɕϊ�����
  Result := BuildInteger(ret);
end;

function TTestObject.DoCells(Param: TJValueList): TJValue;
var
  row,col: Integer;
  v: TJValue;
begin
  EmptyValue(Result);
  //�������`�F�b�N
  if IsParam2(Param) then
  begin
    v := Param[0];
    row := AsInteger(@v);
    v := Param[1];
    col := AsInteger(@v);
    //���������΃Z�b�g����
    if IsParam3(Param) then
    begin
      //setter
      Result := Param[2];
      FCells[row][col] := AsString(@Result);
    end
    else begin
      //getter
      //s := Format('%s(%d,%d) = %s',['Cells',row,col,FCells[row][col]]);
      Result := BuildString(FCells[row][col]);
    end;
  end;
end;

function TTestObject.GetApplicationFilename: String;
begin
  //���ʂɕ������Ԃ���TJValue�ɕϊ�����܂�
  Result := ParamStr(0);
end;




end.
