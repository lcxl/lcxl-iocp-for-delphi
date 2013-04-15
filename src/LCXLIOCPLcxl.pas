unit LCXLIOCPLcxl;

interface

uses
  Windows, Sysutils, LCXLIOCPBase;

type
  TSendDataRec = record
  private
    FTotalLen: LongWord;
    FTotalData: Pointer;
    FData: Pointer;
    FDataLen: LongWord;
  public
    property Data: Pointer read FData;
    property DataLen: LongWord read FDataLen;
    /// <summary>
    /// 将给定的数据转化为本记录的数据结构
    /// </summary>
    function Assgin(_TotalData: Pointer; _TotalLen: LongWord): Boolean;

  end;

  PSendDataRec = ^TSendDataRec;

  TLLSockLst = class(TSocketLst)
  protected
    procedure CreateSockObj(var SockObj: TSocketObj); override; // 覆盖
  end;

  ///	<summary>
  ///	  LCXL协议的socket类
  ///	</summary>
  TLLSockObj = class(TSocketObj)
  private
    FBuf: Pointer;
    FCurDataLen: LongWord;
    FBufLen: LongWord;
    /// <summary>
    /// 接收到的数据
    /// </summary>
    FRecvData: Pointer;
    FRecvDataLen: LongWord;
    /// <summary>
    /// 是否接收一个完整的数据
    /// </summary>
    FIsRecvAll: Boolean;
  protected
    // 初始化
    function Init(): Boolean; override;
    function GetRecvData: Pointer; virtual;
    function GetRecvDataLen: LongWord; virtual;
    property RecvBuf: Pointer read FBuf;
  public
    // 销毁
    destructor Destroy; override;
    // SendData之前锁定
    function SendData(const SendDataRec: TSendDataRec): Boolean; reintroduce; overload;
    function SendData(Data: Pointer; DataLen: LongWord): Boolean; reintroduce; overload;
    // 获取发送数据的指针
    procedure GetSendData(DataLen: LongWord; var SendDataRec: TSendDataRec); reintroduce;
    // 只有没有调用SendData的时候才可以释放，调用SendData之后将会自动释放。
    procedure FreeSendData(const SendDataRec: TSendDataRec); reintroduce;

    property RecvData: Pointer read GetRecvData;
    property RecvDataLen: LongWord read GetRecvDataLen;
    property IsRecvAll: Boolean read FIsRecvAll;

  end;

  // IOCP事件
  TOnLCXLEvent = procedure(EventType: TIocpEventEnum; SockObj: TLLSockObj;
    Overlapped: PIOCPOverlapped) of object;

  // LCXL协议实现类
  TIOCPLCXLList = class(TIOCPBaseList)
  private
    FIOCPEvent: TOnLCXLEvent;
    FListenEvent: TOnListenEvent;
  protected
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); override;
    // 监听事件
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); override;
  public
    // 外部接口
    property IOCPEvent: TOnLCXLEvent read FIOCPEvent write FIOCPEvent;
    property ListenEvent: TOnListenEvent read FListenEvent write FListenEvent;
  end;

implementation

{ TLLSockObj }

destructor TLLSockObj.Destroy;
begin
  if FBuf <> nil then
  begin
    FreeMem(FBuf);
  end;
  inherited;
end;

procedure TLLSockObj.FreeSendData(const SendDataRec: TSendDataRec);
begin
  inherited FreeSendData(SendDataRec.FTotalData);
end;

function TLLSockObj.GetRecvData: Pointer;
begin
  if not FIsRecvAll then
  begin
    Result := nil;
  end
  else
  begin
    Result := FRecvData;
  end;
end;

function TLLSockObj.GetRecvDataLen: LongWord;
begin
  if not FIsRecvAll then
  begin
    Result := 0;
  end
  else
  begin
    Result := FRecvDataLen;
  end;
end;

procedure TLLSockObj.GetSendData(DataLen: LongWord; var SendDataRec: TSendDataRec);
var
  IsSuc: Boolean;
begin
  SendDataRec.FTotalLen := DataLen + SizeOf(DataLen);
  SendDataRec.FTotalData := inherited GetSendData(SendDataRec.FTotalLen);
  PLongWord(SendDataRec.FTotalData)^ := DataLen;

  IsSuc := SendDataRec.Assgin(SendDataRec.FTotalData, SendDataRec.FTotalLen);
  Assert(IsSuc=True);
end;

function TLLSockObj.Init: Boolean;
begin
  // 先调用父类的Init函数
  Result := inherited;
  // 设置为接收数据的长度
  FIsRecvAll := False;
  FCurDataLen := 0;
  FBufLen := 1024;
  GetMem(FBuf, FBufLen);
  // SetKeepAlive(True);
end;

function TLLSockObj.SendData(Data: Pointer; DataLen: LongWord): Boolean;
var
  SendRec: TSendDataRec;
begin
  GetSendData(DataLen, SendRec);
  CopyMemory(SendRec.Data, Data, DataLen);
  Result := SendData(SendRec);
end;

function TLLSockObj.SendData(const SendDataRec: TSendDataRec): Boolean;
begin
  Result := inherited SendData(SendDataRec.FTotalData, SendDataRec.FTotalLen, True);
end;

{ TIOCPOBJLCXL }

procedure TIOCPLCXLList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
var
  LLSockObj: TLLSockObj absolute SockObj;
begin
  case EventType of
    ieRecvAll:
      begin

        // 重新申请内存
        if LLSockObj.FCurDataLen + Overlapped.GetRecvDataLen > LLSockObj.FBufLen then
        begin
          LLSockObj.FBufLen := LLSockObj.FCurDataLen + Overlapped.GetRecvDataLen;
          ReallocMem(LLSockObj.FBuf, LLSockObj.FBufLen);
        end;
        CopyMemory(PByte(LLSockObj.FBuf) + LLSockObj.FCurDataLen, Overlapped.GetRecvData,
          Overlapped.GetRecvDataLen);
        LLSockObj.FCurDataLen := LLSockObj.FCurDataLen + Overlapped.GetRecvDataLen;
        while (LLSockObj.FCurDataLen >= SizeOf(LongWord)) and
          (PLongWord(LLSockObj.FBuf)^ >= LLSockObj.FCurDataLen - SizeOf(LongWord)) do
        begin

          LLSockObj.FRecvData := LLSockObj.FBuf;
          LLSockObj.FRecvDataLen := PLongWord(LLSockObj.FBuf)^ + SizeOf(LongWord);
          LLSockObj.FIsRecvAll := True;

          if Assigned(FIOCPEvent) then
          begin
            FIOCPEvent(ieRecvAll, LLSockObj, Overlapped);
          end;

          LLSockObj.FIsRecvAll := False;
          MoveMemory(LLSockObj.FBuf, PByte(LLSockObj.FBuf) + LLSockObj.FRecvDataLen,
            LLSockObj.FCurDataLen - LLSockObj.FRecvDataLen);

          LLSockObj.FCurDataLen := LLSockObj.FCurDataLen - LLSockObj.FRecvDataLen;

        end;
        if LLSockObj.FCurDataLen > 0 then
        begin
          if Assigned(FIOCPEvent) then
          begin
            FIOCPEvent(ieRecvPart, LLSockObj, Overlapped);
          end;
        end;
      end;
  else
    if Assigned(FIOCPEvent) then
    begin
      FIOCPEvent(EventType, LLSockObj, Overlapped);
    end;
  end;

end;

procedure TIOCPLCXLList.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin
  if Assigned(FListenEvent) then
  begin
    FListenEvent(EventType, SockLst);
  end;

end;

{ TLLSockLst }

procedure TLLSockLst.CreateSockObj(var SockObj: TSocketObj);
begin
  SockObj := TLLSockObj.Create;

end;

{ TSendDataRec }

function TSendDataRec.Assgin(_TotalData: Pointer; _TotalLen: LongWord): Boolean;
begin
  Result := False;
  if (_TotalLen < SizeOf(LongWord)) or (PLongWord(_TotalData)^ <> _TotalLen - SizeOf(LongWord)) then
  begin
    Exit;
  end;
  FTotalData := _TotalData;
  FTotalLen := _TotalLen;

  FData := Pointer(PByte(FTotalData) + SizeOf(LongWord));
  FDataLen := FTotalLen - SizeOf(LongWord);
  Result := True;
end;

end.
