unit LCXLIOCPHttp;

interface

uses
  Windows, Sysutils, Classes, LCXLIOCPBase, IniFiles;

type
  TURLRec = record
    Scheme: string; // 协议名称，本类只支持HTTP
    Host: string; // 如www.baidu.com
    Port: Integer; // 端口号，默认为80
    Query: string; // 查询路径，如sss/sss/ssd.asp
    Fragment: string; // 参数，如sss=ssd&sdfs=sdr，在POST方法中，此为空
  public
    // 重载操作符:=，隐形转换
    class operator Implicit(Source: TURLRec): string; overload;
    class operator Implicit(Source: string): TURLRec; overload;
  end;

  PURLRec = ^TURLRec;

  TIOCPHttpClientList = class;

  THttpRequest = class(TObject)
  private
    FHeadList: TStringList;
  private
    FURLRec: TURLRec;
    FIsPostMethod: Boolean;
    function GetFragment: string;
    function GetHost: string;
    function GetPort: Integer;
    function GetQuery: string;
    function GetScheme: string;
    function GetURL: string;
    procedure SetFragment(const Value: string);
    procedure SetHost(const Value: string);
    procedure SetPort(const Value: Integer);
    procedure SetQuery(const Value: string);
    procedure SetScheme(const Value: string);
    procedure SetURL(const Value: string);
    function GetRequestHead: AnsiString;
    function GetHeadItem(Index: string): string;
    procedure SetHeadItem(Index: string; const Value: string);
  protected
    procedure BeginSendContent(); virtual;abstract;
    function GetContentLength():Int64;virtual; abstract;
    function SendingContent(Data: Pointer; var DataLen: DWORD): Boolean; virtual;abstract;
    procedure EndSendContent(); virtual;abstract;
  public const
    HEADER_ACCPET = 'Accept';
    HEADER_HOST = 'Host';
    HEADER_ENCODING = 'Encoding';
    HEADER_REFERER = 'Referer';
    HEADER_CONNECTION = 'Connection';
    HEADER_USER_AGENT = 'User-Agent';
    HEADER_ACCEPT_CHARSET = 'Accept-Charset';
    HEADER_ACCEPT_ENCODING = 'Accept-Encoding';
    HEADER_ACCEPT_LANGUAGE = 'Accept-Language';
    HEADER_CACHE_COONTROL = 'Cache-Control';
    HEADER_COOKIE = 'Cookie';
  public
    constructor Create(); virtual;
    destructor Destroy(); override;
    property URL: string read GetURL write SetURL;
    property Scheme: string read GetScheme write SetScheme;
    property Host: string read GetHost write SetHost;
    property Port: Integer read GetPort write SetPort;
    property Query: string read GetQuery write SetQuery;
    property Fragment: string read GetFragment write SetFragment;
    property IsPostMethod: Boolean read FIsPostMethod write FIsPostMethod;
    //获得请求头的字符串
    property RequestHead: AnsiString read GetRequestHead;
    property HeadItems[Index: string]: string read GetHeadItem write SetHeadItem; default;
  end;

  THttpResponse = class(TObject)
  private
    FHeadList: TStringList;
    FHttpVersion: string;
    FStatusCode: Integer;
    FStatusText: string;
    FData: Pointer;
    FDataLen: LongWord;
    function GetHeadItem(Index: string): string;
    function GetHeadText: string;
  protected
    procedure BeginRecvContent(); virtual; abstract;
    procedure RecvingContent(Data: Pointer; DataLen: DWORD);virtual; abstract;
    function GetContentLength():Int64;virtual; abstract;
    procedure EndRecvContent(); virtual; abstract;
  public
    constructor Create(); reintroduce; virtual;
    destructor Destroy(); override;
    property HeadItems[Index: string]: string read GetHeadItem; default;
    property HeadText: string read GetHeadText;
    property HttpVersion: string read FHttpVersion;
    property StatusCode: Integer read FStatusCode;
    property StatusText: string read FStatusText;
    property ContentLength: Int64 read GetContentLength;
  end;

  TStreamHttpRequest = class(THttpRequest)
  private
    FContentStream: TStream;
  protected
    procedure BeginSendContent(); override;
    function GetContentLength():Int64;override;
    function SendingContent(Data: Pointer; var DataLen: DWORD): Boolean; override;
    procedure EndSendContent(); override;
  public
    property ContentStream: TStream read FContentStream write FContentStream;
  end;

  TStreamHttpResponse = class(THttpResponse)
  private
    FContentStream: TStream;
  protected
    procedure BeginRecvContent(); override;
    procedure RecvingContent(Data: Pointer; DataLen: DWORD);override;
    function GetContentLength():Int64;override;
    procedure EndRecvContent(); override;
  public
    property ContentStream: TStream read FContentStream write FContentStream;
  end;

  TMemoryStreamHttpResponse = class (TStreamHttpResponse)
  private
    FContentStream: TMemoryStream;
  public
    constructor Create(); override;
    destructor Destroy(); override;
    property ContentStream: TMemoryStream read FContentStream;
  end;

  THttpObj = class(TSocketObj)
  private
    FHttpRequest: THttpRequest;
    FHttpResponse: THttpResponse;
    //是否接受完头部信息
    FRecvHeadCompleted: Boolean;
    // 消息体长度，-1表示没有此项
    FContent_Length: Int64;
    function RequesttoBinData(HttpRequest: THttpRequest; var BinData: Pointer;
      var BinDataLen: LongWord): Boolean;
    procedure SetHttpRequest(const Value: THttpRequest);
    procedure SetHttpResponse(const Value: THttpResponse);
  protected
    function Init(): Boolean; override;
  public
    destructor Destroy(); override;

    function ConnectSer(IOCPList: TIOCPHttpClientList; const SerAddr: string; Port: Integer;
      IncRefNumber: Integer): Boolean; reintroduce;
    // 发送请求给服务器，可用于重复发送
    function SendRequest(): Boolean;

    property HttpRequest: THttpRequest read FHttpRequest write SetHttpRequest;
    property HttpResponse: THttpResponse read FHttpResponse write SetHttpResponse;
    property RecvHeadCompleted: Boolean read FRecvHeadCompleted;
    property Content_Length: Int64 read FContent_Length;
  end;

  TOnHTTPRecvHeadCompletedEvent = procedure(HttpObj: THttpObj) of object;
  TOnHTTPRecvCompletedEvent = procedure(HttpObj: THttpObj) of object;
  TOnHTTPRecvErrorEvent = procedure(HttpObj: THttpObj) of object;
  TOnHTTPCloseEvent = procedure(HttpObj: THttpObj) of object;
  TOnHTTPRecvingEvent = procedure(HttpObj: THttpObj; RecvDataLen: Integer) of object;

  TIOCPHttpClientList = class(TIOCPBaseList)
  private
    // 事件
    FHTTPRecvHeadCompletedEvent: TOnHTTPRecvHeadCompletedEvent;
    FHTTPRecvCompletedEvent: TOnHTTPRecvCompletedEvent;
    FHTTPRecvErrorEvent: TOnHTTPRecvErrorEvent;
    FHTTPCloseEvent: TOnHTTPCloseEvent;
    FHTTPRecvingEvent: TOnHTTPRecvingEvent;
  protected
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); override;
  public
    constructor Create(AIOCPMgr: TIOCPManager); override;
  public
    property HTTPRecvHeadCompletedEvent: TOnHTTPRecvHeadCompletedEvent
      read FHTTPRecvHeadCompletedEvent write FHTTPRecvHeadCompletedEvent;
    property HTTPRecvCompletedEvent: TOnHTTPRecvCompletedEvent
      read FHTTPRecvCompletedEvent write FHTTPRecvCompletedEvent;
    property HTTPRecvErrorEvent: TOnHTTPRecvErrorEvent read FHTTPRecvErrorEvent
      write FHTTPRecvErrorEvent;
    property HTTPCloseEvent: TOnHTTPCloseEvent read FHTTPCloseEvent write FHTTPCloseEvent;
    property HTTPRecvingEvent: TOnHTTPRecvingEvent read FHTTPRecvingEvent
      write FHTTPRecvingEvent;
  end;

function DecodeURL(const URL: string): TURLRec;
function EncodeURL(const URLRec: TURLRec; IsPostMethod: Boolean): string;

implementation

function DecodeURL(const URL: string): TURLRec;
var
  I: Integer;
  tmpstr: string;
begin
  tmpstr := URL;
  I := Pos('://', tmpstr);
  if I > 0 then
  begin
    Result.Scheme := Copy(tmpstr, 1, I - 1);
    Delete(tmpstr, 1, I + 2);
  end
  else
  begin
    Result.Scheme := 'http';
  end;
  I := Pos('/', tmpstr);
  if I > 0 then
  begin
    Result.Host := Copy(tmpstr, 1, I - 1);
    Delete(tmpstr, 1, I);

    I := Pos(':', Result.Host);
    if I > 0 then
    begin
      if not TryStrToInt(Copy(Result.Host, I + 1, Length(Result.Host)), Result.Port) or
        (Result.Port < 0) or (Result.Port > 65535) then
      begin
        Result.Port := 80;
      end;
      Delete(Result.Host, I, Length(Result.Host));
    end
    else
    begin
      Result.Port := 80;
    end;

    I := Pos('?', tmpstr);
    if I > 0 then
    begin
      Result.Query := Copy(tmpstr, 1, I - 1);
      Delete(tmpstr, 1, I);
      Result.Fragment := tmpstr;
    end
    else
    begin
      Result.Query := tmpstr;
      Result.Fragment := '';
    end;
  end
  else
  begin
    Result.Host := tmpstr;
    Result.Port := 80;
    Result.Query := '';
    Result.Fragment := '';
  end;
end;

function EncodeURL(const URLRec: TURLRec; IsPostMethod: Boolean): string;
begin
  Result := URLRec.Scheme + '://' + URLRec.Host + ':' + IntToStr(URLRec.Port) + '/' +
    URLRec.Query;
  if not IsPostMethod and (URLRec.Fragment <> '') then
  begin
    Result := Result + '?' + URLRec.Fragment;
  end;
end;

{ TIOCPOBJHttpClient }

constructor TIOCPHttpClientList.Create(AIOCPMgr: TIOCPManager);
begin
  inherited;
end;

procedure TIOCPHttpClientList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
var
  HttpSock: THttpObj absolute SockObj;
  HeadTmp: AnsiString;
  HeadStatus: string;
  HeadEndIndex: Integer;
  DataBeginIndex: Integer;
  I: Integer;
  SendData: Pointer;
  SendDataLen: DWORD;
begin
  case EventType of
    ieAddSocket:
      ;
    ieDelSocket:
      begin
        if HttpSock.FRecvHeadCompleted then
        begin
          if HttpSock.FContent_Length < 0 then
          begin
            if Assigned(FHTTPRecvCompletedEvent) then
            begin
              FHTTPRecvCompletedEvent(HttpSock);
            end;
          end;
        end;
        if Assigned(FHTTPCloseEvent) then
        begin
          FHTTPCloseEvent(HttpSock);
        end;
      end;
    ieError:
      ;
    ieRecvPart:
      ;
    ieRecvAll:
      begin

        if not HttpSock.FRecvHeadCompleted then
        begin
          ReallocMem(HttpSock.FHttpResponse.FData, HttpSock.FHttpResponse.FDataLen +
            Overlapped.RecvDataLen);
          CopyMemory(PByte(HttpSock.FHttpResponse.FData) +
            HttpSock.FHttpResponse.FDataLen, Overlapped.RecvData, Overlapped.RecvDataLen);
          HttpSock.FHttpResponse.FDataLen := HttpSock.FHttpResponse.FDataLen +
            Overlapped.RecvDataLen;
          // 准备查找空行
          SetString(HeadTmp, PAnsiChar(HttpSock.FHttpResponse.FData),
            HttpSock.FHttpResponse.FDataLen);

          HeadEndIndex := Pos(AnsiString(#13#10#13#10), HeadTmp);
          // 找到协议头
          if HeadEndIndex > 0 then
          begin
            Delete(HeadTmp, HeadEndIndex, Length(HeadTmp));
            HttpSock.FHttpResponse.FHeadList.Text := string(HeadTmp);
            // 获取协议头第一行
            HeadStatus := HttpSock.FHttpResponse.FHeadList[0];
            HttpSock.FHttpResponse.FHeadList.Delete(0);
            // 获取HTTP协议版本
            I := Pos(' ', HeadStatus);
            HttpSock.FHttpResponse.FHttpVersion := Copy(HeadStatus, 1, I - 1);
            Delete(HeadStatus, 1, I);
            // 获取HTTP状态码
            I := Pos(' ', HeadStatus);
            HttpSock.FHttpResponse.FStatusCode := StrToInt(Copy(HeadStatus, 1, I - 1));
            Delete(HeadStatus, 1, I);
            // 获取HTTP状态码提示信息
            HttpSock.FHttpResponse.FStatusText := HeadStatus;

            // 更新数据区域
            DataBeginIndex := HeadEndIndex - 1 +
              Length(HttpSock.FHttpResponse.FHeadList.LineBreak) shl 1;
            HttpSock.FHttpResponse.BeginRecvContent;
            if Integer(HttpSock.FHttpResponse.FDataLen) - DataBeginIndex = 0 then
            begin

            end
            else
            begin
              // 写入到
              HttpSock.FHttpResponse.RecvingContent((PByte(HttpSock.FHttpResponse.FData) + DataBeginIndex), Integer(HttpSock.FHttpResponse.FDataLen) - DataBeginIndex);
              (*
              HttpSock.FHttpResponse.FDataStream.Seek(0, soEnd);
              HttpSock.FHttpResponse.FDataStream.
                Write((PByte(HttpSock.FHttpResponse.FData) + DataBeginIndex)^,
                Integer(HttpSock.FHttpResponse.FDataLen) - DataBeginIndex);
              *)
            end;
            FreeMem(HttpSock.FHttpResponse.FData);
            HttpSock.FHttpResponse.FData := nil;
            HttpSock.FHttpResponse.FDataLen := 0;
            // 协议头接受完成
            HttpSock.FRecvHeadCompleted := True;
            // 获取消息体长度(如果有)
            HttpSock.FContent_Length :=
              StrToIntDef(HttpSock.FHttpResponse['Content-Length'], -1);
            if Assigned(FHTTPRecvHeadCompletedEvent) then
            begin
              FHTTPRecvHeadCompletedEvent(HttpSock);
            end;
          end;
        end
        else
        begin
          HttpSock.FHttpResponse.RecvingContent(Overlapped.RecvData, Overlapped.RecvDataLen);
          (*
          HttpSock.FHttpResponse.FDataStream.Seek(0, soEnd);
          HttpSock.FHttpResponse.FDataStream.Write(Overlapped.RecvData^,
            Overlapped.RecvDataLen);
          *)
        end;
        if Assigned(FHTTPRecvingEvent) then
        begin
          FHTTPRecvingEvent(HttpSock, Overlapped.RecvDataLen);
        end;
        // 如果下载头完成
        if HttpSock.FRecvHeadCompleted then
        begin

          if HttpSock.FContent_Length >= 0 then
          begin
            // 如果下载完成，则激活事件
            if HttpSock.FContent_Length <= Integer(HttpSock.FHttpResponse.GetContentLength()) then
            begin
              if Assigned(FHTTPRecvCompletedEvent) then
              begin
                FHTTPRecvCompletedEvent(HttpSock);
              end;
            end;
          end;
        end;
      end;
    ieRecvFailed:
      begin
        if Assigned(FHTTPRecvErrorEvent) then
        begin
          FHTTPRecvErrorEvent(HttpSock);
        end;
      end;
    ieSendPart:
      ;
    ieSendAll:
      begin
        if HttpSock.FHttpRequest.IsPostMethod then
        begin
          SendDataLen := $1000;
          SendData := HttpSock.GetSendData(SendDataLen);
          if HttpSock.FHttpRequest.SendingContent(SendData, SendDataLen) then
          begin
            if not HttpSock.SendData(SendData, SendDataLen, True) then
            begin
              HttpSock.FHttpRequest.EndSendContent;
            end;
          end
          else
          begin
            HttpSock.FHttpRequest.EndSendContent;
          end;
        end;
      end;
    ieSendFailed:
      ;
  end;

end;

{ THttpObj }

function THttpObj.ConnectSer(IOCPList: TIOCPHttpClientList;
  const SerAddr: string; Port, IncRefNumber: Integer): Boolean;
begin
  result := inherited ConnectSer(IOCPList, SerAddr, Port, IncRefNumber);
end;

destructor THttpObj.Destroy;
begin
  
  inherited;
end;

function THttpObj.Init: Boolean;
begin
  SetRecvBufLenBeforeInit(40960);
  Result := inherited;
  if Result then
  begin
    FRecvHeadCompleted := False;
    FContent_Length := -1;
  end;
end;

function THttpObj.RequesttoBinData(HttpRequest: THttpRequest; var BinData: Pointer;
  var BinDataLen: LongWord): Boolean;
var
  RequestHead: AnsiString;
begin
  Result := False;
  RequestHead := HttpRequest.RequestHead;
  BinDataLen := Length(RequestHead) * sizeof(AnsiChar);
  BinData := GetSendData(BinDataLen);
  if BinData <> nil then
  begin
    CopyMemory(BinData, PAnsiChar(RequestHead), Length(RequestHead) * sizeof(AnsiChar));
    Result := True;
  end;
end;

function THttpObj.SendRequest(): Boolean;
var
  ReqData: Pointer;
  ReqDataLen: LongWord;
begin
  Result := False;
  if FHttpRequest=nil then
  begin
    raise Exception.Create('FHttpRequest must be set');
  end;

  if FHttpResponse=nil then
  begin
    raise Exception.Create('HttpResponse must be set');
  end;

  if RequesttoBinData(HttpRequest, ReqData, ReqDataLen) then
  begin
    if FHttpRequest.IsPostMethod then
    begin
      FHttpRequest.BeginSendContent;

    end;
    if not SendData(ReqData, ReqDataLen, True) then
    begin
      if FHttpRequest.IsPostMethod then
      begin
        FHttpRequest.EndSendContent;
      end;
    end;
  end;
end;

procedure THttpObj.SetHttpRequest(const Value: THttpRequest);
begin
  FHttpRequest := Value;
end;

procedure THttpObj.SetHttpResponse(const Value: THttpResponse);
begin
  FHttpResponse := Value;
end;

{ THttpRequest }

constructor THttpRequest.Create;
begin
  inherited;
  FHeadList := TStringList.Create();
  FHeadList.NameValueSeparator := ':'; // 设置分隔符
  FHeadList.LineBreak := #13#10;
  // 预先的设置
  HeadItems[HEADER_ACCPET] := 'text/html, application/xhtml+xml, application/json, */*';
  HeadItems[HEADER_ACCEPT_LANGUAGE] := 'zh-CN';
  HeadItems[HEADER_ENCODING] := 'Encoding';
  HeadItems[HEADER_CONNECTION] := 'Keep-Alive';
  HeadItems[HEADER_USER_AGENT] :=
    'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)';
end;

destructor THttpRequest.Destroy;
begin
  FHeadList.Free();
  inherited;
end;

function THttpRequest.GetFragment: string;
begin
  Result := FURLRec.Fragment;
end;

function THttpRequest.GetHeadItem(Index: string): string;
begin
  Result := FHeadList.Values[Index];
end;

function THttpRequest.GetHost: string;
begin
  Result := FURLRec.Host;
end;

function THttpRequest.GetPort: Integer;
begin
  Result := FURLRec.Port;
end;

function THttpRequest.GetQuery: string;
begin
  Result := FURLRec.Query;
end;

function THttpRequest.GetRequestHead: AnsiString;
var
  tmpstr: string;
begin
  if not FIsPostMethod then
  begin
    tmpstr := 'GET /' + FURLRec.Query;
    if FURLRec.Fragment <> '' then
    begin
      tmpstr := tmpstr + '?' + FURLRec.Fragment;
    end;
  end
  else
  begin
    tmpstr := 'POST /' + FURLRec.Query;
  end;
  FHeadList.Values[HEADER_HOST] := FURLRec.Host;
  Result := AnsiString(tmpstr + ' HTTP/1.1' + FHeadList.LineBreak + FHeadList.Text +
    FHeadList.LineBreak);
end;

function THttpRequest.GetScheme: string;
begin
  Result := FURLRec.Scheme;
end;

function THttpRequest.GetURL: string;
begin
  Result := EncodeURL(FURLRec, IsPostMethod);
end;

procedure THttpRequest.SetFragment(const Value: string);
begin
  FURLRec.Fragment := Value;
end;

procedure THttpRequest.SetHeadItem(Index: string; const Value: string);
begin
  FHeadList.Values[Index] := Value;
end;

procedure THttpRequest.SetHost(const Value: string);
begin
  FURLRec.Host := Value;
end;

procedure THttpRequest.SetPort(const Value: Integer);
begin
  FURLRec.Port := Value;
end;

procedure THttpRequest.SetQuery(const Value: string);
begin
  FURLRec.Query := Value;
end;

procedure THttpRequest.SetScheme(const Value: string);
begin
  FURLRec.Scheme := Value;
end;

procedure THttpRequest.SetURL(const Value: string);
begin
  FURLRec := DecodeURL(Value);
end;

{ THttpResponse }

constructor THttpResponse.Create();
begin
  inherited Create();
  FHeadList := TStringList.Create();
  FHeadList.NameValueSeparator := ':'; // 设置分隔符
  FHeadList.LineBreak := #13#10;
end;

destructor THttpResponse.Destroy;
begin
  FHeadList.Free();
  if FData <> nil then
  begin
    FreeMem(FData);
  end;
  inherited;
end;

function THttpResponse.GetHeadItem(Index: string): string;
begin
  Result := FHeadList.Values[Index];
end;

function THttpResponse.GetHeadText: string;
begin
  Result := FHeadList.Text;
end;

{ TURLRec }

class operator TURLRec.Implicit(Source: TURLRec): string;
begin
  Result := EncodeURL(Source, False);
end;

class operator TURLRec.Implicit(Source: string): TURLRec;
begin
  Result := DecodeURL(Source);

end;

{ TStreamHttpResponse }

procedure TStreamHttpResponse.BeginRecvContent;
begin
  if FContentStream = nil then
  begin
    raise Exception.Create('ContentStream must be set');
  end;
  FContentStream.Size := 0;
end;

procedure TStreamHttpResponse.EndRecvContent;
begin
  //
end;

function TStreamHttpResponse.GetContentLength: Int64;
begin
  Result := FContentStream.Size;
end;

procedure TStreamHttpResponse.RecvingContent(Data: Pointer; DataLen: DWORD);
begin
  FContentStream.Write(Data^, DataLen);
end;

{ TStreamHttpRequest }

procedure TStreamHttpRequest.BeginSendContent;
begin
  if FContentStream = nil then
  begin
    raise Exception.Create('ContentStream must be set');
  end;
  FContentStream.Position := 0;
end;

procedure TStreamHttpRequest.EndSendContent;
begin
  //
end;

function TStreamHttpRequest.GetContentLength: Int64;
begin
  Result := FContentStream.Size;
end;

function TStreamHttpRequest.SendingContent(Data: Pointer;
  var DataLen: DWORD): Boolean;
begin
   DataLen := FContentStream.Read(Data^, DataLen);
   Result := DataLen > 0;
end;

{ TMemoryStreamHttpResponse }

constructor TMemoryStreamHttpResponse.Create;
begin
  inherited;
  FContentStream := TMemoryStream.Create();
  inherited ContentStream := FContentStream;
end;

destructor TMemoryStreamHttpResponse.Destroy;
begin
  FContentStream.Free;
  inherited;
end;

end.
