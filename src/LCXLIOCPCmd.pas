unit LCXLIOCPCmd;

interface

uses
  Windows, LCXLIOCPBase, LCXLIOCPLcxl;

type
  TCMDDataRec = record
  private
    TotalLen: LongWord;
    TotalData: Pointer;
    function GetDataLen: LongWord;
  public
    CMD: Word;
    Data: Pointer;

    function Assgin(_TotalData: Pointer; _TotalLen: LongWord): Boolean;
    property DataLen: LongWord read GetDataLen;
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
  protected
    //获取Word型的命令
    function GetRecvCMD: Word;
    function GetRecvData: Pointer; override;
    function GetRecvDataLen: LongWord; override;
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
    property RecvCMD: Word read GetRecvCMD;
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
    procedure LCXLEvent(EventType: TIocpEventEnum; SockObj: TLLSockObj;
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
  (Self as TSocketObj).FreeSendData(SendDataRec.TotalData);
end;

function TCmdSockObj.GetRecvCMD: Word;
var
  _RecvDataLen: LongWord;
begin
  Result := 0;
  if not IsRecvLen then
  begin
    _RecvDataLen := inherited GetRecvDataLen();
    if _RecvDataLen >= SizeOf(Word) then
    begin
      Result := PWord(RecvBuf)^;
    end;
  end;
end;

function TCmdSockObj.GetRecvData: Pointer;
var
  _RecvDataLen: LongWord;
begin
  Result := nil;
  if not IsRecvLen then
  begin
    _RecvDataLen := inherited GetRecvDataLen();
    if _RecvDataLen >= SizeOf(Word) then
    begin
      Result := PByte(RecvBuf)+SizeOf(Word);
    end;
  end
end;

function TCmdSockObj.GetRecvDataLen: LongWord;
var
  _RecvDataLen: LongWord;
begin
  Result := 0;
  if not IsRecvLen then
  begin
    _RecvDataLen := inherited GetRecvDataLen();
    if _RecvDataLen >= SizeOf(Word) then
    begin
      Result := _RecvDataLen-SizeOf(Word);
    end;
  end;
end;

procedure TCmdSockObj.GetSendData(DataLen: LongWord;
  var SendDataRec: TCMDDataRec);
begin

  SendDataRec.TotalLen := DataLen+SizeOf(DataLen)+SizeOf(SendDataRec.CMD);
  SendDataRec.TotalData := (Self as TSocketObj).GetSendData(SendDataRec.TotalLen);
  PLongWord(SendDataRec.TotalData)^ := DataLen+SizeOf(SendDataRec.CMD);
  SendDataRec.Data := PByte(SendDataRec.TotalData)+SizeOf(DataLen)+
    SizeOf(SendDataRec.CMD);

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
    FreeSendData(SendRec);

  end;
end;

function TCmdSockObj.SendData(const SendDataRec: TCMDDataRec): Boolean;
begin
  PWord(PByte(SendDataRec.TotalData)+sizeof(SendDataRec.DataLen))^ := SendDataRec.CMD;
  Result := (Self as TSocketObj).SendData(SendDataRec.TotalData, SendDataRec.TotalLen, True);
end;

{ TIOCPOBJCMD }

constructor TIOCPCMDList.Create(AIOCPMgr: TIOCPManager);
begin
  inherited;
  inherited IOCPEvent := LCXLEvent;
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
procedure TIOCPCMDList.LCXLEvent(EventType: TIocpEventEnum; SockObj: TLLSockObj;
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
  TotalData := _TotalData;
  TotalLen := _TotalLen;
  Data := PByte(TotalData)+SizeOf(DataLen)+
    SizeOf(CMD);
  CMD := PWord(PByte(TotalData)+SizeOf(DataLen))^;
end;

function TCMDDataRec.GetDataLen: LongWord;
begin
  Result := TotalLen-SizeOf(TotalLen)-SizeOf(CMD);
end;

{ TCmdSockLst }

procedure TCmdSockLst.CreateSockObj(var SockObj: TSocketObj);
begin
  SockObj := TCMDSockObj.Create;

end;

end.
