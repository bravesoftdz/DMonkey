unit dynamiccall;

{
  This code was written by Wolfy.
  Original C code was written by Ton Plooy at 1998.
}

interface

uses
  Windows,Sysutils;

const
  DC_MICROSOFT    = $0000; //MS
  DC_BORLAND      = $0001; //BORLAND
  DC_CALL_CDECL   = $0010; //CDECL
  DC_CALL_STD     = $0020; //STDCALL
  DC_RETVAL_MATH4 = $0100;
  DC_RETVAL_MATH8 = $0200;

  DC_CALL_STD_BO  = DC_CALL_STD + DC_BORLAND;
  DC_CALL_STD_MS  = DC_CALL_STD + DC_MICROSOFT;
  DC_CALL_STD_M8  = DC_CALL_STD + DC_RETVAL_MATH8;

  DC_FLAG_ARGPTR  = $00000002;

type
  PDynaResult = ^TDynaResult;
  TDynaResult = packed record
    case Integer of
      0: (_int: Integer);
      1: (_long: LongInt);
      2: (_pointer: Pointer);
      3: (_float: Single);
      4: (_double: Double);
      5: (_int64: Int64);
  end;

  PDynaParm = ^TDynaParm;
  TDynaParm = packed record
    dwFlags: DWORD;
    nWidth: Integer;
    case Integer of
      0: (dwArg: DWORD);
      1: (pArg: Pointer);
  end;

  PDynaParms = ^TDynaParms;
  TDynaParms = array[0..255] of TDynaParm;
  TDynaParmArray = array of TDynaParm;

  TDynaValueType = (dvtChar,dvtRefChar,dvtShort,dvtRefShort,
                    dvtLong,dvtRefLong,dvtInt64,dvtRefInt64,
                    dvtString,dvtWideString,
                    dvtFloat,dvtDouble,
                    dvtIDispatch,dvtIUnknown,

                    dvtHandle,dvtPointer,dvtUINT,dvtBool);

  TDynaValue = record
    VType: TDynaValueType;
    _idispatch: IDispatch;
    _iunknown: IUnknown;
    _string: String;
    _widestring: WideString;
    case Integer of
      0: (_char: Char);
      1: (_short: SmallInt);
      2: (_long: LongInt);
      3: (_int64: Int64);
      4: (_double: Double);
      5: (_float: Single);
  end;

  TDynaValueArray = array of TDynaValue;

  PDynaDeclare = ^TDynaDeclare;
  TDynaDeclare = record
    ProcAddr: Pointer;  //�֐��̃A�h���X
    Arguments: String; //�����̌^
    Call: String;      //�Ăяo��
    ReturnValue: String;  //�߂�l
  end;
{
 Arguments
   c char(1)
   1 &char(4)
   t short(2)
   2 &short(4)
   l long(4)
   4 &long(4)
   i int64(8)
   8 &int64(4)

   u uint(4)
   p pointer(4)
   h handle(4)
   b bool(4)

   s string(4)
   w widestring(4)

   f float(4)
   d double(8)

   a IDispatch(4)
   k IUnknown(4)
 Call
   m Microsoft
   b Borland
   s stdcall
   c cdecl
   4 4byte
   8 8byte
}  



function DynaCall(Flags: Integer; lpFunction: Pointer;
  nArgs: Integer; Parm: PDynaParms;
  pRet: Pointer; nRetSize: Integer): TDynaResult; overload;

function DynaCall(Flags: Integer; lpFunction: Pointer;
  Parm: TDynaParmArray;
  pRet: Pointer; nRetSize: Integer): TDynaResult; overload;

function SearchProcAddress(hModule: HINST; ProcName: String): Pointer;


procedure ClearDynaResult(var Res: TDynaResult);
procedure ClearDynaDeclare(var Decl: TDynaDeclare);
procedure ClearDynaValue(var Value: TDynaValue);

function ParseDynaDeclare(Flags: array of String): TDynaDeclare;

function MakeCallFlags(Flags: String): Integer;
function DynaValueArrayToDynaParmArray(Values: TDynaValueArray): TDynaParmArray;

implementation

function SearchProcAddress(hModule: HINST; ProcName: String): Pointer;
//�֐��A�h���X��T�� ���݂��Ȃ��ꍇ��A��t���Ă݂�
begin
  Result := GetProcAddress(hModule,PChar(ProcName));
  if not Assigned(Result) then
    Result := GetProcAddress(hModule,PChar(ProcName + 'A'));
end;   

function DynaCall(Flags: Integer; lpFunction: Pointer;
  nArgs: Integer; Parm: PDynaParms; pRet: Pointer; nRetSize: Integer): TDynaResult;
//�w�肳�ꂽ�֐���^����ꂽ�����ŌĂяo���B
//�K�؂ȃX�^�b�N���\�z���A�������߂�l�̏������s���B
{ TODO : �����̌Ăяo�������܂������ĂȂ� }
var
  Res: TDynaResult;
  i,nInd,nSize: Integer;
  dwEAX,dwEDX,dwVal,dwStSize: DWORD;
  pStack: PDWORD;
  pArg: PBYTE;
begin
  ClearDynaResult(Res);
  dwEAX := 0;
  dwEDX := 0;
  //dwVal := 0;
  dwStSize := 0;
  pStack := nil;
  //pArg := nil;

  //�����̂��߂�256�o�C�g�̃X�^�b�N��Ԃ𗠕Ԃ�
  asm
    mov pStack,esp
    sub esp,$100
  end;

  //�������X�^�b�N�ɐς݁A���ׂĂ̈�����4�o�C�g���E�ɐ��񂳂���
  //�E�[�̈�������n�߂�
  for i := 0 to nArgs - 1 do
  begin
    nInd := (nArgs - 1) - i;
    //�����|�C���^�̃u���b�N����n�߂� DWORD�ɐ��񂵂Ă���
    nSize := (Parm[nInd].nWidth + 3) div 4 * 4;
    pArg := PBYTE(Integer(Parm[nInd].pArg) + nSize - 4);
    dwStSize := dwStSize + DWORD(nSize); //�X�^�b�N��ł̃o�C�g���𐔂���
    while nSize > 0 do
    begin
      //�������X�^�b�N�ɃR�s�[����
      if (Parm[nInd].dwFlags and DC_FLAG_ARGPTR) <> 0 then
      begin
        //Arg�͈��������ϐ��ւ̃|�C���^
        dwVal := PDWORD(pArg)^; //�ŏ���4�o�C�g�𓾂�
        pArg := PBYTE(Integer(pArg) - 4); //�����̎��̕���
      end
      else //Arg�ɂ͎��ۂ̈����������Ă���
        dwVal := Parm[nInd].dwArg;
      //dwVal���X�^�b�N�ɐς�
      Dec(pStack);
      pStack^ := dwVal;
      nSize := nSize - 4;
    end;
  end;

  if ((pRet <> nil) and (((Flags and DC_BORLAND) <> 0) or (nRetSize > 8))) then
  begin
    //�߂�l�̓��W�X�^�o�R�œn����Ȃ�
    dwStSize := dwStSize + 4;
    Dec(pStack);
    pStack^ := DWORD(pRet);
  end;

  asm
    add esp,$100         //���̈ʒu�ɖ߂�
    sub esp,dwStSize

    call [lpFunction]

    mov dwEAX,eax
    mov dwEDX,edx
  end;

  //�ꍇ�ɂ���Ă̓X�^�b�N�̒��߂�����
  if (Flags and DC_CALL_CDECL) <> 0 then
    asm
      add esp,dwStSize
    end;

  if (Flags and DC_RETVAL_MATH4) <> 0 then
  begin
    asm
      fstp dword ptr [Res]
    end;
  end
  else if (Flags and DC_RETVAL_MATH8) <> 0 then
  begin
    asm
      fstp qword ptr [Res]
    end;
  end
  else if (pRet = nil) then
  begin
    asm
      mov eax,[dwEAX]
      mov DWORD PTR [Res],eax
      mov edx,[dwEDX]
      mov DWORD PTR [Res + 4],edx
    end;
  end
  else if (((Flags and DC_BORLAND) = 0) and (nRetSize <= 8)) then
  begin
    //Microsoft��8�o�C�g�ȉ��̍\���̓n�����œK������
    asm
      mov ecx,DWORD PTR [pRet]
      mov eax,[dwEAX]
      mov DWORD PTR [ecx],eax
      mov edx,[dwEDX]
      mov DWORD PTR [ecx + 4],edx
    end;
  end;

  Result := Res;
end;

function DynaCall(Flags: Integer; lpFunction: Pointer;
  Parm: TDynaParmArray;
  pRet: Pointer; nRetSize: Integer): TDynaResult;
//���I�z��ŌĂяo��
var
  p: PDynaParms;
  i,len: Integer;
begin
  len := Length(Parm);
  //����������ꍇ�Ɋm��
  if len > 0 then
    GetMem(p,len * SizeOf(TDynaParm))
  else
    p := nil;

  try
    //�R�s�[
    for i := 0 to len - 1 do
      p^[i] := Parm[i];
    //�Ăяo��
    Result := DynaCall(Flags,lpFunction,len,p,pRet,nRetSize);
  finally
    if Assigned(p) then
      FreeMem(p);
  end;
end;


procedure ClearDynaResult(var Res: TDynaResult);
//Result���N���A����
begin
  FillChar(Res,SizeOf(Res),0);
end;

procedure ClearDynaDeclare(var Decl: TDynaDeclare);
begin
  Decl.Arguments := '';
  Decl.Call := '';
  Decl.ReturnValue := '';
  //Decl.FunctionName := '';
  //Decl.LibraryName := '';
  Decl.ProcAddr := nil;
end;

procedure ClearDynaValue(var Value: TDynaValue);
begin
  Value._idispatch := nil;
  Value._iunknown := nil;
  Value._string := '';
  Value._widestring := '';
  Value._int64 := 0;
end;

function ParseDynaDeclare(Flags: array of String): TDynaDeclare;
//�錾�����
//�֐��A�h���X�͂܂��擾���Ȃ�
var
  i: Integer;
begin
  ClearDynaDeclare(Result);
  for i := 0 to Length(Flags) - 1 do
  begin
    Flags[i] := LowerCase(Flags[i]);

    if Pos('i=',Flags[i]) = 1 then
      Result.Arguments := Copy(Flags[i],3,MaxInt)
    else if Pos('f=',Flags[i]) = 1 then
      Result.Call := Copy(Flags[i],3,MaxInt)
    else if Pos('r=',Flags[i]) = 1 then
      Result.ReturnValue := Copy(Flags[i],3,MaxInt);
  end;
end;

function MakeCallFlags(Flags: String): Integer;
//�Ăяo���t���O���쐬
var
  i,len: Integer;
begin
  len := Length(Flags);
  if len > 0 then
  begin
    Result := 0;
    Flags := LowerCase(Flags);

    for i := 1 to len do
      case Flags[i] of
        'm': Inc(Result,DC_MICROSOFT);
        'b': Inc(Result,DC_BORLAND);
        's': Inc(Result,DC_CALL_STD);
        'c': Inc(Result,DC_CALL_CDECL);
        '4': Inc(Result,DC_RETVAL_MATH4);
        '8': Inc(Result,DC_RETVAL_MATH8);
      end;
  end
  else //�w��̂Ȃ��ꍇ��stdcall
    Result := DC_CALL_STD;
end;

function DynaValueArrayToDynaParmArray(Values: TDynaValueArray): TDynaParmArray;
//�ϊ�����
//������Ȃǂ̎Q�ƃJ�E���g�ɒ���
//Result���g�p����Ƃ���Values�����݂��Ă��Ȃ��ƃ_��
var
  i,len: Integer;
begin
  len := Length(Values);
  if len > 0 then
  begin
    SetLength(Result,len);
    for i := 0 to len - 1 do
    begin
      case Values[i].VType of
        dvtChar:
        begin
          Result[i].nWidth := SizeOf(Char);
          Result[i].dwArg := Cardinal(Values[i]._char);
        end;

        dvtRefChar:
        begin
          Result[i].nWidth := SizeOf(PChar);
          Result[i].pArg := @Values[i]._char;
        end;

        dvtShort:
        begin
          Result[i].nWidth := SizeOf(SmallInt);
          Result[i].dwArg := Cardinal(Values[i]._short);
        end;

        dvtRefShort:
        begin
          Result[i].nWidth := SizeOf(PSmallInt);
          Result[i].pArg := @Values[i]._short;
        end;

        dvtLong,dvtHandle,dvtUINT,dvtPointer,dvtBool:
        begin
          Result[i].nWidth := SizeOf(LongInt);
          Result[i].dwArg := Cardinal(Values[i]._long);
        end;

        dvtRefLong:
        begin
          Result[i].nWidth := SizeOf(PLongInt);
          Result[i].pArg := @Values[i]._long;
        end;

        dvtInt64:
        begin
          Result[i].nWidth := SizeOf(Int64);
          Result[i].dwFlags := DC_FLAG_ARGPTR;
          Result[i].pArg := @Values[i]._int64;
        end;

        dvtRefInt64:
        begin
          Result[i].nWidth := SizeOf(PInt64);
          Result[i].pArg := @Values[i]._int64;
        end;

        dvtIDispatch:
        begin
          Result[i].nWidth := SizeOf(IDispatch);
          Result[i].dwArg := Cardinal(Values[i]._idispatch);
        end;

        dvtIUnknown:
        begin
          Result[i].nWidth := SizeOf(IUnknown);
          Result[i].dwArg := Cardinal(Values[i]._iunknown);
        end;

        dvtString:
        begin
          Result[i].nWidth := SizeOf(PChar);
          Result[i].pArg := PChar(Values[i]._string);
        end;

        dvtWideString:
        begin
          Result[i].nWidth := SizeOf(PWideChar);
          Result[i].pArg := PWideChar(Values[i]._widestring);
        end; 

        dvtFloat:
        begin
          Result[i].nWidth := SizeOf(Single);
          //Result[i].dwFlags := DC_FLAG_ARGPTR;
          //Result[i].pArg := @Values[i].f;
          Result[i].pArg := Pointer(Values[i]._float);
        end;

        dvtDouble:
        begin
          Result[i].nWidth := SizeOf(Double);
          Result[i].dwFlags := DC_FLAG_ARGPTR;
          Result[i].pArg := @Values[i]._double;
        end;
      end;
    end;
  end
  else
    Result := nil;
end;   

end.
