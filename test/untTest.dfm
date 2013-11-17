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
    object tsBaseTest: TTabSheet
      Caption = 'Base'#21327#35758#27979#35797
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object pgc1: TPageControl
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 522
        Height = 62
        ActivePage = tsClient
        Align = alTop
        TabOrder = 0
        object tsSer: TTabSheet
          Caption = #26381#21153#31471
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          DesignSize = (
            514
            34)
          object lblSerPort: TLabel
            Left = 338
            Top = 8
            Width = 36
            Height = 13
            Anchors = [akTop, akRight]
            Caption = #31471#21475#65306
          end
          object edtSerPort: TEdit
            Left = 372
            Top = 5
            Width = 49
            Height = 21
            Alignment = taRightJustify
            Anchors = [akTop, akRight]
            ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
            NumbersOnly = True
            TabOrder = 0
            Text = '1818'
          end
          object btnListen: TButton
            Left = 436
            Top = 3
            Width = 75
            Height = 25
            Anchors = [akTop, akRight]
            Caption = #30417#21548'(&S)'
            TabOrder = 1
            OnClick = btnListenClick
          end
          object btnLocalIP: TButton
            Left = 3
            Top = 3
            Width = 75
            Height = 25
            Caption = #26412#26426'IP'
            TabOrder = 2
            OnClick = btnLocalIPClick
          end
        end
        object tsClient: TTabSheet
          Caption = #23458#25143#31471
          ImageIndex = 1
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          DesignSize = (
            514
            34)
          object lblPort: TLabel
            Left = 347
            Top = 8
            Width = 36
            Height = 13
            Anchors = [akTop, akRight]
            Caption = #31471#21475#65306
          end
          object lblIP: TLabel
            Left = 3
            Top = 8
            Width = 46
            Height = 13
            Caption = 'IP'#22320#22336#65306
          end
          object lblNum: TLabel
            Left = 239
            Top = 8
            Width = 60
            Height = 13
            Anchors = [akTop, akRight]
            Caption = #36830#25509#25968#37327#65306
          end
          object edtPort: TEdit
            Left = 381
            Top = 5
            Width = 49
            Height = 21
            Anchors = [akTop, akRight]
            ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
            NumbersOnly = True
            TabOrder = 0
            Text = '1818'
          end
          object btnConnect: TButton
            Left = 436
            Top = 3
            Width = 75
            Height = 25
            Anchors = [akTop, akRight]
            Caption = #36830#25509'(&C)'
            TabOrder = 1
            OnClick = btnConnectClick
          end
          object edtIP: TEdit
            Left = 55
            Top = 5
            Width = 175
            Height = 21
            Anchors = [akLeft, akTop, akRight]
            ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
            TabOrder = 2
            Text = '127.0.0.1'
          end
          object edtSockNum: TEdit
            Left = 305
            Top = 5
            Width = 36
            Height = 21
            Anchors = [akTop, akRight]
            ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
            NumbersOnly = True
            TabOrder = 3
            Text = '1000'
          end
        end
        object tsSend: TTabSheet
          Caption = #21457#36865
          ImageIndex = 2
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          DesignSize = (
            514
            34)
          object btnSend: TButton
            Left = 413
            Top = 6
            Width = 75
            Height = 25
            Anchors = [akTop, akRight]
            Caption = #21457#36865
            TabOrder = 0
            OnClick = btnSendClick
          end
          object chkLoopSend: TCheckBox
            Left = 310
            Top = 10
            Width = 97
            Height = 17
            Caption = #24490#29615#21457#36865
            TabOrder = 1
            OnClick = chkLoopSendClick
          end
        end
      end
      object pgc2: TPageControl
        AlignWithMargins = True
        Left = 3
        Top = 71
        Width = 522
        Height = 211
        ActivePage = tsSocket
        Align = alClient
        TabOrder = 1
        object tsSocket: TTabSheet
          Caption = #36830#25509#21015#34920
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object lvSocket: TListView
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 508
            Height = 177
            Align = alClient
            Columns = <
              item
                Caption = #24207#21495
                Width = 100
              end
              item
                Caption = #36828#31243#22320#22336
                Width = 150
              end
              item
                Caption = #36828#31243#31471#21475#21495
                Width = 100
              end
              item
                Caption = #31867#22411
                Width = 100
              end>
            MultiSelect = True
            OwnerData = True
            ReadOnly = True
            RowSelect = True
            PopupMenu = pmSockObj
            TabOrder = 0
            ViewStyle = vsReport
            OnData = lvSocketData
          end
        end
        object tssocklst: TTabSheet
          Caption = #30417#21548#21015#34920
          ImageIndex = 1
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object lvSockLst: TListView
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 508
            Height = 177
            Align = alClient
            Columns = <
              item
                Caption = #24207#21495
              end
              item
                Caption = #30417#21548#31471#21475
                Width = 100
              end>
            MultiSelect = True
            OwnerData = True
            ReadOnly = True
            RowSelect = True
            PopupMenu = pmSockLst
            TabOrder = 0
            ViewStyle = vsReport
            OnData = lvSockLstData
          end
        end
      end
      object statMain: TStatusBar
        Left = 0
        Top = 285
        Width = 528
        Height = 19
        Panels = <>
        SimplePanel = True
      end
    end
    object tsLCXLTest: TTabSheet
      Caption = 'LCXL'#21327#35758#27979#35797
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
    object tsCmdTest: TTabSheet
      Caption = 'CMD'#21327#35758#27979#35797
      ImageIndex = 4
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
    end
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
    object tsSendContent: TTabSheet
      Caption = #21457#36865#20869#23481
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grpSendOpt: TGroupBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 522
        Height = 182
        Align = alTop
        Caption = #21457#36865#36873#39033
        TabOrder = 0
        DesignSize = (
          522
          182)
        object lblFileInfo: TLabel
          Left = 135
          Top = 25
          Width = 3
          Height = 13
        end
        object rbSendFile: TRadioButton
          Left = 16
          Top = 24
          Width = 113
          Height = 17
          Caption = #21457#36865#25991#20214#20869#23481
          TabOrder = 0
          OnClick = rbSendFileClick
        end
        object rbSendText: TRadioButton
          Left = 16
          Top = 47
          Width = 113
          Height = 17
          Caption = #21457#36865#25991#26412#20869#23481
          Checked = True
          TabOrder = 1
          TabStop = True
        end
        object mmoSendText: TMemo
          Left = 16
          Top = 70
          Width = 489
          Height = 99
          Anchors = [akLeft, akTop, akRight, akBottom]
          ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          Lines.Strings = (
            #27979#35797#65311#65311#65311)
          TabOrder = 2
        end
      end
    end
    object tsTimeTest: TTabSheet
      Caption = #26102#38388#31283#23450#24615#27979#35797
      ImageIndex = 5
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object chtTime: TChart
        AlignWithMargins = True
        Left = 3
        Top = 63
        Width = 522
        Height = 238
        Title.Text.Strings = (
          #26102#38388#26354#32447)
        BottomAxis.LabelsFormat.TextAlignment = taCenter
        DepthAxis.LabelsFormat.TextAlignment = taCenter
        DepthTopAxis.LabelsFormat.TextAlignment = taCenter
        LeftAxis.LabelsFormat.TextAlignment = taCenter
        RightAxis.LabelsFormat.TextAlignment = taCenter
        TopAxis.LabelsFormat.TextAlignment = taCenter
        View3D = False
        Zoom.Pen.Mode = pmNotXor
        Align = alClient
        TabOrder = 0
        DefaultCanvas = 'TGDIPlusCanvas'
        PrintMargins = (
          15
          19
          15
          19)
        ColorPaletteIndex = 13
      end
      object grpTime: TGroupBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 522
        Height = 54
        Align = alTop
        Caption = #36873#39033
        TabOrder = 1
        DesignSize = (
          522
          54)
        object lbl1: TLabel
          Left = 11
          Top = 19
          Width = 46
          Height = 13
          Caption = 'IP'#22320#22336#65306
        end
        object lbl2: TLabel
          Left = 259
          Top = 19
          Width = 36
          Height = 13
          Anchors = [akTop, akRight]
          Caption = #31471#21475#65306
        end
        object btnTimeTestStart: TButton
          Left = 432
          Top = 16
          Width = 75
          Height = 25
          Anchors = [akTop, akRight]
          Caption = #24320#22987#27979#35797
          TabOrder = 0
          OnClick = btnTimeTestStartClick
        end
        object edtTestTimeIP: TEdit
          Left = 63
          Top = 16
          Width = 175
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          TabOrder = 1
          Text = '127.0.0.1'
        end
        object edtTestTimeIPPort: TEdit
          Left = 301
          Top = 16
          Width = 49
          Height = 21
          Anchors = [akTop, akRight]
          ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
          NumbersOnly = True
          TabOrder = 2
          Text = '1818'
        end
      end
    end
  end
  object tmr1: TTimer
    OnTimer = tmr1Timer
    Left = 480
    Top = 288
  end
  object pmSockObj: TPopupMenu
    Left = 400
    Top = 288
    object mniCloseSockObj: TMenuItem
      Caption = #20851#38381'(&C)'
      OnClick = mniCloseSockObjClick
    end
  end
  object pmSockLst: TPopupMenu
    Left = 440
    Top = 288
    object mniCloseSockLst: TMenuItem
      Caption = #20851#38381'(&C)'
      OnClick = mniCloseSockLstClick
    end
  end
  object dlgOpenFile: TOpenDialog
    Left = 368
    Top = 288
  end
end
