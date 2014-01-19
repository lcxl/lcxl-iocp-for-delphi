unit untTest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, DateUtils, Menus,
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, VclTee.TeeGDIPlus,

  LCXLWinSock2, LCXLIOCPBase(*, LCXLIOCPLcxl, LCXLIOCPCmd*), LCXLIOCPHttpCli, untIOCPPageForm, LCXLHttpComm;

type
  TfrmIOCPTest = class(TForm)
    pgcTotal: TPageControl;
    tsHttpTest2: TTabSheet;
    lblHttpNum: TLabel;
    edtURL: TEdit;
    btnEnter: TButton;
    edtRequestNum: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnWaitClick(Sender: TObject);
    procedure btnEnterClick(Sender: TObject);
  private
    { Private declarations }
    FIOCPMgr: TIOCPManager;
    FIOCPHttp: TIOCPHttpClientList;

    FIOCPTabSheets: array[TIOCP_MODE_ENUM] of TTabSheet;
    function FormatSpeed(Speed: Double): string;

    // HTTP
    procedure OnHTTPRecvHeadCompletedEvent(HttpObj: THttpCliObj);
    procedure OnHTTPRecvCompletedEvent(HttpObj: THttpCliObj);
    procedure OnHTTPRecvErrorEvent(HttpObj: THttpCliObj);
    procedure OnHTTPCloseEvent(HttpObj: THttpCliObj);
    procedure OnHTTPRecvingEvent(HttpObj: THttpCliObj; RecvDataLen: Integer);

  public
    { Public declarations }
  end;

var
  frmIOCPTest: TfrmIOCPTest;

implementation

{$R *.dfm}

procedure TfrmIOCPTest.btnEnterClick(Sender: TObject);
var
  SockObj: THttpCliObj;
  Request: TStreamHttpRequest;
  I: Integer;
begin
  Request := TStreamHttpRequest.Create;
  Request[REQUEST_ACCEPT_ENCODING] := 'gzip';
  Request.URL := AnsiString(edtURL.Text);
  for I := 0 to StrToInt(edtRequestNum.Text)-1 do
  begin
    SockObj := THttpCliObj.Create;

    if not SockObj.ConnectSer(FIOCPHttp, string(Request.Host), Request.Port, 1) then
    begin
      Request.Free;
      SockObj.Free;
    end
    else
    begin
      SockObj.HttpRequest := Request;
      SockObj.HttpResponse := TMemoryStreamHttpResponse.Create();
      SockObj.SendRequest();
      SockObj.DecRefCount();
    end;
  end;
end;

procedure TfrmIOCPTest.btnWaitClick(Sender: TObject);
var
  hEvent: THandle;
begin
  hEvent := CreateEvent(nil, False, False, nil);
  WaitForSingleObject(hEvent, INFINITE);
end;

function TfrmIOCPTest.FormatSpeed(Speed: Double): string;
begin
  if Speed < 1000 then
  begin
    Result := Format('%f b/s', [Speed]);
  end
  else if Speed < 1000 * 1024 then
  begin
    Result := Format('%f k/s', [Speed / 1024]);
  end
  else if Speed < 1000 * 1024 * 1024 then
  begin
    Result := Format('%f m/s', [Speed / 1024 / 1024]);
  end
  else
  begin
    Result := Format('%f g/s', [Speed / 1024 / 1024 / 1024]);
  end;
end;

procedure TfrmIOCPTest.FormCreate(Sender: TObject);
begin

  ReportMemoryLeaksOnShutdown := True;

  FIOCPMgr := TIOCPManager.Create();

  FIOCPTabSheets[IM_BASE] := CreateIOCPTabSheet(pgcTotal, FIOCPMgr, IM_BASE);
  FIOCPTabSheets[IM_LCXL] := CreateIOCPTabSheet(pgcTotal, FIOCPMgr, IM_LCXL);
  FIOCPTabSheets[IM_CMD] :=  CreateIOCPTabSheet(pgcTotal, FIOCPMgr, IM_CMD);



  FIOCPHttp := TIOCPHttpClientList.Create(FIOCPMgr);
  FIOCPHttp.HTTPRecvHeadCompletedEvent := OnHTTPRecvHeadCompletedEvent;
  FIOCPHttp.HTTPRecvCompletedEvent := OnHTTPRecvCompletedEvent;
  FIOCPHttp.HTTPRecvErrorEvent := OnHTTPRecvErrorEvent;
  FIOCPHttp.HTTPCloseEvent := OnHTTPCloseEvent;
  FIOCPHttp.HTTPRecvingEvent := OnHTTPRecvingEvent;

  pgcTotal.ActivePageIndex := 0;
end;

procedure TfrmIOCPTest.FormDestroy(Sender: TObject);
begin
  FIOCPHttp.Free;

  FIOCPTabSheets[IM_BASE].Free;
  FIOCPTabSheets[IM_LCXL].Free;
  FIOCPTabSheets[IM_CMD].Free;

  FIOCPMgr.Free;
end;

procedure TfrmIOCPTest.OnHTTPCloseEvent(HttpObj: THttpCliObj);
begin
  OutputDebugStr('HTTP连接已关闭');
  if HttpObj.HttpRequest <> nil then
  begin
    HttpObj.HttpRequest.Free;
  end;
  if HttpObj.HttpResponse <> nil then
  begin
    HttpObj.HttpResponse.Free;
  end;
end;

procedure TfrmIOCPTest.OnHTTPRecvCompletedEvent(HttpObj: THttpCliObj);
var
  ReferURL: string;
  HttpReq: TStreamHttpRequest;
  HttpResp: TMemoryStreamHttpResponse;
  SockObj: THttpCliObj;
begin
  OutputDebugStr(Format('下载成功,消息体大小%d', [HttpObj.HttpResponse.ContentLength]));
  // 重定向
  if (HttpObj.HttpResponse.StatusCode = 301) or (HttpObj.HttpResponse.StatusCode = 302)
  then
  begin
    ReferURL := string(HttpObj.HttpResponse[RESPONSE_LOCATION]);
    OutputDebugStr('网址重定向: ' + ReferURL);
    SockObj := THttpCliObj.Create;
    HttpReq := TStreamHttpRequest.Create;
    HttpReq.URL := AnsiString(ReferURL);
    if SockObj.ConnectSer(FIOCPHttp, string(HttpReq.Host), HttpReq.Port, 1) then
    begin
      HttpResp := TMemoryStreamHttpResponse.Create;
      SockObj.HttpResponse := HttpResp;
      SockObj.SendRequest();
      SockObj.DecRefCount();
    end
    else
    begin
      OutputDebugStr('网址重定向失败: ' + ReferURL);
      HttpReq.Free;
      SockObj.Free;
    end;
  end;
end;

procedure TfrmIOCPTest.OnHTTPRecvErrorEvent(HttpObj: THttpCliObj);
begin

end;

procedure TfrmIOCPTest.OnHTTPRecvHeadCompletedEvent(HttpObj: THttpCliObj);
begin
  OutputDebugStr(Format('消息协议头获取成功！%s返回状态码%d-%s'#13#10'%s', [HttpObj.HttpRequest.URL,
    HttpObj.HttpResponse.StatusCode, HttpObj.HttpResponse.StatusText,
    HttpObj.HttpResponse.HeadText]));

end;

procedure TfrmIOCPTest.OnHTTPRecvingEvent(HttpObj: THttpCliObj; RecvDataLen: Integer);
begin
  OutputDebugStr(Format('接收消息体数据%d bytes,已接收%d bytes',
    [RecvDataLen, HttpObj.HttpResponse.ContentLength]));
end;

end.
