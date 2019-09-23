unit gSocketHttp;
{
 TgHTTP: HTTP��{�N���X 
   Author: Wolfy
 Modified: 00/05/10
  Version: 0.00
}

interface

uses
  Windows,SysUtils,Classes,SyncObjs,gSocket,gSocketMisc,hashtable,jconvert,
  cookielib,regexpr,unicodelib
{$IFDEF WS2}
  ,winsock2;
{$ELSE}
  ,Winsock;
{$ENDIF}

type
  EHttpLocation = class(EgSocket)
  protected
    FUrl: String;
    FSender: TObject;
  public
    constructor Create(const AUrl: String; ASender: TObject);
    property Url: String read FUrl;
    property Sender: TObject read FSender;
  end;
  
const
  UNKNOWN_BODY_LENGTH = -1;
  _HOST = 'Host';
  _ACCEPT = 'Accept';
  _USERAGENT = 'User-Agent';
  _REFERER = 'Referer';
  _CACHECONTROL = 'Cache-Control';
  _CONNECTION = 'Connection';
  _ACCEPTENCODING = 'Accept-Encoding';
  _AUTHORIZATION = 'Authorization';
  _PRAGMA = 'Pragma';
  _PROXYAUTHORIZATION = 'Proxy-Authorization';
  _RANGE = 'Range';
  _CONTENTLENGTH = 'Content-Length';
  _CONTENTTYPE = 'Content-Type';
  _DATE = 'Date';
  _SERVER = 'Server';
  _SETCOOKIE = 'Set-Cookie';
  _LOCATION = 'Location';
  _CONTENTENCODING = 'Content-Encoding';
  _CONTENTLOCATION = 'Content-Location';
  _CONTENTRANGE = 'Content-Range';
  _CONTENTDISPOSITION = 'Content-Disposition';
  _ETAG = 'ETag';
  _LASTMODIFIED = 'Last-Modified';
  _COOKIE = 'Cookie';

type
  TRequestHeader = class(TObject)
  private
    FHash: TStringHashTable;
    FPassword: String;
    FUserId: String;
    FZeroRange: Boolean;

    function GetAccept: String;
    function GetAcceptEncoding: String;
    function GetAuthorization: String;
    function GetCacheControl: String;
    function GetConnection: String;
    function GetContentLength: String;
    function GetHost: String;
    function GetPragma: String;
    function GetProxyAuthorization: String;
    function GetRange: String;
    function GetReferer: String;
    function GetUserAgent: String;
    procedure SetAccept(const Value: String);
    procedure SetAcceptEncoding(const Value: String);
    procedure SetAuthorization(const Value: String);
    procedure SetCacheControl(const Value: String);
    procedure SetConnection(const Value: String);
    procedure SetContentLength(const Value: String);
    procedure SetHost(const Value: String);
    procedure SetPragma(const Value: String);
    procedure SetProxyAuthorization(const Value: String);
    procedure SetRange(const Value: String);
    procedure SetReferer(const Value: String);
    procedure SetUserAgent(const Value: String);
    function GetContentType: String;
    procedure SetContentType(const Value: String);
    function GetHeaders(Name: String): String;
    procedure SetHeaders(Name: String; const Value: String);
    function GetCookide: String;
    procedure SetCookie(const Value: String);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function HasName(Name: String): Boolean;
    procedure ParseRange(Start,RangeBytes: Integer);
    procedure ParseUserPass(User,Pass: String);
    procedure ParseProxyUserPass(User,Pass: String);
    procedure ParseUrl(Url: String);
    procedure ParseCookie(Cook: TCookie);
    procedure ParseNoCache;
    procedure GetHeader(Strings: TStrings);

    property ZeroRange: Boolean read FZeroRange write FZeroRange;

    property CacheControl: String read GetCacheControl write SetCacheControl;
    property Connection: String read GetConnection write SetConnection;
    property Pragma: String read GetPragma write SetPragma;
    property Accept: String read GetAccept write SetAccept;
    property AcceptEncoding: String read GetAcceptEncoding write SetAcceptEncoding;
    property Authorization: String read GetAuthorization write SetAuthorization;
    property Host: String read GetHost write SetHost;
    property ProxyAuthorization: String read GetProxyAuthorization write SetProxyAuthorization;
    property Range: String read GetRange write SetRange;
    property Referer: String read GetReferer write SetReferer;
    property UserAgent: String read GetUserAgent write SetUserAgent;
    property ContentLength: String read GetContentLength write SetContentLength;
    property ContentType: String read GetContentType write SetContentType;
    property UserId: String read FUserId;
    property Password: String read FPassword;

    property Cookie: String read GetCookide write SetCookie;
    property Headers[Name: String]: String read GetHeaders write SetHeaders; default;
    property Hash: TStringHashTable read FHash;
  end;

  TResponseHeader = class(TObject)
  private
    FHash: TStringHashTable;
    FCookie: TCookie;

    FVersion: String;
    function GetContentType: String;
    procedure SetContentType(const Value: String);
    function GetHeaders(Name: String): String;
    procedure SetHeaders(Name: String; const Value: String);
    procedure SetConnection(const Value: String);
    procedure SetContentDisposition(const Value: String);
    procedure SetContentEncoding(const Value: String);
    procedure SetContentLength(const Value: String);
    procedure SetContentLocation(const Value: String);
    procedure SetContentRange(const Value: String);
    procedure SetDate(const Value: String);
    procedure SetETag(const Value: String);
    procedure SetLastModified(const Value: String);
    procedure SetLocation(const Value: String);
    procedure SetServer(const Value: String);
    function GetConnection: String;
    function GetContentDisposition: String;
    function GetContentEncoding: String;
    function GetContentLength: String;
    function GetContentLocation: String;
    function GetContentRange: String;
    function GetDate: String;
    function GetETag: String;
    function GetLastModified: String;
    function GetLocation: String;
    function GetServer: String;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function HasName(Name: String): Boolean;

    property Connection: String read GetConnection write SetConnection;
    property Date: String read GetDate write SetDate;
    property Server: String read GetServer write SetServer;
    property Location: String read GetLocation write SetLocation;
    property ContentEncoding: String read GetContentEncoding write SetContentEncoding;
    property ContentLength: String read GetContentLength write SetContentLength;
    property ContentLocation: String read GetContentLocation write SetContentLocation;
    property ContentRange: String read GetContentRange write SetContentRange;
    property ContentType: String read GetContentType write SetContentType;
    property ContentDisposition: String read GetContentDisposition write SetContentDisposition;
    property ETag: String read GetETag write SetETag;
    property LastModified: String read GetLastModified write SetLastModified;

    property Version: String read FVersion write FVersion;
    property Cookie: TCookie read FCookie;
    property Headers[Name: String]: String read GetHeaders write SetHeaders; default;
    property Hash: TStringHashTable read FHash;
  end;

type
  THTTPCmdType = (cmdGET,cmdDELETE,cmdHEAD,cmd,OPTIONS,cmdPOST,cmdPUT,cmdTRACE);
  TResultEvent = procedure(cmd: THTTPCmdType) of object;
  TRedirectHandlerEvent = procedure(Sender: TObject; var Handled: Boolean; const Url: String) of object;
  TAboutToSend = procedure(Sender: TObject; var Url,Proxy: String; Headers: THashTable) of object;
  TOnResponse = procedure(Sender: TObject; const Url,Proxy,StatusMsg: String; var RedirectUrl: String; var StatusNumber: Integer; Headers: THashTable) of object;
  //TOnSetCookie = procedure(Sender: TObject; Cookie: TCookie) of object;

  TgHTTP = class(TgSocket)
  private      

  protected
    FReqHeader: TRequestHeader;
    FResHeader: TResponseHeader;

    FVersion: String;
    FHeader: String;
    FRedirectUrl: String;
    FEncodeUrl: Boolean;
    FEncodeUtf8: Boolean;
    FUrl: String;
    FBodyLength: Integer;
    FDisposition: String;
    FAutoRedirect: Boolean;
    FAuthorizationProxyRequest: Boolean;
    
    //event
    FOnAboutToSend: TAboutToSend;
    FOnAuthenticationNeeded: TNotifyEvent;
    FOnFailure: TResultEvent;
    FOnRedirect: TRedirectHandlerEvent;
    FOnSuccess: TResultEvent;
    FOnResponse: TOnResponse;
    function GetBodyDosTime: Integer;
    function GetEnabledRange: Boolean;
    function GetLastModified: TDateTime;
  public
    constructor Create(BufferSize: Integer = BUFFER_SIZE); override;
    destructor Destroy; override;

    procedure Request(Method, Url: String; SendData: String = ''); virtual;
    procedure Response; virtual;
    procedure Head(Url: String);
    function Get(Url: String): String;
    procedure GetFile(Url,Filename: String);
    procedure GetStream(Url: String; Stream: TStream);
    function Post(Url,PostData: String): String;
    function ReadVar(var Buf; Size: Integer): Integer; override;

    property Header: String read FHeader;
    property RedirectUrl: String read FRedirectUrl;
    property LastModified: TDateTime read GetLastModified;
    property BodyDosTime: Integer read GetBodyDosTime;
    property BodyLength: Integer read FBodyLength;
    property EnabledRange: Boolean read GetEnabledRange;
    property EncodeUrl: Boolean read FEncodeUrl write FEncodeUrl;
    property EncodeUtf8: Boolean read FEncodeUtf8 write FEncodeUtf8;
    property Disposition: String read FDisposition;
    property Version: String read FVersion write FVersion;
    property ReqHeader: TRequestHeader read FReqHeader;
    property ResHeader: TResponseHeader read FResHeader;
    property AutoRedirect: Boolean read FAutoRedirect write FAutoRedirect;
    property AuthorizationProxyRequest: Boolean read FAuthorizationProxyRequest write FAuthorizationProxyRequest;

    property OnAboutToSend: TAboutToSend read FOnAboutToSend write FOnAboutToSend;
    property OnAuthenticationNeeded: TNotifyEvent read FOnAuthenticationNeeded write FOnAuthenticationNeeded;
    property OnFailure: TResultEvent read FOnFailure write FOnFailure;
    property OnRedirect: TRedirectHandlerEvent read FOnRedirect write FOnRedirect;
    property OnSuccess: TResultEvent read FOnSuccess write FOnSuccess;
    property OnResponse: TOnResponse read FOnResponse write FOnResponse;
  end;
  

implementation

{ TgHTTP }

constructor TgHTTP.Create(BufferSize: Integer = BUFFER_SIZE);
begin
  inherited Create(BufferSize);

  FReqHeader := TRequestHeader.Create;
  FResHeader := TResponseHeader.Create;
  FPort := 80;
  FVersion := '1.0';
  FBodyLength := UNKNOWN_BODY_LENGTH;
end;

destructor TgHTTP.Destroy;
begin
  FreeAndNil(FReqHeader);
  FreeAndNil(FResHeader);
  inherited Destroy;
end;

function TgHTTP.Get(Url: String): String;
//GET���\�b�h
var
  Handled: Boolean;
  S: String;
begin
  S := Url;
  Report('nfo>' + S + '��get���܂�',Status_Informational);
  try
    repeat
      try
        Handled := True;
        Request('GET',S,'');
        Response;
        //redirect�`�F�b�N
        if (FRedirectUrl <> '') then
        begin
          if FAutoRedirect then
            Handled := False
          else if Assigned(FOnRedirect) then
            FOnRedirect(Self,Handled,FRedirectUrl);
            
          //h = false���Ԃ��Ă����� redirct
          if not Handled then
          begin
            S := FRedirectUrl;
            Report('nfo>' + S + '��redirect���܂�',Status_Informational);
            Continue;
          end;
        end;

        CaptureString(Result,-1);
        //if LowerCase(EntHeaderInfo.ContentEncoding) = 'gzip' then
        //  DecompressGzFile(FBody,'');
      finally
        Disconnect;
      end;
    until Handled;
  except
    //���s
    Report('nfo>' + S + '��get�ُ�I��',Status_Informational);
    if Assigned(FOnFailure) then
      FOnFailure(cmdGET);
    //�Đ���
    raise
  end;
  //����
  if Assigned(FOnSuccess) then
    FOnSuccess(cmdGET);

  Report('nfo>' + S + '��get����I��',Status_Informational);
end;

function TgHTTP.GetBodyDosTime: Integer;
begin
  if ResHeader.HasName(_LASTMODIFIED) then
    Result := HTTPModifiedToDosTime(ResHeader[_LASTMODIFIED])
  else
    Result := HTTPModifiedToDosTime(DateTimeToHttpModified(Now));
end;

function TgHTTP.GetEnabledRange: Boolean;
//���W���[���ł���H
begin
  Result := ResHeader.HasName(_CONTENTRANGE);
end;

procedure TgHTTP.GetFile(Url, Filename: String);
//GET���\�b�h
var
  Handled: Boolean;
  S: String;
begin
  S := Url;
  Report('nfo>' + S + '��get���܂�',Status_Informational);
  try
    repeat
      try
        Handled := True;
        Request('GET',S);
        Response;
        //redirect�`�F�b�N
        if (FRedirectUrl <> '') then
        begin
          if FAutoRedirect then
            Handled := False
          else if Assigned(FOnRedirect) then
            FOnRedirect(Self,Handled,FRedirectUrl);
            
          //h = false���Ԃ��Ă����� redirct
          if not Handled then
          begin
            S := FRedirectUrl;
            Report('nfo>' + S + '��redirect���܂�',Status_Informational);
            Continue;
          end;
        end;

        CaptureFile(Filename);
        //if LowerCase(EntHeaderInfo.ContentEncoding) = 'gzip' then
        //  DecompressGzFile(FBody,'');
      finally
        Disconnect;
      end;
    until Handled;
  except
    //���s
    Report('nfo>' + S + '��get�ُ�I��',Status_Informational);
    if Assigned(FOnFailure) then
      FOnFailure(cmdGET);
    //�Đ���
    raise
  end;
  //����
  if Assigned(FOnSuccess) then
    FOnSuccess(cmdGET);

  Report('nfo>' + S + '��get����I��',Status_Informational);
end;

function TgHTTP.GetLastModified: TDateTime;
begin
  if ResHeader.HasName(_LASTMODIFIED) then
    Result := HttpModifiedToDateTime(ResHeader[_LASTMODIFIED])
  else
    Result := Now;
end;

procedure TgHTTP.GetStream(Url: String; Stream: TStream);
//GET���\�b�h
var
  Handled: Boolean;
  S: String;
begin
  S := Url;
  Report('nfo>' + S + '��get���܂�',Status_Informational);
  try
    repeat
      try
        Handled := True;
        Request('GET',S);
        Response;
        //redirect�`�F�b�N
        if (FRedirectUrl <> '') then
        begin
          if FAutoRedirect then
            Handled := False
          else if Assigned(FOnRedirect) then
            FOnRedirect(Self,Handled,FRedirectUrl);
            
          //h = false���Ԃ��Ă����� redirct
          if not Handled then
          begin
            S := FRedirectUrl;
            Report('nfo>' + S + '��redirect���܂�',Status_Informational);
            Continue;
          end;
        end;

        CaptureStream(Stream,-1);
        //if LowerCase(EntHeaderInfo.ContentEncoding) = 'gzip' then
        //  DecompressGzFile(FBody,'');
      finally
        Disconnect;
      end;
    until Handled;
  except
    //���s
    Report('nfo>' + S + '��get�ُ�I��',Status_Informational);
    if Assigned(FOnFailure) then
      FOnFailure(cmdGET);
    //�Đ���
    raise
  end;
  //����
  if Assigned(FOnSuccess) then
    FOnSuccess(cmdGET);

  Report('nfo>' + S + '��get����I��',Status_Informational);
end;

procedure TgHTTP.Head(Url: String);
//HEAD���\�b�h
var
  Handled: Boolean;
  S: String;
begin
  S := Url;
  Report('nfo>' + S + '��head���܂�',Status_Informational);
  try
    repeat
      try
        Handled := True;
        Request('HEAD',S);
        Response;
        //redirect�`�F�b�N
        if (FRedirectUrl <> '') and Assigned(FOnRedirect) then
          FOnRedirect(Self,Handled,FRedirectUrl);
        //h = false���Ԃ��Ă����� redirct
        if not Handled then
        begin
          S := FRedirectUrl;
          Report('nfo>' + S + '��redirect���܂�',Status_Informational);
          Continue;
        end;
      finally
        Disconnect;
      end;
    until Handled;
  except
    //���s
    Report('nfo>' + S + '��head�ُ�I��',Status_Informational);
    if Assigned(FOnFailure) then
      FOnFailure(cmdHEAD);
    //�Đ���
    raise
  end;
  //����
  if Assigned(FOnSuccess) then
    FOnSuccess(cmdHEAD);

  Report('nfo>' + S + '��head����I��',Status_Informational);
end;

function TgHTTP.Post(Url, PostData: String): String;
//POST���\�b�h
var
  Handled: Boolean;
  S: String;
begin
//  Report('trc>TgHTTP.Post',Status_Trace);

  S := Url;
  Report('nfo>' + S + '��post���܂�',Status_Informational);
  try
    repeat
      try
        Handled := True;
        Request('POST',S,PostData);
        Response;
        //redirect�`�F�b�N
        if (FRedirectUrl <> '') then
        begin
          if FAutoRedirect then
            Handled := False
          else if Assigned(FOnRedirect) then
            FOnRedirect(Self,Handled,FRedirectUrl);
            
          //h = false���Ԃ��Ă����� redirct
          if not Handled then
          begin
            S := FRedirectUrl;
            Report('nfo>' + S + '��redirect���܂�',Status_Informational);
            Continue;
          end;
        end;

        CaptureString(Result,-1);
        //if LowerCase(EntHeaderInfo.ContentEncoding) = 'gzip' then
        // FBody := DecompressString(FBody);
      finally
        Disconnect;
      end;
    until Handled;
  except
    //���s
    Report('nfo>' + S + '��post�ُ�I��',Status_Informational);
    if Assigned(FOnFailure) then FOnFailure(cmdPOST);
    //�Đ���
    raise
  end;
  //����
  if Assigned(FOnSuccess) then FOnSuccess(cmdPOST);

  Report('nfo>' + S + '��post����I��',Status_Informational);
  
end;


function TgHTTP.ReadVar(var Buf; Size: Integer): Integer;
begin
  Result := inherited ReadVar(Buf,Size);
end;

procedure TgHTTP.Request(Method, Url: String; SendData: String = '');
var
  U: TUrlInfo;
  SL: TStringList;
  i: Integer;
begin
  FUrl := Url;
  
  if Method = '' then
    Method := 'GET';

  FBeenCanceled := False;
  FBeenTimeout := False;
  //���
  U := ParseUrl(Url);

  //host
  FReqHeader.Host := ExtractURLHostAndPort(Url);
  //authorization
  if (U.UserId <> '') or (U.Password <> '') then
    FReqHeader.ParseUserPass(U.UserId,U.PAssword);

  //post�f�[�^�̃w�b�_
  if (Method = 'POST') or (Method = 'PUT') or (Method = 'TRACE') then
  begin
    if SendData <> '' then
    begin
      //senddata�𑗂�
      //Content-Type
      ReqHeader.ContentType := 'application/x-www-form-urlencoded';
      ReqHeader.ContentLength := IntToStr(Length(SendData));
    end;
  end;
  //�C�x���g
  if Assigned(FOnAboutToSend) then
  begin
    FOnAboutToSend(Self,Url,FProxy,FReqHeader.FHash);
    //�Ăщ��
    FUrl := Url;
    U := ParseUrl(Url);
  end;

  //proxy������Ȃ��
  if FProxy <> '' then
  begin
    if FEncodeUtf8 then
      U.Path := AnsiToUtf8(U.Path);

    //encode����?
    if FEncodeUrl and (not IsUrlEncoded(U.Path)) then
      U.Path := EncodeURI(U.Path);

    //�v���g�R�����Ȃ��Ȃ��
    if U.Protocol = '' then
      U.Protocol := 'http://'
    else
      U.Protocol := U.Protocol + '://';

    if U.Port <> '' then
      U.Port := ':' + U.Port;

    //user&pass������Ȃ��
    if FAuthorizationProxyRequest and
       ((ReqHeader.UserId <> '') or (ReqHeader.Password <> '')) then
      U.Path := U.Protocol + ReqHeader.UserId + ':' + ReqHeader.Password + '@' + U.Host + U.Port + U.Path
    else
      U.Path := U.Protocol + U.Host + U.Port + U.Path;
    //delegate���܂� proxy�����
    ParseProxy(FProxy,U.Path,U.Host,U.Port);
    //port���Ȃ��Ȃ��8080
    if U.Port = '' then
      U.Port := '8080';
  end
  else begin
    //proxy���Ȃ��Ƃ���

    if FEncodeUtf8 then
      U.Path := AnsiToUtf8(U.Path);
    //encode����?
    if FEncodeUrl and (not IsUrlEncoded(U.Path)) then
      U.Path := EncodeURI(U.Path);
    //port���Ȃ��Ȃ�� 80
    if U.Port = '' then
      U.Port := '80';
  end;
  //proto���Ȃ��Ȃ�� http
  if U.Protocol = '' then
    U.Protocol := 'http';
  //path���Ȃ��Ȃ�� /
  if U.Path = '' then
    U.Path := '/';
  //host��
  FHost := U.Host;
  //socket_number
  FPort := StrToIntDef(U.Port,80);

  //connect
  Connect;

  //�T�[�o�[�Ƀw�b�_�𑗐M
  Report('rtn>�T�[�o�փ��N�G�X�g���M',Status_Basic);

  SL := TStringList.Create;
  try
{ TODO : ���N�G�X�g���܂Ƃ߂đ���I }
    FReqHeader.GetHeader(SL);
    //���\�b�h���ŏ��ɑ}��
    sl.Insert(0,Method + ' ' + U.Path + ' HTTP/' + FVersion);
    //�{��
    Write(sl.Text + CRLF);
    //�_�~�[�𑗂�
    for i := 0 to SL.Count - 1 do
      DoCommand(SL[i],True);
  finally
    SL.Free;
  end;

  //post�f�[�^�̃w�b�_
  if (Method = 'POST') or (Method = 'PUT') or (Method = 'TRACE') then
  begin
    if SendData <> '' then
    begin
      //senddata�𑗂�
      Write(SendData);
    end;
  end;

end;


procedure TgHTTP.Response;
var
  S,Temp: String;
  Field,Data: String;
  All,Partial,i,index: Integer;
  tempsl: TStringList;
begin
  Report('rtn>�T�[�o����̃��X�|���X',Status_Basic);

  FResHeader.Clear;
  FRedirectUrl := '';
  FStatusNo := 0;
  FHeader := '';
  FBodyLength := UNKNOWN_BODY_LENGTH;
  FDisposition := '';

  //�܂��S���ǂ�
  repeat
    S := ResultCommand;
    FHeader := FHeader + S + CRLF;
    FTransActionReply := FHeader;

    if Copy(S,1,4) = 'HTTP' then
    begin
      Temp := S;
      System.Delete(Temp,1,Pos(' ',Temp));
      //�����ԍ�������
      index := Pos(' ',Temp);
      if index > 0 then
      begin
        FStatusNo := StrToIntDef(Copy(Temp,1,index - 1),999);
        // �����R�[�h�������
        FStatus := Copy(Temp,index + 1,MaxInt);
      end
      else begin
        FStatusNo := StrToIntDef(Temp,999);
        FStatus := '';
      end;
      //version
      FResHeader.Version := Copy(S,6,3);
    end
    else if Pos(':',S) > 0 then
    begin
      //field �� �w�b�_��
      Field := LowerCase(Copy(S,1,Pos(':',S) - 1));
      //data �� �w�b�_�̃f�[�^
      Data := Trim(Copy(S,Pos(':',S) + 1,MaxInt));

      if Field = LowerCase(_SETCOOKIE) then
      begin
        //set-cookie�͕����Ă΂��
        FResHeader.Cookie.Parse(FUrl,Data);
      end
      else begin
        FResHeader[Field] := Data;
      end;
    end;
  until (S = '') or (EOS(FSocket));
  //�C�x���g���ɌĂ�
  if Assigned(FOnResponse) then
    FOnResponse(Self,FUrl,FProxy,FStatus,FRedirectUrl,FStatusNo,FResHeader.FHash);
  //�w�b�_���`�F�b�N
  //location
  if FResHeader.HasName(_CONTENTLOCATION) then
    FRedirectUrl := ExpandUrl(FUrl,FResHeader[_CONTENTLOCATION]);

  if FResHeader.HasName(_LOCATION) then
    FRedirectUrl := ExpandUrl(FUrl,FResHeader[_LOCATION]);

  //bodylength
  if FResHeader.HasName(_CONTENTLENGTH) then
    FBodyLength := StrToIntDef(FResHeader[_CONTENTLENGTH],0);
  //bodylength
  if FResHeader.HasName(_CONTENTRANGE) then
  begin
    //fbodylength �� -1�̏ꍇ��
    if FBodyLength = UNKNOWN_BODY_LENGTH then
    begin
      Temp := FResHeader[_CONTENTRANGE];
      System.Delete(Temp,1,6);//bytes ������
      Partial := StrToIntDef(Copy(Temp,1,Pos('-',Temp) - 1),0);
      All := StrToIntDef(Copy(Temp,Pos('/',Temp) + 1,MaxInt),0);
      //0�łȂ��Ȃ��
      if All <> 0 then
        FBodyLength := All - Partial;
    end;
  end;
  //disposition
  if FResHeader.HasName(_CONTENTDISPOSITION) then
  begin
    //�t�@�C�����w�肪�����
    Temp := FResHeader[_CONTENTDISPOSITION];
    tempsl := TStringList.Create;
    try
      // ;�݂̂ŋ�؂�
      SplitRegExpr('[;]+',Temp,tempsl);
      //�󔒂�����
      for i := 0 to tempsl.Count - 1 do
        tempsl[i] := Trim(tempsl[i]);

      FDisposition := ExtractQuotedString(tempsl.Values['filename'],'"');
    finally
      tempsl.Free;
    end; 
  end;

  //401�̎��̓C�x���g
  if (FStatusNo = 401) and Assigned(FOnAuthenticationNeeded) then
    FOnAuthenticationNeeded(Self);

  //�����ԍ���400�ȏ�Ȃ�� ��O
  if FStatusNo >= 400 then
    raise EProtocolError.Create('http',FStatus,FStatusNo);
end;


{ EHttpLocation }

constructor EHttpLocation.Create(const AUrl: String; ASender: TObject);
begin
  inherited Create(AUrl);
  FUrl := AUrl;
  FSender := ASender;
end;

{ TRequestHeader }

procedure TRequestHeader.Clear;
begin
  //��ɃN���A����
  FHash.Clear;
  Accept := '*/*';
  Connection := 'close';
end;

constructor TRequestHeader.Create;
//�쐬
begin
  inherited Create;
  FHash := TStringHashTable.Create(HASH_10,True);
  FHash.RaiseException := False;

  FZeroRange := True;

  Clear;
end;

destructor TRequestHeader.Destroy;
//�j��
begin
  FHash.Free;
  inherited;
end;

function TRequestHeader.GetAccept: String;
begin
  Result := FHash[_ACCEPT];
end;

function TRequestHeader.GetAcceptEncoding: String;
begin
  Result := FHash[_ACCEPTENCODING];
end;

function TRequestHeader.GetAuthorization: String;
begin
  Result := FHash[_AUTHORIZATION];
end;

function TRequestHeader.GetCacheControl: String;
begin
  Result := FHash[_CACHECONTROL];
end;

function TRequestHeader.GetConnection: String;
begin
  Result := FHash[_CONNECTION];
end;

function TRequestHeader.GetContentLength: String;
begin
  Result := FHash[_CONTENTLENGTH];
end;

function TRequestHeader.GetContentType: String;
begin
  Result := FHash[_CONTENTTYPE];
end;

function TRequestHeader.GetCookide: String;
begin
  Result := FHash[_COOKIE];
end;

function TRequestHeader.GetHeaders(Name: String): String;
begin
  Result := FHash[Name];
end;

function TRequestHeader.GetHost: String;
begin
  Result := FHash[_HOST];
end;

function TRequestHeader.GetPragma: String;
begin
  Result := FHash[_PRAGMA];
end;

function TRequestHeader.GetProxyAuthorization: String;
begin
  Result := FHash[_PROXYAUTHORIZATION];
end;

function TRequestHeader.GetRange: String;
begin
  Result := FHash[_RANGE];
end;

function TRequestHeader.GetReferer: String;
begin
  Result := FHash[_REFERER];
end;

function TRequestHeader.GetUserAgent: String;
begin
  Result := FHash[_USERAGENT];
end;

function TRequestHeader.HasName(Name: String): Boolean;
begin
  Result := FHash.HasKey(Name);
end;

procedure TRequestHeader.SetAccept(const Value: String);
begin
  FHash[_ACCEPT] := Value;
end;

procedure TRequestHeader.SetAcceptEncoding(const Value: String);
begin
  FHash[_ACCEPTENCODING] := Value;
end;

procedure TRequestHeader.SetAuthorization(const Value: String);
begin
  FHash[_AUTHORIZATION] := Value;
end;

procedure TRequestHeader.SetCacheControl(const Value: String);
begin
  FHash[_CACHECONTROL] := Value;
end;

procedure TRequestHeader.SetConnection(const Value: String);
begin
  FHash[_CONNECTION] := Value;
end;

procedure TRequestHeader.SetContentLength(const Value: String);
begin
  FHash[_CONTENTLENGTH] := Value;
end;

procedure TRequestHeader.SetContentType(const Value: String);
begin
  FHash[_CONTENTTYPE] := Value;
end;

procedure TRequestHeader.SetCookie(const Value: String);
begin
  FHash[_COOKIE] := Value;
end;

procedure TRequestHeader.SetHeaders(Name: String; const Value: String);
begin
  FHash[Name] := Value;
end;

procedure TRequestHeader.SetHost(const Value: String);
begin
  FHash[_HOST] := Value;
end;

procedure TRequestHeader.SetPragma(const Value: String);
begin
  FHash[_PRAGMA] := Value;
end;

procedure TRequestHeader.SetProxyAuthorization(const Value: String);
begin
  FHash[_PROXYAUTHORIZATION] := Value;
end;

procedure TRequestHeader.ParseProxyUserPass(User, Pass: String);
begin
  if (User <> '') or (Pass <> '') then
    ProxyAuthorization := 'Basic ' + EncodeBase64(User + ':' + Pass);
end;

procedure TRequestHeader.SetRange(const Value: String);
begin
  FHash[_RANGE] := Value;
end;

procedure TRequestHeader.ParseRange(Start, RangeBytes: Integer);
//Range: bytes=7680-
begin
  Range := 'bytes=' + IntToStr(Start) + '-';
  if RangeBytes > 0 then
    Range := Range + IntToStr(RangeBytes);
end;

procedure TRequestHeader.SetReferer(const Value: String);
begin
  FHash[_REFERER] := Value;
end;

procedure TRequestHeader.ParseUrl(Url: String);
var
  info: TUrlInfo;
begin
  info := gsocketmisc.ParseUrl(Url);
  Host := info.Host;
  if (info.UserId <> '') or (info.Password <> '') then
  begin
    Authorization := 'Basic ' + EncodeBase64(info.UserId + ':' + info.Password);
    FUserId := info.UserId;
    FPassword := info.Password;
  end;
end;

procedure TRequestHeader.SetUserAgent(const Value: String);
begin
  FHash[_USERAGENT] := Value;
end;

procedure TRequestHeader.ParseUserPass(User, Pass: String);
begin
  if (User <> '') or (Pass <> '') then
  begin
    Authorization := 'Basic ' + EncodeBase64(User + ':' + Pass);
    FUserId := User;
    FPassword := Pass;
  end;
end;

procedure TRequestHeader.ParseCookie(Cook: TCookie);
begin
  FHash[_COOKIE] := Cook.ClientText;
end;

procedure TRequestHeader.ParseNoCache;
begin
  Pragma := 'no-cache';
  CacheControl := 'no-cache';
end;

procedure TRequestHeader.GetHeader(Strings: TStrings);
//�w�b�_�𕶎���ɂ���
var
  sl: TStringList;
  i: Integer;
  value: String;
begin
  Strings.Clear;
  sl := TStringList.Create;
  try
    sl.Text := FHash.Keys;
    for i := 0 to sl.Count - 1 do
    begin
      value := FHash[sl[i]];
      //���������͖̂���
      if value <> '' then
      begin
        if not FZeroRange then
        begin
          if (LowerCase(sl[i]) = LowerCase(_RANGE)) and
             (value = 'bytes=0-') then
            //�������Ȃ�
          else
            Strings.Add(sl[i] + ': ' + value);
        end
        else
          Strings.Add(sl[i] + ': ' + value);
      end;
    end;
  finally
    sl.Free;
  end;
end;

{ TResponseHeader }

procedure TResponseHeader.Clear;
begin
  FHash.Clear;
  FCookie.Clear;
end;

constructor TResponseHeader.Create;
begin
  inherited Create;
  FHash := TStringHashTable.Create(HASH_10,True);
  FHash.RaiseException := False;
  FCookie := TCookie.Create;
end;

destructor TResponseHeader.Destroy;
begin
  FHash.Free;
  FCookie.Free;
  inherited;
end;

function TResponseHeader.GetConnection: String;
begin
  Result := FHash[_CONNECTION];
end;

function TResponseHeader.GetContentDisposition: String;
begin
  Result := FHash[_CONTENTDISPOSITION];
end;

function TResponseHeader.GetContentEncoding: String;
begin
  Result := FHash[_CONTENTENCODING];
end;

function TResponseHeader.GetContentLength: String;
begin
  Result := FHash[_CONTENTLENGTH];
end;

function TResponseHeader.GetContentLocation: String;
begin
  Result := FHash[_CONTENTLOCATION];
end;

function TResponseHeader.GetContentRange: String;
begin
  Result := FHash[_CONTENTRANGE];
end;

function TResponseHeader.GetContentType: String;
begin
  Result := FHash[_CONTENTTYPE];
end;

function TResponseHeader.GetDate: String;
begin
  Result := FHash[_DATE];
end;

function TResponseHeader.GetETag: String;
begin
  Result := FHash[_ETAG];
end;

function TResponseHeader.GetHeaders(Name: String): String;
begin
  Result := FHash[Name];
end;

function TResponseHeader.GetLastModified: String;
begin
  Result := FHash[_LASTMODIFIED];
end;

function TResponseHeader.GetLocation: String;
begin
  Result := FHash[_LOCATION];
end;

function TResponseHeader.GetServer: String;
begin
  Result := FHash[_SERVER];
end;

function TResponseHeader.HasName(Name: String): Boolean;
begin
  Result := FHash.HasKey(Name);
end;

procedure TResponseHeader.SetConnection(const Value: String);
begin
  FHash[_CONNECTION] := Value;
end;

procedure TResponseHeader.SetContentDisposition(const Value: String);
begin
  FHash[_CONTENTDISPOSITION] := Value;
end;

procedure TResponseHeader.SetContentEncoding(const Value: String);
begin
  FHash[_CONTENTENCODING] := Value;
end;

procedure TResponseHeader.SetContentLength(const Value: String);
begin
  FHash[_CONTENTLENGTH] := Value;
end;

procedure TResponseHeader.SetContentLocation(const Value: String);
begin
  FHash[_CONTENTLOCATION] := Value;
end;

procedure TResponseHeader.SetContentRange(const Value: String);
begin
  FHash[_CONTENTRANGE] := Value;
end;

procedure TResponseHeader.SetContentType(const Value: String);
begin
  FHash[_CONTENTTYPE] := Value;
end;

procedure TResponseHeader.SetDate(const Value: String);
begin
  FHash[_DATE] := Value;
end;

procedure TResponseHeader.SetETag(const Value: String);
begin
  FHash[_ETAG] := Value;
end;

procedure TResponseHeader.SetHeaders(Name: String; const Value: String);
begin
  FHash[Name] := Value;
end;

procedure TResponseHeader.SetLastModified(const Value: String);
begin
  FHash[_LASTMODIFIED] := Value;
end;

procedure TResponseHeader.SetLocation(const Value: String);
begin
  FHash[_LOCATION] := Value;
end;

procedure TResponseHeader.SetServer(const Value: String);
begin
  FHash[_SERVER] := Value;
end;


end.
