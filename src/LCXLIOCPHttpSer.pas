unit LCXLIOCPHttpSer;

interface
uses
  Windows, Sysutils, Classes, LCXLIOCPBase, LCXLHttpComm, LCXLIOCPHttp;
(*
type

  TIOCPHttpServerList = class;

  THttpSerObj = class(THttpBaseObj)

  end;

  TOnServiceEvent = procedure(HttpObj: THttpSerObj) of object;

  TIOCPHttpServerList = class(TIOCPHttpBaseList)
  private
    FServiceEvent: TOnServiceEvent;
    procedure OnHTTPRecvCompleted(HttpObj: THttpBaseObj);
  public
    constructor Create(AIOCPMgr: TIOCPManager); override;

    property ServiceEvent: TOnServiceEvent read FServiceEvent write FServiceEvent;
  end;
*)
implementation

{ TIOCPHttpServerList }
(*
constructor TIOCPHttpServerList.Create(AIOCPMgr: TIOCPManager);
begin
  inherited;
  HTTPRecvCompletedEvent := OnHTTPRecvCompleted;
end;

procedure TIOCPHttpServerList.OnHTTPRecvCompleted(HttpObj: THttpBaseObj);
var
  _HttpObj: THttpSerObj absolute HttpObj;
begin
  if Assigned(FServiceEvent) then
  begin
    FServiceEvent(_HttpObj);
  end;
end;
 *)
end.
