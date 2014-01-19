unit LCXLWs2tcpip;

interface

uses
  Windows, LCXLWinSock2, LCXLWS2Def;

function getaddrinfo(pNodeName: PAnsiChar; pServiceName: PAnsiChar;
  pHints: PADDRINFOA; var ppResult: PADDRINFOA): integer; stdcall;

procedure freeaddrinfo(pAddrInfo: PADDRINFOA); stdcall;

function getnameinfo(pSockaddr: pSockaddr; SockaddrLength: integer;
  pNodeBuffer: PAnsiChar; NodeBufferSize: DWORD; pServiceBuffer: PAnsiChar;
  ServiceBufferSize: DWORD; Flags: integer): integer; stdcall;

function inet_ntop(Family: integer; pAddr: Pointer; pStringBuf: PAnsiChar;
  StringBufSize: size_t): PAnsiChar; stdcall;

implementation

const
  ws2_32_dll = 'ws2_32.dll';
function getaddrinfo; external ws2_32_dll name 'getaddrinfo';
procedure freeaddrinfo; external ws2_32_dll name 'freeaddrinfo';
function getnameinfo; external ws2_32_dll name 'getnameinfo';
function inet_ntop; external ws2_32_dll name 'inet_ntop';

end.
