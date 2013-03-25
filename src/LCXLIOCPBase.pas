unit LCXLIOCPBase;

(* **************************************************************************** *)
(* 作者：LCXL *)
(* 内容：IOCP基础类 *)
(* **************************************************************************** *)
interface

uses
  Windows, SysUtils, Classes, Types, LCXLWinSock2, LCXLMSWSock, LCXLMSTcpIP, LCXLWS2Def,
  LCXLWs2tcpip;

var
  AcceptEx: LPFN_ACCEPTEX;
  GetAcceptExSockaddrs: LPFN_GETACCEPTEXSOCKADDRS;

procedure OutputDebugStr(const DebugInfo: string); inline;

type
  // Iocp套接字事件类型
  // ieRecvPart 在本单元中没有实现，扩展用
  TIocpEventEnum = (ieAddSocket, ieDelSocket, ieError, ieRecvPart, ieRecvAll,
    ieRecvFailed, ieSendPart, ieSendAll, ieSendFailed);
  TListenEventEnum = (leAddSockLst, leDelSockLst);
  // ******************* 前置声明 ************************
  TSocketBase = class;
  // 监听线程类，要实现不同的功能，需要继承并实现其子类
  TSocketLst = class;
  // Overlap结构
  PIOCPOverlapped = ^TIOCPOverlapped;
  // Socket类
  TSocketObj = class;
  // Socket列表类，要实现不同的功能，需要继承并实现其子类
  TIOCPBaseList = class;
  // 又成列表类了。。。
  TSocketMgr = class;
  // IOCP管理类
  TIOCPManager = class;
  // *****************************************************

  // ********************* 事件 **************************
  // IOCP事件
  TOnIOCPEvent = procedure(EventType: TIocpEventEnum; SockObj: TSocketObj;
    Overlapped: PIOCPOverlapped) of object;
  // 监听事件
  TOnListenEvent = procedure(EventType: TListenEventEnum; SockLst: TSocketLst) of object;

  TSocketBase = class(TObject)
  protected
    // 被引用了多少次，当RefCount为0时，则free此Socket对象
    // RefCount=1是只有接受
    // RefCount-1为当前正在发送的次数
    FRefCount: Integer;
    // 是否初始化过
    FIsInited: Boolean;
    // 套接字
    FSock: TSocket;
    // 与Socket关联的IOCPOBJBase结构
    // 此处IOCPOBJRec结构所指向的内存一定是在TsocketObj全部关闭时才会无效
    FSockMgr: TSocketMgr;
    // 端口句柄
    FIOComp: THandle;
    FTag: UIntPtr;
    //
    // Overlapped
    FAssignedOverlapped: PIOCPOverlapped;
    function Init(): Boolean; virtual; abstract;
  public
    constructor Create; virtual;
    procedure Close(); virtual;
    ///	<summary>
    ///	  增加引用计数
    ///	</summary>
    ///	<returns>
    ///	  返回当前的引用计数
    ///	</returns>
    function IncRefCount: Integer;
    ///	<summary>
    ///	  减少引用计数
    ///	</summary>
    ///	<returns>
    ///	  返回当前的引用计数
    ///	</returns>
    function DecRefCount: Integer;


    ///	<summary>
    ///	  socket管理器
    ///	</summary>
    property SockMgr: TSocketMgr read FSockMgr;

    ///	<summary>
    ///	  socket句柄
    ///	</summary>
    property Socket: TSocket read FSock;
    property Tag: UIntPtr read FTag write FTag;

    ///	<summary>
    ///	  是否已经初始化了
    ///	</summary>
    property IsInited: Boolean read FIsInited;
  end;

  // ********************* 结构 **************************
  // 监听线程参数结构体
  TSocketLst = class(TSocketBase)
  private
    // 监听的端口号
    FPort: Integer;
    // 总共的接受的数据
    FLstBuf: Pointer;
    // Recv缓冲区总大小
    FLstBufLen: LongWord;
    // Socket连接池大小
    FSocketPoolSize: Integer;
    procedure SetSocketPoolSize(const Value: Integer);
  protected
    function Accept(): Boolean;
    function Init(): Boolean; override;
    procedure CreateSockObj(var SockObj: TSocketObj); virtual; // 覆盖
  public
    constructor Create; override;
    // 销毁
    destructor Destroy; override;

    ///	<summary>
    ///	  监听端口号
    ///	</summary>
    property Port: Integer read FPort;
    ///	<summary>
    ///	  Socket连接池大小
    ///	</summary>
    property SocketPoolSize: Integer read FSocketPoolSize write SetSocketPoolSize;
    ///	<summary>
    ///	  服务端开始监听
    ///	</summary>
    function StartListen(IOCPList: TIOCPBaseList; Port: Integer;
      InAddr: u_long = INADDR_ANY): Boolean;
  end;

  TOverlappedTypeEnum = (otRecv, otSend, otListen);

  ///	<summary>
  ///	  OverLap结构
  ///	</summary>
  _IOCPOverlapped = record
    lpOverlapped: TOverlapped;
    DataBuf: TWSABUF;
    // 是否正在使用中
    IsUsed: LongBool;
    // OverLap的类型
    OverlappedType: TOverlappedTypeEnum;

    // 关联的 SockRec
    AssignedSockObj: TSocketBase;

    function GetRecvData: Pointer;
    function GetRecvDataLen: LongWord;
    function GetCurSendDataLen: LongWord;
    function GetSendData: Pointer;
    function GetTotalSendDataLen: LongWord;

    case TOverlappedTypeEnum of
      otRecv:
        (RecvData: Pointer;
          RecvDataLen: LongWord;
        );
      otSend:
        (
          // 发送的数据
          SendData: Pointer;
          // 当前发送的数据
          CurSendData: Pointer;
          // 发送数据的长度
          SendDataLen: LongWord;
        );
      otListen:
        (
          // 接受的socket
          AcceptSocket: TSocket;
        );
  end;

  TIOCPOverlapped = _IOCPOverlapped;

  ///	<summary>
  ///	  Socket类，一个类管一个套接字
  ///	</summary>
  TSocketObj = class(TSocketBase)
  private

    // Recv缓冲区总大小
    FRecvBufLen: LongWord;
    // 总共的接受的数据
    FRecvBuf: Pointer;
    // 是否是监听到的socket
    FIsSerSocket: Boolean;

    // 是否正在发送
    FIsSending: Boolean;
    // 待发送数据对列。使用FSockMgr来进行同步化操作
    FSendDataQueue: TList;
    function WSARecv(): Boolean; {$IFNDEF DEBUG} inline;
{$ENDIF}
    function WSASend(Overlapped: PIOCPOverlapped): Boolean; {$IFNDEF DEBUG} inline;
{$ENDIF}
  protected

    // 初始化
    function Init(): Boolean; override;
  public
    constructor Create(); override;
    // 销毁
    destructor Destroy; override;

    ///	<summary>
    ///	  连接指定的网络地址，支持IPv6
    ///	</summary>
    ///	<param name="IOCPList">
    ///	  Socket列表
    ///	</param>
    ///	<param name="SerAddr">
    ///	  要连接的地址
    ///	</param>
    ///	<param name="Port">
    ///	  要连接的端口号
    ///	</param>
    ///	<returns>
    ///	  返回是否连接成功
    ///	</returns>
    function ConnectSer(IOCPList: TIOCPBaseList; const SerAddr: string;
      Port: Integer): Boolean;
    ///	<summary>
    ///	  获取远程IP
    ///	</summary>
    function GetRemoteIP(): string; {$IFNDEF DEBUG} inline; {$ENDIF}
    ///	<summary>
    ///	  获取远程端口
    ///	</summary>
    function GetRemotePort(): Word; {$IFNDEF DEBUG} inline; {$ENDIF}

    ///	<summary>
    ///	  获取接受的数据
    ///	</summary>
    function GetRecvBuf(): Pointer; {$IFNDEF DEBUG} inline; {$ENDIF}

    ///	<summary>
    ///	  设置缓冲区长度
    ///	</summary>
    procedure SetRecvBufLenBeforeInit(NewRecvBufLen: DWORD); inline;
    ///	<summary>
    ///	  发送数据，在 SendData之前请锁定
    ///	</summary>
    function SendData(Data: Pointer; DataLen: LongWord;
      UseGetSendDataFunc: Boolean = False): Boolean;

    ///	<summary>
    ///	  获取发送数据的指针
    ///	</summary>
    function GetSendData(DataLen: LongWord): Pointer;

    ///	<summary>
    ///	  只有没有调用SendData的时候才可以释放，调用SendData之后将会自动释放。
    ///	</summary>
    procedure FreeSendData(Data: Pointer);
    //

    ///	<summary>
    ///	  设置心跳包
    ///	</summary>
    procedure SetKeepAlive(IsOn: Boolean; KeepAliveTime: Integer = 50000;
      KeepAliveInterval: Integer = 30000);

    ///	<summary>
    ///	  是否是服务端接受到的socket
    ///	</summary>
    property IsSerSocket: Boolean read FIsSerSocket;
  end;

  ///	<summary>
  ///	  存储Socket列表的类，这个结构规则为：只能被当前的TIOCPBaseList类和管理类访问，其他类禁止访问
  ///	</summary>
  TSocketMgr = class(TObject)
  private
    FIOCPMgr: TIOCPManager;
    // IOCPBase类
    // 如果IOCPBase域为NIL，则说明此IOCPBase已经Free掉，所以当SockRecList为0的时候
    // 应该将此结构从列表中移除并Free掉
    FIOCPList: TIOCPBaseList;
    FLockRefNum: Integer;
    // Iocp Socket相关信息线程安全列表
    FSockObjCS: TRTLCriticalSection;
    // 存储TSocketObj的指针
    FSockObjList: TList;
    // 添加队列列表
    FSockObjAddList: TList;
    // 删除队列列表
    FSockObjDelList: TList;
    // 存储TIocpSockAcp的指针
    FSockLstList: TList;
    // 添加队列列表
    FSockLstAddList: TList;
    // 删除队列列表
    FSockLstDelList: TList;
  public
    constructor Create(AIOCPMgr: TIOCPManager); reintroduce; virtual;
    destructor Destroy(); override;

    ///	<summary>
    ///	  这个只是单纯的临界区锁，要更加有效的锁定列表，使用 LockSockList
    ///	</summary>
    procedure Lock; {$IFNDEF DEBUG}inline; {$ENDIF}

    ///	<summary>
    ///	  这个只是单纯的临界区锁
    ///	</summary>
    procedure Unlock; {$IFNDEF DEBUG}inline; {$ENDIF}

    ///	<summary>
    ///	  锁定列表，注意的锁定后不能对列表进行增加，删除操作，一切都由SocketMgr类维护
    ///	</summary>
    procedure LockSockList;
    procedure UnlockSockList;
    // 增加TIOCPOBJBase引用，如果返回为NULL，则表示IOCPObj已经不可用
    function IncIOCPObjRef: TIOCPBaseList; {$IFNDEF DEBUG}inline; {$ENDIF}

    ///	<summary>
    ///	  设置IOCPObj可以free了
    ///	</summary>
    procedure SetIOCPObjCanFree;
    // 减少引用，必须在IncIOCPObjRef函数执行成功时执行；
    class procedure DecIOCPObjRef(IOCPObj: TIOCPBaseList); {$IFNDEF DEBUG}inline; {$ENDIF}
    // 添加SockObj
    function IOCPRegSockBase(SockBase: TSocketBase): Boolean; {$IFNDEF DEBUG}inline;
{$ENDIF}
    // 添加sockobj，返回True表示成功，返回False表示失败
    function AddSockObj(SockObj: TSocketObj): Boolean;
    // 是否成功初始化SockObj
    function InitSockObj(SockObj: TSocketObj): Boolean;
    // 增加引用
    function IncSockBaseRef(SockBase: TSocketBase): Integer; {$IFNDEF DEBUG}inline;
{$ENDIF}
    // 减少引用
    class function DecSockBaseRef(SockBase: TSocketBase): Integer; {$IFNDEF DEBUG}inline;
{$ENDIF}
    // 释放sockObj
    class procedure FreeSockObj(SockObj: TSocketObj); {$IFNDEF DEBUG}inline; {$ENDIF}
    // 添加SockLst
    function AddSockLst(SockLst: TSocketLst): Boolean; {$IFNDEF DEBUG}inline; {$ENDIF}
    // 释放SockLst
    class procedure FreeSockLst(SockLst: TSocketLst); {$IFNDEF DEBUG}inline; {$ENDIF}
    // 查询是否可以释放本类，此函数只能在锁定期间调用
    function IsCanFree(): Boolean; inline;
  end;

  ///	<summary>
  ///	  IOCP管理基类
  ///	</summary>
  TIOCPBaseList = class(TObject)
  private
    // 是否可以释放此内存，由TSocketMgr触发
    FCanDestroyEvent: THandle;
    // IOCPObj对象
    FSockMgr: TSocketMgr;
    (* ********访问下列变量需要进入临界区IOCPOBJRec.SockObjCS******** *)
    // 是否被设置为释放
    FIsFreeing: Boolean;
    // 被引用次数，只有在FRefCount为0的时候才能真正Free此对象
    FRefCount: Integer;
    (* ************************************************************** *)

    // 添加Socket（监听的和连接的都会调用此函数）
    function AddSockObj(NewSockObj: TSocketObj): Boolean;
    function AddSockLst(NewSockLst: TSocketLst): Boolean;
  protected
    // IOCP事件
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); virtual;
    // 监听事件
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); virtual;

  public
    // 构造器，工作为1.注册自身到IOCPManager对象中，并且设置一个默认的内存分配函数
    constructor Create(AIOCPMgr: TIOCPManager); virtual;
    // 析构器，工作为1.反注册自身，
    destructor Destroy; override;
    // 处理消息函数，
    procedure ProcessMsgEvent();
    // 关闭所有的Socket
    procedure CloseAllSockObj;
    // 关闭所有的Socklst
    procedure CloseAllSockLst;
    // 以锁定状态获取Socket列表
    // 注意：锁定后Socket 列表只能读取，不能进行删除等操作！
    procedure LockSockList; inline;
    // 获取Socket列表
    // 注意：在访问此socket列表之前必须先进行锁定！
    function GetSockList: TList;
    function GetSockLstList: TList;

    property SockList: TList read GetSockList;
    property SockLstList: TList read GetSockLstList;
    // 解锁socket列表
    procedure UnlockSockList; inline;

    // 获取本机IP地址列表
    class procedure GetLocalAddrs(Addrs: TStrings);

  end;

  TIOCPBase2List = class(TIOCPBaseList)
  private
    FIOCPEvent: TOnIOCPEvent;
    FListenEvent: TOnListenEvent;
  protected
    // IOCP事件
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); override;
    // 监听事件
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); override;
  public
    // 外部接口
    property IOCPEvent: TOnIOCPEvent read FIOCPEvent write FIOCPEvent;
    property ListenEvent: TOnListenEvent read FListenEvent write FListenEvent;
  end;

  // IOCP网络模型管理类，一个程序中只有一个实例
  TIOCPManager = class(TObject)
  private
    FwsaData: TWSAData;
    // IOCPBaseRec结构列表
    FSockMgrList: TList;
    // IOCPBase对象临界区
    FSockMgrCS: TRTLCriticalSection;
    // OverLapped线程安全列表
    FOverLappedList: TList;
    FOverLappedCS: TRTLCriticalSection;
    // 完成端口句柄
    FCompletionPort: THandle;
    // IOCP线程句柄动态数组
    FIocpWorkThreads: array of THandle;
  protected

    // 删除Overlapped列表
    procedure FreeOverLappedList;
    // 设置Overlapped为未使用
    procedure DelOverlapped(UsedOverlapped: PIOCPOverlapped);
    // 获取未使用的Overlapped
    function NewOverlapped(SockObj: TSocketBase; OverlappedType: TOverlappedTypeEnum)
      : PIOCPOverlapped;
    // 退出命令
    function PostExitStatus(): Boolean;
  public
    // 构造器
    constructor Create(IOCPThreadCount: Integer = 0);
    // 析构器
    destructor Destroy; override;
    // 注册IOCPBase，在TIOCPBase.Create中调用
    function CreateSockMgr(IOCPBase: TIOCPBaseList): TSocketMgr;
    procedure LockSockMgr; inline;
    function GetSockMgrList: TList; inline;
    procedure UnlockSockMgr; inline;

    procedure LockOverLappedList; inline;
    function GetOverLappedList: TList; inline;
    procedure UnlockOverLappedList; inline;
    // 释放IOCPBaseRec
    procedure FreeSockMgr(SockMgr: TSocketMgr);
  end;

implementation

procedure OutputDebugStr(const DebugInfo: string);
begin
{$IFDEF DEBUG}
  Windows.OutputDebugString(PChar(Format('%s', [DebugInfo])));
{$ENDIF}
end;

// IOCP工作线程
function IocpWorkThread(CompletionPortID: Pointer): DWORD; stdcall;
var
  CompletionPort: THandle absolute CompletionPortID;
  BytesTransferred: DWORD;
  resuInt: Integer;

  // CompletionKeyUIntPtr: ULONG_PTR;
  // CompletionKey: TCOMPLETION_KEY_ENUM absolute CompletionKeyUIntPtr;
  SockBase: TSocketBase;
  SockObj: TSocketObj absolute SockBase;
  SockLst: TSocketLst absolute SockBase;
  _NewSockObj: TSocketObj;

  remote: PSOCKADDR;
  local: PSOCKADDR;
  remoteLen: Integer;
  localLen: Integer;

  SockMgr: TSocketMgr;
  FIocpOverlapped: PIOCPOverlapped;
  FIsSuc: Boolean;
  _IOCPObj: TIOCPBaseList;

  _NeedDecSockObj: Boolean;
begin
  while True do
  begin
    // 查询任务
    FIsSuc := GetQueuedCompletionStatus(CompletionPort, BytesTransferred,
      ULONG_PTR(SockBase), POverlapped(FIocpOverlapped), INFINITE);
    // 尝试获取SockBase
    if SockBase <> nil then
    begin
      Assert(SockBase = FIocpOverlapped.AssignedSockObj);
    end
    else
    begin
      // IOCP 线程退出指令
      // 退出
      OutputDebugStr('获得退出命令，退出并命令下一线程退出。');
      // 通知下一个工作线程退出
      PostQueuedCompletionStatus(CompletionPort, 0, 0, nil);
      Break;
    end;
    if FIsSuc then
    begin

      // 如果是退出线程消息，则退出
      case FIocpOverlapped.OverlappedType of
        otRecv, otSend:
          begin
            if BytesTransferred = 0 then
            begin
              Assert(FIocpOverlapped = SockObj.FAssignedOverlapped);
              OutputDebugStr(Format('socket(%d)已关闭:%d ',
                [SockObj.FSock, WSAGetLastError]));
              // 减少引用
              SockMgr := SockObj.FSockMgr;
              SockMgr.DecSockBaseRef(SockObj);
              // 继续
              Continue;
            end;
            // socket事件
            // 获取IOCPObj，如果没有
            _IOCPObj := SockBase.FSockMgr.IncIOCPObjRef;
            case FIocpOverlapped.OverlappedType of

              otRecv:
                begin
                  Assert(FIocpOverlapped = SockObj.FAssignedOverlapped);
                  // 移动当前接受的指针
                  FIocpOverlapped.RecvDataLen := BytesTransferred;
                  FIocpOverlapped.RecvData := SockObj.FRecvBuf;
                  // 获取事件指针
                  // 发送结果
                  if _IOCPObj <> nil then
                  begin
                    // 产生事件
                    try

                      _IOCPObj.OnIOCPEvent(ieRecvAll, SockObj, FIocpOverlapped);

                    except
                      on E: Exception do
                      begin
                        OutputDebugStr(Format('Message=%s, StackTrace=%s',
                          [E.Message, E.StackTrace]));
                      end;
                    end;

                  end;

                  // 投递下一个WSARecv
                  if not SockObj.WSARecv() then
                  begin
                    // 如果出错
                    OutputDebugStr(Format('WSARecv函数出错socket=%d:%d',
                      [SockObj.FSock, WSAGetLastError]));

                    // 减少引用
                    SockMgr := SockObj.FSockMgr;
                    SockMgr.DecSockBaseRef(SockObj);
                  end;
                end;
              otSend:
                begin
                  // 获取事件指针
                  // 数据指针后移
                  Inc(PByte(FIocpOverlapped.CurSendData), BytesTransferred);
                  // 如果已全部发送完成，释放内存
                  if UIntPtr(FIocpOverlapped.CurSendData) -
                    UIntPtr(FIocpOverlapped.SendData) = FIocpOverlapped.SendDataLen then
                  begin
                    // 触发事件
                    if _IOCPObj <> nil then
                    begin
                      try
                        _IOCPObj.OnIOCPEvent(ieSendAll, SockObj, FIocpOverlapped);
                      except
                        on E: Exception do
                        begin
                          OutputDebugStr(Format('Message=%s, StackTrace=%s',
                            [E.Message, E.StackTrace]));
                        end;
                      end;
                    end;
                    SockMgr := SockObj.FSockMgr;
                    SockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);

                    // 获取待发送的数据

                    FIocpOverlapped := nil;

                    SockMgr.Lock;
                    Assert(SockObj.FIsSending);
                    if SockObj.FSendDataQueue.Count > 0 then
                    begin
                      FIocpOverlapped := SockObj.FSendDataQueue.Items[0];
                      SockObj.FSendDataQueue.Delete(0);
                      OutputDebugStr(Format('Socket(%d)取出待发送数据', [SockObj.FSock]));
                    end
                    else
                    begin
                      SockObj.FIsSending := False;
                    end;
                    SockMgr.Unlock;

                    // 默认减少Socket引用
                    _NeedDecSockObj := True;
                    if FIocpOverlapped <> nil then
                    begin
                      if not SockObj.WSASend(FIocpOverlapped) then
                      // 投递WSASend
                      begin
                        // 如果有错误
                        OutputDebugStr(Format('IocpWorkThread:WSASend函数失败(socket=%d):%d',
                          [SockObj.FSock, WSAGetLastError]));
                        if _IOCPObj <> nil then
                        begin
                          try
                            _IOCPObj.OnIOCPEvent(ieSendFailed, SockObj, FIocpOverlapped);
                          except
                            on E: Exception do
                            begin
                              OutputDebugStr(Format('Message=%s, StackTrace=%s',
                                [E.Message, E.StackTrace]));
                            end;
                          end;
                        end;

                        SockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);
                      end
                      else
                      begin
                        // 发送成功，不减少引用
                        _NeedDecSockObj := False;
                      end;
                    end;

                    if _NeedDecSockObj then
                    begin
                      // 减少引用
                      SockMgr.DecSockBaseRef(SockObj);
                    end;
                  end
                  else
                  begin
                    // 没有全部发送完成
                    FIocpOverlapped.DataBuf.len := FIocpOverlapped.SendDataLen +
                      UIntPtr(FIocpOverlapped.SendData) -
                      UIntPtr(FIocpOverlapped.CurSendData);
                    FIocpOverlapped.DataBuf.buf := FIocpOverlapped.CurSendData;

                    if _IOCPObj <> nil then
                    begin
                      try
                        _IOCPObj.OnIOCPEvent(ieSendPart, SockObj, FIocpOverlapped);
                      except
                        on E: Exception do
                        begin
                          OutputDebugStr(Format('Message=%s, StackTrace=%s',
                            [E.Message, E.StackTrace]));
                        end;
                      end;
                    end;
                    // 继续投递WSASend
                    if not SockObj.WSASend(FIocpOverlapped) then
                    begin // 如果出错
                      OutputDebugStr(Format('WSASend函数出错socket=%d:%d',
                        [SockObj.FSock, WSAGetLastError]));

                      if _IOCPObj <> nil then
                      begin
                        try
                          _IOCPObj.OnIOCPEvent(ieSendFailed, SockObj, FIocpOverlapped);
                        except
                          on E: Exception do
                          begin
                            OutputDebugStr(Format('Message=%s, StackTrace=%s',
                              [E.Message, E.StackTrace]));
                          end;
                        end;
                      end;
                      SockObj.FSockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);
                      // 减少引用
                      SockMgr := SockObj.FSockMgr;
                      SockMgr.DecSockBaseRef(SockObj);
                    end;
                  end;
                end;
            end;
            if _IOCPObj <> nil then
            begin
              TSocketMgr.DecIOCPObjRef(_IOCPObj);
            end;
          end;
        otListen:
          begin
            Assert(FIocpOverlapped = SockLst.FAssignedOverlapped,
              'FIocpOverlapped != SockLst.FLstOverLap');
            GetAcceptExSockaddrs(SockLst.FLstBuf, 0, SizeOf(SOCKADDR_IN) + 16,
              SizeOf(SOCKADDR_IN) + 16, local, localLen, remote, remoteLen);

            // 更新上下文
            resuInt := setsockopt(FIocpOverlapped.AcceptSocket, SOL_SOCKET,
              SO_UPDATE_ACCEPT_CONTEXT, @SockLst.FSock, SizeOf(SockLst.FSock));
            if resuInt <> 0 then
            begin
              OutputDebugStr(Format('socket(%d)设置setsockopt失败:%d',
                [FIocpOverlapped.AcceptSocket, WSAGetLastError()]));
            end;
            // 获取IOCPObj，如果没有
            _IOCPObj := SockBase.FSockMgr.IncIOCPObjRef;
            // 监听
            if _IOCPObj <> nil then
            begin

              // 产生事件，添加SockObj，如果失败，则close之
              _NewSockObj := nil;
              // 创建新的SocketObj类
              SockLst.CreateSockObj(_NewSockObj);
              // 填充Socket句柄
              _NewSockObj.FSock := FIocpOverlapped.AcceptSocket;
              // 设置为服务socket
              _NewSockObj.FIsSerSocket := True;
              // 添加到Socket列表中
              if _IOCPObj.AddSockObj(_NewSockObj) then
              begin

              end
              else
              begin
                closesocket(FIocpOverlapped.AcceptSocket);
              end;
              // 投递下一个Accept端口
              if not SockLst.Accept() then
              begin
                OutputDebugStr('AcceptEx函数失败: ' + IntToStr(WSAGetLastError));
                SockMgr := SockLst.FSockMgr;
                SockMgr.FreeSockLst(SockLst);
              end;
              TSocketMgr.DecIOCPObjRef(_IOCPObj);
            end
            else
            begin
              // IOCPBase类已经释放
              OutputDebugStr('IOCPBase类已经释放。添加Socket失败');
              closesocket(FIocpOverlapped.AcceptSocket);
            end;
          end;
      end;
    end
    else
    begin
      if FIocpOverlapped <> nil then
      begin
        OutputDebugStr(Format('GetQueuedCompletionStatus函数失败(socket=%d): %d',
          [SockBase.FSock, GetLastError]));
        // 关闭
        if FIocpOverlapped <> SockBase.FAssignedOverlapped then
        begin
          // 只有otSend的FIocpOverlapped
          Assert(FIocpOverlapped.OverlappedType = otSend);
          SockBase.FSockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);
        end;
        // 减少引用
        SockMgr := SockBase.FSockMgr;
        case FIocpOverlapped.OverlappedType of
          otRecv, otSend:
            begin
              SockMgr.DecSockBaseRef(SockObj);
            end;
          otListen:
            begin
              SockMgr.FreeSockLst(SockLst);
            end;
        end;
      end
      else
      begin
        OutputDebugStr(Format('GetQueuedCompletionStatus函数失败: %d', [GetLastError]));

      end;

    end;
  end;
  Result := 0;
end;

{ TSocketLst }

function TSocketLst.Accept: Boolean;
var
  BytesReceived: DWORD;
begin
  Assert(FAssignedOverlapped <> nil);
  Assert(FAssignedOverlapped.OverlappedType = otListen);
  // 清空Overlapped
  ZeroMemory(@FAssignedOverlapped.lpOverlapped, SizeOf(FAssignedOverlapped.lpOverlapped));

  FAssignedOverlapped.AcceptSocket := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0,
    WSA_FLAG_OVERLAPPED);

  Result := (AcceptEx(FSock, FAssignedOverlapped.AcceptSocket, FLstBuf, 0,
    SizeOf(sockaddr_storage) + 16, SizeOf(sockaddr_storage) + 16, BytesReceived,
    @FAssignedOverlapped.lpOverlapped) = True) or (WSAGetLastError = WSA_IO_PENDING);
  // 投递AcceptEx
  if not Result then
  begin
    closesocket(FAssignedOverlapped.AcceptSocket);
    FAssignedOverlapped.AcceptSocket := INVALID_SOCKET;
  end;
end;

constructor TSocketLst.Create;
begin
  inherited;
  FSocketPoolSize := 10;
end;

procedure TSocketLst.CreateSockObj(var SockObj: TSocketObj);
begin
  Assert(SockObj = nil);
  SockObj := TSocketObj.Create;
end;

destructor TSocketLst.Destroy;
begin

  if FLstBuf <> nil then
  begin
    FreeMem(FLstBuf);
  end;

  inherited;
end;

function TSocketLst.Init: Boolean;
begin

  GetMem(FLstBuf, FLstBufLen); // 分配接受数据的内存
  Result := True;
end;

procedure TSocketLst.SetSocketPoolSize(const Value: Integer);
begin
  if not FIsInited then
  begin
    if Value > 0 then
    begin
      FSocketPoolSize := Value;
    end;
  end
  else
  begin
    raise Exception.Create('SocketPoolSize can''t be set after StartListen');
  end;
end;

function TSocketLst.StartListen(IOCPList: TIOCPBaseList; Port: Integer;
  InAddr: u_long): Boolean;
var
  InternetAddr: TSockAddrIn;
  // ListenSock: Integer;
  ErrorCode: Integer;
begin
  Result := False;
  FPort := Port;
  FSock := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, WSA_FLAG_OVERLAPPED);
  if (FSock = INVALID_SOCKET) then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('WSASocket 函数失败：' + IntToStr(ErrorCode));
    Exit;
  end;
  InternetAddr.sin_family := AF_INET;
  InternetAddr.sin_addr.s_addr := htonl(InAddr);
  InternetAddr.sin_port := htons(Port);
  // 绑定端口号
  if (bind(FSock, @InternetAddr, SizeOf(InternetAddr)) = SOCKET_ERROR) then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('bind 函数失败：' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
    Exit;
  end;
  // 开始监听
  if listen(FSock, SOMAXCONN) = SOCKET_ERROR then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('listen 函数失败：' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
    Exit;
  end;
  // 添加到SockLst
  Result := IOCPList.AddSockLst(Self);
  if not Result then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('AddSockLst 函数失败：' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
  end;
end;

{ TSocketObj }

function TSocketObj.ConnectSer(IOCPList: TIOCPBaseList; const SerAddr: string;
  Port: Integer): Boolean;
var
  LastError: DWORD;
  _Hints: TAddrInfoA;
  _ResultAddInfo: PADDRINFOA;
  _NextAddInfo: PADDRINFOA;
  _Retval: Integer;
{$IFDEF DEBUG}
  _DebugStr: string;
{$ENDIF}
  _AddrString: string;
  _AddrStringLen: DWORD;
begin
  Assert(FIsSerSocket = False, '');
  Result := False;
  ZeroMemory(@_Hints, SizeOf(_Hints));
  _Hints.ai_family := AF_UNSPEC;
  _Hints.ai_socktype := SOCK_STREAM;
  _Hints.ai_protocol := IPPROTO_TCP;

  _Retval := getaddrinfo(PAnsiChar(AnsiString(SerAddr)),
    PAnsiChar(AnsiString(IntToStr(Port))), @_Hints, _ResultAddInfo);
  if _Retval <> 0 then
  begin
    Exit;
  end;
  _NextAddInfo := _ResultAddInfo;

  while _NextAddInfo <> nil do
  begin
    _AddrStringLen := 1024;
    // 申请缓冲区
    SetLength(_AddrString, _AddrStringLen);
    // 获取
{$IFDEF DEBUG}
    if WSAAddressToString(_NextAddInfo.ai_addr, _NextAddInfo.ai_addrlen, nil,
      PChar(_AddrString), _AddrStringLen) = 0 then
    begin
      // 改为真实长度,这里的_AddrStringLen包含了末尾的字符#0，所以要减去这个#0的长度
      SetLength(_AddrString, _AddrStringLen - 1);

      _DebugStr := Format('ai_addr:%s,ai_flags:%d,ai_canonname=%s',
        [_AddrString, _NextAddInfo.ai_flags, _NextAddInfo.AI_CANONNAME]);
      OutputDebugStr(_DebugStr);

    end
    else
    begin
      _AddrString := 'None';
      OutputDebugStr('WSAAddressToString Error');
    end;
{$ENDIF}
    FSock := WSASocket(_NextAddInfo.ai_family, _NextAddInfo.ai_socktype,
      _NextAddInfo.ai_protocol, nil, 0, WSA_FLAG_OVERLAPPED);

    if FSock <> INVALID_SOCKET then
    begin
      if connect(FSock, _NextAddInfo.ai_addr, _NextAddInfo.ai_addrlen) = SOCKET_ERROR then
      begin
        LastError := WSAGetLastError();
{$IFDEF DEBUG}
        OutputDebugStr(Format('连接%s失败：%d', [_AddrString, LastError]));
{$ENDIF}
        closesocket(FSock);
        WSASetLastError(LastError);
        FSock := INVALID_SOCKET;
      end
      else
      begin
        Result := IOCPList.AddSockObj(Self);
        Break;
      end;
    end;
    _NextAddInfo := _NextAddInfo.ai_next;

  end;
  freeaddrinfo(_ResultAddInfo);

end;

constructor TSocketObj.Create;
begin
  inherited;
  // 设置初始缓冲区为4096
  FRecvBufLen := 4096;
end;

destructor TSocketObj.Destroy;
var
  _TmpData: Pointer;
  _IOCPOverlapped: PIOCPOverlapped absolute _TmpData;
begin
  if FSendDataQueue <> nil then
  begin
    for _TmpData in FSendDataQueue do
    begin
      FSockMgr.FIOCPMgr.DelOverlapped(_IOCPOverlapped);
    end;
    FSendDataQueue.Free;
  end;
  if FRecvBuf <> nil then
  begin
    FreeMem(FRecvBuf);
  end;
  inherited;
end;

procedure TSocketObj.FreeSendData(Data: Pointer);
begin
  FreeMem(Data);
end;

function TSocketObj.GetRecvBuf: Pointer;
begin
  Result := FRecvBuf;
end;

function TSocketObj.GetRemoteIP: string;
var
  name: TSockAddr;
  namelen: Integer;
begin
  namelen := SizeOf(name);
  if getpeername(FSock, name, namelen) = 0 then
  begin
    Result := string(inet_ntoa(name.sin_addr));
  end
  else
  begin
    // OutputDebugStr(Format('socket(%d)getpeername失败:%d', [FSock, WSAGetLastError()]));
    Result := '';
  end;
end;

function TSocketObj.GetRemotePort: Word;
var
  name: TSockAddr;
  namelen: Integer;
begin
  namelen := SizeOf(name);
  if getpeername(FSock, name, namelen) = 0 then
  begin
    Result := ntohs(name.sin_port);
  end
  else
  begin
    // OutputDebugStr(Format('socket(%d)getpeername失败:%d', [FSock, WSAGetLastError()]));
    Result := 0;
  end;
end;

function TSocketObj.GetSendData(DataLen: LongWord): Pointer;
begin
  GetMem(Result, DataLen);
end;

function TSocketObj.Init: Boolean;
begin
  Assert(FRecvBufLen > 0);
  Result := False;
  GetMem(FRecvBuf, FRecvBufLen); // 分配接受数据的内存
  if FRecvBuf = nil then
  begin
    Exit;
  end;
  // 初始化
  FSendDataQueue := TList.Create;
  Result := True;
end;

function TSocketObj.SendData(Data: Pointer; DataLen: LongWord;
  UseGetSendDataFunc: Boolean): Boolean;
var
  FIocpOverlapped: PIOCPOverlapped;
  _NewData: Pointer;
  _IsSending: Boolean;
  _IsInited: Boolean;
begin
  if DataLen = 0 then
  begin
    Result := True;
    Exit;
  end;
  // 先增加引用
  FSockMgr.IncSockBaseRef(Self);
  _NewData := nil;
  Assert(Data <> nil);
  Result := False;

  FIocpOverlapped := FSockMgr.FIOCPMgr.NewOverlapped(Self, otSend);
  if FIocpOverlapped <> nil then
  begin

    if UseGetSendDataFunc then
    begin
      // 填充发送数据有关的信息
      FIocpOverlapped.SendData := Data;
    end
    else
    begin
      GetMem(_NewData, DataLen);
      CopyMemory(_NewData, Data, DataLen);
      FIocpOverlapped.SendData := _NewData;
    end;
    FIocpOverlapped.CurSendData := FIocpOverlapped.SendData;
    FIocpOverlapped.SendDataLen := DataLen;

    FIocpOverlapped.DataBuf.buf := FIocpOverlapped.CurSendData;
    FIocpOverlapped.DataBuf.len := FIocpOverlapped.SendDataLen;
    FSockMgr.Lock;
    _IsSending := FIsSending;
    _IsInited := FIsInited;
    // 如果里面有正在发送的
    if FIsSending then
    begin
      FSendDataQueue.Add(FIocpOverlapped);
      OutputDebugStr(Format('Socket(%d)中的发送数据加入到待发送对列', [Self.FSock]));
    end
    else
    begin
      FIsSending := True;
    end;
    FSockMgr.Unlock;

    if not _IsSending then
    begin
      // OutputDebugStr(Format('SendData:Overlapped=%p,Overlapped=%d',[FIocpOverlapped, Integer(FIocpOverlapped.OverlappedType)]));

      if not Self.WSASend(FIocpOverlapped) then // 投递WSASend
      begin
        // 如果有错误
        OutputDebugStr(Format('SendData:WSASend函数失败(socket=%d):%d',
          [FSock, WSAGetLastError]));
        // 删除此Overlapped
        FSockMgr.FIOCPMgr.DelOverlapped(FIocpOverlapped);

        FSockMgr.Lock;
        FIsSending := False;
        FSockMgr.Unlock;
      end
      else
      begin
        Result := True;
      end;
    end
    else
    begin
      // 添加到待发送对列的数据不会增加引用，因此需要取消先前的预引用
      FSockMgr.DecSockBaseRef(Self);
      Result := True;
    end;
  end;

  if not Result then
  begin
    if not UseGetSendDataFunc then
    begin
      if _NewData <> nil then
      begin
        FreeMem(_NewData);
      end;
    end;
    // 减少引用
    FSockMgr.DecSockBaseRef(Self);
  end;
end;

procedure TSocketObj.SetKeepAlive(IsOn: Boolean;
  KeepAliveTime, KeepAliveInterval: Integer);
var
  alive_in: tcp_keepalive;
  alive_out: tcp_keepalive;
  ulBytesReturn: ulong;
begin
  alive_in.KeepAliveTime := KeepAliveTime; // 开始首次KeepAlive探测前的TCP空闭时间
  alive_in.KeepAliveInterval := KeepAliveInterval; // 两次KeepAlive探测间的时间间隔
  alive_in.onoff := u_long(IsOn);
  WSAIoctl(FSock, SIO_KEEPALIVE_VALS, @alive_in, SizeOf(alive_in), @alive_out,
    SizeOf(alive_out), @ulBytesReturn, nil, nil);
end;

procedure TSocketObj.SetRecvBufLenBeforeInit(NewRecvBufLen: DWORD);
begin
  if FRecvBufLen <> NewRecvBufLen then
  begin
    FRecvBufLen := NewRecvBufLen;
  end;
end;

function TSocketObj.WSARecv(): Boolean;
var
  Flags: DWORD;
begin
  // 清空Overlapped
  ZeroMemory(@FAssignedOverlapped.lpOverlapped, SizeOf(FAssignedOverlapped.lpOverlapped));
  // 设置OverLap
  FAssignedOverlapped.DataBuf.len := FRecvBufLen;
  FAssignedOverlapped.DataBuf.buf := FRecvBuf;
  Flags := 0;
  Result := (LCXLWinSock2.WSARecv(FSock, @FAssignedOverlapped.DataBuf, 1, nil, @Flags,
    @FAssignedOverlapped.lpOverlapped, nil) = 0) or (WSAGetLastError = WSA_IO_PENDING)
end;

function TSocketObj.WSASend(Overlapped: PIOCPOverlapped): Boolean;
begin
  // OutputDebugStr(Format('WSASend:Overlapped=%p,Overlapped=%d',[Overlapped, Integer(Overlapped.OverlappedType)]));
  // 清空Overlapped
  ZeroMemory(@Overlapped.lpOverlapped, SizeOf(Overlapped.lpOverlapped));

  Assert(Overlapped.OverlappedType = otSend);
  Assert((Overlapped.DataBuf.buf <> nil) and (Overlapped.DataBuf.len > 0));

  Result := (LCXLWinSock2.WSASend(FSock, @Overlapped.DataBuf, 1, nil, 0,
    @Overlapped.lpOverlapped, nil) = 0) or (WSAGetLastError = WSA_IO_PENDING)
end;

{ TSocketMgrObj }

function TSocketMgr.AddSockLst(SockLst: TSocketLst): Boolean;
begin
  Result := IOCPRegSockBase(SockLst);
  if Result then
  begin
    Lock;
    Result := FSockLstList.Add(SockLst) >= 0;
    Unlock;
  end;
end;

function TSocketMgr.IOCPRegSockBase(SockBase: TSocketBase): Boolean;
begin
  Assert(FIOCPList <> nil);
  // 在IOCP中注册此Socket
  SockBase.FIOComp := CreateIoCompletionPort(SockBase.FSock, FIOCPMgr.FCompletionPort,
    ULONG_PTR(SockBase), 0);
  Result := SockBase.FIOComp <> 0;
  if not Result then
  begin
    OutputDebugStr(Format('Socket(%d)IOCP注册失败！Error:%d',
      [SockBase.FSock, WSAGetLastError()]));
  end;
end;

function TSocketMgr.IsCanFree: Boolean;
begin
  Result := (FIOCPList = nil) and (FSockObjList.Count = 0) and (FSockLstList.Count = 0)
    and (FSockObjDelList.Count = 0) and (FSockObjAddList.Count = 0);
end;

function TSocketMgr.AddSockObj(SockObj: TSocketObj): Boolean;
var
  _IsLocked: Boolean;
begin
  Assert(SockObj.FSock <> INVALID_SOCKET);
  SockObj.FSockMgr := Self;
  Lock;
  // List是否被锁住
  _IsLocked := FLockRefNum > 0;
  if _IsLocked then
  begin
    // 被锁住，不能对Socket列表进行添加或删除操作，先加到Socket待添加List中。
    FSockObjAddList.Add(SockObj);
    OutputDebugStr(Format('列表被锁定，Socket(%d)进入待添加队列', [SockObj.FSock]));
  end
  else
  begin
    // 没有被锁住，直接添加到Socket列表中
    FSockObjList.Add(SockObj);

  end;
  Unlock;
  if not _IsLocked then
  begin
    // 如果没有被锁住，初始化Socket
    // 增加SockObj的引用，以免初始化失败的时候会被自动Free掉
    IncSockBaseRef(SockObj);
    Result := InitSockObj(SockObj);
    if Result then
    begin
      // 初始化成功了，那就减少SockObj的引用
      DecSockBaseRef(SockObj);
    end
    else
    begin
      // 初始化出错，
      Assert(SockObj.FRefCount = 1);

    end;
  end
  else
  begin
    // 如果被锁住，那返回值永远是True
    Result := True;
  end;
end;

constructor TSocketMgr.Create(AIOCPMgr: TIOCPManager);
begin
  inherited Create();
  FLockRefNum := 0;
  FIOCPMgr := AIOCPMgr;
  InitializeCriticalSection(FSockObjCS);
  FSockObjList := TList.Create;
  FSockObjAddList := TList.Create;
  FSockObjDelList := TList.Create;

  FSockLstList := TList.Create;
  FSockLstAddList := TList.Create;
  FSockLstDelList := TList.Create;
end;

class procedure TSocketMgr.DecIOCPObjRef(IOCPObj: TIOCPBaseList);
var
  _IOCPObj: TIOCPBaseList;
  CanFree: Boolean;
  SockMgr: TSocketMgr;
  IOCPMgr: TIOCPManager;
begin
  _IOCPObj := nil;
  SockMgr := IOCPObj.FSockMgr;
  // 锁定
  SockMgr.Lock;
  Assert(SockMgr.FIOCPList <> nil);
  // 减少引用
  Dec(SockMgr.FIOCPList.FRefCount);

  if SockMgr.FIOCPList.FRefCount = 0 then
  begin
    Assert(SockMgr.FIOCPList.FIsFreeing);

    _IOCPObj := SockMgr.FIOCPList;
    SockMgr.FIOCPList := nil;
  end;
  CanFree := SockMgr.IsCanFree();
  SockMgr.Unlock;
  // _IOCPObj是否可以释放
  if _IOCPObj <> nil then
  begin
    // 释放IOCPObj内存
    Assert(_IOCPObj.FCanDestroyEvent <> 0);
    SetEvent(_IOCPObj.FCanDestroyEvent);
    // _IOCPObj.FCanDestroy := True;
    // _IOCPObj.Destroy;
    if CanFree then
    begin
      IOCPMgr := SockMgr.FIOCPMgr;
      IOCPMgr.FreeSockMgr(SockMgr);
    end;
  end;
end;

class function TSocketMgr.DecSockBaseRef(SockBase: TSocketBase): Integer;
var
  _IsLocked: Boolean;
  SockObj: TSocketObj absolute SockBase;
  SockLst: TSocketLst absolute SockBase;
begin
  SockBase.FSockMgr.Lock;
  Dec(SockBase.FRefCount);
  Result := SockBase.FRefCount;
  SockBase.FSockMgr.Unlock;
  if Result = 0 then
  begin
    if SockBase is TSocketObj then
    begin
      SockBase.FSockMgr.Lock;

      _IsLocked := SockBase.FSockMgr.FLockRefNum > 0;
      if _IsLocked then
      begin
        OutputDebugStr(Format('列表被锁定，Socket(%d)进入待删除队列', [SockBase.FSock]));
        SockBase.FSockMgr.FSockObjDelList.Add(SockObj);
      end
      else
      begin
        SockBase.FSockMgr.FSockObjList.Remove(SockObj);
      end;
      SockBase.FSockMgr.Unlock;
      // 如果没有被锁定
      if not _IsLocked then
      begin
        FreeSockObj(SockObj);
      end;
    end
    else if SockBase is TSocketLst then
    begin
      FreeSockLst(SockLst);
    end
    else
    begin
      Assert(False, 'unknown SockBase');
    end;
  end;
end;

destructor TSocketMgr.Destroy;
begin
  FSockLstDelList.Free;
  FSockLstAddList.Free;
  FSockLstList.Free;

  FSockObjDelList.Free;
  FSockObjAddList.Free;
  FSockObjList.Free;

  DeleteCriticalSection(FSockObjCS);
  inherited;
end;

class procedure TSocketMgr.FreeSockLst(SockLst: TSocketLst);
var
  CanFree: Boolean;
  _IOCPObj: TIOCPBaseList;
  SockMgr: TSocketMgr;
  IOCPMgr: TIOCPManager;
begin
  SockMgr := SockLst.FSockMgr;

  SockMgr.Lock;
  // 从列表中移除
  SockMgr.FSockLstList.Remove(SockLst);
  SockMgr.Unlock;

  _IOCPObj := SockMgr.IncIOCPObjRef;
  if _IOCPObj <> nil then
  begin
    _IOCPObj.OnListenEvent(leDelSockLst, SockLst);
    TSocketMgr.DecIOCPObjRef(_IOCPObj);
  end;
  IOCPMgr := SockMgr.FIOCPMgr;
  // 删除OverLapped
  IOCPMgr.DelOverlapped(SockLst.FAssignedOverlapped);
  SockMgr.Lock;
  CanFree := SockMgr.IsCanFree();
  SockMgr.Unlock;

  SockLst.Free;
  if CanFree then
  begin
    IOCPMgr.FreeSockMgr(SockMgr);
  end;
end;

class procedure TSocketMgr.FreeSockObj(SockObj: TSocketObj);
var
  CanFree: Boolean;
  _IOCPObj: TIOCPBaseList;
  SockMgr: TSocketMgr;
  IOCPMgr: TIOCPManager;
begin
  SockMgr := SockObj.FSockMgr;

  // 引用IOCPObj
  _IOCPObj := SockMgr.IncIOCPObjRef();
  if _IOCPObj <> nil then
  begin
    // 触发事件，此时socket已经从列表中删除了
    try
      _IOCPObj.OnIOCPEvent(ieDelSocket, SockObj, nil);
    except

    end;
    TSocketMgr.DecIOCPObjRef(_IOCPObj);
  end;
  SockMgr.Lock;
  Assert(SockObj.FRefCount = 0);
  CanFree := SockMgr.IsCanFree;
  SockMgr.Unlock;
  // 删除
  if (SockObj.FAssignedOverlapped <> nil) then
  begin
    SockObj.FSockMgr.FIOCPMgr.DelOverlapped(SockObj.FAssignedOverlapped);
  end;
  // 释放sockobj
  SockObj.Free;

  if CanFree then
  begin
    IOCPMgr := SockMgr.FIOCPMgr;
    IOCPMgr.FreeSockMgr(SockMgr);
  end;
end;

function TSocketMgr.IncIOCPObjRef: TIOCPBaseList;
begin
  Lock;
  Result := FIOCPList;
  if Result <> nil then
  begin
    if Result.FIsFreeing then
    begin
      Result := nil;
    end
    else
    begin
      Inc(Result.FRefCount);
    end;
  end;
  Unlock;
end;

function TSocketMgr.IncSockBaseRef(SockBase: TSocketBase): Integer;
begin
  Lock;
  Assert(SockBase.FRefCount > 0);
  Inc(SockBase.FRefCount);
  Result := SockBase.FRefCount;

  Unlock;

end;

function TSocketMgr.InitSockObj(SockObj: TSocketObj): Boolean;
var
  _IOCPObj: TIOCPBaseList;
begin
  Result := False;
  // 开始初始化Socket
  if SockObj.Init() then
  begin
    // 锁定
    Lock;
    SockObj.FIsInited := True;
    Unlock;
    Assert(SockObj.FRefCount > 0);
    // 添加到Mgr
    if IOCPRegSockBase(SockObj) then
    begin
      // 成功就设置IsSuc为True
      Result := True;
    end;
  end;
  // 引用IOCPObj
  _IOCPObj := IncIOCPObjRef();

  // 是否成功创建和添加到sockobj列表
  if Result then
  begin
    if _IOCPObj <> nil then
    begin
      try
        _IOCPObj.OnIOCPEvent(ieAddSocket, SockObj, nil);
      except

      end;
    end;
    // 获得Recv的Overlapped
    SockObj.FAssignedOverlapped := FIOCPMgr.NewOverlapped(SockObj, otRecv);
    if not SockObj.WSARecv() then // 投递WSARecv
    begin // 如果出错
      OutputDebugStr(Format('InitSockObj:WSARecv函数出错socket=%d:%d',
        [SockObj.FSock, WSAGetLastError]));

      if _IOCPObj <> nil then
      begin
        try
          _IOCPObj.OnIOCPEvent(ieRecvFailed, SockObj, SockObj.FAssignedOverlapped);
        except

        end;
      end;
      // 减少引用
      DecSockBaseRef(SockObj);
      Result := False;
    end;
  end
  else
  begin
    // 减少引用
    DecSockBaseRef(SockObj);
  end;
  if _IOCPObj <> nil then
  begin
    TSocketMgr.DecIOCPObjRef(_IOCPObj);
  end;
end;

procedure TSocketMgr.Lock;
begin
  EnterCriticalSection(FSockObjCS);

end;

procedure TSocketMgr.LockSockList;
begin
  Lock;
  Assert(FLockRefNum >= 0);
  Inc(FLockRefNum);
  Unlock;
end;

procedure TSocketMgr.SetIOCPObjCanFree;
var
  SockBasePtr: Pointer;
  SockBase: TSocketBase absolute SockBasePtr;

  IOCPObj: TIOCPBaseList;
begin
  Lock;
  IOCPObj := FIOCPList;
  // 开始自动释放
  FIOCPList.FIsFreeing := True;
  // 关闭所有的监听
  for SockBasePtr in FSockLstList do
  begin
    SockBase.Close;
  end;
  // 关闭所有的socket
  for SockBasePtr in FSockObjList do
  begin
    SockBase.Close;
  end;
  // 关闭所有待添加的socket
  for SockBasePtr in FSockObjAddList do
  begin
    SockBase.Close;
  end;
  Unlock;
  // 减少引用
  // 会有问题吗？
  DecIOCPObjRef(IOCPObj);
end;

procedure TSocketMgr.Unlock;
begin
  LeaveCriticalSection(FSockObjCS);
end;

procedure TSocketMgr.UnlockSockList;
var
  isAdd: Boolean;
  SockObj: TSocketObj;
  _IsEnd: Boolean;
begin
  isAdd := False;
  repeat
    SockObj := nil;
    Lock;
    Assert(FLockRefNum >= 1, 'Socket列表锁定线程数出错。');
    // 判断是不是只有本线程锁定了列表，只要判断FLockRefNum是不是大于1
    _IsEnd := FLockRefNum > 1;
    if not _IsEnd then
    begin
      // 只有本线程锁住了socket，然后查看socket删除列表是否为空
      if FSockObjDelList.Count > 0 then
      begin
        // 不为空，从第一个开始删
        SockObj := FSockObjDelList.Items[0];
        FSockObjDelList.Delete(0);
        FSockObjList.Remove(SockObj);
        isAdd := False;
      end
      else
      begin
        // 查看socket添加列表是否为空
        if FSockObjAddList.Count > 0 then
        begin
          isAdd := True;
          // 如果不为空，则pop一个sockobj添加到列表中
          SockObj := FSockObjAddList.Items[0];
          FSockObjAddList.Delete(0);
          FSockObjList.Add(SockObj);
        end
        else
        begin
          // 都为空，则表示已经结束了
          _IsEnd := True;
        end;
      end;
    end;
    // 如果没什么想要处理的了，锁定列表数减1
    if _IsEnd then
    begin
      Dec(FLockRefNum);
    end;
    Unlock;

    // 查看sockobj是否为空，不为空则表示在锁List期间有删除sock或者添加sock操作
    if SockObj <> nil then
    begin

      if isAdd then
      begin
        // 有添加sock操作，初始化sockobj，如果失败，会自动被Free掉，无需获取返回值
        InitSockObj(SockObj);
      end
      else
      begin
        // 有删除sock操作，删除sockobk
        FreeSockObj(SockObj);
      end;
    end;
  until _IsEnd;
end;

{ TIOCPOBJBase }

function TIOCPBaseList.AddSockLst(NewSockLst: TSocketLst): Boolean;
var
  IsSuc: Boolean;
begin
  NewSockLst.FSockMgr := FSockMgr;
  NewSockLst.FLstBufLen := (SizeOf(sockaddr_storage) + 16) * 2;
  IsSuc := False;
  if NewSockLst.Init() then
  begin
    NewSockLst.FIsInited := True;
    // 添加到Mgr
    if FSockMgr.AddSockLst(NewSockLst) then
    begin

      // 成功就设置IsSuc为True
      IsSuc := True;
    end;
  end;
  if IsSuc then
  begin
    OnListenEvent(leAddSockLst, NewSockLst);
    // 获得Listen的Overlapped
    NewSockLst.FAssignedOverlapped := FSockMgr.FIOCPMgr.NewOverlapped(NewSockLst,
      otListen);
    if not NewSockLst.Accept() then // 投递AcceptEx
    begin
      OutputDebugStr('AcceptEx函数失败: ' + IntToStr(WSAGetLastError));
      NewSockLst.Close;
      Result := False;
    end
    else
    begin
      Result := True;
    end;
  end
  else
  begin
    NewSockLst.Close;
    Result := False;
  end;
end;

function TIOCPBaseList.AddSockObj(NewSockObj: TSocketObj): Boolean;
begin
  Result := FSockMgr.AddSockObj(NewSockObj);
end;

procedure TIOCPBaseList.CloseAllSockLst;
var
  SockList: TList;
  SockLst: TSocketLst;
  SockLstPtr: Pointer;
begin
  FSockMgr.Lock;
  SockList := FSockMgr.FSockLstList;
  for SockLstPtr in SockList do
  begin
    SockLst := TSocketLst(SockLstPtr);
    // 关闭连接
    SockLst.Close;
  end;
  FSockMgr.Unlock;
end;

procedure TIOCPBaseList.CloseAllSockObj;
var
  SockList: TList;
  SockObj: TSocketObj;
  SockObjPtr: Pointer;
begin
  FSockMgr.LockSockList;
  SockList := FSockMgr.FSockObjList;
  for SockObjPtr in SockList do
  begin
    SockObj := TSocketObj(SockObjPtr);
    // 关闭连接
    SockObj.Close;
  end;
  FSockMgr.UnlockSockList;
end;

constructor TIOCPBaseList.Create(AIOCPMgr: TIOCPManager);
begin
  // 创建SockMgr
  FSockMgr := AIOCPMgr.CreateSockMgr(Self);
end;

destructor TIOCPBaseList.Destroy;
const
  EVENT_NUMBER = 1;
var
  _IsEnd: Boolean;
  EventArray: array [0 .. EVENT_NUMBER - 1] of THandle;
begin
  // 创建释放类事件
  FCanDestroyEvent := CreateEvent(nil, True, False, nil);
  // 设置此类可以被释放
  FSockMgr.SetIOCPObjCanFree;

  EventArray[0] := FCanDestroyEvent;
  _IsEnd := False;
  // 等待释放类的事件
  while not _IsEnd do
  begin
    case MsgWaitForMultipleObjects(1, EventArray[0], True, INFINITE, QS_ALLINPUT) of
      WAIT_OBJECT_0:
        begin
          // 可以释放了
          _IsEnd := True;
        end;
      WAIT_OBJECT_0 + EVENT_NUMBER:
        begin
          // 有GUI消息，先处理GUI消息
          OutputDebugStr('TIOCPBaseList.Destroy:Process GUI Event');
          ProcessMsgEvent();
        end;
    else
      _IsEnd := True;
    end;
  end;
  inherited;
end;

class procedure TIOCPBaseList.GetLocalAddrs(Addrs: TStrings);
var
  phe: PHostEnt;
  pptr: PInAddr;
  sHostName: AnsiString;
  addrlist: PPAnsiChar;
begin
  Addrs.Clear;
  SetLength(sHostName, MAX_PATH);
  if gethostname(PAnsiChar(sHostName), MAX_PATH) = SOCKET_ERROR then
    Exit;
  phe := GetHostByName(PAnsiChar(sHostName));
  if phe = nil then
    Exit;
  addrlist := PPAnsiChar(phe^.h_addr_list);
  while addrlist^ <> nil do
  begin
    pptr := PInAddr(addrlist^);
    Addrs.Add(string(inet_ntoa(pptr^)));
    Inc(addrlist);
  end;
end;

function TIOCPBaseList.GetSockList: TList;
begin
  Result := FSockMgr.FSockObjList;
end;

function TIOCPBaseList.GetSockLstList: TList;
begin
  Result := FSockMgr.FSockLstList;
end;

procedure TIOCPBaseList.LockSockList;
begin
  FSockMgr.LockSockList;
end;

procedure TIOCPBaseList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
begin
  // 不做任何事请，请覆盖此事件
end;

procedure TIOCPBaseList.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin
  // 不做任何事请，请覆盖此事件
end;

procedure TIOCPBaseList.ProcessMsgEvent;
var
  Unicode: Boolean;
  MsgExists: Boolean;
  Msg: TMsg;
begin
  while PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE) do
  begin
    Unicode := (Msg.hwnd = 0) or IsWindowUnicode(Msg.hwnd);
    if Unicode then
      MsgExists := PeekMessageW(Msg, 0, 0, 0, PM_REMOVE)
    else
      MsgExists := PeekMessageA(Msg, 0, 0, 0, PM_REMOVE);

    if MsgExists then
    begin
      TranslateMessage(Msg);
      if Unicode then
        DispatchMessageW(Msg)
      else
        DispatchMessageA(Msg);
    end;
  end;
end;

procedure TIOCPBaseList.UnlockSockList;
begin
  FSockMgr.UnlockSockList;
end;

{ TIOCPManager }

constructor TIOCPManager.Create(IOCPThreadCount: Integer);
var
  ThreadID: DWORD;
  I: Integer;
  TmpSock: TSocket;
  dwBytes: DWORD;
begin
  inherited Create();
  IsMultiThread := True;
  OutputDebugStr('TIOCPManager.Create');
  // 使用 2.2版的WS2_32.DLL
  if WSAStartup($0202, FwsaData) <> 0 then
  begin
    raise Exception.Create('WSAStartup Fails');
  end;
  // 获取AcceptEx和GetAcceptExSockaddrs的函数指针
  TmpSock := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0, WSA_FLAG_OVERLAPPED);
  if TmpSock = INVALID_SOCKET then
  begin
    raise Exception.Create('WSASocket Fails');
  end;
  if (SOCKET_ERROR = WSAIoctl(TmpSock, SIO_GET_EXTENSION_FUNCTION_POINTER,
    @WSAID_ACCEPTEX, SizeOf(WSAID_ACCEPTEX), @@AcceptEx, SizeOf(@AcceptEx), @dwBytes, nil,
    nil)) then
  begin
    raise Exception.Create(Format('WSAIoctl WSAID_ACCEPTEX Fails:%d',
      [WSAGetLastError()]));
  end;

  if (SOCKET_ERROR = WSAIoctl(TmpSock, SIO_GET_EXTENSION_FUNCTION_POINTER,
    @WSAID_GETACCEPTEXSOCKADDRS, SizeOf(WSAID_GETACCEPTEXSOCKADDRS),
    @@GetAcceptExSockaddrs, SizeOf(@GetAcceptExSockaddrs), @dwBytes, nil, nil)) then
  begin
    raise Exception.Create(Format('WSAIoctl WSAID_GETACCEPTEXSOCKADDRS Fails:%d',
      [WSAGetLastError()]));
  end;

  closesocket(TmpSock);
  // 初始化临界区
  InitializeCriticalSection(FSockMgrCS);
  FSockMgrList := TList.Create;

  InitializeCriticalSection(FOverLappedCS);
  FOverLappedList := TList.Create;
  // 初始化IOCP完成端口
  FCompletionPort := CreateIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 0);
  if IOCPThreadCount <= 0 then
  begin
    IOCPThreadCount := CPUCount + 2;
  end;
  SetLength(FIocpWorkThreads, IOCPThreadCount);
  // 创建IOCP工作线程
  for I := 0 to IOCPThreadCount - 1 do
  begin
    FIocpWorkThreads[I] := CreateThread(nil, 0, @IocpWorkThread, Pointer(FCompletionPort),
      0, ThreadID);
    if FIocpWorkThreads[I] = 0 then
    begin
      raise Exception.Create('CreateThread FIocpWorkThreads Fails');
    end;
  end;
end;

function TIOCPManager.CreateSockMgr(IOCPBase: TIOCPBaseList): TSocketMgr;
var
  _SockMgr: TSocketMgr;
begin
  _SockMgr := TSocketMgr.Create(Self);
  _SockMgr.FIOCPList := IOCPBase;
  // 引用加1
  _SockMgr.FIOCPList.FRefCount := 1;
  LockSockMgr;
  FSockMgrList.Add(Pointer(_SockMgr));
  UnlockSockMgr;
  Result := _SockMgr;
end;

procedure TIOCPManager.DelOverlapped(UsedOverlapped: PIOCPOverlapped);
begin
  Assert(UsedOverlapped <> nil);
  // 正在使用设置为False
  Assert(UsedOverlapped.IsUsed = True);
  (*
    OutputDebugStr(Format('DelOverlapped=%p, type=%d, socket=%d',
    [UsedOverlapped, Integer(UsedOverlapped.OverlappedType),
    UsedOverlapped.AssignedSockObj.FSock]));
  *)
  case UsedOverlapped.OverlappedType of
    otSend:
      begin
        Assert(UsedOverlapped.SendData <> nil);
        if UsedOverlapped.SendData <> nil then
        begin
          FreeMem(UsedOverlapped.SendData);
          UsedOverlapped.SendData := nil;
        end;
      end;
    otListen:
      begin
        if UsedOverlapped.AcceptSocket <> INVALID_SOCKET then
        begin
          closesocket(UsedOverlapped.AcceptSocket);
        end;
      end;
  end;

  LockOverLappedList;
  // 正在使用设置为False
  UsedOverlapped.IsUsed := False;
  FOverLappedList.Add(UsedOverlapped);
  UnlockOverLappedList;
end;

procedure TIOCPManager.FreeOverLappedList;
var
  POverL: PIOCPOverlapped;
begin
  LockOverLappedList;
  for POverL in FOverLappedList do
  begin
    Assert(POverL.IsUsed = False, 'POverL.IsUsed must be False');
    FreeMem(POverL);
  end;
  FOverLappedList.Clear;
  FOverLappedList.Free;
  FOverLappedList := nil;
  UnlockOverLappedList;
end;

destructor TIOCPManager.Destroy;
var
  Resu: Boolean;
{$IFDEF DEBUG}
  SockMgrPtr: Pointer;
  _SockMgr: TSocketMgr absolute SockMgrPtr;
{$ENDIF}
begin

  // 关闭所有的Socket
  // 锁定
{$IFDEF DEBUG}
  LockSockMgr;
  for SockMgrPtr in FSockMgrList do
  begin
    Assert((_SockMgr.FIOCPList = nil) or (_SockMgr.FIOCPList.FIsFreeing),
      'TIOCPManager类释放之前必须先把所有TIOCPOBJBase及其子类释放掉。');
  end;
  UnlockSockMgr;
{$ENDIF}
  Resu := PostExitStatus();

  Assert(Resu = True);
  OutputDebugStr('等待完成端口工作线程退出。');
  // 等待工作线程退出
  WaitForMultipleObjects(Length(FIocpWorkThreads), @FIocpWorkThreads[0], True, INFINITE);
  OutputDebugStr('等待完成端口句柄。');
  // 关闭IOCP句柄
  CloseHandle(FCompletionPort);
  // 等待SockLst释放，这个比较特殊
  // WaitSockLstFree;
  // 释放
  FreeOverLappedList;
  DeleteCriticalSection(FOverLappedCS);

  Assert(FSockMgrList.Count = 0,
    'FSockMgrList.Count <> 0, you must free ALL TIOCPOBJBase class before free this class.');
  FSockMgrList.Free;
  FSockMgrList := nil;
  DeleteCriticalSection(FSockMgrCS);
  // 关闭Socket
  WSACleanup;
  inherited;
end;

procedure TIOCPManager.FreeSockMgr(SockMgr: TSocketMgr);
begin
  LockSockMgr;
  FSockMgrList.Remove(SockMgr);
  UnlockSockMgr;
  SockMgr.Free;
end;

function TIOCPManager.GetOverLappedList: TList;
begin
  Result := FOverLappedList;
end;

function TIOCPManager.GetSockMgrList: TList;
begin
  Result := FSockMgrList;
end;

procedure TIOCPManager.LockOverLappedList;
begin
  EnterCriticalSection(FOverLappedCS);
end;

procedure TIOCPManager.LockSockMgr;
begin
  EnterCriticalSection(FSockMgrCS);
end;

function TIOCPManager.NewOverlapped(SockObj: TSocketBase;
  OverlappedType: TOverlappedTypeEnum): PIOCPOverlapped;
var
  _NewOverLapped: PIOCPOverlapped;
begin

  LockOverLappedList;
  if FOverLappedList.Count > 0 then
  begin
    _NewOverLapped := FOverLappedList.Items[0];
    FOverLappedList.Delete(0);
  end
  else
  begin
    // 申请内存
    GetMem(_NewOverLapped, SizeOf(TIOCPOverlapped));
  end;
  _NewOverLapped.IsUsed := True;
  // 解除锁定
  UnlockOverLappedList;

  // 已经使用
  _NewOverLapped.AssignedSockObj := SockObj;
  _NewOverLapped.OverlappedType := OverlappedType;
  // 清零
  case OverlappedType of
    otSend:
      begin

        _NewOverLapped.SendData := nil;
        _NewOverLapped.CurSendData := nil;
        _NewOverLapped.SendDataLen := 0;
      end;
    otRecv:
      begin
        _NewOverLapped.RecvData := nil;
        _NewOverLapped.RecvDataLen := 0;
      end;
    otListen:
      begin
        _NewOverLapped.AcceptSocket := INVALID_SOCKET;
      end;
  end;
  (*
    OutputDebugStr(Format('NewOverlapped=%p, type=%d, socket=%d',
    [_NewOverLapped, Integer(_NewOverLapped.OverlappedType),
    _NewOverLapped.AssignedSockObj.FSock]));
  *)
  Result := _NewOverLapped;
end;

function TIOCPManager.PostExitStatus: Boolean;
begin
  OutputDebugStr('发送线程退出命令。');
  Result := PostQueuedCompletionStatus(FCompletionPort, 0, 0, nil);
end;

procedure TIOCPManager.UnlockOverLappedList;
begin
  LeaveCriticalSection(FOverLappedCS);
end;

procedure TIOCPManager.UnlockSockMgr;
begin
  LeaveCriticalSection(FSockMgrCS);
end;

{ _IOCPOverlapped }

function _IOCPOverlapped.GetCurSendDataLen: LongWord;
begin
  Assert(OverlappedType = otSend);
  Result := DWORD_PTR(CurSendData) - DWORD_PTR(SendData);
end;

function _IOCPOverlapped.GetRecvData: Pointer;
begin
  Assert(OverlappedType = otRecv);
  Result := RecvData;
end;

function _IOCPOverlapped.GetRecvDataLen: LongWord;
begin
  Assert(OverlappedType = otRecv);
  Result := RecvDataLen;
end;

function _IOCPOverlapped.GetSendData: Pointer;
begin
  Assert(OverlappedType = otSend);
  Result := SendData;
end;

function _IOCPOverlapped.GetTotalSendDataLen: LongWord;
begin
  Assert(OverlappedType = otSend);
  Result := SendDataLen;
end;

{ TSocketBase }

procedure TSocketBase.Close;
begin
  shutdown(FSock, SD_BOTH);
  if closesocket(FSock) <> ERROR_SUCCESS then
  begin
    OutputDebugStr(Format('closesocket failed:%d', [WSAGetLastError]));
  end;
end;

{ TIOCPOBJBase2 }

procedure TIOCPBase2List.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
begin
  if Assigned(FIOCPEvent) then
  begin
    FIOCPEvent(EventType, SockObj, Overlapped);
  end;

end;

procedure TIOCPBase2List.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin
  if Assigned(FListenEvent) then
  begin
    FListenEvent(EventType, SockLst);
  end;

end;

constructor TSocketBase.Create;
begin
  inherited;
  FSock := INVALID_SOCKET;
  FRefCount := 1;
end;

end.
