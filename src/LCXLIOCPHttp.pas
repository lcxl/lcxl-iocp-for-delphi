unit LCXLIOCPHttp;

interface
uses
  Windows, Sysutils, Classes, LCXLIOCPBase, LCXLHttpComm;
type
  THttpBaseObj = class(TSocketObj)
  private
    FHttpRequest: THttpRequest;
    FHttpResponse: THttpResponse;

    //是否接受完头部信息
    FRecvHeadCompleted: Boolean;
    // 消息体长度，-1表示没有此项
    FContent_Length: Int64;
  protected
    function Init(): Boolean; override;
  public
    property HttpRequest: THttpRequest read FHttpRequest write FHttpRequest;
    property HttpResponse: THttpResponse read FHttpResponse write FHttpResponse;
    property RecvHeadCompleted: Boolean read FRecvHeadCompleted write FRecvHeadCompleted;
    property Content_Length: Int64 read FContent_Length write FContent_Length;
  end;

  TOnHTTPRecvHeadCompletedEvent = procedure(HttpObj: THttpBaseObj) of object;
  TOnHTTPRecvCompletedEvent = procedure(HttpObj: THttpBaseObj) of object;
  TOnHTTPRecvErrorEvent = procedure(HttpObj: THttpBaseObj) of object;
  TOnHTTPCloseEvent = procedure(HttpObj: THttpBaseObj) of object;
  TOnHTTPRecvingEvent = procedure(HttpObj: THttpBaseObj; RecvDataLen: Integer) of object;


  TIOCPHttpBaseList = class(TCustomIOCPBaseList)
  end;
implementation

{ THttpObj }

function THttpBaseObj.Init: Boolean;
begin
  SetRecvBufLenBeforeInit(40960);
  Result := inherited;
  if Result then
  begin
    FRecvHeadCompleted := False;
    FContent_Length := -1;
  end;
end;

{ TIOCPHttpBaseList }


end.
