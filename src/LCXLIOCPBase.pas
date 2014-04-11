unit LCXLIOCPBase;
(* **************************************************************************** *)
(* 作者: LCXL *)
(* E-mail: lcx87654321@163.com *)
(* 说明: IOCP基本单元，定义了IOCP管理类，IOCP列表类和IOCP Socket类。 *)
(* **************************************************************************** *)
interface

uses
  Windows, SysUtils, Classes, Types, LCXLWinSock2, LCXLMSWSock, LCXLMSTcpIP, LCXLWS2Def,
  LCXLWs2tcpip;

procedure OutputDebugStr(const DebugInfo: string; AddLinkBreak: Boolean=True); inline;

type
  // Iocp套接字事件类型
  ///	<summary>
  ///	  Iocp套接字事件类型
  ///	</summary>
  TIocpEventEnum = (
    ieAddSocket,

    ///	<summary>
    ///	  socket从IOCP管理器移除事件
    ///	</summary>
    ieDelSocket,

    ///	<summary>
    ///	  socket被系统关闭事件，当触发这事件时，用户必须释放此socket的引用，以便iocp管理器清除此socket，当用户引用释放之后，会触发ieD
    ///	  elSocket事件
    ///	</summary>
    ieCloseSocket,

    ieError,

    ///	<summary>
    ///	  ieRecvPart 在本单元中没有实现，扩展用
    ///	</summary>
    ieRecvPart,

    ///	<summary>
    ///	  当接受到数据时会触发此事件类型
    ///	</summary>
    ieRecvAll,

    ///	<summary>
    ///	  接受失败
    ///	</summary>
    ieRecvFailed,

    ///	<summary>
    ///	  只发送了一部分数据
    ///	</summary>
    ieSendPart,

    ///	<summary>
    ///	  已经发送了全部数据
    ///	</summary>
    ieSendAll,

    ///	<summary>
    ///	  <font style="BACKGROUND-COLOR: #ffffe0">发送失败</font>
    ///	</summary>
    ieSendFailed
  );
  TListenEventEnum = (leAddSockLst, leDelSockLst, leCloseSockLst, leListenFailed);
  // ******************* 前置声明 ************************
  TSocketBase = class;
  // 监听线程类，要实现不同的功能，需要继承并实现其子类
  TSocketLst = class;
  // Overlap结构
  PIOCPOverlapped = ^TIOCPOverlapped;
  // Socket类
  TSocketObj = class;
  // Socket列表类，要实现不同的功能，需要继承并实现其子类
  TCustomIOCPBaseList = class;
  // IOCP管理类
  TIOCPManager = class;
  // *****************************************************

  TOverlappedTypeEnum = (otRecv, otSend, otListen);

  /// <summary>
  /// socket类的状态
  /// </summary>
  TSocketInitStatus = (
    /// <summary>
    /// socket类正在初始化
    /// </summary>
    sisInitializing,

    /// <summary>
    /// socket类初始化完成
    /// </summary>
    sisInitialized,

    /// <summary>
    /// socket类正在析构
    /// </summary>
    sisDestroying);

  /// <summary>
  /// OverLap结构
  /// </summary>
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
  /// <summary>
  /// Socket类型
  /// </summary>
  TSocketType = (STObj, STLst);
  TSocketBase = class(TObject)
  protected
    FSocketType: TSocketType;
    // 被引用了多少次，当RefCount为0时，则free此Socket对象
    // RefCount=1是只有接受
    // RefCount-1为当前正在发送的次数
    FRefCount: Integer;
    // 用户引用计数
    FUserRefCount: Integer;
    // 是否初始化过
    FIniteStatus: TSocketInitStatus;
    // 套接字
    FSock: TSocket;
    // 与Socket关联的IOCPOBJBase结构
    // 此处IOCPOBJRec结构所指向的内存一定是在TsocketObj全部关闭时才会无效
    FOwner: TCustomIOCPBaseList;
    // 端口句柄
    FIOComp: THandle;
    //
    // Overlapped
    FAssignedOverlapped: PIOCPOverlapped;
    FTag: UIntPtr;
    function Init(): Boolean; virtual; abstract;
    /// <summary>
    /// 增加引用计数
    /// </summary>
    /// <returns>
    /// 返回当前的引用计数
    /// </returns>
    function InternalIncRefCount(Count: Integer = 1; UserMode: Boolean = False): Integer;

    /// <summary>
    /// 减少引用计数，当引用计数为0时，此sockbase自释放
    /// </summary>
    /// <returns>
    /// 返回当前的引用计数
    /// </returns>
    function InternalDecRefCount(Count: Integer = 1; UserMode: Boolean = False): Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Close(); virtual;

    /// <summary>
    /// socket管理器
    /// </summary>
    property Owner: TCustomIOCPBaseList read FOwner;

    /// <summary>
    /// socket句柄
    /// </summary>
    property Socket: TSocket read FSock;

    /// <summary>
    /// 是否已经初始化了
    /// </summary>
    property IniteStatus: TSocketInitStatus read FIniteStatus;

    /// <summary>
    /// 标签，内容由用户定义
    /// </summary>
    property Tag: UIntPtr read FTag write FTag;
    /// <summary>
    /// 增加引用计数，同时增加用户引用和系统引用计数
    /// </summary>
    /// <returns>
    /// 返回当前的引用计数
    /// </returns>
    function IncRefCount(Count: Integer = 1): Integer;

    /// <summary>
    /// 减少引用计数，当引用计数为0时，此socket有可能会被系统自动释放，请不要再操作此socket
    /// </summary>
    /// <returns>
    /// 返回当前的引用计数
    /// </returns>
    function DecRefCount(Count: Integer = 1): Integer;
    /// <summary>
    /// 引用计数
    /// </summary>
    property RefCount: Integer read FRefCount;
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
    /// <summary>
    /// 当建立了一个连接，就调用此方法来创建此连接的socket类，默认会将监听类的TAG传递给新的socket类
    /// </summary>
    procedure CreateSockObj(var SockObj: TSocketObj); virtual; // 覆盖
  public
    constructor Create; override;
    // 销毁
    destructor Destroy; override;

    /// <summary>
    /// 监听端口号
    /// </summary>
    property Port: Integer read FPort;
    /// <summary>
    /// Socket连接池大小
    /// </summary>
    property SocketPoolSize: Integer read FSocketPoolSize write SetSocketPoolSize;
    /// <summary>
    /// 服务端开始监听
    /// </summary>
    function StartListen(IOCPList: TCustomIOCPBaseList; Port: Integer;
      Family: Integer = AF_UNSPEC): Boolean;
  end;

  /// <summary>
  /// Socket类，一个类管一个套接字
  /// </summary>
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

    /// <summary>
    /// 连接指定的网络地址，支持IPv6
    /// </summary>
    /// <param name="IOCPList">
    /// Socket列表
    /// </param>
    /// <param name="SerAddr">
    /// 要连接的地址
    /// </param>
    /// <param name="Port">
    /// 要连接的端口号
    /// </param>
    /// <param name="IncRefNumber">如果成功，则增加多少引用计数，引用计数需要程序员自己释放，不然会一直占用</param>
    /// <returns>
    /// 返回是否连接成功
    /// </returns>
    function ConnectSer(IOCPList: TCustomIOCPBaseList; const SerAddr: string; Port: Integer;
      IncRefNumber: Integer): Boolean;
    /// <summary>
    /// 获取远程IP
    /// </summary>
    function GetRemoteIP(): string; {$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// 获取远程端口
    /// </summary>
    function GetRemotePort(): Word; {$IFNDEF DEBUG} inline; {$ENDIF}

    function GetRemoteAddr(var Address: string; var Port: Word): Boolean;{$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// 获取远程IP
    /// </summary>
    function GetLocalIP(): string; {$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// 获取远程端口
    /// </summary>
    function GetLocalPort(): Word; {$IFNDEF DEBUG} inline; {$ENDIF}

    function GetLocalAddr(var Address: string; var Port: Word): Boolean;{$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// 获取接受的数据
    /// </summary>
    function GetRecvBuf(): Pointer; {$IFNDEF DEBUG} inline; {$ENDIF}
    /// <summary>
    /// 设置缓冲区长度
    /// </summary>
    procedure SetRecvBufLenBeforeInit(NewRecvBufLen: DWORD); inline;
    /// <summary>
    /// 发送数据，在 SendData之前请锁定
    /// </summary>
    function SendData(Data: Pointer; DataLen: LongWord;
      UseGetSendDataFunc: Boolean = False): Boolean;

    /// <summary>
    /// 获取发送数据的指针
    /// </summary>
    function GetSendData(DataLen: LongWord): Pointer; {$IFNDEF DEBUG} inline; {$ENDIF}

    /// <summary>
    /// 只有没有调用SendData的时候才可以释放，调用SendData之后将会自动释放。
    /// </summary>
    procedure FreeSendData(Data: Pointer);{$IFNDEF DEBUG} inline; {$ENDIF}
    //

    /// <summary>
    /// 设置心跳包
    /// </summary>
    function SetKeepAlive(IsOn: Boolean; KeepAliveTime: Integer = 50000;
      KeepAliveInterval: Integer = 30000): Boolean;

    /// <summary>
    /// 是否是服务端接受到的socket
    /// </summary>
    property IsSerSocket: Boolean read FIsSerSocket;
  end;

  /// <summary>
  /// 存储Socket列表的类，前身为的TSocketMgr类
  /// </summary>
  TCustomIOCPBaseList = class(TObject)
  private
    // 是否可以释放此内存，由TSocketMgr触发
    FCanDestroyEvent: THandle;
    /// <summary>
    /// 是否正在释放
    /// </summary>
    FIsFreeing: Boolean;
    /// <summary>
    /// IOCP管理器
    /// </summary>
    FOwner: TIOCPManager;
    /// <summary>
    /// 列表锁定引用次数
    /// </summary>
    FLockRefNum: Integer;
    /// <summary>
    /// Iocp Socket保障线程安全的临界区
    /// </summary>
    FSockBaseCS: TRTLCriticalSection;
    /// <summary>
    /// 存储TSockBase的指针
    /// </summary>
    FSockBaseList: TList;
    /// <summary>
    /// 添加队列列表，当socket队列被锁定时，会添加到此列表中，等解锁之后再添加到socket列表中
    /// </summary>
    FSockBaseAddList: TList;
    /// <summary>
    /// 删除队列列表
    /// </summary>
    FSockBaseDelList: TList;
    /// <summary>
    /// 存储TSocketObj的指针，原始指针在FSockBaseList中
    /// </summary>
    FSockObjList: TList;
    /// <summary>
    /// 存储TIocpSockAcp的指针，原始指针在FSockBaseList中
    /// </summary>
    FSockLstList: TList;
    function GetSockBaseList: TList;
    function GetSockLstList: TList;
    function GetSockObjList: TList;
  protected
    /// <summary>
    /// 这个只是单纯的临界区锁，要更加有效的锁定列表，使用 LockSockList
    /// </summary>
    procedure Lock; {$IFNDEF DEBUG}inline; {$ENDIF}
    /// <summary>
    /// 这个只是单纯的临界区锁
    /// </summary>
    procedure Unlock; {$IFNDEF DEBUG}inline; {$ENDIF}
    /// <summary>
    /// 添加sockobj到列表中，返回True表示成功，返回False表示失败，注意这里要处理IsFreeing为True的情况
    /// </summary>
    function AddSockBase(SockBase: TSocketBase): Boolean;
    /// <summary>
    /// 移除sockbase，如果 列表被锁定，则将socket类放入待删除队列中
    /// </summary>
    function RemoveSockBase(SockBase: TSocketBase): Boolean;
    /// <summary>
    /// 初始化SockBase
    /// </summary>
    function InitSockBase(SockBase: TSocketBase): Boolean;
    /// <summary>
    /// 释放sockbase，并触发事件，此时sockbase必须已经从列表中移除
    /// </summary>
    function FreeSockBase(SockBase: TSocketBase): Boolean;
    /// <summary>
    /// 在IOCP管理器中注册SockBase
    /// </summary>
    function IOCPRegSockBase(SockBase: TSocketBase): Boolean; {$IFNDEF DEBUG}inline;
{$ENDIF}
    procedure WaitForDestroyEvent();
    /// <summary>
    /// 检查是否可以释放
    /// </summary>
    procedure CheckCanDestroy();
    /// <summary>
    /// IOCP事件
    /// </summary>
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); virtual;
    /// <summary>
    /// 监听事件
    /// </summary>
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); virtual;

  public
    constructor Create(AIOCPMgr: TIOCPManager); reintroduce; virtual;
    destructor Destroy(); override;

    /// <summary>
    /// 锁定列表，注意的锁定后不能对列表进行增加，删除操作，一切都由SocketMgr类维护
    /// </summary>
    procedure LockSockList;
    /// <summary>
    /// 解锁列表
    /// </summary>
    procedure UnlockSockList;
    /// <summary>
    /// 处理消息函数，在有窗口的程序下使用
    /// </summary>
    procedure ProcessMsgEvent();

    /// <summary>
    /// 关闭所有的Socket
    /// </summary>
    procedure CloseAllSockObj;
    /// <summary>
    /// 关闭所有的Socklst
    /// </summary>
    procedure CloseAllSockLst;
    /// <summary>
    /// 关闭所有的Socket，包括监听socket和非监听socket
    /// </summary>
    procedure CloseAllSockBase;

    /// <summary>
    /// 此类的拥有者
    /// </summary>
    property Owner: TIOCPManager read FOwner;
    property SockObjList: TList read GetSockObjList;
    property SockLstList: TList read GetSockLstList;
    property SockBaseList: TList read GetSockBaseList;


  end;

  // IOCP网络模型管理类，一个程序中只有一个实例
  TIOCPManager = class(TObject)
  private
    FwsaData: TWSAData;
    // IOCPBaseRec结构列表
    FSockList: TList;
    // IOCPBase对象临界区
    FSockListCS: TRTLCriticalSection;
    // OverLapped线程安全列表
    FOverLappedList: TList;
    FOverLappedListCS: TRTLCriticalSection;
    // 完成端口句柄
    FCompletionPort: THandle;
    // IOCP线程句柄动态数组
    FIocpWorkThreads: array of THandle;
    function GetSockList: TList;
    function GetOverLappedList: TList;
  protected
    procedure AddSockList(SockList: TCustomIOCPBaseList);
    procedure RemoveSockList(SockList: TCustomIOCPBaseList);
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
    /// <summary>
    /// 获取本机IP地址列表
    /// </summary>
    /// <param name="Addrs">
    /// 获取后的ip地址存入此列表中
    /// </param>
    class procedure GetLocalAddrs(Addrs: TStrings);

    procedure LockSockList; inline;
    property SockList: TList read GetSockList;
    procedure UnlockSockList; inline;

    procedure LockOverLappedList; inline;
    property OverLappedList: TList read GetOverLappedList;
    procedure UnlockOverLappedList; inline;
  end;

type
  // ********************* 事件 **************************
  // IOCP事件
  TOnIOCPBaseEvent = procedure(EventType: TIocpEventEnum; SockObj: TSocketObj;
    Overlapped: PIOCPOverlapped) of object;
  // 监听事件
  TOnListenBaseEvent = procedure(EventType: TListenEventEnum; SockLst: TSocketLst) of object;

  TIOCPBaseList = class(TCustomIOCPBaseList)
  private
    FIOCPEvent: TOnIOCPBaseEvent;
    FListenEvent: TOnListenBaseEvent;
  protected
    // IOCP事件
    procedure OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
      Overlapped: PIOCPOverlapped); override;
    // 监听事件
    procedure OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst); override;
  public
    // 外部接口
    property IOCPEvent: TOnIOCPBaseEvent read FIOCPEvent write FIOCPEvent;
    property ListenEvent: TOnListenBaseEvent read FListenEvent write FListenEvent;
  end;

implementation
var
  AcceptEx: LPFN_ACCEPTEX;
  GetAcceptExSockaddrs: LPFN_GETACCEPTEXSOCKADDRS;

procedure OutputDebugStr(const DebugInfo: string; AddLinkBreak: Boolean);
begin
{$IFDEF DEBUG}
  if AddLinkBreak then
  begin
    Windows.OutputDebugString(PChar(Format('%s'#10, [DebugInfo])));
  end
  else
  begin
    Windows.OutputDebugString(PChar(DebugInfo));
  end;
{$ENDIF}
end;

// IOCP工作线程
function IocpWorkThread(CompletionPortID: Pointer): Integer;
var
  CompletionPort: THandle absolute CompletionPortID;
  BytesTransferred: DWORD;
  resuInt: Integer;

  SockBase: TSocketBase;
  SockObj: TSocketObj absolute SockBase;
  SockLst: TSocketLst absolute SockBase;
  _NewSockObj: TSocketObj;

  FIocpOverlapped: PIOCPOverlapped;
  FIsSuc: Boolean;

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
              SockObj.InternalDecRefCount;
              // 继续
              Continue;
            end;
            // socket事件
            case FIocpOverlapped.OverlappedType of

              otRecv:
                begin
                  Assert(FIocpOverlapped = SockObj.FAssignedOverlapped);
                  // 移动当前接受的指针
                  FIocpOverlapped.RecvDataLen := BytesTransferred;
                  FIocpOverlapped.RecvData := SockObj.FRecvBuf;
                  // 获取事件指针
                  // 发送结果

                  // 产生事件
                  try

                    SockObj.Owner.OnIOCPEvent(ieRecvAll, SockObj, FIocpOverlapped);

                  except
                    on E: Exception do
                    begin
                      OutputDebugStr(Format('Message=%s, StackTrace=%s',
                        [E.Message, E.StackTrace]));
                    end;
                  end;

                  // 投递下一个WSARecv
                  if not SockObj.WSARecv() then
                  begin
                    // 如果出错
                    OutputDebugStr(Format('WSARecv函数出错socket=%d:%d',
                      [SockObj.FSock, WSAGetLastError]));

                    // 减少引用
                    SockObj.InternalDecRefCount;
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

                    try
                      SockObj.Owner.OnIOCPEvent(ieSendAll, SockObj, FIocpOverlapped);
                    except
                      on E: Exception do
                      begin
                        OutputDebugStr(Format('Message=%s, StackTrace=%s',
                          [E.Message, E.StackTrace]));
                      end;
                    end;
                    SockObj.Owner.Owner.DelOverlapped(FIocpOverlapped);

                    // 获取待发送的数据

                    FIocpOverlapped := nil;

                    SockObj.Owner.Lock;
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
                    SockObj.Owner.Unlock;

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

                        try
                          SockObj.Owner.OnIOCPEvent(ieSendFailed, SockObj,
                            FIocpOverlapped);
                        except
                          on E: Exception do
                          begin
                            OutputDebugStr(Format('Message=%s, StackTrace=%s',
                              [E.Message, E.StackTrace]));
                          end;
                        end;

                        SockObj.Owner.Owner.DelOverlapped(FIocpOverlapped);
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
                      SockObj.InternalDecRefCount;
                    end;
                  end
                  else
                  begin
                    // 没有全部发送完成
                    FIocpOverlapped.DataBuf.len := FIocpOverlapped.SendDataLen +
                      UIntPtr(FIocpOverlapped.SendData) -
                      UIntPtr(FIocpOverlapped.CurSendData);
                    FIocpOverlapped.DataBuf.buf := FIocpOverlapped.CurSendData;

                    try
                      SockObj.Owner.OnIOCPEvent(ieSendPart, SockObj, FIocpOverlapped);
                    except
                      on E: Exception do
                      begin
                        OutputDebugStr(Format('Message=%s, StackTrace=%s',
                          [E.Message, E.StackTrace]));
                      end;
                    end;
                    // 继续投递WSASend
                    if not SockObj.WSASend(FIocpOverlapped) then
                    begin // 如果出错
                      OutputDebugStr(Format('WSASend函数出错socket=%d:%d',
                        [SockObj.FSock, WSAGetLastError]));

                      try
                        SockObj.Owner.OnIOCPEvent(ieSendFailed, SockObj, FIocpOverlapped);
                      except
                        on E: Exception do
                        begin
                          OutputDebugStr(Format('Message=%s, StackTrace=%s',
                            [E.Message, E.StackTrace]));
                        end;
                      end;

                      SockObj.Owner.Owner.DelOverlapped(FIocpOverlapped);
                      // 减少引用
                      SockObj.InternalDecRefCount;
                    end;
                  end;
                end;
            end;
          end;
        otListen:
          begin
            Assert(FIocpOverlapped = SockLst.FAssignedOverlapped,
              'FIocpOverlapped != SockLst.FLstOverLap');
            (*
            GetAcceptExSockaddrs(SockLst.FLstBuf, 0, SizeOf(SOCKADDR_IN) + 16,
              SizeOf(SOCKADDR_IN) + 16, local, localLen, remote, remoteLen);
            *)
            // 更新上下文
            resuInt := setsockopt(FIocpOverlapped.AcceptSocket, SOL_SOCKET,
              SO_UPDATE_ACCEPT_CONTEXT, @SockLst.FSock, SizeOf(SockLst.FSock));
            if resuInt <> 0 then
            begin
              OutputDebugStr(Format('socket(%d)设置setsockopt失败:%d',
                [FIocpOverlapped.AcceptSocket, WSAGetLastError()]));
            end;

            // 监听
            // 产生事件，添加SockObj，如果失败，则close之
            _NewSockObj := nil;
            // 创建新的SocketObj类
            SockLst.CreateSockObj(_NewSockObj);
            // 填充Socket句柄
            _NewSockObj.FSock := FIocpOverlapped.AcceptSocket;
            // 设置为服务socket
            _NewSockObj.FIsSerSocket := True;
            // 添加到Socket列表中
            SockLst.Owner.AddSockBase(_NewSockObj);
            
            // 投递下一个Accept端口
            if not SockLst.Accept() then
            begin
              OutputDebugStr('AcceptEx函数失败: ' + IntToStr(WSAGetLastError));
              SockLst.InternalDecRefCount;
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
          SockBase.Owner.Owner.DelOverlapped(FIocpOverlapped);
        end;
        // 减少引用
        SockBase.InternalDecRefCount;
      end
      else
      begin
        OutputDebugStr(Format('GetQueuedCompletionStatus函数失败: %d', [GetLastError]));
      end;
    end;
  end;
  Result := 0;
end;

{ TSocketBase }

procedure TSocketBase.Close;
begin
  shutdown(FSock, SD_BOTH);
  if closesocket(FSock) <> ERROR_SUCCESS then
  begin
    OutputDebugStr(Format('closesocket failed:%d', [WSAGetLastError]));
  end;
  FSock := INVALID_SOCKET;
end;

constructor TSocketBase.Create;
begin
  inherited;
  FSock := INVALID_SOCKET;
  // 引用计数默认为1
  FRefCount := 0;
  // 用户计数默认为0
  FUserRefCount := 0;
end;

function TSocketBase.DecRefCount(Count: Integer): Integer;
begin
  Assert(Count > 0);
  if FUserRefCount = 0 then
  begin
    raise Exception.Create
      ('IncRefCount function must be called before call this function!');
  end;
  Result := InternalDecRefCount(Count, True);
end;

destructor TSocketBase.Destroy;
begin
  if FAssignedOverlapped <> nil then
  begin
    Assert(FOwner <> nil);
    Assert(FOwner.FOwner <> nil);
    FOwner.FOwner.DelOverlapped(FAssignedOverlapped);
  end;
  inherited;
end;

function TSocketBase.IncRefCount(Count: Integer): Integer;
begin
  Assert(Count > 0);
  Result := InternalIncRefCount(Count, True);
end;

function TSocketBase.InternalDecRefCount(Count: Integer; UserMode: Boolean): Integer;
var
  // socket是否关闭
  _IsSocketClosed1: Boolean;
  _IsSocketClosed2: Boolean;
  _CanFree: Boolean;
begin
  FOwner.Lock;
  _IsSocketClosed1 := FRefCount = FUserRefCount;
  Dec(FRefCount, Count);
  if UserMode then
  begin
    Dec(FUserRefCount, Count);
    Result := FUserRefCount;
  end
  else
  begin
    Result := FRefCount;
  end;
  _IsSocketClosed2 := FRefCount = FUserRefCount;
  _CanFree := FRefCount = 0;
  FOwner.Unlock;
  // socket已经关闭
  if not _IsSocketClosed1 and _IsSocketClosed2 then
  begin
    // 触发close事件
    if Self.FSocketType = STObj then
    begin
      Self.FOwner.OnIOCPEvent(ieCloseSocket, Self as TSocketObj, nil);
    end
    else
    begin
      Self.FOwner.OnListenEvent(leCloseSockLst, Self as TSocketLst);
    end;
  end;

  if _CanFree then
  begin
    // 移除自身，并且释放
    FOwner.RemoveSockBase(Self);
    // 自释放
    // Free;
  end;
end;

function TSocketBase.InternalIncRefCount(Count: Integer; UserMode: Boolean): Integer;
begin
  FOwner.Lock;
  Inc(FRefCount, Count);
  if UserMode then
  begin
    Inc(FUserRefCount, Count);
    Result := FUserRefCount;
  end
  else
  begin
    Result := FRefCount;
  end;
  FOwner.Unlock;
  Assert(Result > 0);
end;

{ TSocketObj }

function TSocketObj.ConnectSer(IOCPList: TCustomIOCPBaseList; const SerAddr: string;
  Port: Integer; IncRefNumber: Integer): Boolean;
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
  LastError := 0;
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

        FSock := INVALID_SOCKET;
      end
      else
      begin
        FOwner := IOCPList;
        // 增加引用
        IncRefCount(IncRefNumber);
        Result := IOCPList.AddSockBase(Self);
        if not Result then
        begin
          LastError := WSAGetLastError();
{$IFDEF DEBUG}
          OutputDebugStr(Format('添加%s到列表中失败：%d', [_AddrString, LastError]));
{$ENDIF}
          closesocket(FSock);
          FSock := INVALID_SOCKET;
          // 减少引用
          DecRefCount(IncRefNumber);
        end;
        // *)
        Break;
      end;
    end;
    _NextAddInfo := _NextAddInfo.ai_next;

  end;
  freeaddrinfo(_ResultAddInfo);
  WSASetLastError(LastError);
end;

constructor TSocketObj.Create;
begin
  inherited;
  FSocketType := STObj;
  // 设置初始缓冲区为4096
  FRecvBufLen := 4096;
end;

destructor TSocketObj.Destroy;
var
  _TmpData: Pointer;
  _IOCPOverlapped: PIOCPOverlapped absolute _TmpData;
begin
  // if  then

  if FSendDataQueue <> nil then
  begin
    for _TmpData in FSendDataQueue do
    begin
      FOwner.Owner.DelOverlapped(_IOCPOverlapped);
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

function TSocketObj.GetLocalAddr(var Address: string; var Port: Word): Boolean;
var
  name: TSOCKADDR_STORAGE;
  namelen: Integer;
  addrbuf: array[0..NI_MAXHOST-1] of AnsiChar;
  portbuf: array[0..NI_MAXSERV-1] of AnsiChar;
begin
  Address := '';
  Port := 0;
  Result := False;

  namelen := SizeOf(name);
  if getsockname(FSock, PSockAddr(@name), namelen) = 0 then
  begin
    if (getnameinfo(PSockAddr(@name), namelen, addrbuf, NI_MAXHOST, portbuf, NI_MAXSERV, NI_NUMERICHOST or NI_NUMERICSERV)=0) then
    begin
      Address := string(addrbuf);
      Port := StrToIntDef(string(portbuf), 0);
    end;
  end;
end;

function TSocketObj.GetLocalIP: string;
var
  tmp: Word;
begin
  GetLocalAddr(Result, tmp);
end;

function TSocketObj.GetLocalPort: Word;
var
  tmp: string;
begin
  GetLocalAddr(tmp, Result);
end;

function TSocketObj.GetRecvBuf: Pointer;
begin
  Result := FRecvBuf;
end;

function TSocketObj.GetRemoteAddr(var Address: string; var Port: Word): Boolean;
var
  name: TSOCKADDR_STORAGE;
  namelen: Integer;
  addrbuf: array[0..NI_MAXHOST-1] of AnsiChar;
  portbuf: array[0..NI_MAXSERV-1] of AnsiChar;
begin
  Address := '';
  Port := 0;
  Result := False;

  namelen := SizeOf(name);
  if getpeername(FSock, PSockAddr(@name), namelen) = 0 then
  begin
    if (getnameinfo(PSockAddr(@name), namelen, addrbuf, NI_MAXHOST, portbuf, NI_MAXSERV, NI_NUMERICHOST or NI_NUMERICSERV)=0) then
    begin
      Address := string(addrbuf);
      Port := StrToIntDef(string(portbuf), 0);
    end;
  end;
end;

function TSocketObj.GetRemoteIP: string;
var
  tmp:Word;
begin
  GetRemoteAddr(result, tmp);
end;

function TSocketObj.GetRemotePort: Word;
var
  tmp: string;
begin
  GetRemoteAddr(tmp, result);
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
  _PauseSend: Boolean;
begin
  if DataLen = 0 then
  begin
    Result := True;
    Exit;
  end;
  // 先增加引用
  InternalIncRefCount;
  _NewData := nil;
  Assert(Data <> nil);
  Result := False;

  FIocpOverlapped := FOwner.Owner.NewOverlapped(Self, otSend);
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
    FOwner.Lock;
    _PauseSend := FIsSending or (FIniteStatus = sisInitializing);
    // 如果里面有正在发送的
    if _PauseSend then
    begin
      FSendDataQueue.Add(FIocpOverlapped);
      OutputDebugStr(Format('Socket(%d)中的发送数据加入到待发送对列', [Self.FSock]));
    end
    else
    begin
      FIsSending := True;
    end;
    FOwner.Unlock;

    if not _PauseSend then
    begin
      // OutputDebugStr(Format('SendData:Overlapped=%p,Overlapped=%d',[FIocpOverlapped, Integer(FIocpOverlapped.OverlappedType)]));

      if not Self.WSASend(FIocpOverlapped) then // 投递WSASend
      begin
        // 如果有错误
        OutputDebugStr(Format('SendData:WSASend函数失败(socket=%d):%d',
          [FSock, WSAGetLastError]));
        // 删除此Overlapped
        FOwner.Owner.DelOverlapped(FIocpOverlapped);

        FOwner.Lock;
        FIsSending := False;
        FOwner.Unlock;
      end
      else
      begin
        Result := True;
      end;
    end
    else
    begin
      // 添加到待发送对列的数据不会增加引用，因此需要取消先前的预引用
      InternalDecRefCount;
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
    InternalDecRefCount;
  end;
end;

function TSocketObj.SetKeepAlive(IsOn: Boolean;
  KeepAliveTime, KeepAliveInterval: Integer): Boolean;
var
  alive_in: tcp_keepalive;
  alive_out: tcp_keepalive;
  ulBytesReturn: ulong;
begin
  alive_in.KeepAliveTime := KeepAliveTime; // 开始首次KeepAlive探测前的TCP空闭时间
  alive_in.KeepAliveInterval := KeepAliveInterval; // 两次KeepAlive探测间的时间间隔
  alive_in.onoff := u_long(IsOn);
  Result := WSAIoctl(FSock, SIO_KEEPALIVE_VALS, @alive_in, SizeOf(alive_in), @alive_out,
    SizeOf(alive_out), @ulBytesReturn, nil, nil) = 0;
end;

procedure TSocketObj.SetRecvBufLenBeforeInit(NewRecvBufLen: DWORD);
begin
  if FRecvBufLen <> NewRecvBufLen then
  begin
    FRecvBufLen := NewRecvBufLen;
  end;
end;

function TSocketObj.WSARecv: Boolean;
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
    @FAssignedOverlapped.lpOverlapped, nil) = 0) or (WSAGetLastError = WSA_IO_PENDING);
end;

function TSocketObj.WSASend(Overlapped: PIOCPOverlapped): Boolean;
begin
  // OutputDebugStr(Format('WSASend:Overlapped=%p,Overlapped=%d',[Overlapped, Integer(Overlapped.OverlappedType)]));
  // 清空Overlapped
  ZeroMemory(@Overlapped.lpOverlapped, SizeOf(Overlapped.lpOverlapped));

  Assert(Overlapped.OverlappedType = otSend);
  Assert((Overlapped.DataBuf.buf <> nil) and (Overlapped.DataBuf.len > 0));

  Result := (LCXLWinSock2.WSASend(FSock, @Overlapped.DataBuf, 1, nil, 0,
    @Overlapped.lpOverlapped, nil) = 0) or (WSAGetLastError = WSA_IO_PENDING);
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
    OutputDebugStr('AcceptEx函数失败: ' + IntToStr(WSAGetLastError));
    closesocket(FAssignedOverlapped.AcceptSocket);
    FAssignedOverlapped.AcceptSocket := INVALID_SOCKET;
  end;
end;

constructor TSocketLst.Create;
begin
  inherited;
  FSocketType := STLst;
  FSocketPoolSize := 10;
  FLstBufLen := (SizeOf(sockaddr_storage) + 16) * 2;
end;

procedure TSocketLst.CreateSockObj(var SockObj: TSocketObj);
begin
  Assert(SockObj = nil);
  SockObj := TSocketObj.Create;
  SockObj.Tag := Self.Tag;
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
  if FIniteStatus = sisInitializing then
  begin
    if Value > 0 then
    begin
      FSocketPoolSize := Value;
    end;
  end
  else
  begin
    raise Exception.Create('SocketPoolSize can''t be setted after StartListen');
  end;
end;

function TSocketLst.StartListen(IOCPList: TCustomIOCPBaseList; Port: Integer;
  Family: Integer): Boolean;
var
  ErrorCode: Integer;
  _Hints: TAddrInfoA;
  _ResultAddInfo: PADDRINFOA;
  _Retval: Integer;
begin
  Result := False;
  FPort := Port;


  _Hints.ai_family := AF_UNSPEC;
  _Hints.ai_socktype := SOCK_STREAM;
  _Hints.ai_protocol := IPPROTO_TCP;
  _Hints.ai_flags := AI_PASSIVE or AI_ADDRCONFIG;
  _Retval := getaddrinfo(nil,
    PAnsiChar(AnsiString(IntToStr(Port))), @_Hints, _ResultAddInfo);
  if _Retval <> 0 then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('getaddrinfo 函数失败：' + IntToStr(ErrorCode));
    Exit;
  end;
  FSock := WSASocket(_ResultAddInfo.ai_family, _ResultAddInfo.ai_socktype, _ResultAddInfo.ai_protocol, nil, 0, WSA_FLAG_OVERLAPPED);
  if (FSock = INVALID_SOCKET) then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('WSASocket 函数失败：' + IntToStr(ErrorCode));
    freeaddrinfo(_ResultAddInfo);

    Exit;
  end;

  // 绑定端口号
  if (bind(FSock, _ResultAddInfo.ai_addr, _ResultAddInfo.ai_addrlen) = SOCKET_ERROR) then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('bind 函数失败：' + IntToStr(ErrorCode));
    closesocket(FSock);
    freeaddrinfo(_ResultAddInfo);

    WSASetLastError(ErrorCode);
    FSock := INVALID_SOCKET;
    Exit;
  end;
  freeaddrinfo(_ResultAddInfo);
  // 开始监听
  if listen(FSock, SOMAXCONN) = SOCKET_ERROR then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('listen 函数失败：' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
    FSock := INVALID_SOCKET;
    Exit;
  end;
  FOwner := IOCPList;
  // 添加到SockLst
  Result := IOCPList.AddSockBase(Self);
  if not Result then
  begin
    ErrorCode := WSAGetLastError;
    OutputDebugStr('AddSockLst 函数失败：' + IntToStr(ErrorCode));
    closesocket(FSock);
    WSASetLastError(ErrorCode);
    FSock := INVALID_SOCKET;

  end;
end;

{ TIOCPBaseList }

function TCustomIOCPBaseList.AddSockBase(SockBase: TSocketBase): Boolean;
var
  _IsLocked: Boolean;
begin
  Assert(SockBase.Socket <> INVALID_SOCKET);
  Assert(SockBase.RefCount >= 0);
  SockBase.FOwner := Self;
  // 增加引用计数+1，此引用计数代表Recv的引用
  SockBase.InternalIncRefCount;

  // 开始初始化Socket
  if not SockBase.Init() then
  begin

    Result := False;
    // ieCloseSocket，在没有加入到IOCP之前，都得触发
    SockBase.Close;
    SockBase.InternalDecRefCount;

    Exit;
  end;

  Lock;
  // List是否被锁住
  _IsLocked := FLockRefNum > 0;
  if _IsLocked then
  begin
    // 被锁住，不能对Socket列表进行添加或删除操作，先加到Socket待添加List中。

    FSockBaseAddList.Add(SockBase);
    OutputDebugStr(Format('列表被锁定，Socket(%d)进入待添加队列', [SockBase.FSock]));
  end
  else
  begin
    // 没有被锁住，直接添加到Socket列表中
    FSockBaseList.Add(SockBase);
    // 添加到影子List
    if SockBase.FSocketType = STObj then
    begin
      FSockObjList.Add(SockBase);
    end
    else
    begin
      FSockLstList.Add(SockBase);
    end;
  end;
  Unlock;
  if not _IsLocked then
  begin
    // 如果没有被锁住，则初始化Socket
    // InitSockBase(SockBase);
    // (*
    Result := InitSockBase(SockBase);
    if Result then
    begin
    end
    else
    begin
      // 初始化出错，
      Assert(SockBase.FRefCount > 0);

    end;
    // *)
  end
  else
  begin
    // 如果被锁住，那返回值永远是True
    Result := True;
  end;

  // Result := True;
end;

procedure TCustomIOCPBaseList.CheckCanDestroy;
var
  _CanDestroy: Boolean;
begin
  Lock;
  _CanDestroy := (FSockBaseList.Count = 0) and (FSockBaseAddList.Count = 0) and
    (FSockBaseDelList.Count = 0);
  Unlock;
  if _CanDestroy then
  begin
    //
    SetEvent(FCanDestroyEvent);
  end;
end;

procedure TCustomIOCPBaseList.CloseAllSockBase;
var
  _SockBasePtr: Pointer;
  _SockBase: TSocketBase absolute _SockBasePtr;
begin
  LockSockList;
  for _SockBasePtr in FSockBaseList do
  begin
    // 关闭连接
    _SockBase.Close;
  end;
  UnlockSockList;
end;

procedure TCustomIOCPBaseList.CloseAllSockLst;
var
  _SockLstPtr: Pointer;
  _SockLst: TSocketBase absolute _SockLstPtr;
begin
  LockSockList;
  for _SockLstPtr in FSockLstList do
  begin
    // 关闭连接
    _SockLst.Close;
  end;
  UnlockSockList;
end;

procedure TCustomIOCPBaseList.CloseAllSockObj;
var
  _SockObjPtr: Pointer;
  _SockObj: TSocketBase absolute _SockObjPtr;
begin
  LockSockList;
  for _SockObjPtr in FSockObjList do
  begin
    // 关闭连接
    _SockObj.Close;
  end;
  UnlockSockList;
end;

constructor TCustomIOCPBaseList.Create(AIOCPMgr: TIOCPManager);
begin
  inherited Create();
  FOwner := AIOCPMgr;
  FLockRefNum := 0;
  FIsFreeing := False;

  InitializeCriticalSection(FSockBaseCS);
  FSockBaseList := TList.Create;
  FSockBaseAddList := TList.Create;
  FSockBaseDelList := TList.Create;
  FSockObjList := TList.Create;
  FSockLstList := TList.Create;
  // 添加自身
  FOwner.AddSockList(Self);
end;

destructor TCustomIOCPBaseList.Destroy;
begin
  FCanDestroyEvent := CreateEvent(nil, True, False, nil);
  FIsFreeing := True;
  CloseAllSockBase;
  CheckCanDestroy;
  WaitForDestroyEvent();

  FOwner.RemoveSockList(Self);
  CloseHandle(FCanDestroyEvent);
  FSockLstList.Free;
  FSockObjList.Free;
  FSockBaseDelList.Free;
  FSockBaseAddList.Free;
  FSockBaseList.Free;
  inherited;
end;

function TCustomIOCPBaseList.FreeSockBase(SockBase: TSocketBase): Boolean;
var
  _SockObj: TSocketObj absolute SockBase;
  _SockLst: TSocketLst absolute SockBase;

begin
  Assert(SockBase.FRefCount = 0);
  if SockBase.FSocketType = STObj then
  begin
    try
      OnIOCPEvent(ieDelSocket, _SockObj, nil);
    except

    end;
  end
  else
  begin
    try
      OnListenEvent(leDelSockLst, _SockLst);
    except

    end;
  end;
  SockBase.Free;
  if FIsFreeing then
  begin
    CheckCanDestroy;

  end;
  Result := True;
end;

function TCustomIOCPBaseList.GetSockBaseList: TList;
begin
  Result := FSockBaseList;
end;

function TCustomIOCPBaseList.GetSockLstList: TList;
begin
  Result := FSockLstList;
end;

function TCustomIOCPBaseList.GetSockObjList: TList;
begin
  Result := FSockObjList;
end;

function TCustomIOCPBaseList.InitSockBase(SockBase: TSocketBase): Boolean;
var
  _SockObj: TSocketObj absolute SockBase;
  _SockLst: TSocketLst absolute SockBase;
begin
  // Result := False;
  Result := True;
  // 进入到这里，就说明已经添加到socket列表中了，所以要触发
  try
    if SockBase.FSocketType = STObj then
    begin
      OnIOCPEvent(ieAddSocket, _SockObj, nil);
    end
    else
    begin
      OnListenEvent(leAddSockLst, _SockLst);
    end;
  except

  end;

  // 锁定

  Assert(SockBase.FRefCount > 0);
  // 添加到Mgr
  if not IOCPRegSockBase(SockBase) then
  begin
    // 失败？
    // ieCloseSocket，自己手动发动
    SockBase.Close;
    SockBase.InternalDecRefCount;
    Exit;
  end;
  // Result := True;
  // 注册到系统的IOCP中才算初始化完成
  Lock;
  SockBase.FIniteStatus := sisInitialized;
  Unlock;

  if SockBase.FSocketType = STObj then
  begin
    // 获得Recv的Overlapped
    _SockObj.FAssignedOverlapped := FOwner.NewOverlapped(_SockObj, otRecv);
    if not _SockObj.WSARecv() then // 投递WSARecv
    begin // 如果出错
      OutputDebugStr(Format('InitSockObj:WSARecv函数出错socket=%d:%d',
        [_SockObj.FSock, WSAGetLastError]));

      try
        OnIOCPEvent(ieRecvFailed, _SockObj, _SockObj.FAssignedOverlapped);
      except

      end;

      // 减少引用
      SockBase.InternalDecRefCount;
    end;
  end
  else
  begin
    // 获得Listen的Overlapped
    _SockLst.FAssignedOverlapped := FOwner.NewOverlapped(_SockLst, otListen);
    if not _SockLst.Accept() then // 投递AcceptEx
    begin
      // 减少引用
      SockBase.InternalDecRefCount;
    end;
  end;

end;

function TCustomIOCPBaseList.IOCPRegSockBase(SockBase: TSocketBase): Boolean;
begin
  // 在IOCP中注册此Socket
  SockBase.FIOComp := CreateIoCompletionPort(SockBase.FSock, FOwner.FCompletionPort,
    ULONG_PTR(SockBase), 0);
  Result := SockBase.FIOComp <> 0;
  if not Result then
  begin
    OutputDebugStr(Format('Socket(%d)IOCP注册失败！Error:%d',
      [SockBase.FSock, WSAGetLastError()]));
  end;
end;

procedure TCustomIOCPBaseList.Lock;
begin
  EnterCriticalSection(FSockBaseCS);
end;

procedure TCustomIOCPBaseList.LockSockList;
begin
  Lock;
  Assert(FLockRefNum >= 0);
  Inc(FLockRefNum);
  Unlock;
end;

procedure TCustomIOCPBaseList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
begin

end;

procedure TCustomIOCPBaseList.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin

end;

procedure TCustomIOCPBaseList.ProcessMsgEvent;

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

function TCustomIOCPBaseList.RemoveSockBase(SockBase: TSocketBase): Boolean;
var
  _IsLocked: Boolean;
begin
  Assert(SockBase.FRefCount = 0);
  Lock;
  _IsLocked := FLockRefNum > 0;
  if not _IsLocked then
  begin
    FSockBaseList.Remove(SockBase);
    if SockBase.FSocketType = STObj then
    begin
      FSockObjList.Remove(SockBase);
    end
    else
    begin
      FSockLstList.Remove(SockBase);
    end;
  end
  else
  begin
    FSockBaseDelList.Add(SockBase);
  end;
  Unlock;
  if not _IsLocked then
  begin
    FreeSockBase(SockBase);
  end;
  Result := True;
end;

procedure TCustomIOCPBaseList.Unlock;
begin
  LeaveCriticalSection(FSockBaseCS);
end;

procedure TCustomIOCPBaseList.UnlockSockList;

var
  isAdd: Boolean;
  _SockBase: TSocketBase;
  _SockObj: TSocketObj absolute _SockBase;
  _SockLst: TSocketLst absolute _SockBase;
  _IsEnd: Boolean;
begin
  isAdd := False;
  repeat
    _SockBase := nil;
    Lock;
    Assert(FLockRefNum >= 1, 'Socket列表锁定线程数出错。');
    // 判断是不是只有本线程锁定了列表，只要判断FLockRefNum是不是大于1
    _IsEnd := FLockRefNum > 1;
    if not _IsEnd then
    begin
      // 只有本线程锁住了socket，然后查看socket删除列表是否为空
      if FSockBaseDelList.Count > 0 then
      begin
        // 不为空，从第一个开始删
        _SockBase := FSockBaseDelList.Items[0];
        FSockBaseDelList.Delete(0);

        FSockBaseList.Remove(_SockBase);
        if _SockBase.FSocketType = STObj then
        begin
          FSockObjList.Remove(_SockObj);
        end
        else
        begin
          FSockLstList.Remove(_SockLst);
        end;
        isAdd := False;
      end
      else
      begin
        // 查看socket添加列表是否为空
        if FSockBaseAddList.Count > 0 then
        begin
          isAdd := True;
          // 如果不为空，则pop一个sockobj添加到列表中
          _SockBase := FSockBaseAddList.Items[0];
          FSockBaseAddList.Delete(0);
          FSockBaseList.Add(_SockBase);
          if _SockBase.FSocketType = STObj then
          begin
            FSockObjList.Add(_SockObj);
          end
          else
          begin
            FSockLstList.Add(_SockLst);
          end;
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
    if _SockBase <> nil then
    begin

      if isAdd then
      begin
        // 有添加sock操作，初始化sockobj，如果失败，会自动被Free掉，无需获取返回值
        InitSockBase(_SockBase);
      end
      else
      begin
        // 有删除sock操作，删除sockobk
        // InitSockBase(_SockBase);
        // RemoveSockBase(_SockBase);
        Assert(_SockBase.FRefCount = 0);
        // _SockBase.Free;
        FreeSockBase(_SockBase);
      end;
    end;
  until _IsEnd;
end;

procedure TCustomIOCPBaseList.WaitForDestroyEvent;
const
  EVENT_NUMBER = 1;
var
  _IsEnd: Boolean;
  EventArray: array [0 .. EVENT_NUMBER - 1] of THandle;
begin
  EventArray[0] := FCanDestroyEvent;
  _IsEnd := False;
  // 等待释放类的事件
  while not _IsEnd do
  begin
    case MsgWaitForMultipleObjects(EVENT_NUMBER, EventArray[0], False, INFINITE, QS_ALLINPUT) of
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

{ TIOCPManager }

procedure TIOCPManager.AddSockList(SockList: TCustomIOCPBaseList);
begin
  LockSockList;
  FSockList.Add(SockList);
  UnlockSockList;
end;

constructor TIOCPManager.Create(IOCPThreadCount: Integer);
var
  ThreadID: DWORD;
  I: Integer;
  TmpSock: TSocket;
  dwBytes: DWORD;
begin
  inherited Create();
  //IsMultiThread := True;
  OutputDebugStr('IOCPManager::IOCPManager');
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
  InitializeCriticalSection(FSockListCS);
  FSockList := TList.Create;

  InitializeCriticalSection(FOverLappedListCS);
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
    //BeginThread()
    FIocpWorkThreads[I] := BeginThread(nil, 0, @IocpWorkThread, Pointer(FCompletionPort),
      0, ThreadID);
    (*
    FIocpWorkThreads[I] := CreateThread(nil, 0, @IocpWorkThread, Pointer(FCompletionPort),
      0, ThreadID);
    *)
    if FIocpWorkThreads[I] = 0 then
    begin
      raise Exception.Create('CreateThread FIocpWorkThreads Fails');
    end;
  end;
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

destructor TIOCPManager.Destroy;
var
  Resu: Boolean;

begin

  // 关闭所有的Socket
  // 锁定
  LockSockList;
  try
    if FSockList.Count > 0 then
    begin
      raise Exception.Create('SockList必须全部释放');
    end;
  finally
    UnlockSockList;
  end;

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
  DeleteCriticalSection(FOverLappedListCS);

  Assert(FSockList.Count = 0,
    'FSockMgrList.Count <> 0, you must free ALL TIOCPOBJBase class before free this class.');
  FSockList.Free;
  FSockList := nil;
  DeleteCriticalSection(FSockListCS);
  // 关闭Socket
  WSACleanup;
  inherited;
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

class procedure TIOCPManager.GetLocalAddrs(Addrs: TStrings);
var
  sHostName: AnsiString;
  _Hints: TAddrInfoA;
  _ResultAddInfo: PADDRINFOA;
  _NextAddInfo: PADDRINFOA;
  _Retval: Integer;
  _AddrString: string;
  _AddrStringLen: DWORD;
begin
  Addrs.Clear;
  SetLength(sHostName, MAX_PATH);
  if gethostname(PAnsiChar(sHostName), MAX_PATH) = SOCKET_ERROR then
  begin
    Exit;
  end;

  ZeroMemory(@_Hints, SizeOf(_Hints));
  _Hints.ai_family := AF_UNSPEC;
  _Hints.ai_socktype := SOCK_STREAM;
  _Hints.ai_protocol := IPPROTO_TCP;

  _Retval := getaddrinfo(PAnsiChar(sHostName), nil, @_Hints, _ResultAddInfo);
  if _Retval <> 0 then
  begin
    Exit;
  end;
  _NextAddInfo := _ResultAddInfo;

  while _NextAddInfo <> nil do
  begin
    _AddrStringLen := 256;
    // 申请缓冲区
    SetLength(_AddrString, _AddrStringLen);
    // 获取
    if WSAAddressToString(_NextAddInfo.ai_addr, _NextAddInfo.ai_addrlen, nil,
      PChar(_AddrString), _AddrStringLen) = 0 then
    begin
      // 改为真实长度,这里的_AddrStringLen包含了末尾的字符#0，所以要减去这个#0的长度
      SetLength(_AddrString, _AddrStringLen - 1);
      Addrs.Add(_AddrString);
    end
    else
    begin
      OutputDebugStr('WSAAddressToString Error');
    end;

    _NextAddInfo := _NextAddInfo.ai_next;

  end;
  freeaddrinfo(_ResultAddInfo);

end;

function TIOCPManager.GetOverLappedList: TList;
begin
  Result := FOverLappedList;
end;

function TIOCPManager.GetSockList: TList;
begin
  Result := FSockList;
end;

procedure TIOCPManager.LockOverLappedList;
begin
  EnterCriticalSection(FOverLappedListCS);
end;

procedure TIOCPManager.LockSockList;
begin
  EnterCriticalSection(FSockListCS);
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

procedure TIOCPManager.RemoveSockList(SockList: TCustomIOCPBaseList);
begin
  LockSockList;
  FSockList.Remove(SockList);
  UnlockSockList;
end;

procedure TIOCPManager.UnlockOverLappedList;
begin
  LeaveCriticalSection(FOverLappedListCS);
end;

procedure TIOCPManager.UnlockSockList;
begin
  LeaveCriticalSection(FSockListCS);
end;

{ TIOCPBase2List }

procedure TIOCPBaseList.OnIOCPEvent(EventType: TIocpEventEnum; SockObj: TSocketObj;
  Overlapped: PIOCPOverlapped);
begin
  if Assigned(FIOCPEvent) then
  begin
    FIOCPEvent(EventType, SockObj, Overlapped);
  end;

end;

procedure TIOCPBaseList.OnListenEvent(EventType: TListenEventEnum; SockLst: TSocketLst);
begin
  if Assigned(FListenEvent) then
  begin
    FListenEvent(EventType, SockLst);
  end;

end;

end.
