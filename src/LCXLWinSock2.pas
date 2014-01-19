(* **************************************************************************** *)
(* 单元: LCXLWinSock2.pas(因为WinSock2.pas在Delphi XE会和自带的有冲突) *)
(* 修改: LCXL *)
(* E-mail: lcx87654321@qq.com *)
(* 说明: 增加了UNICODE版Delphi的支持 *)
(* 原作者信息: *)
(* **************************************************************************** *)
(* *)
(* Windows Sockets API v. 2.20 Header File *)
(* *)
(* Prerelease 16.09.96 *)
(* *)
(* Base:	  WinSock2.h from Winsock SDK 1.6 BETA *)
(* Delphi 2 RTL Windows32 API Interface *)
(* *)
(* (c) 1996 by Artur Grajek 'AHS' *)
(* email: c51725ag@juggernaut.eti.pg.gda.pl *)
(* *)
(* **************************************************************************** *)
{$MINENUMSIZE 4} { Force 4 bytes enumeration size }
unit LCXLWinSock2;

interface

uses Windows, LCXLWS2Def;



  { Socket function prototypes }

  // Using "var addr:TSockAddr" in accept makes impossible to compile for IPv6
function accept(s: TSocket; addr: PSockAddr; var addrlen: Integer): TSocket; stdcall;
// Using "var addr:TSockAddr" in bind makes impossible to compile for IPv6
function bind(s: TSocket; addr: PSockAddr; namelen: Integer): Integer; stdcall;
function closesocket(s: TSocket): Integer; stdcall;
// Using "var addr:TSockAddr" in connect makes impossible to compile for IPv6
function connect(s: TSocket; name: PSockAddr; namelen: Integer): Integer; stdcall;
function ioctlsocket(s: TSocket; cmd: Longint; var arg: u_long): Integer; stdcall;
// Using "var addr:TSockAddr" in getsockname makes impossible to compile for IPv6
function getpeername(s: TSocket; name: PSockAddr; var namelen: Integer)
  : Integer; stdcall;
// Using "var addr:TSockAddr" in getsockname makes impossible to compile for IPv6
function getsockname(s: TSocket; name: PSockAddr; var namelen: Integer): Integer; stdcall;
function getsockopt(s: TSocket; level, optname: Integer; optval: PAnsiChar;
  var optlen: Integer): Integer; stdcall;
function htonl(hostlong: u_long): u_long; stdcall;
function htons(hostshort: u_short): u_short; stdcall;
function inet_addr(cp: PAnsiChar): u_long; stdcall; { PInAddr; }  { TInAddr }
function inet_ntoa(inaddr: TInAddr): PAnsiChar; stdcall;
function listen(s: TSocket; backlog: Integer): Integer; stdcall;
function ntohl(netlong: u_long): u_long; stdcall;
function ntohs(netshort: u_short): u_short; stdcall;
function recv(s: TSocket; var buf; len, flags: Integer): Integer; stdcall;
// Using "var from: TSockAddr" in recvfrom makes impossible to compile for IPv6
function recvfrom(s: TSocket; var buf; len, flags: Integer; from: PSockAddr;
  var fromlen: Integer): Integer; stdcall;
function select(nfds: Integer; readfds, writefds, exceptfds: PFDSet; timeout: PTimeVal)
  : Longint; stdcall;
function send(s: TSocket; var buf; len, flags: Integer): Integer; stdcall;
// Using "var addrto: TSockAddr" in sendto makes impossible to compile for IPv6
function sendto(s: TSocket; var buf; len, flags: Integer; addrto: PSockAddr;
  tolen: Integer): Integer; stdcall;
function setsockopt(s: TSocket; level, optname: Integer; optval: PAnsiChar;
  optlen: Integer): Integer; stdcall;
function shutdown(s: TSocket; how: Integer): Integer; stdcall;
function socket(af, struct, protocol: Integer): TSocket; stdcall;
function gethostbyaddr(addr: Pointer; len, struct: Integer): PHostEnt; stdcall;
function gethostbyname(name: PAnsiChar): PHostEnt; stdcall;
function gethostname(name: PAnsiChar; len: Integer): Integer; stdcall;
function getservbyport(port: Integer; proto: PAnsiChar): PServEnt; stdcall;
function getservbyname(name, proto: PAnsiChar): PServEnt; stdcall;
function getprotobynumber(proto: Integer): PProtoEnt; stdcall;
function getprotobyname(name: PAnsiChar): PProtoEnt; stdcall;
function WSAStartup(wVersionRequired: Word; var WSData: TWSAData): Integer; stdcall;
function WSACleanup: Integer; stdcall;
procedure WSASetLastError(iError: Integer); stdcall;
function WSAGetLastError: Integer; stdcall;
function WSAIsBlocking: BOOL; stdcall;
function WSAUnhookBlockingHook: Integer; stdcall;
function WSASetBlockingHook(lpBlockFunc: TFarProc): TFarProc; stdcall;
function WSACancelBlockingCall: Integer; stdcall;
function WSAAsyncGetServByName(HWindow: HWND; wMsg: u_int; name, proto, buf: PAnsiChar;
  buflen: Integer): THANDLE; stdcall;
function WSAAsyncGetServByPort(HWindow: HWND; wMsg, port: u_int; proto, buf: PAnsiChar;
  buflen: Integer): THANDLE; stdcall;
function WSAAsyncGetProtoByName(HWindow: HWND; wMsg: u_int; name, buf: PAnsiChar;
  buflen: Integer): THANDLE; stdcall;
function WSAAsyncGetProtoByNumber(HWindow: HWND; wMsg: u_int; number: Integer;
  buf: PAnsiChar; buflen: Integer): THANDLE; stdcall;
function WSAAsyncGetHostByName(HWindow: HWND; wMsg: u_int; name, buf: PAnsiChar;
  buflen: Integer): THANDLE; stdcall;
function WSAAsyncGetHostByAddr(HWindow: HWND; wMsg: u_int; addr: PAnsiChar;
  len, struct: Integer; buf: PAnsiChar; buflen: Integer): THANDLE; stdcall;
function WSACancelAsyncRequest(hAsyncTaskHandle: THANDLE): Integer; stdcall;
function WSAAsyncSelect(s: TSocket; HWindow: HWND; wMsg: u_int; lEvent: Longint)
  : Integer; stdcall;

{ WinSock 2 extensions -- data types for the condition function in
  WSAAccept() and overlapped I/O completion routine. }

type

  PCONDITIONPROC = function(lpCallerId: PWSABUF; lpCallerData: PWSABUF; lpSQOS: PQOS;
    lpGQOS: PQOS; lpCalleeId: PWSABUF; lpCalleeData: PWSABUF; g: PGroup;
    dwCallbackData: DWORD): u_int; stdcall;

  LPWSAOVERLAPPED_COMPLETION_ROUTINE = procedure(dwError: DWORD; cbTransferred: DWORD;
    lpOverlapped: LPWSAOVERLAPPED; dwFlags: DWORD); stdcall;

  { WinSock 2 API new function prototypes }

function WSAAccept(s: TSocket; addr: PSockAddr; addrlen: PINT;
  lpfnCondition: PCONDITIONPROC; dwCallbackData: DWORD): TSocket; stdcall;
function WSACloseEvent(hEvent: WSAEVENT): BOOL; stdcall;
function WSAConnect(s: TSocket; name: PSockAddr; namelen: u_int; lpCallerData: PWSABUF;
  lpCalleeData: PWSABUF; lpSQOS: PQOS; lpGQOS: PQOS): u_int; stdcall;
function WSACreateEvent: WSAEVENT; stdcall;
{$IFDEF UNICODE}
function WSADuplicateSocket(s: TSocket; dwProcessId: DWORD;
  lpProtocolInfo: PWSAPROTOCOL_INFOW): u_int; stdcall;
{$ELSE}
function WSADuplicateSocket(s: TSocket; dwProcessId: DWORD;
  lpProtocolInfo: PWSAPROTOCOL_INFOA): u_int; stdcall;
{$ENDIF} { UNICODE }
function WSAEnumNetworkEvents(s: TSocket; hEventObject: WSAEVENT;
  lpNetworkEvents: PWSANETWORKEVENTS): u_int; stdcall;
{$IFDEF UNICODE}
function WSAEnumProtocols(lpiProtocols: PINT; lpProtocolBuffer: PWSAPROTOCOL_INFOW;
  lpdwBufferLength: PDWORD): u_int; stdcall;
{$ELSE}
function WSAEnumProtocols(lpiProtocols: PINT; lpProtocolBuffer: PWSAPROTOCOL_INFOA;
  lpdwBufferLength: PDWORD): u_int; stdcall;
{$ENDIF} { UNICODE }
function WSAEventSelect(s: TSocket; hEventObject: WSAEVENT; lNetworkEvents: u_long)
  : u_int; stdcall;
function WSAGetOverlappedResult(s: TSocket; lpOverlapped: LPWSAOVERLAPPED;
  lpcbTransfer: PDWORD; fWait: BOOL; lpdwFlags: PDWORD): BOOL; stdcall;
function WSAGetQOSByName(s: TSocket; lpQOSName: PWSABUF; lpQOS: PQOS): BOOL; stdcall;
function WSAHtonl(s: TSocket; hostlong: u_long; lpnetlong: pu_long): u_int; stdcall;
function WSAHtons(s: TSocket; hostshort: u_short; lpnetshort: pu_short): u_int; stdcall;
function WSAIoctl(s: TSocket; dwIoControlCode: DWORD; lpvInBuffer: Pointer;
  cbInBuffer: DWORD; lpvOutBuffer: Pointer; cbOutBuffer: DWORD; lpcbBytesReturned: PDWORD;
  lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE)
  : Integer; stdcall;
function WSAJoinLeaf(s: TSocket; name: PSockAddr; namelen: u_int; lpCallerData: PWSABUF;
  lpCalleeData: PWSABUF; lpSQOS: PQOS; lpGQOS: PQOS; dwFlags: DWORD): TSocket; stdcall;
function WSANtohl(s: TSocket; netlong: u_long; lphostlong: pu_long): u_int; stdcall;
function WSANtohs(s: TSocket; netshort: u_short; lphostshort: pu_short): u_int; stdcall;
function WSARecv(s: TSocket; lpBuffers: PWSABUF; dwBufferCount: DWORD;
  lpNumberOfBytesRecvd: PDWORD; lpFlags: PDWORD; lpOverlapped: LPWSAOVERLAPPED;
  lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): u_int; stdcall;
function WSARecvDisconnect(s: TSocket; lpInboundDisconnectData: PWSABUF): u_int; stdcall;
function WSARecvFrom(s: TSocket; lpBuffers: PWSABUF; dwBufferCount: DWORD;
  lpNumberOfBytesRecvd: PDWORD; lpFlags: PDWORD; lpFrom: PSockAddr; lpFromlen: PINT;
  lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE)
  : u_int; stdcall;
function WSAResetEvent(hEvent: WSAEVENT): BOOL; stdcall;
function WSASend(s: TSocket; lpBuffers: PWSABUF; dwBufferCount: DWORD;
  lpNumberOfBytesSent: PDWORD; dwFlags: DWORD; lpOverlapped: LPWSAOVERLAPPED;
  lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): Integer; stdcall;
function WSASendDisconnect(s: TSocket; lpOutboundDisconnectData: PWSABUF): u_int; stdcall;
function WSASendTo(s: TSocket; lpBuffers: PWSABUF; dwBufferCount: DWORD;
  lpNumberOfBytesSent: PDWORD; dwFlags: DWORD; lpTo: PSockAddr; iTolen: u_int;
  lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE)
  : u_int; stdcall;
function WSASetEvent(hEvent: WSAEVENT): BOOL; stdcall;
{$IFDEF UNICODE}
function WSASocket(af: u_int; atype: u_int; protocol: u_int;
  lpProtocolInfo: PWSAPROTOCOL_INFOW; g: TGroup; dwFlags: DWORD): TSocket; stdcall;
{$ELSE}
function WSASocket(af: u_int; atype: u_int; protocol: u_int;
  lpProtocolInfo: PWSAPROTOCOL_INFOA; g: TGroup; dwFlags: DWORD): TSocket; stdcall;
{$ENDIF} { UNICODE }
function WSAWaitForMultipleEvents(cEvents: DWORD; lphEvents: LPWSAEVENT; fWaitAll: BOOL;
  dwTimeout: DWORD; fAlertable: BOOL): DWORD; stdcall;
{$IFDEF UNICODE}
function WSAAddressToString(lpsaAddress: PSockAddr; dwAddressLength: DWORD;
  lpProtocolInfo: PWSAPROTOCOL_INFOW; lpszAddressString: PWideChar;
  var lpdwAddressStringLength: DWORD): u_int; stdcall;
{$ELSE}
function WSAAddressToString(lpsaAddress: PSockAddr; dwAddressLength: DWORD;
  lpProtocolInfo: PWSAPROTOCOL_INFOA; lpszAddressString: PAnsiChar;
  var lpdwAddressStringLength: DWORD): u_int; stdcall;
{$ENDIF} { UNICODE }
{$IFDEF UNICODE}
function WSAStringToAddress(AddressString: PWideChar; AddressFamily: u_int;
  lpProtocolInfo: PWSAPROTOCOL_INFOW; lpAddress: PSockAddr; lpAddressLength: PINT)
  : u_int; stdcall;
{$ELSE}
function WSAStringToAddress(AddressString: PAnsiChar; AddressFamily: u_int;
  lpProtocolInfo: PWSAPROTOCOL_INFOA; lpAddress: PSockAddr; lpAddressLength: PINT)
  : u_int; stdcall;
{$ENDIF} { UNICODE }
{ Registration and Name Resolution API functions }
{$IFDEF UNICODE}
function WSALookupServiceBegin(lpqsRestrictions: PWSAQuerySetW; dwControlFlags: DWORD;
  lphLookup: LPHANDLE): u_int; stdcall;
{$ELSE}
function WSALookupServiceBegin(lpqsRestrictions: PWSAQuerySetA; dwControlFlags: DWORD;
  lphLookup: LPHANDLE): u_int; stdcall;
{$ENDIF} { UNICODE }
{$IFDEF UNICODE}
function WSALookupServiceNext(hLookup: THANDLE; dwControlFlags: DWORD;
  lpdwBufferLength: PDWORD; lpqsResults: PWSAQuerySetW): u_int; stdcall;
{$ELSE}
function WSALookupServiceNext(hLookup: THANDLE; dwControlFlags: DWORD;
  lpdwBufferLength: PDWORD; lpqsResults: PWSAQuerySetA): Longint; stdcall;
{$ENDIF} { UNICODE }
function WSALookupServiceEnd(hLookup: THANDLE): u_int; stdcall;
{$IFDEF UNICODE}
function WSAInstallServiceClass(lpServiceClassInfo: PWSAServiceClassInfoW)
  : u_int; stdcall;
{$ELSE}
function WSAInstallServiceClass(lpServiceClassInfo: PWSAServiceClassInfoA)
  : u_int; stdcall;
{$ENDIF} { UNICODE }
function WSARemoveServiceClass(lpServiceClassId: PGUID): u_int; stdcall;
{$IFDEF UNICODE}
function WSAGetServiceClassInfo(lpProviderId: PGUID; lpServiceClassId: PGUID;
  lpdwBufSize: PDWORD; lpServiceClassInfo: PWSAServiceClassInfoW): u_int; stdcall;
{$ELSE}
function WSAGetServiceClassInfo(lpProviderId: PGUID; lpServiceClassId: PGUID;
  lpdwBufSize: PDWORD; lpServiceClassInfo: PWSAServiceClassInfoA): u_int; stdcall;
{$ENDIF} { UNICODE }
{$IFDEF UNICODE}
function WSAEnumNameSpaceProviders(lpdwBufferLength: PDWORD;
  lpnspBuffer: PWSANAMESPACE_INFOW): u_int; stdcall;
{$ELSE}
function WSAEnumNameSpaceProviders(lpdwBufferLength: PDWORD;
  lpnspBuffer: PWSANAMESPACE_INFOA): u_int; stdcall;
{$ENDIF} { UNICODE }
{$IFDEF UNICODE}
function WSAGetServiceClassNameByClassId(lpServiceClassId: PGUID;
  lpszServiceClassName: PWideChar; lpdwBufferLength: PDWORD): u_int; stdcall;
{$ELSE}
function WSAGetServiceClassNameByClassId(lpServiceClassId: PGUID;
  lpszServiceClassName: PAnsiChar; lpdwBufferLength: PDWORD): u_int; stdcall;
{$ENDIF} { UNICODE }
{$IFDEF UNICODE}
function WSASetService(lpqsRegInfo: PWSAQuerySetW; essoperation: TWSAESETSERVICEOP;
  dwControlFlags: DWORD): u_int; stdcall;
{$ELSE}
function WSASetService(lpqsRegInfo: PWSAQuerySetA; essoperation: TWSAESETSERVICEOP;
  dwControlFlags: DWORD): u_int; stdcall;
{$ENDIF} { UNICODE }
function WSARecvEx(s: TSocket; var buf; len: Integer; var flags: Integer)
  : Integer; stdcall;

function TransmitFile(hSocket: TSocket; hFile: THANDLE; nNumberOfBytesToWrite: DWORD;
  nNumberOfBytesPerSend: DWORD; lpOverlapped: POverlapped;
  lpTransmitBuffers: PTransmitFileBuffers; dwReserved: DWORD): BOOL; stdcall;

function WSAMakeASyncReply(buflen, Error: Word): Longint;
function WSAMakeSelectReply(Event, Error: Word): Longint;
function WSAGetAsyncBuflen(Param: Longint): Word;
function WSAGetAsyncError(Param: Longint): Word;
function WSAGetSelectEvent(Param: Longint): Word;
function WSAGetSelectError(Param: Longint): Word;


implementation

function WSAMakeASyncReply;
begin
  WSAMakeASyncReply := MakeLong(buflen, Error);
end;

function WSAMakeSelectReply;
begin
  WSAMakeSelectReply := MakeLong(Event, Error);
end;

function WSAGetAsyncBuflen;
begin
  WSAGetAsyncBuflen := LOWORD(Param);
end;

function WSAGetAsyncError;
begin
  WSAGetAsyncError := HIWORD(Param);
end;

function WSAGetSelectEvent;
begin
  WSAGetSelectEvent := LOWORD(Param);
end;

function WSAGetSelectError;
begin
  WSAGetSelectError := HIWORD(Param);
end;

function accept; external ws2_32_dll name 'accept';
function bind; external ws2_32_dll name 'bind';
function closesocket; external ws2_32_dll name 'closesocket';
function connect; external ws2_32_dll name 'connect';
function getpeername; external ws2_32_dll name 'getpeername';
function getsockname; external ws2_32_dll name 'getsockname';
function getsockopt; external ws2_32_dll name 'getsockopt';
function htonl; external ws2_32_dll name 'htonl';
function htons; external ws2_32_dll name 'htons';
function inet_addr; external ws2_32_dll name 'inet_addr';
function inet_ntoa; external ws2_32_dll name 'inet_ntoa';
function ioctlsocket; external ws2_32_dll name 'ioctlsocket';
function listen; external ws2_32_dll name 'listen';
function ntohl; external ws2_32_dll name 'ntohl';
function ntohs; external ws2_32_dll name 'ntohs';
function recv; external ws2_32_dll name 'recv';
function recvfrom; external ws2_32_dll name 'recvfrom';
function select; external ws2_32_dll name 'select';
function send; external ws2_32_dll name 'send';
function sendto; external ws2_32_dll name 'sendto';
function setsockopt; external ws2_32_dll name 'setsockopt';
function shutdown; external ws2_32_dll name 'shutdown';
function socket; external ws2_32_dll name 'socket';

function gethostbyaddr; external ws2_32_dll name 'gethostbyaddr';
function gethostbyname; external ws2_32_dll name 'gethostbyname';
function getprotobyname; external ws2_32_dll name 'getprotobyname';
function getprotobynumber; external ws2_32_dll name 'getprotobynumber';
function getservbyname; external ws2_32_dll name 'getservbyname';
function getservbyport; external ws2_32_dll name 'getservbyport';
function gethostname; external ws2_32_dll name 'gethostname';

function WSAAsyncSelect; external ws2_32_dll name 'WSAAsyncSelect';
function WSARecvEx; external ws2_32_dll name 'WSARecvEx';
function WSAAsyncGetHostByAddr; external ws2_32_dll name 'WSAAsyncGetHostByAddr';
function WSAAsyncGetHostByName; external ws2_32_dll name 'WSAAsyncGetHostByName';
function WSAAsyncGetProtoByNumber; external ws2_32_dll name 'WSAAsyncGetProtoByNumber';
function WSAAsyncGetProtoByName; external ws2_32_dll name 'WSAAsyncGetprotoByName';
function WSAAsyncGetServByPort; external ws2_32_dll name 'WSAAsyncGetServByPort';
function WSAAsyncGetServByName; external ws2_32_dll name 'WSAAsyncGetServByName';
function WSACancelAsyncRequest; external ws2_32_dll name 'WSACancelAsyncRequest';
function WSASetBlockingHook; external ws2_32_dll name 'WSASetBlockingHook';
function WSAUnhookBlockingHook; external ws2_32_dll name 'WSAUnhookBlockingHook';
function WSAGetLastError; external ws2_32_dll name 'WSAGetLastError';
procedure WSASetLastError; external ws2_32_dll name 'WSASetLastError';
function WSACancelBlockingCall; external ws2_32_dll name 'WSACancelBlockingCall';
function WSAIsBlocking; external ws2_32_dll name 'WSAIsBlocking';
function WSAStartup; external ws2_32_dll name 'WSAStartup';
function WSACleanup; external ws2_32_dll name 'WSACleanup';
{$IFDEF UNICODE}
function WSASetService; external ws2_32_dll name 'WSASetServiceW';
function WSAGetServiceClassNameByClassId;
  external ws2_32_dll name 'WSAGetServiceClassNameByClassIdW';
function WSAEnumNameSpaceProviders; external ws2_32_dll name 'WSAEnumNameSpaceProvidersW';
function WSAGetServiceClassInfo; external ws2_32_dll name 'WSAGetServiceClassInfoW';
function WSAInstallServiceClass; external ws2_32_dll name 'WSAInstallServiceClassW';
function WSALookupServiceNext; external ws2_32_dll name 'WSALookupServiceNextW';
function WSALookupServiceBegin; external ws2_32_dll name 'WSALookupServiceBeginW';
function WSAStringToAddress; external ws2_32_dll name 'WSAStringToAddressW';
function WSAAddressToString; external ws2_32_dll name 'WSAAddressToStringW';
function WSASocket; external ws2_32_dll name 'WSASocketW';
function WSAEnumProtocols; external ws2_32_dll name 'WSAEnumProtocolsW';
function WSADuplicateSocket; external ws2_32_dll name 'WSADuplicateSocketW';
{$ELSE}
function WSASetService; external ws2_32_dll name 'WSASetServiceA';
function WSAGetServiceClassNameByClassId;
  external ws2_32_dll name 'WSAGetServiceClassNameByClassIdA';
function WSAEnumNameSpaceProviders; external ws2_32_dll name 'WSAEnumNameSpaceProvidersA';
function WSAGetServiceClassInfo; external ws2_32_dll name 'WSAGetServiceClassInfoA';
function WSAInstallServiceClass; external ws2_32_dll name 'WSAInstallServiceClassA';
function WSALookupServiceNext; external ws2_32_dll name 'WSALookupServiceNextA';
function WSALookupServiceBegin; external ws2_32_dll name 'WSALookupServiceBeginA';
function WSAStringToAddress; external ws2_32_dll name 'WSAStringToAddressA';
function WSAAddressToString; external ws2_32_dll name 'WSAAddressToStringA';
function WSASocket; external ws2_32_dll name 'WSASocketA';
function WSAEnumProtocols; external ws2_32_dll name 'WSAEnumProtocolsA';
function WSADuplicateSocket; external ws2_32_dll name 'WSADuplicateSocketA';
{$ENDIF} { UNICODE }
function WSALookupServiceEnd; external ws2_32_dll name 'WSALookupServiceEnd';
function WSARemoveServiceClass; external ws2_32_dll name 'WSARemoveServiceClass';
function WSAWaitForMultipleEvents; external ws2_32_dll name 'WSAWaitForMultipleEvents';
function WSASetEvent; external ws2_32_dll name 'WSASetEvent';
function WSASendTo; external ws2_32_dll name 'WSASendTo';
function WSASendDisconnect; external ws2_32_dll name 'WSASendDisconnect';
function WSASend; external ws2_32_dll name 'WSASend';
function WSAResetEvent; external ws2_32_dll name 'WSAResetEvent';
function WSARecvFrom; external ws2_32_dll name 'WSARecvFrom';
function WSARecvDisconnect; external ws2_32_dll name 'WSARecvDisconnect';
function WSARecv; external ws2_32_dll name 'WSARecv';
function WSAIoctl; external ws2_32_dll name 'WSAIoctl';
function WSAJoinLeaf; external ws2_32_dll name 'WSAJoinLeaf';
function WSANtohl; external ws2_32_dll name 'WSANtohl';
function WSANtohs; external ws2_32_dll name 'WSANtohs';
function WSAHtons; external ws2_32_dll name 'WSAHtons';
function WSAHtonl; external ws2_32_dll name 'WSAHtonl';
function WSAGetQOSByName; external ws2_32_dll name 'WSAGetQOSByName';
function WSAGetOverlappedResult; external ws2_32_dll name 'WSAGetOverlappedResult';
function WSAEventSelect; external ws2_32_dll name 'WSAEventSelect';
function WSAEnumNetworkEvents; external ws2_32_dll name 'WSAEnumNetworkEvents';
function WSACreateEvent; external ws2_32_dll name 'WSACreateEvent';
function WSAConnect; external ws2_32_dll name 'WSAConnect';
function WSACloseEvent; external ws2_32_dll name 'WSACloseEvent';
function WSAAccept; external ws2_32_dll name 'WSAAccept';

function TransmitFile; external ws2_32_dll name 'TransmitFile';

end.
