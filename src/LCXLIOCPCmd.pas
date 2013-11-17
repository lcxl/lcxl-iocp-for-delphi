unit LCXLIOCPCmd;

interface

uses
  Windows, LCXLIOCPBase, LCXLIOCPLcxl;

type
  TCMDDataRec = record
  private
    FTotalLen: LongWord;
    FTotalData: Pointer;
    FData: Pointer;
    FDataLen: LongWord;
    function GetCMD: Word;
    procedure SetCMD(const Value: Word);

  public
    property CMD: Word read GetCMD write SetCMD;
    property Data: Pointer read FData;
    property DataLen: LongWord read FDataLen;

    function Assgin(_TotalData: Pointer; _TotalLen: LongWord): Boolean;
  end;
  PCMDDataRec = ^TCMDDataRec;

  TCmdSockLst = class(TLLSockLst)
  protected
    procedure CreateSockObj(var SockObj: TSocketObj); override; // 覆盖
  end;

  ///	<summary>
  ///	  基于命令的通讯协议Socket类实现
  ///	</summary>
  TCmdSockObj = class(TLLSockObj)
  public
    ///	<remarks>
    ///	  SendData之前要锁定
    ///	</remarks>
    function SendData(const SendDataRec: TCMDDataRec): Boolean; reintroduce; overload;

    ///	<remarks>
    ///	  SendData之前要锁定
    ///	</remarks>
    function SendData(CMD: Word; Data: Pointer; DataLen: LongWord): Boolean; reintroduce;overload;

    ///	<remarks>
    ///	  SendData之前要锁定
    ///	</remarks>
    function SendData(CMD: Word; Data: array of Pointer; DataLen: array of LongWord): Boolean; reintroduce;overload;

    ///	<summary>
    ///	  获取发送数据的指针
    ///	</summary>
    procedure GetSendData(DataLen: LongWord; var SendDataRec: TCMDDataRec); reintroduce;

    ///	<summary>
    ///	  只有没有调用SendData的时候才可以释放，调用SendData之后将会自动释放。
    ///	</summary>
    ///	<param name="SendDataRec">
    ///	  要释放的数据
    ///	</param>
    procedure FreeSendData(const SendDataRec: TCMDDataRec);reintroduce;
    class procedure GetSendDataFromOverlapped(Overlapped: PIOCPOverlapped; var SendDataRec: TCMDDataRec); inline;
  end;

  ///	<summary>
  ///	  IOCP命令事件
  ///	</summary>
  TOnCMDEvent = procedure(EventType: TIocpEventEnum; SockObj: TCmdSockObj;
    Overlapped: PIOCPOverlapped) of object;



  ///	<summary>
  ///	  基于命令的通讯协议Socket类列表的实现
  ///	</summary>
  TIOCPCMDList = class(TIOCPLCXLList)
  private
    FIOCPEvent: TOnCMDEvent;
    /// <summary>
    /// 基类的事件
    /// </summary>
    procedure BaseIOCPEvent(EventType: TIocpEventEnum; SockObj: TLLSockObj;
      Overlapped: PIOCPOverlapped);
  public
    constructor Create(AIOCPMgr: TIOCPManager); override;
    // 外部接口
    property IOCPEvent: TOnCMDEvent read FIOCPEvent write FIOCPEvent;
  end;
implementation

{ TCmdSockObj }

procedure TCmdSockObj.FreeSendData(const SendDataRec: TCMDDataRec);
begin
  (Self as TSocketObj).FreeSendData(SendDataRec.FTotalData);
end;

procedure TCmdSockObj.GetSendData(DataLen: LongWord;
  var SendDataRec: TCMDDataRec);
var
  IsSuc: Boolean;
begin

  SendDataRec.FTotalLen := DataLen+SizeOf(DataLen)+SizeOf(SendDataRec.CMD);
  SendDataRec.FTotalData := (Self as TSocketObj).GetSendData(SendDataRec.FTotalLen);
  PLongWord(SendDataRec.FTotalData)^ := DataLen+SizeOf(SendDataRec.CMD);

  IsSuc := SendDataRec.Assgin(SendDataRec.FTotalData, SendDataRec.FTotalLen);
  Assert(IsSuc=True);
end;

class procedure TCmdSockObj.GetSendDataFromOverlapped(Overlapped: PIOCPOverlapped;
  var SendDataRec: TCMDDataRec);
begin
  Assert(Overlapped.OverlappedType = otSend);
  SendDataRec.Assgin(Overlapped.SendData, Overlapped.SendDataLen);
end;

function TCmdSockObj.SendData(CMD: Word; Data: array of Pointer;
  DataLen: array of LongWord): Boolean;
var
  SendRec: TCMDDataRec;
  DataPos: PByte;
  TotalDataLen: LongWord;
  I: Integer;
begin
  Assert(Length(DataLen)=Length(Data), 'TCmdSockObj.SendData, Data参数必须和DataLen数量一致');
  TotalDataLen := 0;
  for I := 0 to Length(DataLen)-1 do
  begin
    TotalDataLen := TotalDataLen+DataLen[I];
  end;
  GetSendData(TotalDataLen, SendRec);
  DataPos := PByte(SendRec.Data);
  for I := 0 to Length(Data)-1 do
  begin
    CopyMemory(DataPos, Data[I], DataLen[I]);
    DataPos:= DataPos+DataLen[I];
  end;
  SendRec.CMD := CMD;
  Result := SendData(SendRec);
end;

function TCmdSockObj.SendData(CMD: Word; Data: Pointer; DataLen: LongWord): Boolean;
var
  SendRec: TCMDDataRec;
begin
  GetSendData(DataLen, SendRec);
  CopyMemory(SendRec.Data, Data, DataLen);
  SendRec.CMD := CMD;
  Result := SendData(SendRec);
  if not Result then
  begin
    OutputDebugStr('TCmdSockObj.SendData Failed!');
    FreeSendData(SendRec);

  end;
end;

function TCmdSockObj.SendData(const SendDataRec: TCMDDataRec): Boolean;
begin
  Result := (Self as TSocketObj).SendData(SendDataRec.FTotalData, SendDataRec.FTotalLen, True);
end;

{ TIOCPOBJCMD }

constructor TIOCPCMDList.Create(AIOCPMgr: TIOCPManager);
begin
  inherited;
  inherited IOCPEvent := BaseIOCPEvent;
end;

(*
procedure TIOCPCMDList.CreateSockObj(var SockObj: TSocketObj);
begin
  if SockObj = nil then
  begin
    SockObj := TCMDSockObj.Create;
  end;

end;
*)
procedure TIOCPCMDList.BaseIOCPEvent(EventType: TIocpEventEnum; SockObj: TLLSockObj;
  Overlapped: PIOCPOverlapped);
var
  CMDSockObj: TCMDSockObj absolute SockObj;
begin
  if Assigned(FIOCPEvent) then
    begin
      FIOCPEvent(EventType, CMDSockObj, Overlapped);
    end;
end;

{ TCMDDataRec }

function TCMDDataRec.Assgin(_TotalData: Pointer; _TotalLen: LongWord): Boolean;
begin
  Result := False;
  if (_TotalLen < SizeOf(LongWord)+sizeof(Word)) or (_TotalData = nil) then
  begin
    Exit;
  end;
  if PLongWord(_TotalData)^ <> _TotalLen-SizeOf(LongWord) then
  begin
    Exit;
  end;
  FTotalData := _TotalData;
  FTotalLen := _TotalLen;

  FData := PByte(FTotalData)+SizeOf(DataLen)+
    SizeOf(Word);
  FDataLen := FTotalLen - SizeOf(DataLen) - SizeOf(Word);
  Result := True;
end;

function TCMDDataRec.GetCMD: Word;
begin
  Result := PWord(PByte(FTotalData)+SizeOf(LongWord))^;
end;

procedure TCMDDataRec.SetCMD(const Value: Word);
begin
  PWord(PByte(FTotalData)+SizeOf(LongWord))^ := Value;
end;

{ TCmdSockLst }

procedure TCmdSockLst.CreateSockObj(var SockObj: TSocketObj);
begin
  SockObj := TCMDSockObj.Create;

end;

end.
