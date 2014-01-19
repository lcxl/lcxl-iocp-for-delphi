object frmIOCPTest: TfrmIOCPTest
  Left = 0
  Top = 0
  Caption = 'IOCP V2'#25511#20214#27979#35797' by LCXL'
  ClientHeight = 332
  ClientWidth = 536
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pgcTotal: TPageControl
    Left = 0
    Top = 0
    Width = 536
    Height = 332
    ActivePage = tsHttpTest2
    Align = alClient
    TabOrder = 0
    object tsHttpTest2: TTabSheet
      Caption = 'HTTP'#27979#35797
      ImageIndex = 1
      DesignSize = (
        528
        304)
      object lblHttpNum: TLabel
        Left = 16
        Top = 38
        Width = 40
        Height = 13
        Caption = #35831#27714#25968':'
      end
      object edtURL: TEdit
        Left = 16
        Top = 8
        Width = 428
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
        TabOrder = 0
        Text = 'http://www.baidu.com'
      end
      object btnEnter: TButton
        Left = 450
        Top = 6
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = #25171#24320'(&O)'
        TabOrder = 1
        OnClick = btnEnterClick
      end
      object edtRequestNum: TEdit
        Left = 62
        Top = 35
        Width = 67
        Height = 21
        Alignment = taRightJustify
        ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
        TabOrder = 2
        Text = '10000'
      end
    end
  end
end
