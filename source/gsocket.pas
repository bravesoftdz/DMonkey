unit gSocket;
{
 TgSocket: Socket��{�N���X 
   Author: Wolfy
 Modified: 00/05/10
  Version: 0.00
}

{..$DEFINE READLN_OLD}

interface

uses
  Windows,SysUtils,Classes,SyncObjs,gSocketMisc,messages
{$IFDEF WS2}
  ,winsock2;
{$ELSE}
  ,Winsock;
{$ENDIF}

var
  WSAData: TWSAData;
  gSockStartup: Boolean;
  WinSockVersion: String;
  WinsockDescription: String;
  WinsockSystemStatus: String;

const
  Status_None = 0;
  Status_Informational = 1;
  Status_Basic = 2;
  Status_Routines = 4;
  Status_Debug = 8;
  Status_Trace = 16;
  BUFFER_SIZE = 4096 * 16;

type
  {��O���`}
  //��� ��������S�Ĕh������
  EgSocket = class(Exception);

  ESocketError = class(EgSocket)
  private
    FErrorNo: Word;
  public
    constructor Create(Number: Word);
    property ErrorNo: Word read FErrorNo;
  end;

  EProtocolError = class(EgSocket)
  private
    FStatusNo: Word;
    FProtocol: String;
    FStatusMsg: String;
  public
    constructor Create(const Proto,Msg: String; Number: Word);
    property StatusNo: Word read FStatusNo;
    property StatusMsg: String read FStatusMsg;
    property Protocol: String read FProtocol;
  end;

  ETCPIPError = class(EgSocket)
  private
    FIPAddress: u_long;
  public
{$IFDEF WS2}
    constructor Create(const Msg: String; IP: Integer);
{$ELSE}
    constructor Create(const Msg: String; IP: u_long);
{$ENDIF}
    property IPAddress: u_long read FIPAddress;
  end;


  ESocketTimeout = class(EgSocket);
  ESocketCancel = class(EgSocket);
  EProtocolBusy = class(EgSocket);
  ELocalError = class(EgSocket);
  EBindError = class(EgSocket);

  //Event
  THandlerEvent = procedure(var Handled: Boolean) of object;
  TOnErrorEvent = procedure(Sender: TObject; Errno: Word; Errmsg: String) of object;
  TOnStatus = procedure(Sender: TObject; const Status: String) of object;
  TOnPacketEvent = procedure(Sender: TObject; Bytes: Integer; var DoStop: Boolean) of object;
  TAcceptEvent =
    procedure(Sender: TObject; Socket: TSocket; SockAddrIn: TSockAddrIn) of object;
  TSocketEvent = procedure(Sender: TObject; Socket: TSocket) of object;
  TSelectTimeoutEvent = procedure(Sender: TObject; var DoStop: Boolean) of object;


  TIdleType = (itRead,itWrite,itError);
  TIdleSet = set of TIdleType;

  //���socket�N���X
  TgSocket = class(TObject)
  private     

  protected
    //property
    FBeenCanceled: Boolean;
    FBeenTimeout: Boolean;
    FBytesRecvd: Int64;
    FBytesSent: Int64;
    FBytesTotal: Int64;
    FConnected: Boolean;
    FSocket: TSocket;
    FHost: String;
    FLastErrorNo: Integer;
    FPort: Word;
    FProxy: String;
    //FProxyPort: Word;
    FRemoteIP: String;
    FStatusNo: Integer;
    FReportLevel: Integer;
    FStatus: String;
    FTimeout: Integer;
    FTransActionReply: String;
    //FWSAInfo: TStringList;
    //misc
    FIPAddress: u_long;
    FBuffer: Pointer;
    FBufferSize: LongInt;
    FLock: TCriticalSection;
    FStream: TStream;
    //end of socket �� recv�݂̂ɐݒ肷��B send�͊֌W�Ȃ�
    FEOS: Boolean;
    FSendStream: TMemoryStream;
    FSockAddrIn: TSockAddrIn;
    //FRemoteAddrIn: TSockAddrIn;
    FBinded: Boolean;
    FOpenPort: Word;

    //Event
    FOnConnect: TNotifyEvent;
    FOnConnectionFailed: TNotifyEvent;
    FOnConnectionRequired: THandlerEvent;
    FOnDisconnect: TNotifyEvent;
    FOnError: TOnErrorEvent;
    FOnHostResolved: TNotifyEvent;
    FOnInvalidHost: THandlerEvent;
    FOnPacketRecvd: TOnPacketEvent;
    FOnPacketSent: TOnPacketEvent;
    FOnRead: TNotifyEvent;
    FOnStatus: TOnStatus;
    FOnAccept: TAcceptEvent;
    FOnSelectTimeout: TSelectTimeoutEvent;

    function GetConnected: Boolean;
    function GetLocalIP: String;
    function GetRemoteIP: String;
    function GetRemotePort: String;
    procedure Startup; virtual;
    procedure Cleanup; virtual;
    procedure Report(const S: String; Level: Integer); virtual;
    procedure ConnectSocket(var Socket: TSocket; OpenPort: u_short; IP: u_long);
    procedure CloseSocket(var Socket:TSocket);
    function CreateSocket: TSocket;
    procedure BindSocket(var Socket: TSocket; Offset, Range: Word; var BindPort: u_short); overload;
    procedure BindSocket(var Socket: TSocket; BindPort: Word); overload;
    function AcceptSocket(var Socket:TSocket): TSocket;
    function SocketState(var Socket:TSocket): TSocketState;
    function EOS(var Socket:TSocket): Boolean; virtual;
    function ReadBuffer(var Socket: TSocket; var Buf; Size: Integer): Integer;
    function PeekBuffer(var Socket: TSocket; var Buf; Size: Integer): Integer;
    function WriteBuffer(var Socket:TSocket; var Buf; Size: Integer): Integer;

    procedure CaptureFromSocket(var Socket: TSocket; Stream: TStream; Size, Position: Integer);
    procedure SendToSocket(var Socket: TSocket; Stream: TStream; Size,Position: Integer);
    function ReadLnFromSocket(var Socket: TSocket): String;
    procedure SetEndOfSocket(var Socket: TSocket; Value: Boolean); virtual;
    procedure ConnectHost(const HostName: String; OpenPort: u_short);
    function Idle: TIdleSet; virtual;
    function ReadVar(var Buf; Size: Integer): Integer; virtual;

  public
    constructor Create(BufferSize: Integer = BUFFER_SIZE); virtual;
    constructor CreateFromServer(Socket: TSocket; BufferSize: Integer = BUFFER_SIZE);
    destructor Destroy; override;

    procedure Abort; virtual;
    function Accept: TSocket; virtual;
    procedure Bind; virtual;
    procedure Cancel; virtual;
    procedure CaptureFile(const FileName: String); virtual;
    procedure CaptureStream(Stream: TStream; Size: Integer); virtual;
    procedure CaptureString(var S: String; Size: Integer); virtual;
    procedure CertifyConnect; virtual;
    procedure Connect; virtual;
    procedure Disconnect; virtual;
    procedure FilterHeader(FileStream: TFileStream); virtual;
    function GetLocalAddress: String; virtual;
    function GetLocalPortString: String; virtual;
    procedure Listen; virtual;
    function Read(Value: Integer): String; virtual;
    function ReadLn: String; virtual;
    procedure RequestCloseSocket;
    procedure SendBuffer(Value: PChar; BufLen: Integer);
    procedure SendFile(const FileName: String);
    procedure SendStream(Stream: TStream);
    function TransAction(const CommandString: String): String; virtual;
    procedure Write(const S: String);
    procedure WriteLn(const S: String);
    procedure DoCommand(const CommandStr: String; Dummy: Boolean = False); virtual;
    function ResultCommand: String; virtual;

    property BeenCanceled: Boolean read FBeenCanceled;
    property BeenTimeout: Boolean read FBeenTimeout;
    property Binded: Boolean read FBinded;
    property BytesRecvd: Int64 read FBytesRecvd;
    property BytesSent: Int64 read FBytesSent;
    property BytesTotal: Int64 read FBytesTotal;
    property Connected: Boolean read GetConnected;
    property Handle: TSocket read FSocket;
    property Host: String read FHost write FHost;
    property LastErrorNo: Integer read FLastErrorNo;
    property LocalIP: String read GetLocalIP;
    property Port: Word read FPort write FPort;
    property Proxy: String read FProxy write FProxy;
    //property ProxyPort: Word read FProxyPort write FProxyPort;
    property RemoteIP: String read GetRemoteIP;
    property ReplyNumber: Integer read FStatusNo;
    property StatusNo: Integer read FStatusNo;
    property ReportLevel: Integer read FReportLevel write FReportLevel;
    property Status: String read FStatus;
    property Timeout: Integer read FTimeout write FTimeout;
    property TransActionReply: String read FTransActionReply;
    //property WSAInfo: TStringList read FWSAInfo;

    //Event
    property OnConnect: TNotifyEvent read FOnConnect write FOnConnect;
    property OnConnectionFailed: TNotifyEvent read FOnConnectionFailed write FOnConnectionFailed;
    property OnConnectionRequired: THandlerEvent read FOnConnectionRequired write FOnConnectionRequired;
    property OnDisconnect: TNotifyEvent read FOnDisconnect write FOnDisconnect;
    property OnError: TOnErrorEvent read FOnError write FOnError;
    property OnHostResolved: TNotifyEvent read FOnHostResolved write FOnHostResolved;
    property OnInvalidHost: THandlerEvent read FOnInvalidHost write FOnInvalidHost;
    property OnPacketRecvd: TOnPacketEvent read FOnPacketRecvd write FOnPacketRecvd;
    property OnPacketSent: TOnPacketEvent read FOnPacketSent write FOnPacketSent;
    property OnRead: TNotifyEvent read FOnRead write FOnRead;
    property OnStatus: TOnStatus read FOnStatus write FOnStatus;
    property OnAccept: TAcceptEvent read FOnAccept write FOnAccept;
    property OnSelectTimeout: TSelectTimeoutEvent read FOnSelectTimeout write FOnSelectTimeout;
  end;

  TgSocket2 = class(TgSocket)
  public
    procedure DoCommand(const CommandStr: String; Dummy: Boolean = False); override;
    function ResultCommand: String; override;
    function Idle: TIdleSet; override;
  end;


implementation

procedure WinsockInitialize;
//winsock�J�n
var
  r: Integer;
begin
  gSockStartup := False;
  r := WSAStartup(MAKEWORD(2,2),WSAData);
  if r <> 0 then
    r := WSAStartup(MAKEWORD(2,0),WSAData);

  if r <> 0 then
    r := WSAStartup(MAKEWORD(1,1),WSAData);

  if r = 0 then
  begin
    gSockStartup := True;
    WinsockVersion := IntToStr(LOBYTE(WSAData.wVersion)) + '.' +
        IntToStr(HIBYTE(WSAData.wVersion));
    WinsockDescription := WSAData.szDescription;
    WinsockSystemStatus := WSAData.szSystemStatus;
  end
  else
    gSockStartup := False;
end;

procedure WinsockCleanup;
//winsock�I��
begin
  if gSockStartup then
  begin
    //Winsock.WSACancelBlockingCall;
    WSACleanup;
  end;
end;


{ ESocketError }

constructor ESocketError.Create(Number: Word);
begin
  inherited Create('socket error no.' + IntToStr(Number));
  FErrorNo := Number;
end;

{ EProtocolError }

constructor EProtocolError.Create(const Proto, Msg: String; Number: Word);
begin
  inherited Create(Msg);
  FStatusNo := Number;
  FStatusMsg := Msg;
  FProtocol := Proto;
end;

{ ETCPIPError }

{$IFDEF WS2}
constructor ETCPIPError.Create(const Msg: String; IP: Integer);
begin
  inherited Create(Msg);
  FIPAddress := IP;
end;
{$ELSE}
constructor ETCPIPError.Create(const Msg: String; IP: u_long);
begin
  inherited Create(Msg);
  FIPAddress := IP;
end;
{$ENDIF}



{ TgSocket }

procedure TgSocket.Abort;
begin
//������
//  Report('trc>TgSocket.Abort',Status_Trace);
  Cancel;
end;

function TgSocket.Accept: TSocket;
//accept
begin
//  Report('trc>TgSocket.Accept',Status_Trace);

  Result := AcceptSocket(FSocket);
  //if Result = INVALID_SOCKET then
  //  raise ESocketError.Create(WSAGetLastError); 
end;

function TgSocket.AcceptSocket(var Socket: TSocket): TSocket;
//�A�Z�v�g ���s���Ă���O���o���Ȃ�
var
{$IFDEF WS2}
  Size: Integer;
{$ELSE}
  Size: u_int;
{$ENDIF}
begin
//  Report('trc>TgSocket.AcceptSocket',Status_Trace);

  Report('rtn>accept���J�n���܂�',Status_Routines);
  Size := SizeOf(FSockAddrIn);
{$IFDEF WS2}
  Result := winsock2.accept(Socket,FSockAddrIn,Size);
{$ELSE}
  Result := winsock.accept(Socket,@FSockAddrIn,@Size);
{$ENDIF}
  if Result = TSocket(SOCKET_ERROR) then
  begin
    Result := INVALID_SOCKET;
    Report('err>accept�Ɏ��s���܂���',Status_Basic);
  end
  else begin
    Report('suc>accept�ɐ������܂���',Status_Routines);
    Report('dbg>socket(' + IntToStr(Result) + ')���󂯎��܂���',Status_Debug);
    //event
    if Assigned(FOnAccept) then FOnAccept(Self,Result,FSockAddrIn);
  end;
end;

procedure TgSocket.BindSocket(var Socket: TSocket; Offset, Range: Word;
  var BindPort: u_short);
//bind & Listen
var
  SockAddr : TSockAddr;
  i: Integer;
  Rnd: Word;
begin
//  Report('trc>TgSocket.BindSocket',Status_Trace);

  Report('rtn>port ' + IntToStr(Offset) + '�`' + IntToStr(Offset + Range) +
    '�͈̔͂�bind���J�n���܂�',Status_Routines);
  with SockAddr do
  begin
    Sin_Family := AF_INET;
    Sin_addr.S_addr := INADDR_ANY;
  end;
  //BIND��port�������_���Ɍ��߂�
  for i := 0 to Range - 1 do
  begin
    Rnd := Offset + Random(Range);
    SockAddr.Sin_Port := htons(Rnd);
{$IFDEF WS2}
    if winsock2.bind(Socket,@SockAddr,SizeOf(SockAddr)) <> SOCKET_ERROR then
{$ELSE}
    if winsock.bind(Socket,SockAddr,SizeOf(SockAddr)) <> SOCKET_ERROR then
{$ENDIF}
    begin
      BindPort := Rnd;
      Report('suc>port ' + IntToStr(Rnd) + '��bind�������܂���',Status_Routines);
      Break;
    end
    else begin
      Report('err>port ' + IntToStr(Rnd) + '��bind���s���܂���',Status_Basic);
      Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
    end;
  end;

  Report('rtn>listen���J�n���܂�',Status_Routines);
{$IFDEF WS2}
  if Winsock2.listen(Socket,SOMAXCONN) = SOCKET_ERROR then
{$ELSE}
  if Winsock.listen(Socket,SOMAXCONN) = SOCKET_ERROR then
{$ENDIF}
  begin
    FLastErrorNo := WSAGetLastError;
    Report('err>listen���s���܂���',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);

    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise EBindError.Create(ErrorToStr(WSAGetLastError));
  end
  else
    Report('suc>listen�������܂���',Status_Routines);

end;

procedure TgSocket.Cancel;
begin
//  Report('trc>TgSocket.Cancel',Status_Trace);

  FBeenCanceled := True;
  Report('rtn>cancel���܂�',Status_Routines);
  if FConnected then Disconnect;

  raise ESocketCancel.Create('cancel');
end;

procedure TgSocket.CaptureFromSocket(var Socket: TSocket; Stream: TStream;
  Size, Position: Integer);
//stream��socket�f�[�^��ߑ�
//repeat until �̏ꍇ�ڑ�����Ă��Ȃ��ꍇ�ɗ�O���N����
//while �̏ꍇ �ڑ�����Ă��Ȃ��ꍇ�ɂ͂Ȃɂ��N����Ȃ�
var
  rr: Integer;
begin
//  Report('trc>TgSocket.CaptureFromScoket',Status_Trace);

  Stream.Position := Position;
  //������
  if Size = -1 then
    repeat
      rr := ReadBuffer(Socket,FBuffer^,FBufferSize);
      if rr > 0 then
        Stream.WriteBuffer(FBuffer^,rr);

    until EOS(Socket)
  else
    repeat
      if Size > FBufferSize then
        rr := ReadBuffer(Socket,FBuffer^,FBufferSize)
      else 
        rr := ReadBuffer(Socket,FBuffer^,Size);

      if rr > 0 then
      begin
        Stream.WriteBuffer(FBuffer^,rr);
        //0�ȉ��ɂȂ�����I��
        Dec(Size,rr);
      end;
    until EOS(Socket) or (Size <= 0); 
end;


procedure TgSocket.CaptureFile(const FileName: String);
//capture���ăt�@�C���ɕۑ� �t�@�C���͐V�K
var
  FS: TFileStream;
begin
//  Report('trc>TgSocket.CaptureFile',Status_Trace);

  //���݂��Ȃ���΍쐬
  if not FileExists(FileName) then
    FS := TFileStream.Create(FileName,fmCreate or fmShareDenyWrite)
  else
    FS := TFileStream.Create(FileName,fmOpenWrite or fmShareDenyWrite);

  try
    //�ŏ�����
    FS.Size := 0;
    CaptureFromSocket(FSocket,FS,-1,0);
  finally
    FS.Free;
  end;
end;

procedure TgSocket.CaptureStream(Stream: TStream; Size: Integer);
//socket stream��ߑ����� x stream�̍Ō�ɒǉ�����
//straem�̈ʒu�͈ړ����Ȃ�
begin
//  Report('trc>TgSocket.CaptureStream',Status_Trace);

  //Stream.Seek(0,soFromEnd);
  CaptureFromSocket(FSocket,Stream,Size,Stream.Position);
end;

procedure TgSocket.CaptureString(var S: String; Size: Integer);
//socket ��ߑ����� S�̍Ō�ɒǉ�����
var
  SS: TStringStream;
  DataS: String;
begin
//  Report('trc>TgSocket.CaptureString',Status_Trace);

  SS := TStringStream.Create(DataS);
  try
    SS.Seek(0,soFromEnd);
    CaptureFromSocket(FSocket,SS,Size,SS.Position);
    S := S + SS.DataString;
  finally
    SS.Free;
  end;
end;

procedure TgSocket.CertifyConnect;
//�ڑ�����Ă��邩�`�F�b�N
var
  h: Boolean;
begin
//  Report('trc>TgSocket.CertifyConnect',Status_Trace);

  h := False;
  if (not FConnected) and Assigned(FOnConnectionRequired) then
    FOnConnectionRequired(h);
  //h = true �Ȃ��
  if h then
    Connect
  else begin
    FLastErrorNo := WSAGetLastError;
    
    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ETCPIPError.Create('not connected',FIPAddress);
  end;
end;

procedure TgSocket.Cleanup;
//�I��
begin
  if FConnected then
    Disconnect;

  if Assigned(FBuffer) then
    FreeMem(FBuffer);
end;

procedure TgSocket.CloseSocket(var Socket: TSocket);
//�\�P�b�g�N���[�Y
begin
//  Report('trc>TgSocket.CloseSocket',Status_Trace);

  //�\�P�b�g�������Ă����
  if Socket <> INVALID_SOCKET then
  begin
    Report('rtn>socket(' + IntToStr(Socket) + ')��close���܂�',Status_Routines);
    //Winsock.WSACancelBlockingCall;
    //Winsock.shutdown(Socket,2);
{$IFDEF WS2}
    winsock2.closesocket(Socket);
{$ELSE}
    winsock.closesocket(Socket);
{$ENDIF}
    Socket := INVALID_SOCKET;
  end;
end;

procedure TgSocket.ConnectHost(const HostName: String; OpenPort: u_short);
//socket�쐬���Đڑ�
var
  Handled: Boolean;
  Count: Integer;
begin
//  Report('trc>TgSocket.ConnectHost',Status_Trace);

  Handled := False;
  Count := 0;
  if FConnected then Disconnect;

  repeat
    Report('rtn>' + HostName + '��T���Ă��܂�',Status_Routines);
    FIPAddress := LookupHostname(HostName);
    if FIPAddress = u_long(INVALID_IP_ADDRESS) then
    begin
      FLastErrorNo := WSAGetLastError;
      //host�����t����Ȃ�
      Report('err>' + HostName + '��������܂���',Status_Basic);
      if Assigned(FOnInvalidHost) then FOnInvalidHost(Handled);

      if Assigned(FOnError) then
        FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

      //5��܂Ńg���C
      if handled and (Count < 5) then Continue;

      raise ETCPIPError.Create('not found ' + HostName,FIPAddress);
    end
    else begin
      //Host����
      Report('suc>' + HostName + '��������܂���',Status_Basic);
      if Assigned(FOnHostResolved) then FOnHostResolved(Self);
    end;

    Inc(Count);
  until (not Handled) or (Count < 5);

  ConnectSocket(FSocket,OpenPort,FIPAddress);
  if FSocket = INVALID_SOCKET then
  begin
    FLastErrorNo := WSAGetLastError;

    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ESocketError.Create(WSAGetLastError);
  end;

  FConnected := True;
  //connect event
  if Assigned(FOnConnect) then FOnConnect(Self);
end;

procedure TgSocket.Connect;
//�ڑ�
begin
//  Report('trc>TgSocket.Connect',Status_Trace);

  ConnectHost(FHost,FPort);
end;

procedure TgSocket.ConnectSocket(var Socket: TSocket; OpenPort: u_short;
  IP: u_long);
//�R�l�N�g
begin
//  Report('trc>TgSocket.ConnectSocket',Status_Trace);

  CloseSocket(Socket);
  Socket := CreateSocket;
  with FSockAddrIn do
  begin
    Sin_Family := AF_INET;
    Sin_Port := htons(OpenPort);
    Sin_addr := TInAddr(IP);
  end;

  Report('rtn>' + FHost + '��connect���܂�',Status_Routines);
{$IFDEF WS2}
  if Winsock2.Connect(Socket,@FSockAddrIn,SizeOf(FSockAddrIn)) = SOCKET_ERROR then
{$ELSE}
  if Winsock.Connect(Socket,FSockAddrIn,SizeOf(FSockAddrIn)) = SOCKET_ERROR then
{$ENDIF}
  begin
    FLastErrorNo := WSAGetLastError;

    Report('err>' + FHost + '(' + IPtoStr(IP) + '):' + IntToStr(OpenPort) +
      '��connect���s���܂���' ,Status_Basic);
    if Assigned(FOnConnectionFailed) then FOnConnectionFailed(Self);

    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ESocketError.Create(WSAGetLastError);
  end
  else begin
    FOpenPort := OpenPort;
    Report('suc>' + FHost + '(' + IPToStr(IP) + '):' + IntToStr(OpenPort) +
      '��connect�������܂���' ,Status_Basic);
  end;
end;

constructor TgSocket.Create(BufferSize: Integer);
//�쐬
begin
  inherited Create;
//  Report('trc>TgSocket.Create',Status_Trace);

  //FWSAInfo := TStringList.Create;
  FLock := TCriticalSection.Create;
  FBufferSize := BufferSize;
  FSendStream := TMemoryStream.Create;
  FTimeout := 30;
  FReportLevel := Status_Basic;

  //WSAInfo
  //FWSAInfo.Add(WinsockVersion);
  //FWSAInfo.Add(WSAData.szDescription);
  //FWSAInfo.Add(WSAData.szSystemStatus);
  //FWSAInfo.Add(IntToStr(WSAData.iMaxSockets));
  //FWSAInfo.Add(IntToStr(WSAData.iMaxUdpDg));
  //FWSAInfo.Add(WSAData.lpVendorInfo);

  Startup;
end;

function TgSocket.CreateSocket: TSocket;
//socket�쐬
begin
//  Report('trc>TgSocket.CreateSocket',Status_Trace);

  Report('rtn>socket���쐬���܂�',Status_Routines);
  Result := Socket(AF_INET,SOCK_STREAM,IPPROTO_IP);
  if Result = INVALID_SOCKET then
  begin
    FLastErrorNo := WSAGetLastError;
    
    Report('err>socket�̍쐬�Ɏ��s���܂���',Status_Basic);
    Report(ErrorToStr(WSAGetLastError),Status_Debug);
    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));
      
    raise ESocketError.Create(WSAGetLastError);
  end
  else
    Report('dbg>socket(' + IntToStr(Result) + ')���쐬���܂���',Status_Debug);
end;

destructor TgSocket.Destroy;
begin
  Cleanup; 
  //FWSAInfo.Free;
  FreeAndNil(FLock);
  FreeAndNil(FSendStream);
  inherited Destroy;
end;

procedure TgSocket.Disconnect;
//�ؒf
begin
//  Report('trc>TgSocket.Disconnect',Status_Trace);

  if FConnected then
    Report('nfo>' + FHost + ':' + IntToStr(FOpenPort) + '����ؒf���܂�',Status_Basic);

  CloseSocket(FSocket);
  FSocket := INVALID_SOCKET;
{$IFDEF WS2}
  FIPAddress := u_long(INVALID_IP_ADDRESS);
{$ELSE}
  FIPAddress := INVALID_IP_ADDRESS;
{$ENDIF}
  FConnected := False;
  if Assigned(FOnDisconnect) then FOnDisConnect(Self);
end;

procedure TgSocket.DoCommand(const CommandStr: String; Dummy: Boolean);
//send command
begin
  //����
  if not Dummy then
    WriteLn(CommandStr);

  if Trim(CommandStr) <> '' then
    Report('cmd>' + CommandStr,Status_Basic);
end;

function TgSocket.ResultCommand: String;
//�R�}���h�̌���
begin
  Result := ReadLn;
  FTransActionReply := Result;
  if Result <> '' then
    Report('res>' + Result,Status_Basic)
end;

function TgSocket.EOS(var Socket: TSocket): Boolean;
//Socket�� End of Socket
begin
//  Report('trc>TgSocket.EOS',Status_Trace);

  if Socket = FSocket then
    Result := FEOS or (SocketState(FSocket) <> ssConnected)
  else
    Result := SocketState(Socket) <> ssConnected;
end;

procedure TgSocket.SetEndOfSocket(var Socket: TSocket; Value: Boolean);
// end of socket��set
begin
//  Report('trc>TgSocket.SetEndOfSocket',Status_Trace);
  //��soket���Ƃɐݒ肷�邱��
  if Socket = FSocket then
    FEOS := Value;
end;

procedure TgSocket.FilterHeader(FileStream: TFileStream);
begin
//������
//  Report('trc>TgSocket.FileHeader',Status_Trace);
end;

function TgSocket.GetLocalIP: String;
//�\�P�b�g�̃A�h���X��Ԃ�
begin
//  Report('trc>TgSocket.GetLocalIP',Status_Trace);

  if FConnected then
    Result := GetSocketIPAddr(FSocket)
  else
    Result := IPToStr(GetLocalIPAddr);
end;

function TgSocket.GetLocalAddress: String;
//FTP�Ŏg�p����IP�A�h���X��Ԃ�
var
  IP: String;
begin
//  Report('trc>TgSocket.GetLocalAdress',Status_Trace);

  IP := GetLocalIP;
  // . �� , �ɕϊ�
  while Pos('.',IP) > 0 do IP[Pos('.',IP)] :=  ',';

  Result := IP + ',';
end;

function TgSocket.GetLocalPortString: String;
//ftp�Ŏg�p���� port��Ԃ�
begin
//  Report('trc>TgSocket.GetLocalPortString',Status_Trace);

  Result := IntToStr(FPort and $ff00 shr 8)+','+
            IntToStr(FPort and $00ff);
end;

function TgSocket.GetRemoteIP: String;
//�ڑ����Ȃ�� remote IP��Ԃ�
begin
//  Report('trc>TgSocket.GetRemoteIP',Status_Trace);

  Result := '';
  if Connected then //and (FIPAddress <> INVALID_IP_ADDRESS) then
  begin
    Result := IPToStr(u_long(FSockAddrIn.sin_addr));
    //Result := IPToStr(FIPAddress);
  end;
end;

procedure TgSocket.Listen;
begin
//������
//  Report('trc>TgSocket.Listen',Status_Trace);
end;

function TgSocket.ReadVar(var Buf; Size: Integer): Integer;
begin
  Result := ReadBuffer(FSocket,Buf,Size);
end;

function TgSocket.Read(Value: Integer): String;
//value�����ǂ�
begin
  Result := '';
  CaptureString(Result,Value);
end;

function TgSocket.ReadBuffer(var Socket: TSocket; var Buf; Size: Integer): Integer;
//socket����ǂ�
var
  rfd: TFDSet;
  Timeval: TTimeVal;
  Flag,i: Integer;
  stop: Boolean;
begin
  //FillChar(Buf,Size,0);
  //end of socket = true�ɂ��Ă���
  SetEndOfSocket(Socket,True);
  // winsock.select
  FBeenTimeout := False;

  //�^�C���A�E�g��1�b���`�F�b�N���Ă���
  Timeval.tv_sec := 1;
  Timeval.tv_usec := 0;
  Flag := 1;
  for i := 0 to FTimeout - 1 do
  begin
    FD_ZERO(rfd);
    FD_SET(Socket,rfd);
    //�`�F�b�N
    Flag := select(Socket,@rfd,nil,nil,@Timeval);
    if Flag = 0 then
    begin
      stop := False;
      //timeout�Ȃ�΃C�x���g
      if Assigned(FOnSelectTimeout) then
        FOnSelectTimeout(Self,stop);
      //�~�߂�Ȃ��
      if stop then
        Break;
    end
    else
      Break; //�I���
  end;

  //socket �ǂݍ���
  if Flag > 0 then
    Result := recv(Socket,Buf,Size,0)
  //Timeout
  else if Flag = 0 then
  begin
    FLastErrorNo := WSAGetLastError;
    FBeenTimeout := True;

    Report('err>recv timeout',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ESocketTimeout.Create('socket timeout');
  end
  //Socket Error
  else begin
    FLastErrorNo := WSAGetLastError;

    Report('err>socket error',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ESocketError.Create(WSAGetLastError);
  end;

  //Socket Error
  if (Result = SOCKET_ERROR) and (WSAGetLastError <> WSAEWOULDBLOCK) then
  begin
    FLastErrorNo := WSAGetLastError;

    Report('err>socket error',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ESocketError.Create(WSAGetLastError);
  end
  //Socket ����I��
  else if Result = 0 then
  begin
    //�߂�l��0�� end of socket = true
    SetEndOfSocket(Socket,True);
    CloseSocket(Socket);
  end
  //��M�o�C�g
  else if Result > 0 then
  begin
    //�߂�l������� end of socket  = false
    SetEndOfSocket(Socket,False);
    Report('dbg>socket���� ' + IntToStr(Result) + ' bytes�ǂݍ��݂܂���',Status_Debug);
    Inc(FBytesRecvd,Result);
    Inc(FBytesTotal,Result);
    stop := False;
    //recv event
    if Assigned(FOnPacketRecvd) then
      FOnPacketRecvd(Self,Result,stop);
    //��O���N�����Ď~�߂�
    if stop then
      raise ESocketError.Create(0);
  end;

end;

function TgSocket.ReadLnFromSocket(var Socket: TSocket): String;
//socket�����s���ǂ� ���s�͂��Ȃ�
//
//CR     CR�ŉ��s�����ۏ؂�����
//CR LF
//LF     LF�ł���ΕK�����s
var
{$IFDEF READLN_OLD}
  C: Char;
{$ENDIF}
  ret,index: Integer;
  buff,temp: String;
const
  LEN = 1024;

begin
  Result := '';
{$IFDEF READLN_OLD}
  repeat
    ret := ReadBuffer(Socket,C,1);
    if ret <> 1 then
      Break;

    if C = CR then
    else if C = LF then
      Exit
    else
      Result := Result + C;

  until EOS(Socket);

{$ELSE}
  
  SetLength(buff,LEN);
  repeat
    ret := PeekBuffer(Socket,buff[1],LEN);
    if ret > 0 then
    begin
      //�R�s�[����
      temp := Copy(buff,1,ret);
      index := Pos(CRLF,temp);
      if index > 0 then
      begin
        Result := Result + Copy(temp,1,index - 1);
        //�ǂݍ���
        ReadBuffer(Socket,buff[1],index + 1);
        //�I���
        Break;
      end
      else begin
        index := Pos(LF,temp);
        if index > 0 then
        begin
          Result := Result + Copy(temp,1,index - 1);
          //�ǂݍ���
          ReadBuffer(Socket,buff[1],index);
          //�I���
          Break;
        end
        else begin
          index := Pos(CR,temp);
          if index > 0 then
          begin
            Result := Result + Copy(temp,1,index - 1);
            //�ǂݍ���
            ReadBuffer(Socket,buff[1],index);
            //�I���
            Break;
          end
          else begin
            //�݂���Ȃ�����
            Result := Result + temp;
            //�ǂݍ���
            ReadBuffer(Socket,buff[1],ret);
          end;
        end;
      end;
    end
    else
      Break;

  until EOS(Socket);
{$ENDIF}
end;

function TgSocket.ReadLn: String;
//��s���ǂ� ���s�͂��Ȃ�
begin
//  Report('trc>TgSocket.ReadLn',Status_Trace);

  Result := ReadLnFromSocket(FSocket);
end;

procedure TgSocket.RequestCloseSocket;
//socket�����
begin
//  Report('trc>TgSocket.RequestCloseSocket',Status_Trace);

//  if FConnected then Disconnect;
  CloseSocket(FSocket);
end;

procedure TgSocket.SendToSocket(var Socket: TSocket; Stream: TStream;
  Size,Position: Integer);
// socket �� stream�𑗂�
var
  rr: Integer;
begin
//  Report('trc>TgSocket.SendToSocket',Status_Trace);

  Stream.Position := Position;
  //������
  if Size = -1 then
    repeat
      rr := Stream.Read(FBuffer^,FBufferSize);
      WriteBuffer(Socket,FBuffer^,rr);
    until (rr <= 0)
  else begin
  //Size�o�C�g����
    repeat
      //size���傫����� �o�b�t�@��
      if Size > FBufferSize then
        rr := Stream.Read(FBuffer^,FBufferSize)
      else //size����������� size
        rr := Stream.Read(FBuffer^,Size);
      //�o�b�t�@������
      WriteBuffer(Socket,FBuffer^,rr);
      //0�ȉ��ɂȂ�����I��
      Dec(Size,rr);
    until (Size <= 0) or (rr <= 0);    
  end;
  
end;

procedure TgSocket.SendBuffer(Value: PChar; BufLen: Integer);
//�o�b�t�@�𑗂�
begin
//  Report('trc>TgSocket.SendBuffer',Status_Trace);

  WriteBuffer(FSocket,Value^,BufLen);
end;

procedure TgSocket.SendFile(const FileName: String);
//�t�@�C���𑗂� �ŏ�����S��
var
  FS: TFileStream;
begin
//  Report('trc>TgSocket.SendFile',Status_Trace);

  if not FileExists(FileName) then Exit;

  FS := TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  try
    SendToSocket(FSocket,FS,-1,0);
  finally
    FS.Free;
  end;
end;

procedure TgSocket.SendStream(Stream: TStream);
//stream�𑗂� o���݂�position����    x�ŏ�����S��
begin
//  Report('trc>TgSocket.SendStream',Status_Trace);

  SendToSocket(FSocket,Stream,-1,Stream.Position);
end;

function TgSocket.SocketState(var Socket: TSocket): TSocketState;
//�\�P�b�g�̏��
var
  peer_adr: TSockAddr;
{$IFDEF WS2}
  x: Integer;
{$ELSE}
  x: u_int;
{$ENDIF}
begin
//  Report('trc>TgSocket.SocketState',Status_Trace);

  if Socket = INVALID_SOCKET then
    Result := ssInvalid
  else begin
    x := SizeOf(TSockAddr);
    if getpeername(Socket,peer_adr,x) = 0 then
      Result := ssConnected
    else
      if WSAGetLastError <> WSAENOTCONN then
        Result := ssStateUnknown
      else
        Result := ssValid
  end;
end;

procedure TgSocket.Startup;
begin
//  Report('trc>TgSocket.Startup',Status_Trace);

  //�\�P�b�g������
  FSocket := INVALID_SOCKET;
  FIPAddress := INVALID_IP_ADDRESS;
  FConnected := False;
  GetMem(FBuffer,FBufferSize);
end;

procedure TgSocket.Report(const S: String; Level: Integer);
//�g���[�X���O �����ŗ�O���N�����̂͋֎~�I�I�I
begin
  try
    //reportlevel��� level�����������
    if (FReportLevel >= Level) and (Assigned(FOnStatus)) then
      FOnStatus(Self,S);
  except
  end;
  
end;

function TgSocket.TransAction(const CommandString: String): String;
//�R�}���h�𑗂��ă��v���C��Ԃ�
var
  S: String;
  sl: TStringList;
begin
//  Report('trc>TgSocket.TransAction',Status_Trace);

  WriteLn(CommandString);
  sl := TStringList.Create;
  try
    repeat
      S := ReadLn;
      sl.Add(S);
    until (S = '') or EOS(FSocket);

    Result := sl.Text;
    FTransActionReply := Result;
  finally
    sl.Free;
  end;
end;

procedure TgSocket.Write(const S: String);
//������𑗂�
{$ifdef UNICODE}
var
  Bytes: TBytes;
  Encoding: TEncoding;
{$endif}
begin
//  Report('trc>TgSocket.Write',Status_Trace);

{$ifdef UNICODE}
  Encoding := TEncoding.ASCII;
  Bytes := Encoding.GetBytes(S);
  WriteBuffer(FSocket, Bytes[0], Length(Bytes));
{$else}
  WriteBuffer(FSocket,PChar(S)^,Length(S));
{$endif}
end;

function TgSocket.WriteBuffer(var Socket: TSocket; var Buf; Size: Integer): Integer;
//�\�P�b�g�Ƀo�b�t�@������
var
  wfd: TFDSet ;
  Timeval: TTimeval;
  r,Flag,i: Integer;
  stop: Boolean;
begin
//  Report('trc>TgSocket.WriteBuffer',Status_Trace);

  Result := 0;
  //�o�b�t�@���X�g���[���ɓǂݍ���ł���
  FSendStream.Clear;
  FSendStream.WriteBuffer(Buf,Size);
  FSendStream.Seek(0,soFromBeginning);
  repeat
    r := FSendStream.Read(FBuffer^,FBufferSize);
    if r <= 0 then
      Break;

    //timeout
    FBeenTimeout := False;

    //�^�C���A�E�g��1�b���`�F�b�N���Ă���
    Timeval.tv_sec := 1;
    Timeval.tv_usec := 0;
    Flag := 1;
    for i := 0 to FTimeout - 1 do
    begin
      FD_ZERO(wfd);
      FD_SET(Socket,wfd);
      //�`�F�b�N
      Flag := select(Socket,nil,@wfd,nil,@Timeval);
      if Flag = 0 then
      begin
        stop := False;
        //timeout�Ȃ�΃C�x���g
        if Assigned(FOnSelectTimeout) then
          FOnSelectTimeout(Self,stop);
        //�~�߂�Ȃ��
        if stop then
          Break;
      end
      else
        Break; //�I���
    end;

    //����
    if Flag > 0 then
      Result := send(Socket,FBuffer^,r,0)
    //timeout
    else if Flag = 0 then
    begin
      FLastErrorNo := WSAGetLastError;
      FBeenTimeout := True;

      Report('err>send timeout',Status_Basic);
      Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
      if Assigned(FOnError) then
        FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

      raise ESocketTimeout.Create('Send Timeout');
    end
    //Socket Error
    else begin
      FLastErrorNo := WSAGetLastError;

      Report('err>socket error',Status_Basic);
      Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
      if Assigned(FOnError) then
        FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

      raise ESocketError.Create(WSAGetLastError);
    end;


    if (Result = SOCKET_ERROR) and (WSAGetLastError <> WSAEWOULDBLOCK) then
    begin
      FLastErrorNo := WSAGetLastError;

      Report('err>socket error',Status_Basic);
      Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
      if Assigned(FOnError) then
        FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

      raise ESocketError.Create(WSAGetLastError);
    end
    else if Result >= 0 then
    begin
      Report('dbg>socket�� ' + IntToStr(Result) + ' bytes�������݂܂���',Status_Debug);
      //���M�o�C�g
      Inc(FBytesSent,Result);
      Inc(FBytesTotal,Result);
      //sent event
      stop := False;
      if Assigned(FOnPacketSent) then
        FOnPacketSent(Self,Result,stop);
      //��O���N�����Ď~�߂�
      if stop then
        raise ESocketError.Create(0);
    end;

  until (r <= 0) or (Result = SOCKET_ERROR);

end;

procedure TgSocket.WriteLn(const S: String);
//�P�s����
begin
//  Report('trc>TgSocket.WriteLn',Status_Trace);

  Write(S + CRLF);
end;

procedure TgSocket.BindSocket(var Socket: TSocket; BindPort: Word);
//bind����
var
  SockAddrIn : TSockAddrIn;
begin
//  Report('trc>TgSocket.Bind',Status_Trace);

  with SockAddrIn do
  begin
    Sin_Family := AF_INET;
    Sin_addr.S_addr := INADDR_ANY;
    //port = 0 �̏ꍇ�� OS��port��I������
    Sin_Port := htons(BindPort);
  end;

  //bind
{$IFDEF WS2}
  if Winsock2.bind(Socket,@SockAddrIn,SizeOf(TSockAddrIn)) = SOCKET_ERROR then
{$ELSE}
  if Winsock.bind(Socket,SockAddrIn,SizeOf(TSockAddrIn)) = SOCKET_ERROR then
{$ENDIF}
  begin
    FLastErrorNo := WSAGetLastError;
    Report('err>port ' + IntToStr(BindPort) + '��bind���s���܂���',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);

    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise EBindError.Create(ErrorToStr(WSAGetLastError));
  end
  else
    Report('suc>port ' + IntToStr(BindPort) + '��bind�������܂���',Status_Routines);

  //listen
  Report('rtn>listen���J�n���܂�',Status_Routines);
{$IFDEF WS2}
  if Winsock2.listen(Socket,SOMAXCONN) = SOCKET_ERROR then
{$ELSE}
  if Winsock.listen(Socket,SOMAXCONN) = SOCKET_ERROR then
{$ENDIF}
  begin
    FLastErrorNo := WSAGetLastError;
    Report('err>listen���s���܂���',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);

    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise EBindError.Create(ErrorToStr(WSAGetLastError));
  end
  else
    Report('suc>listen�������܂���',Status_Routines);


end;

constructor TgSocket.CreateFromServer(Socket: TSocket; BufferSize: Integer);
var
  Len: Integer;
begin
  inherited Create;

  //FWSAInfo := TStringList.Create;
  FLock := TCriticalSection.Create;
  FBufferSize := BufferSize;
  FSendStream := TMemoryStream.Create;
  FTimeout := 120;
  FReportLevel := Status_Basic;

  //WSAInfo
  //FWSAInfo.Add(WinsockVersion);
  //FWSAInfo.Add(WSAData.szDescription);
  //FWSAInfo.Add(WSAData.szSystemStatus);
  //FWSAInfo.Add(IntToStr(WSAData.iMaxSockets));
  //FWSAInfo.Add(IntToStr(WSAData.iMaxUdpDg));
  //FWSAInfo.Add(WSAData.lpVendorInfo);

  //�\�P�b�g���ŏ�����g����悤�ɂ���
  FSocket := Socket;
  Len := SizeOf(FSockAddrIn);
  //get sockaddrin
  getpeername(FSocket,FSockAddrIn,Len);
  FIPAddress := u_long(FSockAddrIn.sin_addr);
  FConnected := True;
  GetMem(FBuffer,FBufferSize);
end;

procedure TgSocket.Bind;
//bind
begin
//  Report('trc>TgSocket.Bind',Status_Trace);

  CloseSocket(FSocket);
  FSocket := CreateSocket;
  BindSocket(FSocket,FPort);
  FBinded := True;
end;

function TgSocket.Idle: TIdleSet;
//�ǂݍ��݂�����܂Őڑ���ҋ@����
var
  rfd,wfd,efd: TFDSet;
  Timeval: TTimeVal;
  r: Integer;
begin
//  Report('trc>TgSocket.Idle',Status_Trace);

  Result := [];
  // winsock.select
  FD_ZERO(rfd);
  FD_ZERO(wfd);
  FD_ZERO(efd);
  FD_SET(FSocket,rfd);
  FD_SET(FSocket,wfd);
  FD_SET(FSocket,efd);

  Timeval.tv_sec := 0;
  // 10.�b�ҋ@
  Timeval.tv_usec := 10000;
  //�^�C���A�E�g�̎��͌p��
  r := select(FSocket + 1,@rfd,@wfd,@efd,@Timeval);
  if r > 0 then
  begin
    if FD_ISSET(FSocket,rfd) then
    begin
      if Assigned(FOnRead) then FOnRead(Self);

      Result := Result + [itRead];
    end;
    if FD_ISSET(FSocket,wfd) then Result := Result + [itWrite];
    if FD_ISSET(FSocket,efd) then Result := Result + [itError];
  end;

end;

{ TgSockt2 }

procedure TgSocket2.DoCommand(const CommandStr: String; Dummy: Boolean);
begin
  inherited;
end;

function TgSocket2.Idle: TIdleSet;
begin
  Result := inherited Idle;
end;

function TgSocket2.ResultCommand: String;
begin
  Result := inherited ResultCommand;
end;


function TgSocket.GetConnected: Boolean;
begin
  Result := FConnected and (SocketState(FSocket) = ssConnected);
end;

function TgSocket.GetRemotePort: String;
//remote port��Ԃ�
begin
  Result := '';
  if Connected then Result := IntToStr(FSockAddrIn.Sin_Port);
end;

function TgSocket.PeekBuffer(var Socket: TSocket; var Buf;
  Size: Integer): Integer;
//socket����ǂށi�o�b�t�@�͍폜���Ȃ�)
var
  rfd: TFDSet;
  Timeval: TTimeVal;
  Flag,i: Integer;
  stop: Boolean;
begin
  //end of socket = true�ɂ��Ă���
  SetEndOfSocket(Socket,True);
  // winsock.select
  FBeenTimeout := False;

  //�^�C���A�E�g��1�b���`�F�b�N���Ă���
  Timeval.tv_sec := 1;
  Timeval.tv_usec := 0;
  Flag := 1;
  for i := 0 to FTimeout - 1 do
  begin
    FD_ZERO(rfd);
    FD_SET(Socket,rfd);
    //�`�F�b�N
    Flag := select(Socket,@rfd,nil,nil,@Timeval);
    if Flag = 0 then
    begin
      stop := False;
      //timeout�Ȃ�΃C�x���g
      if Assigned(FOnSelectTimeout) then
        FOnSelectTimeout(Self,stop);
      //�~�߂�Ȃ��
      if stop then
        Break;
    end
    else
      Break; //�I���
  end;

  //socket �ǂݍ���
  if Flag > 0 then
    Result := recv(Socket,Buf,Size,MSG_PEEK)
  //Timeout
  else if Flag = 0 then
  begin
    FLastErrorNo := WSAGetLastError;
    FBeenTimeout := True;

    Report('err>recv timeout',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ESocketTimeout.Create('socket timeout');
  end
  //Socket Error
  else begin
    FLastErrorNo := WSAGetLastError;

    Report('err>socket error',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ESocketError.Create(WSAGetLastError);
  end;

  //Socket Error
  if (Result = SOCKET_ERROR) and (WSAGetLastError <> WSAEWOULDBLOCK) then
  begin
    FLastErrorNo := WSAGetLastError;

    Report('err>socket error',Status_Basic);
    Report('dbg>' + ErrorToStr(WSAGetLastError),Status_Debug);
    if Assigned(FOnError) then
      FOnError(Self,WSAGetLastError,ErrorToStr(WSAGetLastError));

    raise ESocketError.Create(WSAGetLastError);
  end
  //Socket ����I��
  else if Result = 0 then
  begin
    //�߂�l��0�� end of socket = true
    SetEndOfSocket(Socket,True);
    CloseSocket(Socket);
  end;

end;

initialization
  WinsockInitialize;

finalization
  WinsockCleanup;


end.
