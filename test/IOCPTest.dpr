program IOCPTest;

uses
  Forms,
  untTest in 'untTest.pas' {frmIOCPTest};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmIOCPTest, frmIOCPTest);
  Application.Run;
end.
