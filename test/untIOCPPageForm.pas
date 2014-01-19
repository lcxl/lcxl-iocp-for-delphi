unit untIOCPPageForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, DateUtils,

  LCXLWinSock2, LCXLIOCPBase, LCXLIOCPLcxl, LCXLIOCPCmd, Vcl.ExtCtrls, Vcl.Menus;
type
  TIOCP_MODE_ENUM = (IM_BASE, IM_LCXL, IM_CMD);
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
const
  WM_SOCK_EVENT = WM_USER + 200;
  WM_LISTEN_EVENT = WM_USER + 201;
type
  TfrmIOCPPageForm = class(TForm)
    pgc1: TPageControl;
    tsSer: TTabSheet;
    lblSerPort: TLabel;
    edtSerPort: TEdit;
    btnListen: TButton;
    btnLocalIP: TButton;
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
    chkLoopSend: TCheckBox;
    pgc2: TPageControl;
    tsSocket: TTabSheet;
    lvSocket: TListView;
    tssocklst: TTabSheet;
    lvSockLst: TListView;
    statMain: TStatusBar;
    tmrRefreshStatus: TTimer;
    btnLoadSendFile: TButton;
    dlgOpenFile: TOpenDialog;
    pmSockObj: TPopupMenu;
    mniCloseSockObj: TMenuItem;
    pmSockLst: TPopupMenu;
    mniCloseSockLst: TMenuItem;
    lblFileInfo: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrRefreshStatusTimer(Sender: TObject);
    procedure btnLocalIPClick(Sender: TObject);
    procedure btnListenClick(Sender: TObject);
    procedure chkLoopSendClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnLoadSendFileClick(Sender: TObject);
    procedure mniCloseSockObjClick(Sender: TObject);
    procedure mniCloseSockLstClick(Sender: TObject);
    procedure lvSocketData(Sender: TObject; Item: TListItem);
    procedure lvSockLstData(Sender: TObject; Item: TListItem);
  private
    { Private declarations }
    FIOCPMode: TIOCP_MODE_ENUM;
    FIOCPMgr: TIOCPManager;
    FIOCPObj:TCustomIOCPBaseList;

    FSendBytes: LongWord;
    FRecvBytes: LongWord;
    FPreTime: TDateTime;
    FLoopSend: Boolean;

    FMsgHandle: THandle;
    FCS: TRTLCriticalSection;
    FSendContent: TMemoryStream;
    function FormatSpeed(Speed: Double): string;

    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIocpOverlapped);
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);

    procedure OnIOCPBaseEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIocpOverlapped);
    procedure OnListenBaseEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
    procedure OnIOCPLCXLEvent(EventType: TIocpEventEnum; SockObj: TLLSockObj;
      Overlapped: PIocpOverlapped);
    procedure OnListenLCXLEvent(EventType: TListenEventEnum; SockLst: TLLSockLst);
    procedure OnIOCPCMDEvent(EventType: TIocpEventEnum; SockObj: TCMDSockObj;
      Overlapped: PIocpOverlapped);
    procedure OnListenCMDEvent(EventType: TListenEventEnum; SockLst: TCMDSockLst);

    // 线程安全
    procedure MsgSockEvent(var theMsg: TMessage); message WM_SOCK_EVENT;
    procedure MsgListenEvent(var theMsg: TMessage); message WM_LISTEN_EVENT;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent; AIOCPMgr: TIOCPManager; AIOCPMode: TIOCP_MODE_ENUM); reintroduce; virtual;
    destructor Destroy; override;
    property MsgHandle: THandle read FMsgHandle write FMsgHandle;
  end;

var
  frmIOCPPageForm: TfrmIOCPPageForm;


function CreateIOCPTabSheet(AParent: TPageControl; AIOCPMgr: TIOCPManager; AIOCPMode: TIOCP_MODE_ENUM): TTabSheet;

implementation

{$R *.dfm}

function CreateIOCPTabSheet(AParent: TPageControl; AIOCPMgr: TIOCPManager; AIOCPMode: TIOCP_MODE_ENUM): TTabSheet;
var
  NewSheet : TTabSheet;
  NewIOCPPageForm: TfrmIOCPPageForm;
begin
  NewSheet := TTabSheet.Create(AParent);
  NewSheet.PageControl := AParent;
  NewIOCPPageForm := TfrmIOCPPageForm.Create(NewSheet, AIOCPMgr, AIOCPMode);
  NewIOCPPageForm.Parent := NewSheet;
  NewIOCPPageForm.Align := alClient;
  NewIOCPPageForm.BorderStyle := bsNone;
  NewIOCPPageForm.Visible := True;
  NewSheet.Caption :=  NewIOCPPageForm.Caption;
  NewIOCPPageForm.MsgHandle := NewIOCPPageForm.Handle;
  Result := NewSheet;
end;

{ TfrmIOCPPageForm }

procedure TfrmIOCPPageForm.btnConnectClick(Sender: TObject);
var
  I: Integer;
  SockObj: TSocketObj;
  SockNum: Integer;
begin
  SockNum := StrToIntDef(edtSockNum.Text, 2000);
  for I := 0 to SockNum-1 do
  begin
    SockObj := nil;
    case FIOCPMode of
      IM_BASE:
        SockObj := TSocketObj.Create;
      IM_LCXL:
        SockObj := TLLSockObj.Create;
      IM_CMD:
        SockObj := TCMDSockObj.Create;
    end;

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

procedure TfrmIOCPPageForm.btnListenClick(Sender: TObject);
var
  SockLst: TSocketLst;
begin
  SockLst := nil;
  case FIOCPMode of
    IM_BASE:
    begin
      SockLst := TSocketLst.Create;
    end;

    IM_LCXL:
    begin
      SockLst := TLLSockLst.Create;
    end;
    IM_CMD:
    begin
      SockLst := TCmdSockLst.Create;
    end;
  end;
  if not SockLst.StartListen(FIOCPObj, StrToInt(edtSerPort.Text)) then
  begin
    SockLst.Free;
  end
  else
  begin

  end;
end;

procedure TfrmIOCPPageForm.btnLoadSendFileClick(Sender: TObject);
begin
  if dlgOpenFile.Execute(Handle) then
  begin
    try
      FSendContent.LoadFromFile(dlgOpenFile.FileName);
      lblFileInfo.Caption := Format('大小(%d B)文件:%s', [FSendContent.Size, dlgOpenFile.FileName]);
    except
      MessageBox(Handle, '加载文件内容失败！', '错误', MB_ICONSTOP);
    end;
  end;
end;

procedure TfrmIOCPPageForm.btnLocalIPClick(Sender: TObject);
var
  Addrs: TStringList;
begin
  Addrs := TStringList.Create;
  FIOCPMgr.GetLocalAddrs(Addrs);
  MessageBox(Handle, Pchar(Format('本机IP地址为'#13#10'%s', [Addrs.Text])), '提示', MB_ICONINFORMATION);
  Addrs.Free;
end;

procedure TfrmIOCPPageForm.btnSendClick(Sender: TObject);
var
  SockObjPrt: Pointer;
  SockObj: TSocketObj ABSOLUTE SockObjPrt;
begin
  if FSendContent.Size = 0 then
  begin
    MessageBox(Handle, '没有要发送的内容，请先设置', '提示', MB_ICONINFORMATION);
    Exit;
  end;
  FIOCPObj.LockSockList;
  for SockObjPrt in FIOCPObj.SockObjList do
  begin
    case FIOCPMode of
      IM_BASE:
      begin
        SockObj.SendData(FSendContent.Memory, FSendContent.Size);
      end;
      IM_LCXL:
      begin
        (SockObj as TLLSockObj).SendData(FSendContent.Memory, FSendContent.Size);
      end;
      IM_CMD:
      begin
        (SockObj as TCmdSockObj).SendData($0020,FSendContent.Memory, FSendContent.Size);
      end;
    end;
  end;
  FIOCPObj.UnlockSockList;
end;

procedure TfrmIOCPPageForm.chkLoopSendClick(Sender: TObject);
begin
  EnterCriticalSection(FCS);
  FLoopSend := chkLoopSend.Checked;
  LeaveCriticalSection(FCS)
end;

constructor TfrmIOCPPageForm.Create(AOwner: TComponent; AIOCPMgr: TIOCPManager;
  AIOCPMode: TIOCP_MODE_ENUM);
begin
  FIOCPMgr := AIOCPMgr;
  FIOCPMode := AIOCPMode;
  inherited Create(AOwner);
end;

destructor TfrmIOCPPageForm.Destroy;
begin

  inherited;
end;

function TfrmIOCPPageForm.FormatSpeed(Speed: Double): string;
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

procedure TfrmIOCPPageForm.FormCreate(Sender: TObject);
begin
  InitializeCriticalSection(FCS);
  FSendContent := TMemoryStream.Create;
  case FIOCPMode of
    IM_BASE:
    begin
      Caption := 'Base协议测试';
      FIOCPObj := TIOCPBaseList.Create(FIOCPMgr);
      (FIOCPObj as TIOCPBaseList).IOCPEvent := OnIOCPBaseEvent;
      (FIOCPObj as TIOCPBaseList).ListenEvent := OnListenBaseEvent;

    end;
    IM_LCXL:
    begin
      Caption := 'Lcxl协议测试';
      FIOCPObj := TIOCPLCXLList.Create(FIOCPMgr);
      (FIOCPObj as TIOCPLCXLList).IOCPEvent := OnIOCPLCXLEvent;
      (FIOCPObj as TIOCPLCXLList).ListenEvent := OnListenLCXLEvent;
    end;
    IM_CMD:
    begin
      Caption := 'Cmd协议测试';
      FIOCPObj := TIOCPCMDList.Create(FIOCPMgr);
      (FIOCPObj as TIOCPCMDList).IOCPEvent := OnIOCPCMDEvent;
      (FIOCPObj as TIOCPCMDList).ListenEvent := OnListenCMDEvent;
    end;
  end;
  FPreTime := Now;

  FMsgHandle := Handle;
end;

procedure TfrmIOCPPageForm.FormDestroy(Sender: TObject);
begin
  FIOCPObj.Free;
  FSendContent.Free;
  DeleteCriticalSection(FCS);
end;

procedure TfrmIOCPPageForm.lvSocketData(Sender: TObject; Item: TListItem);
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

procedure TfrmIOCPPageForm.lvSockLstData(Sender: TObject; Item: TListItem);
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

procedure TfrmIOCPPageForm.mniCloseSockLstClick(Sender: TObject);
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

procedure TfrmIOCPPageForm.mniCloseSockObjClick(Sender: TObject);
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

procedure TfrmIOCPPageForm.MsgListenEvent(var theMsg: TMessage);
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

procedure TfrmIOCPPageForm.MsgSockEvent(var theMsg: TMessage);
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

procedure TfrmIOCPPageForm.OnIOCPBaseEvent(EventType: TIocpEventEnum;
  SockObj: TSocketObj; Overlapped: PIocpOverlapped);
begin
  OnIOCPEvent(EventType, SockObj, Overlapped);
end;

procedure TfrmIOCPPageForm.OnIOCPCMDEvent(EventType: TIocpEventEnum;
  SockObj: TCMDSockObj; Overlapped: PIocpOverlapped);
begin
  OnIOCPEvent(EventType, SockObj, Overlapped);
end;

procedure TfrmIOCPPageForm.OnIOCPEvent(EventType: TIocpEventEnum;
  SockObj: TSocketObj; Overlapped: PIocpOverlapped);
var
  SockRec: TSockRec;
  _LoopSend: Boolean;
  _SendDataRec: TSendDataRec;
  _CMDSendDataRec: TCMDDataRec;
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

        if _LoopSend then
        begin
          case FIOCPMode of
            IM_BASE:
            begin
              SockObj.SendData(Overlapped.GetSendData, Overlapped.GetTotalSendDataLen);
            end;
            IM_LCXL:
            begin
              _SendDataRec.Assgin(Overlapped.GetSendData, Overlapped.GetTotalSendDataLen);
              (SockObj as TLLSockObj).SendData(_SendDataRec.Data, _SendDataRec.DataLen);
            end;
            IM_CMD:
            begin
              _CMDSendDataRec.Assgin(Overlapped.GetSendData, Overlapped.GetTotalSendDataLen);
              (SockObj as TCmdSockObj).SendData(_CMDSendDataRec.CMD, _CMDSendDataRec.Data, _CMDSendDataRec.DataLen);
            end;
          end;

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

procedure TfrmIOCPPageForm.OnIOCPLCXLEvent(EventType: TIocpEventEnum;
  SockObj: TLLSockObj; Overlapped: PIocpOverlapped);
begin
  OnIOCPEvent(EventType, SockObj, Overlapped);
end;

procedure TfrmIOCPPageForm.OnListenBaseEvent(EventType: TListenEventEnum;
  SockLst: TSocketLst);
begin
  OnListenEvent(EventType, SockLst);
end;

procedure TfrmIOCPPageForm.OnListenCMDEvent(EventType: TListenEventEnum;
  SockLst: TCMDSockLst);
begin
  OnListenEvent(EventType, SockLst);
end;

procedure TfrmIOCPPageForm.OnListenEvent(EventType: TListenEventEnum;
  SockLst: TSocketLst);
var
  ListenRec: TListenRec;
begin
  ListenRec.EventType := EventType;
  ListenRec.SockLst := SockLst;
  SendMessage(FMsgHandle, WM_LISTEN_EVENT, WParam(@ListenRec), 0)
end;

procedure TfrmIOCPPageForm.OnListenLCXLEvent(EventType: TListenEventEnum;
  SockLst: TLLSockLst);
begin
  OnListenEvent(EventType, SockLst);
end;

procedure TfrmIOCPPageForm.tmrRefreshStatusTimer(Sender: TObject);
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

