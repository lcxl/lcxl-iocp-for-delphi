
unit LCXLMSWSock;


{$HPPEMIT ''}
{$HPPEMIT '#include "mswsock.h"'}
{$HPPEMIT ''}

interface

uses
  Windows, LCXLWinSock2, LCXLWS2Def;

{$IFNDEF JWA_IMPLEMENTATIONSECTION}

//
// Options for connect and disconnect data and options.  Used only by
// non-TCP/IP transports such as DECNet, OSI TP4, etc.
//

const
  SO_CONNDATA                = $7000;
  {$EXTERNALSYM SO_CONNDATA}
  SO_CONNOPT                 = $7001;
  {$EXTERNALSYM SO_CONNOPT}
  SO_DISCDATA                = $7002;
  {$EXTERNALSYM SO_DISCDATA}
  SO_DISCOPT                 = $7003;
  {$EXTERNALSYM SO_DISCOPT}
  SO_CONNDATALEN             = $7004;
  {$EXTERNALSYM SO_CONNDATALEN}
  SO_CONNOPTLEN              = $7005;
  {$EXTERNALSYM SO_CONNOPTLEN}
  SO_DISCDATALEN             = $7006;
  {$EXTERNALSYM SO_DISCDATALEN}
  SO_DISCOPTLEN              = $7007;
  {$EXTERNALSYM SO_DISCOPTLEN}

//
// Option for opening sockets for synchronous access.
//

const
  SO_OPENTYPE                = $7008;
  {$EXTERNALSYM SO_OPENTYPE}

  SO_SYNCHRONOUS_ALERT       = $10;
  {$EXTERNALSYM SO_SYNCHRONOUS_ALERT}
  SO_SYNCHRONOUS_NONALERT    = $20;
  {$EXTERNALSYM SO_SYNCHRONOUS_NONALERT}

//
// Other NT-specific options.
//

const
  SO_MAXDG                   = $7009;
  {$EXTERNALSYM SO_MAXDG}
  SO_MAXPATHDG               = $700A;
  {$EXTERNALSYM SO_MAXPATHDG}
  SO_UPDATE_ACCEPT_CONTEXT   = $700B;
  {$EXTERNALSYM SO_UPDATE_ACCEPT_CONTEXT}
  SO_CONNECT_TIME            = $700C;
  {$EXTERNALSYM SO_CONNECT_TIME}
  SO_UPDATE_CONNECT_CONTEXT  = $7010;
  {$EXTERNALSYM SO_UPDATE_CONNECT_CONTEXT}

//
// TCP options.
//

const
  TCP_BSDURGENT              = $7000;
  {$EXTERNALSYM TCP_BSDURGENT}

//
// MS Transport Provider IOCTL to control
// reporting PORT_UNREACHABLE messages
// on UDP sockets via recv/WSARecv/etc.
// Path TRUE in input buffer to enable (default if supported),
// FALSE to disable.
//

  SIO_UDP_CONNRESET          = IOC_IN or IOC_VENDOR or 12;
  {$EXTERNALSYM SIO_UDP_CONNRESET}

//
// Microsoft extended APIs.
//

type
  _TRANSMIT_FILE_BUFFERS = record
    Head: LPVOID;
    HeadLength: DWORD;
    Tail: LPVOID;
    TailLength: DWORD;
  end;
  {$EXTERNALSYM _TRANSMIT_FILE_BUFFERS}
  TRANSMIT_FILE_BUFFERS = _TRANSMIT_FILE_BUFFERS;
  {$EXTERNALSYM TRANSMIT_FILE_BUFFERS}
  PTRANSMIT_FILE_BUFFERS = ^TRANSMIT_FILE_BUFFERS;
  {$EXTERNALSYM PTRANSMIT_FILE_BUFFERS}
  LPTRANSMIT_FILE_BUFFERS = ^TRANSMIT_FILE_BUFFERS;
  {$EXTERNALSYM LPTRANSMIT_FILE_BUFFERS}
  TTransmitFileBuffers = TRANSMIT_FILE_BUFFERS;
  PTransmitFileBuffers = LPTRANSMIT_FILE_BUFFERS;

const
  TF_DISCONNECT         = $01;
  {$EXTERNALSYM TF_DISCONNECT}
  TF_REUSE_SOCKET       = $02;
  {$EXTERNALSYM TF_REUSE_SOCKET}
  TF_WRITE_BEHIND       = $04;
  {$EXTERNALSYM TF_WRITE_BEHIND}
  TF_USE_DEFAULT_WORKER = $00;
  {$EXTERNALSYM TF_USE_DEFAULT_WORKER}
  TF_USE_SYSTEM_THREAD  = $10;
  {$EXTERNALSYM TF_USE_SYSTEM_THREAD}
  TF_USE_KERNEL_APC     = $20;
  {$EXTERNALSYM TF_USE_KERNEL_APC}

//
// "QueryInterface" versions of the above APIs.
//

type
  LPFN_TRANSMITFILE = function(hSocket: TSocket; hFile: THandle; nNumberOfBytesToWrite,
    nNumberOfBytesPerSend: DWORD; lpOverlapped: POVERLAPPED;
    lpTransmitBuffers: LPTRANSMIT_FILE_BUFFERS; dwReserved: DWORD): BOOL; stdcall;
  {$EXTERNALSYM LPFN_TRANSMITFILE}
  TFnTransmitFile = LPFN_TRANSMITFILE;

const
  WSAID_TRANSMITFILE: TGUID = (
    D1:$b5367df0; D2:$cbac; D3:$11cf; D4:($95, $ca, $00, $80, $5f, $48, $a1, $92));
  {$EXTERNALSYM WSAID_TRANSMITFILE}

type
  LPFN_ACCEPTEX = function(sListenSocket, sAcceptSocket: TSocket; lpOutputBuffer: LPVOID;
    dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
    var lpdwBytesReceived: DWORD; lpOverlapped: POVERLAPPED): BOOL; stdcall;
  {$EXTERNALSYM LPFN_ACCEPTEX}
  TFnAcceptEx = LPFN_ACCEPTEX;

const
  WSAID_ACCEPTEX: TGUID = (
    D1:$b5367df1; D2:$cbac; D3:$11cf; D4:($95, $ca, $00, $80, $5f, $48, $a1, $92));
  {$EXTERNALSYM WSAID_ACCEPTEX}

type
  LPFN_GETACCEPTEXSOCKADDRS = procedure(lpOutputBuffer: LPVOID; dwReceiveDataLength,
    dwLocalAddressLength, dwRemoteAddressLength: DWORD; var LocalSockaddr: LPSOCKADDR;
    var LocalSockaddrLength: Integer; var RemoteSockaddr: LPSOCKADDR;
    var RemoteSockaddrLength: Integer); stdcall;
  {$EXTERNALSYM LPFN_GETACCEPTEXSOCKADDRS}
  TFnGetAcceptExSockAddrs = LPFN_GETACCEPTEXSOCKADDRS;

const
  WSAID_GETACCEPTEXSOCKADDRS: TGUID = (
    D1: $b5367df2; D2:$cbac; D3:$11cf; D4:($95, $ca, $00, $80, $5f, $48, $a1, $92));
  {$EXTERNALSYM WSAID_GETACCEPTEXSOCKADDRS}

  TP_ELEMENT_MEMORY  = 1;
  {$EXTERNALSYM TP_ELEMENT_MEMORY}
  TP_ELEMENT_FILE    = 2;
  {$EXTERNALSYM TP_ELEMENT_FILE}
  TP_ELEMENT_EOP     = 4;
  {$EXTERNALSYM TP_ELEMENT_EOP}

type
  _TRANSMIT_PACKETS_ELEMENT = record
    dwElFlags: ULONG;
    cLength: ULONG;
    case Integer of
      0: (
        nFileOffset: LARGE_INTEGER;
        hFile: THandle);
      1: (
        pBuffer: LPVOID);
  end;
  {$EXTERNALSYM _TRANSMIT_PACKETS_ELEMENT}
  TRANSMIT_PACKETS_ELEMENT = _TRANSMIT_PACKETS_ELEMENT;
  {$EXTERNALSYM TRANSMIT_PACKETS_ELEMENT}
  PTRANSMIT_PACKETS_ELEMENT = ^TRANSMIT_PACKETS_ELEMENT;
  {$EXTERNALSYM PTRANSMIT_PACKETS_ELEMENT}
  LPTRANSMIT_PACKETS_ELEMENT = ^TRANSMIT_PACKETS_ELEMENT;
  {$EXTERNALSYM LPTRANSMIT_PACKETS_ELEMENT}
  TTransmitPacketElement = TRANSMIT_PACKETS_ELEMENT;
  PTransmitPacketElement = PTRANSMIT_PACKETS_ELEMENT;

const
  TP_DISCONNECT         = TF_DISCONNECT;
  {$EXTERNALSYM TP_DISCONNECT}
  TP_REUSE_SOCKET       = TF_REUSE_SOCKET;
  {$EXTERNALSYM TP_REUSE_SOCKET}
  TP_USE_DEFAULT_WORKER = TF_USE_DEFAULT_WORKER;
  {$EXTERNALSYM TP_USE_DEFAULT_WORKER}
  TP_USE_SYSTEM_THREAD  = TF_USE_SYSTEM_THREAD;
  {$EXTERNALSYM TP_USE_SYSTEM_THREAD}
  TP_USE_KERNEL_APC     = TF_USE_KERNEL_APC;
  {$EXTERNALSYM TP_USE_KERNEL_APC}

type
  LPFN_TRANSMITPACKETS = function(Socket: TSocket; lpPacketArray: LPTRANSMIT_PACKETS_ELEMENT; ElementCount: DWORD;
    nSendSize: DWORD; lpOverlapped: POVERLAPPED; dwFlags: DWORD): BOOL; stdcall;
  {$EXTERNALSYM LPFN_TRANSMITPACKETS}

const
  WSAID_TRANSMITPACKETS: TGUID = (
    D1: $d9689da0; D2:$1f90; D3:$11d3; D4:($99, $71, $00, $c0, $4f, $68, $c8, $76));
  {$EXTERNALSYM WSAID_TRANSMITPACKETS}

type
  LPFN_CONNECTEX = function(s: TSocket; name: PSockAddr; namelen: Integer; lpSendBuffer: PVOID; dwSendDataLength: DWORD;
    lpdwBytesSent: LPDWORD; lpOverlapped: POVERLAPPED): BOOL; stdcall;
  {$EXTERNALSYM LPFN_CONNECTEX}

const
  WSAID_CONNECTEX: TGUID = (
    D1: $25a207b9; D2:$ddf3; D3:$4660; D4:($8e, $e9, $76, $e5, $8c, $74, $06, $3e));
  {$EXTERNALSYM WSAID_CONNECTEX}

type
  LPFN_DISCONNECTEX = function(s: TSocket; lpOverlapped: POVERLAPPED; dwFlags: DWORD; dwReserved: DWORD): BOOL; stdcall;
  {$EXTERNALSYM LPFN_DISCONNECTEX}

const
  WSAID_DISCONNECTEX: TGUID = (
    D1: $7fda2e11; D2:$8630; D3:$436f; D4:($a0, $31, $f5, $36, $a6, $ee, $c1, $57));
  {$EXTERNALSYM WSAID_DISCONNECTEX}

  DE_REUSE_SOCKET = TF_REUSE_SOCKET;
  {$EXTERNALSYM DE_REUSE_SOCKET}

//
// Network-location awareness -- Name registration values for use
// with WSASetService and other structures.
//

// {6642243A-3BA8-4aa6-BAA5-2E0BD71FDD83}

  NLA_NAMESPACE_GUID: TGUID = (
    D1: $6642243a; D2:$3ba8; D3:$4aa6; D4:($ba, $a5, $2e, $0b, $d7, $1f, $dd, $83));
  {$EXTERNALSYM NLA_NAMESPACE_GUID}

// {6642243A-3BA8-4aa6-BAA5-2E0BD71FDD83}

  NLA_SERVICE_CLASS_GUID: TGUID = (
    D1: $37e515; D2:$b5c9; D3:$4a43; D4:($ba, $da, $8b, $48, $a8, $7a, $d2, $39));
  {$EXTERNALSYM NLA_SERVICE_CLASS_GUID}

  NLA_ALLUSERS_NETWORK  = $00000001;
  {$EXTERNALSYM NLA_ALLUSERS_NETWORK}
  NLA_FRIENDLY_NAME     = $00000002;
  {$EXTERNALSYM NLA_FRIENDLY_NAME}

type
  _NLA_BLOB_DATA_TYPE = (
    NLA_RAW_DATA,
    NLA_INTERFACE,
    NLA_802_1X_LOCATION,
    NLA_CONNECTIVITY,
    NLA_ICS);
  {$EXTERNALSYM _NLA_BLOB_DATA_TYPE}
  NLA_BLOB_DATA_TYPE = _NLA_BLOB_DATA_TYPE;
  {$EXTERNALSYM NLA_BLOB_DATA_TYPE}
  PNLA_BLOB_DATA_TYPE = ^NLA_BLOB_DATA_TYPE;
  {$EXTERNALSYM PNLA_BLOB_DATA_TYPE}
  TNlaBlobDataType = NLA_BLOB_DATA_TYPE;
  PNlaBlobDataType = PNLA_BLOB_DATA_TYPE;

  _NLA_CONNECTIVITY_TYPE = (
    NLA_NETWORK_AD_HOC,
    NLA_NETWORK_MANAGED,
    NLA_NETWORK_UNMANAGED,
    NLA_NETWORK_UNKNOWN);
  {$EXTERNALSYM _NLA_CONNECTIVITY_TYPE}
  NLA_CONNECTIVITY_TYPE = _NLA_CONNECTIVITY_TYPE;
  {$EXTERNALSYM NLA_CONNECTIVITY_TYPE}
  PNLA_CONNECTIVITY_TYPE = ^NLA_CONNECTIVITY_TYPE;
  {$EXTERNALSYM PNLA_CONNECTIVITY_TYPE}
  TNlaConnectivityType = NLA_CONNECTIVITY_TYPE;
  PNlaConnectivityType = PNLA_CONNECTIVITY_TYPE;

  _NLA_INTERNET = (
    NLA_INTERNET_UNKNOWN,
    NLA_INTERNET_NO,
    NLA_INTERNET_YES);
  {$EXTERNALSYM _NLA_INTERNET}
  NLA_INTERNET = _NLA_INTERNET;
  {$EXTERNALSYM NLA_INTERNET}
  PNLA_INTERNET = ^NLA_INTERNET;
  {$EXTERNALSYM PNLA_INTERNET}
  TNlaInternet = NLA_INTERNET;
  PNlaInternet = PNLA_INTERNET;

  _NLA_BLOB = record
    header: record
      type_: NLA_BLOB_DATA_TYPE;
      dwSize: DWORD;
      nextOffset: DWORD;
    end;
    case Integer of
      0: (
        // header.type -> NLA_RAW_DATA
        rawData: array [0..0] of AnsiChar);
      1: (
        // header.type -> NLA_INTERFACE
        dwType: DWORD;
        dwSpeed: DWORD;
        adapterName: array [0..0] of AnsiChar);
      2: (
        // header.type -> NLA_802_1X_LOCATION
        information: array [0..0] of AnsiChar);
      3: (
        // header.type -> NLA_CONNECTIVITY
        type_: NLA_CONNECTIVITY_TYPE;
        internet: NLA_INTERNET);
      4: (
        // header.type -> NLA_ICS
        remote: record
          speed: DWORD;
          type_: DWORD;
          state: DWORD;
          machineName: array [0..255] of WCHAR;
          sharedAdapterName: array [0..255] of WCHAR;
        end);
  end;
  {$EXTERNALSYM _NLA_BLOB}
  NLA_BLOB = _NLA_BLOB;
  {$EXTERNALSYM NLA_BLOB}
  PNLA_BLOB = ^NLA_BLOB;
  {$EXTERNALSYM PNLA_BLOB}
  LPNLA_BLOB = ^NLA_BLOB;
  {$EXTERNALSYM LPNLA_BLOB}
  TNlaBlob = NLA_BLOB;
  PNlaBlob = PNLA_BLOB;

  _WSAMSG = record
    name: LPSOCKADDR;          // Remote address
    namelen: Integer;              // Remote address length
    lpBuffers: PWSABUF;       // Data buffer array
    dwBufferCount: DWORD;      // Number of elements in the array
    Control: TWSABUF;           // Control buffer
    dwFlags: DWORD;            // Flags
  end;
  {$EXTERNALSYM _WSAMSG}
  WSAMSG = _WSAMSG;
  {$EXTERNALSYM WSAMSG}
  PWSAMSG = ^WSAMSG;
  {$EXTERNALSYM PWSAMSG}
  LPWSAMSG = ^WSAMSG;
  {$EXTERNALSYM LPWSAMSG}
  TWsaMsg = WSAMSG;

//
// Layout of ancillary data objects in the control buffer
//

  _WSACMSGHDR = record
    cmsg_len: SIZE_T;
    cmsg_level: Integer;
    cmsg_type: Integer;
    // followed by UCHAR cmsg_data[]
  end;
  {$EXTERNALSYM _WSACMSGHDR}
  WSACMSGHDR = _WSACMSGHDR;
  {$EXTERNALSYM WSACMSGHDR}
  PWSACMSGHDR = ^WSACMSGHDR;
  {$EXTERNALSYM PWSACMSGHDR}
  LPWSACMSGHDR = ^WSACMSGHDR;
  {$EXTERNALSYM LPWSACMSGHDR}
  TWsaCMsgHdr = WSACMSGHDR;

//
// Alignment macros for header and data members of
// the control buffer.
//

{ TODO
#define WSA_CMSGHDR_ALIGN(length)                           \
            ( ((length) + TYPE_ALIGNMENT(WSACMSGHDR)-1) &   \
                (~(TYPE_ALIGNMENT(WSACMSGHDR)-1)) )         \

#define WSA_CMSGDATA_ALIGN(length)                          \
            ( ((length) + MAX_NATURAL_ALIGNMENT-1) &        \
                (~(MAX_NATURAL_ALIGNMENT-1)) )
}

//
//  WSA_CMSG_FIRSTHDR
//
//  Returns a pointer to the first ancillary data object,
//  or a null pointer if there is no ancillary data in the
//  control buffer of the WSAMSG structure.
//
//  LPCMSGHDR
//  WSA_CMSG_FIRSTHDR (
//      LPWSAMSG    msg
//      );
//

(* TODO
#define WSA_CMSG_FIRSTHDR(msg) \
    ( ((msg)->Control.len >= sizeof(WSACMSGHDR))            \
        ? (LPWSACMSGHDR)(msg)->Control.buf                  \
        : (LPWSACMSGHDR)NULL )
*)

//
//  WSA_CMSG_NXTHDR
//
//  Returns a pointer to the next ancillary data object,
//  or a null if there are no more data objects.
//
//  LPCMSGHDR
//  WSA_CMSG_NEXTHDR (
//      LPWSAMSG        msg,
//      LPWSACMSGHDR    cmsg
//      );
//

{ TODO
#define WSA_CMSG_NXTHDR(msg, cmsg)                          \
    ( ((cmsg) == NULL)                                      \
        ? WSA_CMSG_FIRSTHDR(msg)                            \
        : ( ( ((u_char *)(cmsg) +                           \
                    WSA_CMSGHDR_ALIGN((cmsg)->cmsg_len) +   \
                    sizeof(WSACMSGHDR) ) >                  \
                (u_char *)((msg)->Control.buf) +            \
                    (msg)->Control.len )                    \
            ? (LPWSACMSGHDR)NULL                            \
            : (LPWSACMSGHDR)((u_char *)(cmsg) +             \
                WSA_CMSGHDR_ALIGN((cmsg)->cmsg_len)) ) )
}

//
//  WSA_CMSG_DATA
//
//  Returns a pointer to the first byte of data (what is referred
//  to as the cmsg_data member though it is not defined in
//  the structure).
//
//  u_char *
//  WSA_CMSG_DATA (
//      LPWSACMSGHDR   pcmsg
//      );
//

{ TODO
#define WSA_CMSG_DATA(cmsg)             \
            ( (u_char *)(cmsg) + WSA_CMSGDATA_ALIGN(sizeof(WSACMSGHDR)) )
}

//
//  WSA_CMSG_SPACE
//
//  Returns total size of an ancillary data object given
//  the amount of data. Used to allocate the correct amount
//  of space.
//
//  SIZE_T
//  WSA_CMSG_SPACE (
//      SIZE_T length
//      );
//

{ TODO
#define WSA_CMSG_SPACE(length)  \
        (WSA_CMSGDATA_ALIGN(sizeof(WSACMSGHDR) + WSA_CMSGHDR_ALIGN(length)))
}

//
//  WSA_CMSG_LEN
//
//  Returns the value to store in cmsg_len given the amount of data.
//
//  SIZE_T
//  WSA_CMSG_LEN (
//      SIZE_T length
//  );
//

{ TODO
#define WSA_CMSG_LEN(length)    \
         (WSA_CMSGDATA_ALIGN(sizeof(WSACMSGHDR)) + length)
}

//
// Definition for flags member of the WSAMSG structure
// This is in addition to other MSG_xxx flags defined
// for recv/recvfrom/send/sendto.
//

const
  MSG_TRUNC     = $0100;
  {$EXTERNALSYM MSG_TRUNC}
  MSG_CTRUNC    = $0200;
  {$EXTERNALSYM MSG_CTRUNC}
  MSG_BCAST     = $0400;
  {$EXTERNALSYM MSG_BCAST}
  MSG_MCAST     = $0800;
  {$EXTERNALSYM MSG_MCAST}

type
  LPFN_WSARECVMSG = function(s: TSocket; lpMsg: LPWSAMSG; lpdwNumberOfBytesRecvd: LPDWORD; lpOverlapped: LPWSAOVERLAPPED;
    lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): Integer; stdcall;
  {$EXTERNALSYM LPFN_WSARECVMSG}

const
  WSAID_WSARECVMSG: TGUID = (
    D1: $f689d7c8; D2:$6f1f; D3:$436b; D4:($8a, $53, $e5, $4f, $e3, $51, $c3, $22));
  {$EXTERNALSYM WSAID_WSARECVMSG}

{$ENDIF JWA_IMPLEMENTATIONSECTION}




implementation


end.

