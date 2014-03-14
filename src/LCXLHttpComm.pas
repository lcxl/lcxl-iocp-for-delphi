unit LCXLHttpComm;
(* **************************************************************************** *)
(* 作者: LCXL *)
(* E-mail: lcx87654321@163.com *)
(* 说明: IOCP Http共同类定义单元 *)
(* **************************************************************************** *)
interface

uses
  Windows, SysUtils, Classes, Generics.Collections;

type
  //URL数据结构
  TURLRec = record
    // 协议名称，本类只支持HTTP
    Scheme: AnsiString;
    // 如www.baidu.com
    Host: AnsiString;
    // 端口号，默认为80
    Port: Integer;
    // 查询路径，如/sss/sss/ssd.asp
    Query: AnsiString;
    // 参数，如sss=ssd&sdfs=sdr，在POST方法中，此为空
    Fragment: AnsiString;
  private
    procedure SetQueryAndFragment(const Value: AnsiString);
    function GetQueryAndFragment: AnsiString;
  public
    property QueryAndFragment: AnsiString read GetQueryAndFragment write SetQueryAndFragment;

  public
    // 重载操作符:=，隐形转换
    {$IFDEF UNICODE}
    class operator Implicit(Source: AnsiString): TURLRec; overload;
    {$ENDIF UNICODE}
    class operator Implicit(Source: TURLRec): string; overload;
    class operator Implicit(Source: string): TURLRec; overload;
  end;
  PURLRec = ^TURLRec;

  THeadRec = record
    Key: AnsiString;
    Value: AnsiString;
  end;
  PHeadRec = ^THeadRec;

  THeadList = class(TList<THeadRec>)
  protected
    function GetHeadItems(Index: AnsiString): AnsiString;
    procedure SetHeadItems(Index: AnsiString; const Value: AnsiString);
  public
    ///	<summary>
    ///	  保存到字符串中
    ///	</summary>
    ///	<param name="Separator">
    ///	  分隔符，默认为": "（冒号加空格）
    ///	</param>
    ///	<param name="LineBreak">
    ///	  换行符，默认为#13#10
    ///	</param>
    ///	<returns>
    ///	  格式化好的请求/响应字符串列表，字符串末尾以换行符结尾
    ///	</returns>
    function SaveToString(const Separator: AnsiString; const LineBreak: AnsiString): AnsiString;

    ///	<summary>
    ///	  从字符串加载请求/响应头
    ///	</summary>
    ///	<param name="AStr">
    ///	  字符串，末尾需要以LinkBreak结尾
    ///	</param>
    ///	<param name="Separator">
    ///	  分隔符，为了保证最大兼容性，此处应该只能是":"
    ///	</param>
    ///	<param name="LineBreak">
    ///	  换行符，一般是#13#10
    ///	</param>
    function LoadFromString(const AStr: AnsiString; const Separator: AnsiString; const LineBreak: AnsiString): Boolean;
    property HeadItems[Index: AnsiString]: AnsiString read GetHeadItems write SetHeadItems; default;
  end;

  THttpHeadList = class(THeadList)
  private
    function GetHeadText: AnsiString;
    procedure SetHeadText(const Value: AnsiString);
  public
    function GetContentLength(): Int64; virtual; abstract;
    procedure BeginTransferContent(IsWriteContent: Boolean); virtual; abstract;
    function TransferingContent(Data: Pointer; DataLen: DWORD): DWORD;
      virtual; abstract;
    procedure EndTransferContent(); virtual; abstract;
  public
    property HeadText: AnsiString read GetHeadText write SetHeadText;
  end;

const
  HTTP_LINE_BREAK: AnsiString = #13#10;
  DOUBLE_HTTP_LINE_BREAK: AnsiString = #13#10#13#10;
const
  REQUEST_ACCPET = 'Accept';
  REQUEST_HOST = 'Host';
  REQUEST_ENCODING = 'Encoding';
  REQUEST_REFERER = 'Referer';
  REQUEST_CONNECTION = 'Connection';
  REQUEST_USER_AGENT = 'User-Agent';
  REQUEST_ACCEPT_CHARSET = 'Accept-Charset';
  REQUEST_ACCEPT_ENCODING = 'Accept-Encoding';
  REQUEST_ACCEPT_LANGUAGE = 'Accept-Language';
  REQUEST_CACHE_COONTROL = 'Cache-Control';
  REQUEST_COOKIE = 'Cookie';

type
  THttpRequest = class(THttpHeadList)
  private
    FURLRec: TURLRec;
    FIsPostMethod: Boolean;
    function GetFragment: AnsiString;
    function GetHost: AnsiString;
    function GetPort: Integer;
    function GetQuery: AnsiString;
    function GetScheme: AnsiString;
    function GetURL: AnsiString;
    procedure SetFragment(const Value: AnsiString);
    procedure SetHost(const Value: AnsiString);
    procedure SetPort(const Value: Integer);
    procedure SetQuery(const Value: AnsiString);
    procedure SetScheme(const Value: AnsiString);
    procedure SetURL(const Value: AnsiString);
    function GetRequestHead: AnsiString;
    procedure SetRequestHead(const Value: AnsiString);
  public
    constructor Create(); virtual;
    destructor Destroy(); override;
    property URL: AnsiString read GetURL write SetURL;
    property Scheme: AnsiString read GetScheme write SetScheme;
    property Host: AnsiString read GetHost write SetHost;
    property Port: Integer read GetPort write SetPort;
    property Query: AnsiString read GetQuery write SetQuery;
    property Fragment: AnsiString read GetFragment write SetFragment;
    property IsPostMethod: Boolean read FIsPostMethod write FIsPostMethod;
    // 设置获得请求头的字符串，末尾是两个Linebreak
    property RequestHead: AnsiString read GetRequestHead write SetRequestHead;
  end;

const
  RESPONSE_CONTENT_TYPE = 'Content-Type';
  RESPONSE_CONTENT_LENGTH = 'Content-Length';
  RESPONSE_DATE = 'Date';
  RESPONSE_LOCATION = 'Location';
type
  THttpResponse = class(THttpHeadList)
  private
    FHttpVersion: AnsiString;
    FStatusCode: Integer;
    FStatusText: AnsiString;
    function GetResponseHead: AnsiString;
    procedure SetResponseHead(const Value: AnsiString);
  public
    constructor Create(); reintroduce; virtual;
    destructor Destroy(); override;
    property HttpVersion: AnsiString read FHttpVersion write FHttpVersion;
    property StatusCode: Integer read FStatusCode write FStatusCode;
    property StatusText: AnsiString read FStatusText write FStatusText;
    property ContentLength: Int64 read GetContentLength;
    // 设置获得请求头的字符串，末尾是两个Linebreak
    property ResponseHead: AnsiString read GetResponseHead write SetResponseHead;
  end;

  TStreamHttpRequest = class(THttpRequest)
  private
    FContentStream: TStream;
    FIsWriteContent: Boolean;
  public
    function GetContentLength(): Int64; override;
    procedure BeginTransferContent(IsWriteContent: Boolean); override;
    function TransferingContent(Data: Pointer; DataLen: DWORD): DWORD;override;
    procedure EndTransferContent(); override;
  public
    property ContentStream: TStream read FContentStream write FContentStream;
  end;

  TStreamHttpResponse = class(THttpResponse)
  private
    FContentStream: TStream;
    FIsWriteContent: Boolean;
  public
    function GetContentLength(): Int64; override;
    procedure BeginTransferContent(IsWriteContent: Boolean); override;
    function TransferingContent(Data: Pointer; DataLen: DWORD): DWORD; override;
    procedure EndTransferContent(); override;
  public
    property ContentStream: TStream read FContentStream write FContentStream;
  end;

  TMemoryStreamHttpResponse = class(TStreamHttpResponse)
  private
    FContentStream: TMemoryStream;
  public
    constructor Create(); override;
    destructor Destroy(); override;
    property ContentStream: TMemoryStream read FContentStream;
  end;

function DecodeURL(const URL: AnsiString): TURLRec;
function EncodeURL(const URLRec: TURLRec; IsPostMethod: Boolean): AnsiString;

implementation

function DecodeURL(const URL: AnsiString): TURLRec;
var
  I: Integer;
  tmpstr: AnsiString;
begin
  tmpstr := URL;
  I := Pos(AnsiString('://'), tmpstr);
  if I > 0 then
  begin
    Result.Scheme := Copy(tmpstr, 1, I - 1);
    Delete(tmpstr, 1, I + 2);
  end
  else
  begin
    Result.Scheme := 'http';
  end;
  I := Pos(AnsiString('/'), tmpstr);
  if I > 0 then
  begin
    Result.Host := Copy(tmpstr, 1, I - 1);
    Delete(tmpstr, 1, I-1);

    I := Pos(AnsiString(':'), Result.Host);
    if I > 0 then
    begin
      if not TryStrToInt(Copy(string(Result.Host), I + 1, Length(Result.Host)),
        Result.Port) or (Result.Port < 0) or (Result.Port > 65535) then
      begin
        Result.Port := 80;
      end;
      Delete(Result.Host, I, Length(Result.Host));
    end
    else
    begin
      Result.Port := 80;
    end;
    Result.SetQueryAndFragment(tmpstr);
  end
  else
  begin
    Result.Host := tmpstr;
    Result.Port := 80;
    Result.Query := '/';
    Result.Fragment := '';
  end;
end;

function EncodeURL(const URLRec: TURLRec; IsPostMethod: Boolean): AnsiString;
var
  _Query: AnsiString;
begin
  _Query := URLRec.Query;
  if _Query = '' then
  begin
    _Query := '/';
  end;
  if _Query[1] <> '/' then
  begin
    raise Exception.Create('Query不合法');
  end;
  Result := URLRec.Scheme + '://' + URLRec.Host + ':' + AnsiString(IntToStr(URLRec.Port)) +
    _Query;
  if not IsPostMethod and (URLRec.Fragment <> '') then
  begin
    Result := Result + '?' + URLRec.Fragment;
  end;
end;

{ THttpRequest }

constructor THttpRequest.Create;
begin
  inherited;
  // 预先的设置
  HeadItems[REQUEST_ACCPET] :=
    'text/html, application/xhtml+xml, application/json, */*';
  HeadItems[REQUEST_ACCEPT_LANGUAGE] := 'zh-CN';
  HeadItems[REQUEST_ENCODING] := 'Encoding';
  HeadItems[REQUEST_CONNECTION] := 'Keep-Alive';
  HeadItems[REQUEST_USER_AGENT] :=
    'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0)';
end;

destructor THttpRequest.Destroy;
begin
  inherited;
end;

function THttpRequest.GetFragment: AnsiString;
begin
  Result := FURLRec.Fragment;
end;

function THttpRequest.GetHost: AnsiString;
begin
  Result := FURLRec.Host;
end;

function THttpRequest.GetPort: Integer;
begin
  Result := FURLRec.Port;
end;

function THttpRequest.GetQuery: AnsiString;
begin
  Result := FURLRec.Query;
end;

function THttpRequest.GetRequestHead: AnsiString;
var
  tmpstr: AnsiString;
begin
  if not FIsPostMethod then
  begin
    tmpstr := 'GET ' + FURLRec.Query;
    if FURLRec.Fragment <> '' then
    begin
      tmpstr := tmpstr + '?' + FURLRec.Fragment;
    end;
  end
  else
  begin
    tmpstr := 'POST ' + FURLRec.Query;
  end;
  HeadItems[REQUEST_HOST] := FURLRec.Host;
  Result := tmpstr + ' HTTP/1.1' + HTTP_LINE_BREAK +
    HeadText + HTTP_LINE_BREAK;
end;

function THttpRequest.GetScheme: AnsiString;
begin
  Result := FURLRec.Scheme;
end;

function THttpRequest.GetURL: AnsiString;
begin
  Result := EncodeURL(FURLRec, IsPostMethod);
end;

procedure THttpRequest.SetFragment(const Value: AnsiString);
begin
  FURLRec.Fragment := Value;
end;

procedure THttpRequest.SetHost(const Value: AnsiString);
begin
  FURLRec.Host := Value;
end;

procedure THttpRequest.SetPort(const Value: Integer);
begin
  FURLRec.Port := Value;
end;

procedure THttpRequest.SetQuery(const Value: AnsiString);
begin
  FURLRec.Query := Value;
end;

procedure THttpRequest.SetRequestHead(const Value: AnsiString);
var
  tmpstr: AnsiString;
  tmpstr1: AnsiString;
  I: Integer;
  J: Integer;
  K: Integer;
begin
  if Pos(AnsiString(DOUBLE_HTTP_LINE_BREAK), Value)<=0 then
  begin
    raise Exception.Create('Invalid Parameter');
  end;
  I := Pos(HTTP_LINE_BREAK, Value);
  tmpstr := Copy(Value,  1, I-1);
  J := Pos(AnsiString(' '), tmpstr);
  tmpstr1 := Copy(tmpstr, 1, J-1);
  if tmpstr1 = 'POST' then
  begin
    FIsPostMethod := True;
  end
  else if tmpstr1 = 'GET' then
  begin
    FIsPostMethod := False;
  end
  else
  begin
    raise Exception.Create('Invalid action');
  end;
  K := Pos(AnsiString(' '), tmpstr, J+1);
  if K <= 0 then
  begin
    FURLRec.QueryAndFragment := Copy(tmpstr, J+1, Length(tmpstr));
  end
  else
  begin
    FURLRec.QueryAndFragment := Copy(tmpstr, J+1, K-J);
  end;
  FURLRec.Scheme := 'http';
  FURLRec.Port := 80;
  HeadText := Copy(Value, I-1+Length(HTTP_LINE_BREAK), Length(Value));
  FURLRec.Host := HeadItems[REQUEST_HOST];
end;

procedure THttpRequest.SetScheme(const Value: AnsiString);
begin
  FURLRec.Scheme := Value;
end;

procedure THttpRequest.SetURL(const Value: AnsiString);
begin
  FURLRec := DecodeURL(Value);
end;

{ THttpResponse }

constructor THttpResponse.Create();
begin
  inherited Create();
end;

destructor THttpResponse.Destroy;
begin

  inherited;
end;

function THttpResponse.GetResponseHead: AnsiString;
begin
  Result := AnsiString('HTTP/1.1 ') + AnsiString(IntToStr(FStatusCode))+FStatusText+HTTP_LINE_BREAK+HeadText+HTTP_LINE_BREAK;
end;

procedure THttpResponse.SetResponseHead(const Value: AnsiString);
var
  I: Integer;
  HeadStatus: AnsiString;
  HeadTmp: AnsiString;
begin
  if Pos(DOUBLE_HTTP_LINE_BREAK, Value)<=0 then
  begin
    raise Exception.Create('Error Message');
  end;
  HeadTmp := Value;
  // 获取协议头第一行
  I := Pos(HTTP_LINE_BREAK, HeadTmp);
  HeadStatus := Copy(HeadTmp, 1, I-1);
  System.Delete(HeadTmp, 1, I-1+Length(HTTP_LINE_BREAK));
  HeadText := HeadTmp;
  // 获取HTTP协议版本
  I := Pos(AnsiString(' '), HeadStatus);
  HttpVersion := Copy(HeadStatus, 1, I - 1);
  System.Delete(HeadStatus, 1, I);
  // 获取HTTP状态码
  I := Pos(AnsiString(' '), HeadStatus);
  StatusCode := StrToInt(Copy(string(HeadStatus), 1, I - 1));
  System.Delete(HeadStatus, 1, I);
  // 获取HTTP状态码提示信息
  StatusText := HeadStatus;
end;

{ TURLRec }

class operator TURLRec.Implicit(Source: TURLRec): string;
begin
  Result := string(EncodeURL(Source, False));
end;

function TURLRec.GetQueryAndFragment: AnsiString;
begin
  if Fragment <> '' then
  begin
    Result := Query+'?'+Fragment;
  end
  else
  begin
    Result := Query;
  end;
end;

class operator TURLRec.Implicit(Source: string): TURLRec;
begin
  Result := string(DecodeURL(AnsiString(Source)));

end;
procedure TURLRec.SetQueryAndFragment(const Value: AnsiString);
var
  tmpstr: AnsiString;
  I: Integer;
begin
  tmpstr := Value;
  if tmpstr = '' then
  begin
    tmpstr := '/';
  end;
  if tmpstr[1] <> '/' then
  begin
    raise Exception.Create('Invalid Parameter');
  end;
  I := Pos(AnsiString('?'), tmpstr);
  if I<=0 then
  begin
    Query := tmpstr;
    Fragment := '';
  end
  else
  begin
    Query := Copy(tmpstr, 1, I-1);
    Fragment := Copy(tmpstr, I+1, Length(tmpstr));
  end;
end;

{$IFDEF UNICODE}
class operator TURLRec.Implicit(Source: AnsiString): TURLRec;
begin
  Result := DecodeURL(Source);
end;
{$ENDIF}
{ TStreamHttpResponse }

procedure TStreamHttpResponse.BeginTransferContent(IsWriteContent: Boolean);
begin
  FIsWriteContent := IsWriteContent;
  if FContentStream = nil then
  begin
    raise Exception.Create('ContentStream must be set');
  end;
  FContentStream.Size := 0;
end;

procedure TStreamHttpResponse.EndTransferContent;
begin
  //
end;

function TStreamHttpResponse.GetContentLength: Int64;
begin
  Result := FContentStream.Size;
end;

function TStreamHttpResponse.TransferingContent(Data: Pointer; DataLen: DWORD): DWORD;
begin
  if FIsWriteContent then
  begin
    Result := FContentStream.Write(Data^, DataLen);
  end
  else
  begin
    Result := FContentStream.Read(Data^, DataLen);
  end;
end;

{ TStreamHttpRequest }

procedure TStreamHttpRequest.BeginTransferContent(IsWriteContent: Boolean);
begin
  if FContentStream = nil then
  begin
    raise Exception.Create('ContentStream must be set');
  end;
  FIsWriteContent := IsWriteContent;
  FContentStream.Position := 0;
end;

procedure TStreamHttpRequest.EndTransferContent;
begin
  //
end;

function TStreamHttpRequest.GetContentLength: Int64;
begin
  Result := FContentStream.Size;
end;

function TStreamHttpRequest.TransferingContent(Data: Pointer;
  DataLen: DWORD): DWORD;
begin
  if FIsWriteContent then
  begin
    Result := FContentStream.Write(Data^, DataLen);
  end
  else
  begin
    Result := FContentStream.Read(Data^, DataLen);
  end;
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

{ THeadList }

function THeadList.GetHeadItems(Index: AnsiString): AnsiString;
var
  TmpHead: THeadRec;
begin
  Result := '';
  for TmpHead in Self do
  begin
    if TmpHead.Key = Index then
    begin
      Result := TmpHead.Value;
      Break;
    end;
  end;
end;

function THeadList.LoadFromString(const AStr, Separator,
  LineBreak: AnsiString): Boolean;
var
  BIndex, EIndex: Integer;
  I: Integer;
  TmpStr: AnsiString;
  NewHeadRec: THeadRec;
begin
  Result := False;
  if (AStr = '') or (Separator = '') or (LineBreak = '') or
    (Length(AStr)>=Length(LineBreak)) then
  begin
    Exit;
  end;

  Clear;
  BIndex := 1;
  EIndex := Pos(LineBreak, AStr, BIndex);
  while(EIndex > 0)do
  begin
    TmpStr := Copy(AStr, BIndex, EIndex-BIndex);
    I := Pos(Separator, TmpStr);
    if I > 0 then
    begin
      NewHeadRec.Key := AnsiString(Trim(Copy(string(TmpStr), 1, I-1)));
      NewHeadRec.Value := AnsiString(Trim(string(Copy(TmpStr, I+1, Length(TmpStr)-I))));
      Add(NewHeadRec);
    end;

    Inc(BIndex, Length(LineBreak));
    EIndex := Pos(LineBreak, AStr, BIndex);
  end;
  Result := True;
end;

function THeadList.SaveToString(const Separator, LineBreak: AnsiString): AnsiString;
var
  TmpHead: THeadRec;
begin
  Result := '';
  Assert((Separator <> '') and (LineBreak <> ''));
  for TmpHead in Self do
  begin
    Result := Result + TmpHead.Key + Separator + TmpHead.Value + LineBreak;
  end;
end;

procedure THeadList.SetHeadItems(Index: AnsiString; const Value: AnsiString);
var
  I: Integer;
  TmpHead: THeadRec;
  Found: Boolean;
begin
  Found := False;
  for I := 0 to Count-1 do
  begin
    if (Items[I].Key = Index) then
    begin
      TmpHead := Items[I];
      TmpHead.Value := Value;
      Items[I] := TmpHead;
      Found := True;
      Break;
    end;
  end;
  if not Found then
  begin
    TmpHead.Key := Index;
    TmpHead.Value := Value;
    Add(TmpHead);
  end;
end;

{ THttpHeadList }

function THttpHeadList.GetHeadText: AnsiString;
begin
  Result := SaveToString(': ', HTTP_LINE_BREAK);
end;

procedure THttpHeadList.SetHeadText(const Value: AnsiString);
begin
  LoadFromString(Value, ':', HTTP_LINE_BREAK);
end;

end.
