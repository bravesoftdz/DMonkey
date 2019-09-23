program dm;
{$APPTYPE CONSOLE}

//�R���\�[��
//2001/04/30
//Wolfy

{..$UNDEF MemCheckStackTrace}

uses
{$IFDEF MemCheckStackTrace}
  memcheck,
{$ENDIF}
  windows,
  sysutils,
  _dm_main,
  activex;

{$IFDEF MemCheckStackTrace}
procedure GetExceptInfoFunc(Obj: TObject;
  var Message: string; var ExceptionRecord: PExceptionRecord);
begin
  if Obj is Exception then
  begin
    Message := Exception(Obj).Message;
    if Obj is EExternal then
      ExceptionRecord := EExternal(Obj).ExceptionRecord;
  end;
end;

procedure SetExceptMessageFunc(Obj: TObject; const NewMessage: string);
begin
  if Obj is Exception then
    Exception(Obj).Message := NewMessage;
end;
{$ENDIF}

var
  main: TDMMain;
begin
{$IFDEF MemCheckStackTrace}
  // ��O�n���h�����C���X�g�[��
  // �Ȃ� MemCheck ���j�b�g���ł��Ȃ����Ƃ����ƁAMemCheck ���j�b�g��
  // SysUtils ���j�b�g������Ƀ����N�����K�v�����邽�߁B
  MemCheckInstallExceptionHandler(GetExceptInfoFunc, SetExceptMessageFunc);
{$ENDIF}
  OleInitialize(nil);
  try
    main := TDMMain.Create;
    try try
      main.Run;
    finally
      main.Free;
    end;
    except
      on E:Exception do
      begin
        writeln(e.ClassName + ': ' + e.Message);
        readln;
      end;
    end;
    //readln;
  finally
    OleUninitialize;
  end;
end.
