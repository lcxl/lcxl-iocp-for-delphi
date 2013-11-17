unit untTest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, DateUtils,

  LCXLWinSock2, LCXLIOCPBase(*, LCXLIOCPLcxl, LCXLIOCPCmd*), LCXLIOCPHttp, Menus,
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, VclTee.TeeGDIPlus;

const
  WM_SOCK_EVENT = WM_USER + 200;
  WM_LISTEN_EVENT = WM_USER + 201;

type
  TSockRec = record
    EventType: TIocpEventEnum;
    //SockObj: TCMDSockObj;
    SockObj: TSocketObj;
    Overlapped: PIocpOverlapped;
  end;

  PSockRec = ^TSockRec;

  TListenRec = record
    EventType: TListenEventEnum;
    SockLst: TSocketLst;
  end;

  PListenRec = ^TListenRec;

  TTestType = (TT_NONE, TT_KALMAN);

type
  TfrmIOCPTest = class(TForm)
    tmr1: TTimer;
    pmSockObj: TPopupMenu;
    pmSockLst: TPopupMenu;
    mniCloseSockLst: TMenuItem;
    mniCloseSockObj: TMenuItem;
    pgcTotal: TPageControl;
    tsBaseTest: TTabSheet;
    pgc1: TPageControl;
    tsSer: TTabSheet;
    lblSerPort: TLabel;
    edtSerPort: TEdit;
    btnListen: TButton;
    tsClient: TTabSheet;
    lblPort: TLabel;
    lblIP: TLabel;
    lblNum: TLabel;
    edtPort: TEdit;
    btnConnect: TButton;
    edtIP: TEdit;
    edtSockNum: TEdit;
    tsSend: TTabSheet;
    btnSend: TButton;
    pgc2: TPageControl;
    tsSocket: TTabSheet;
    lvSocket: TListView;
    tssocklst: TTabSheet;
    lvSockLst: TListView;
    statMain: TStatusBar;
    tsHttpTest2: TTabSheet;
    edtURL: TEdit;
    btnEnter: TButton;
    chkLoopSend: TCheckBox;
    tsSendContent: TTabSheet;
    dlgOpenFile: TOpenDialog;
    grpSendOpt: TGroupBox;
    rbSendFile: TRadioButton;
    rbSendText: TRadioButton;
    mmoSendText: TMemo;
    lblFileInfo: TLabel;
    btnLocalIP: TButton;
    lblHttpNum: TLabel;
    edtRequestNum: TEdit;
    tsLCXLTest: TTabSheet;
    tsCmdTest: TTabSheet;
    tsTimeTest: TTabSheet;
    chtTime: TChart;
    grpTime: TGroupBox;
    btnTimeTestStart: TButton;
    edtTestTimeIP: TEdit;
    lbl1: TLabel;
    edtTestTimeIPPort: TEdit;
    lbl2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvSocketData(Sender: TObject; Item: TListItem);
    procedure lvSockLstData(Sender: TObject; Item: TListItem);
    procedure btnListenClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure btnWaitClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnEnterClick(Sender: TObject);
    procedure mniCloseSockLstClick(Sender: TObject);
    procedure mniCloseSockObjClick(Sender: TObject);
    procedure chkLoopSendClick(Sender: TObject);
    procedure rbSendFileClick(Sender: TObject);
    procedure btnLocalIPClick(Sender: TObject);
    procedure btnTimeTestStartClick(Sender: TObject);
  private
    { Private declarations }
    FIOCPMgr: TIOCPManager;
    //FIOCPObj: TIOCPCMDList;
    FIOCPObj:TIOCPBase2List;
    FIOCPHttp: TIOCPHttpClientList;

    FSendBytes: LongWord;
    FRecvBytes: LongWord;
    FPreTime: TDateTime;
    FLoopSend: Boolean;

    FMsgHandle: THandle;
    FCS: TRTLCriticalSection;
    FSendContent: TMemoryStream;
    /// <summary>
    /// 测试类型
    /// </summary>
    FTestType: TTestType;
    FIsTestStarted: Boolean;
    function FormatSpeed(Speed: Double): string;

    // 注意，此函数不是线程安全的
    (*
    procedure OnSockEvent(EventType: TIocpEventEnum; SockObj: TCMDSockObj;
      Overlapped: PIocpOverlapped);
    *)
    procedure OnSockEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIocpOverlapped);
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
    // HTTP
    procedure OnHTTPRecvHeadCompletedEvent(HttpObj: THttpObj);
    procedure OnHTTPRecvCompletedEvent(HttpObj: THttpObj);
    procedure OnHTTPRecvErrorEvent(HttpObj: THttpObj);
    procedure OnHTTPCloseEvent(HttpObj: THttpObj);
    procedure OnHTTPRecvingEvent(HttpObj: THttpObj; RecvDataLen: Integer);

    // 线程安全
    procedure MsgSockEvent(var theMsg: TMessage); message WM_SOCK_EVENT;
    procedure MsgListenEvent(var theMsg: TMessage); message WM_LISTEN_EVENT;
  public
    { Public declarations }
  end;

var
  frmIOCPTest: TfrmIOCPTest;

implementation

{$R *.dfm}

procedure TfrmIOCPTest.btnConnectClick(Sender: TObject);
var
  I: Integer;
  SockObj: TSocketObj;
  SockNum: Integer;
begin
  SockNum := StrToIntDef(edtSockNum.Text, 2000);
  for I := 0 to SockNum-1 do
  begin
    SockObj := TSocketObj.Create;
    if SockObj.ConnectSer(FIOCPObj, edtIP.Text, StrToInt(edtPort.Text), 1) then
    begin
      //只连接，不做其他事情
      SockObj.DecRefCount();
    end
    else
    begin
      SockObj.Free;
    end;
    Application.ProcessMessages;
  end;
  lvSocket.Refresh;
end;

procedure TfrmIOCPTest.btnEnterClick(Sender: TObject);
var
  SockObj: THttpObj;
  Request: TStreamHttpRequest;
  I: Integer;
begin
  Request := TStreamHttpRequest.Create;
  Request[THttpRequest.HEADER_ACCEPT_ENCODING] := 'gzip';
  Request.URL := edtURL.Text;
  for I := 0 to StrToInt(edtRequestNum.Text)-1 do
  begin
    SockObj := THttpObj.Create;

    if not SockObj.ConnectSer(FIOCPHttp, Request.Host, Request.Port, 1) then
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

procedure TfrmIOCPTest.btnListenClick(Sender: TObject);
var
  SOckLst: TSocketLst;
begin

  SOckLst := TSocketLst.Create;
  if not SockLst.StartListen(FIOCPObj, StrToInt(edtSerPort.Text)) then
  begin
    SockLst.Free;
  end
  else
  begin

  end;
end;

procedure TfrmIOCPTest.btnLocalIPClick(Sender: TObject);
var
  Addrs: TStringList;
begin
  Addrs := TStringList.Create;
  FIOCPObj.GetLocalAddrs(Addrs);
  MessageBox(Handle, Pchar(Format('本机IP地址为'#13#10'%s', [Addrs.Text])), '提示', MB_ICONINFORMATION);
  Addrs.Free;
end;

procedure TfrmIOCPTest.btnRunClick(Sender: TObject);
begin
  statMain.SimpleText := '正在进行测试。。';
  while True do
  begin

  end;
end;

procedure TfrmIOCPTest.btnSendClick(Sender: TObject);
var
  SockObjPrt: Pointer;
  SockObj: TSocketObj ABSOLUTE SockObjPrt;
  _s: string;
  _P: Pointer;

begin
  if rbSendText.Checked then
  begin
    _s := mmoSendText.Lines.Text;
    FSendContent.Clear;
    FSendContent.Write(PChar(_s)^, Length(_s)*SizeOf(Char));
  end;
  FIOCPObj.LockSockList;
  for SockObjPrt in FIOCPObj.SockObjList do
  begin

    _P :=SockObj.GetSendData(FSendContent.Size);
    CopyMemory(_P, FSendContent.Memory, FSendContent.Size);
    SockObj.SendData(_p, FSendContent.Size, True);
  end;
  FIOCPObj.UnlockSockList;

end;

procedure TfrmIOCPTest.btnTimeTestStartClick(Sender: TObject);
var
  _SockObj: TSocketObj;
begin
  case FTestType of
    TT_NONE:
    begin
      _SockObj := TSocketObj.Create;
      if not _SockObj.ConnectSer(FIOCPObj, edtTestTimeIP.Text, StrToInt(edtTestTimeIPPort.Text), 0) then
      begin
        _SockObj.Free;
        MessageBox(Handle, '连接失败！', '', MB_ICONSTOP);
      end;
      btnTimeTestStart.Caption := '停止测试';
      FTestType := TT_KALMAN;
    end ;
    TT_KALMAN:
    begin

      btnTimeTestStart.Caption := '开始测试';
      FTestType := TT_NONE;
    end;
  else
    MessageBox(Handle, '正在其他测试正在进行中，请先关闭其他测试', '提示', MB_ICONINFORMATION);
  end;
end;

procedure TfrmIOCPTest.btnWaitClick(Sender: TObject);
var
  hEvent: THandle;
begin
  hEvent := CreateEvent(nil, False, False, nil);
  WaitForSingleObject(hEvent, INFINITE);
end;

procedure TfrmIOCPTest.chkLoopSendClick(Sender: TObject);
begin
  EnterCriticalSection(FCS);
  FLoopSend := chkLoopSend.Checked;
  LeaveCriticalSection(FCS);
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
  InitializeCriticalSection(FCS);
  ReportMemoryLeaksOnShutdown := True;

  FSendContent := TMemoryStream.Create;

  FIOCPMgr := TIOCPManager.Create();
  FIOCPObj := TIOCPBase2List.Create(FIOCPMgr);
  FIOCPObj.IOCPEvent := OnSockEvent;
  FIOCPObj.ListenEvent := OnListenEvent;

  FIOCPHttp := TIOCPHttpClientList.Create(FIOCPMgr);
  FIOCPHttp.HTTPRecvHeadCompletedEvent := OnHTTPRecvHeadCompletedEvent;
  FIOCPHttp.HTTPRecvCompletedEvent := OnHTTPRecvCompletedEvent;
  FIOCPHttp.HTTPRecvErrorEvent := OnHTTPRecvErrorEvent;
  FIOCPHttp.HTTPCloseEvent := OnHTTPCloseEvent;
  FIOCPHttp.HTTPRecvingEvent := OnHTTPRecvingEvent;

  FPreTime := Now;

  FMsgHandle := Handle;
  pgcTotal.ActivePageIndex := 0;
end;

procedure TfrmIOCPTest.FormDestroy(Sender: TObject);
begin
  FIOCPHttp.Free;
  FIOCPObj.Free;
  FIOCPMgr.Free;
  FSendContent.Free;
  DeleteCriticalSection(FCS);
end;

procedure TfrmIOCPTest.lvSocketData(Sender: TObject; Item: TListItem);
var
  SockObj: TSocketObj;
  SockList: TList;
  ListCount: Integer;
begin
  FIOCPObj.LockSockList;
  SockList := FIOCPObj.SockObjList;
  ListCount := SockList.Count;
  if SockList.Count > Item.Index then
  begin
    SockObj := TSocketObj(SockList[Item.Index]);
    Item.Caption := Format('%d(%d)', [Item.Index, SockObj.Socket]);
    Item.SubItems.Add(SockObj.GetRemoteIP);
    Item.SubItems.Add(IntToStr(SockObj.GetRemotePort));
    if SockObj.IsSerSocket then
    begin
      Item.SubItems.Add('服务端socket');
    end
    else
    begin
      Item.SubItems.Add('客户端socket');
    end;
  end;

  FIOCPObj.UnlockSockList;
  if lvSocket.Items.Count <> ListCount then
  begin
    lvSocket.Items.Count := ListCount;
  end;
end;

procedure TfrmIOCPTest.lvSockLstData(Sender: TObject; Item: TListItem);
var
  SockLst: TSocketLst;
  ListCount: Integer;
begin
  FIOCPObj.LockSockList;
  ListCount := FIOCPObj.SockLstList.Count;
  if Item.Index < ListCount then
  begin
    SockLst := TSocketLst(FIOCPObj.SockLstList[Item.Index]);
    Item.Caption := IntToStr(Item.Index);
    Item.SubItems.Add(IntToStr(SockLst.Port));
  end;

  FIOCPObj.UnlockSockList;
  if ListCount <> lvSockLst.Items.Count then
  begin
    lvSockLst.Items.Count := ListCount;
  end;
end;

procedure TfrmIOCPTest.mniCloseSockLstClick(Sender: TObject);
var
  SockLst: TSocketLst;
begin
  if lvSockLst.ItemIndex>=0 then
  begin
    FIOCPObj.LockSockList;
    SockLst := FIOCPObj.SockLstList.Items[lvSockLst.ItemIndex];
    SockLst.Close;
    FIOCPObj.UnlockSockList;

  end;
end;

procedure TfrmIOCPTest.mniCloseSockObjClick(Sender: TObject);
var
  SockObj: TSocketObj;
begin
  if lvSocket.ItemIndex>=0 then
  begin
    FIOCPObj.LockSockList;
    SockObj := FIOCPObj.SockObjList.Items[lvSocket.ItemIndex];
    SockObj.Close;
    FIOCPObj.UnlockSockList;

  end;
end;

procedure TfrmIOCPTest.MsgListenEvent(var theMsg: TMessage);
var
  ListenRec: PListenRec;
begin
  ListenRec := PListenRec(theMsg.WParam);
  case ListenRec.EventType of
    leAddSockLst:
      begin
        FIOCPObj.LockSockList;
        lvSockLst.Items.Count := FIOCPObj.SockLstList.Count;
        FIOCPObj.UnlockSockList;
        lvSockLst.Refresh;
      end;
    leDelSockLst:
      begin
        FIOCPObj.LockSockList;
        lvSockLst.Items.Count := FIOCPObj.SockLstList.Count;
        FIOCPObj.UnlockSockList;
        lvSockLst.Refresh;
      end;
  end;
end;

procedure TfrmIOCPTest.MsgSockEvent(var theMsg: TMessage);
var
  SockRec: PSockRec;
begin
  SockRec := PSockRec(theMsg.WParam);
  case SockRec.EventType of
    ieAddSocket:
      begin
        FIOCPObj.LockSockList;
        lvSocket.Items.Count := FIOCPObj.SockObjList.Count;
        FIOCPObj.UnlockSockList;
      end;
    ieDelSocket:
      begin
        FIOCPObj.LockSockList;
        lvSocket.Items.Count := FIOCPObj.SockObjList.Count;
        FIOCPObj.UnlockSockList;
      end;
    ieError:
      begin
      end;
    ieRecvPart:
      begin
      end;
    ieRecvAll:
      begin

      end;
    ieRecvFailed:
      begin
      end;
    ieSendPart:
      begin
      end;
    ieSendAll:
      begin

      end;
    ieSendFailed:
      begin
      end;
  end;
end;

procedure TfrmIOCPTest.OnHTTPCloseEvent(HttpObj: THttpObj);
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

procedure TfrmIOCPTest.OnHTTPRecvCompletedEvent(HttpObj: THttpObj);
var
  ReferURL: string;
  HttpReq: TStreamHttpRequest;
  HttpResp: TMemoryStreamHttpResponse;
  SockObj: THttpObj;
begin
  OutputDebugStr(Format('下载成功,消息体大小%d', [HttpObj.HttpResponse.ContentLength]));
  // 重定向
  if (HttpObj.HttpResponse.StatusCode = 301) or (HttpObj.HttpResponse.StatusCode = 302)
  then
  begin
    ReferURL := HttpObj.HttpResponse['Location'];
    OutputDebugStr('网址重定向: ' + ReferURL);
    SockObj := THttpObj.Create;
    HttpReq := TStreamHttpRequest.Create;
    HttpReq.URL := ReferURL;
    if SockObj.ConnectSer(FIOCPHttp, HttpReq.Host, HttpReq.Port, 1) then
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

procedure TfrmIOCPTest.OnHTTPRecvErrorEvent(HttpObj: THttpObj);
begin

end;

procedure TfrmIOCPTest.OnHTTPRecvHeadCompletedEvent(HttpObj: THttpObj);
begin
  OutputDebugStr(Format('消息协议头获取成功！%s返回状态码%d-%s'#13#10'%s', [HttpObj.HttpRequest.URL,
    HttpObj.HttpResponse.StatusCode, HttpObj.HttpResponse.StatusText,
    HttpObj.HttpResponse.HeadText]));

end;

procedure TfrmIOCPTest.OnHTTPRecvingEvent(HttpObj: THttpObj; RecvDataLen: Integer);
begin
  EnterCriticalSection(FCS);
  FRecvBytes := FRecvBytes + Longword(RecvDataLen);
  LeaveCriticalSection(FCS);
  OutputDebugStr(Format('接收消息体数据%d bytes,已接收%d bytes',
    [RecvDataLen, HttpObj.HttpResponse.ContentLength]));
end;

procedure TfrmIOCPTest.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
var
  ListenRec: TListenRec;
begin
  ListenRec.EventType := EventType;
  ListenRec.SockLst := SockLst;
  SendMessage(FMsgHandle, WM_LISTEN_EVENT, WParam(@ListenRec), 0);

end;

procedure TfrmIOCPTest.OnSockEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIocpOverlapped);

var
  SockRec: TSockRec;
  //_p: TCMDDataRec;
  _P: Pointer;
  _LoopSend: Boolean;
begin
  SockRec.EventType := EventType;
  SockRec.SockObj := SockObj;
  SockRec.Overlapped := Overlapped;
  case EventType of
    ieRecvAll:
      begin
        EnterCriticalSection(FCS);
        FRecvBytes := FRecvBytes + Overlapped.GetRecvDataLen;
        LeaveCriticalSection(FCS);
      end;
    ieSendAll:
      begin
        EnterCriticalSection(FCS);
        FSendBytes := FSendBytes + SockRec.Overlapped.GetTotalSendDataLen;
        _LoopSend := FLoopSend;
        LeaveCriticalSection(FCS);
        case FTestType of
          TT_NONE:
          begin
            if _LoopSend then
        begin
          _P := SockObj.GetSendData(Overlapped.GetTotalSendDataLen);
          CopyMemory(_P, Overlapped.GetSendData, Overlapped.GetTotalSendDataLen);
          SockObj.SendData(_P, Overlapped.GetTotalSendDataLen, true);
        end;
          end;
          TT_KALMAN:
          begin
            if True then

          end ;
        end;

      end;
    ieRecvPart:
    begin

    end;
    ieSendPart:
    begin

    end;
  else

    SendMessage(FMsgHandle, WM_SOCK_EVENT, WParam(@SockRec), 0);
  end;
end;

procedure TfrmIOCPTest.rbSendFileClick(Sender: TObject);
begin
  if dlgOpenFile.Execute(Handle) then
  begin
    FSendContent.LoadFromFile(dlgOpenFile.FileName);
    lblFileInfo.Caption := Format('大小(%d B)文件:%s', [FSendContent.Size, dlgOpenFile.FileName]);
  end;
end;

procedure TfrmIOCPTest.tmr1Timer(Sender: TObject);
var
  FCurTime: TDateTime;
  FSendSpeed: Double;
  FRecvSpeed: Double;
  _s, _r: Double;
  ms: Integer;
begin
  FCurTime := Now;
  EnterCriticalSection(FCS);
  _s := FSendBytes;
  _r := FRecvBytes;
  FSendBytes := 0;
  FRecvBytes := 0;
  LeaveCriticalSection(FCS);
  ms := MilliSecondsBetween(FCurTime, FPreTime);
  if ms > 0 then
  begin
    FSendSpeed := _s * 1000 / ms;
    FRecvSpeed := _r * 1000 / ms;
    statMain.SimpleText := Format('共有%d个连接，共发送速度:%s 接受速度:%s',
      [lvSocket.Items.Count, FormatSpeed(FSendSpeed), FormatSpeed(FRecvSpeed)]);
  end;

  FPreTime := FCurTime;
end;

end.
