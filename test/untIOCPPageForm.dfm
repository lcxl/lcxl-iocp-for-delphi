object frmIOCPPageForm: TfrmIOCPPageForm
  Left = 0
  Top = 0
  Align = alClient
  BorderStyle = bsNone
  Caption = 'frmIOCPPageForm'
  ClientHeight = 317
  ClientWidth = 519
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pgc1: TPageControl
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 513
    Height = 62
    ActivePage = tsSer
    Align = alTop
    TabOrder = 0
    object tsSer: TTabSheet
      Caption = #26381#21153#31471
      DesignSize = (
        505
        34)
      object lblSerPort: TLabel
        Left = 329
        Top = 8
        Width = 36
        Height = 13
        Anchors = [akTop, akRight]
        Caption = #31471#21475#65306
        ExplicitLeft = 338
      end
      object edtSerPort: TEdit
        Left = 363
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
        Left = 427
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
      DesignSize = (
        505
        34)
      object lblPort: TLabel
        Left = 338
        Top = 8
        Width = 36
        Height = 13
        Anchors = [akTop, akRight]
        Caption = #31471#21475#65306
        ExplicitLeft = 347
      end
      object lblIP: TLabel
        Left = 3
        Top = 8
        Width = 46
        Height = 13
        Caption = 'IP'#22320#22336#65306
      end
      object lblNum: TLabel
        Left = 230
        Top = 8
        Width = 60
        Height = 13
        Anchors = [akTop, akRight]
        Caption = #36830#25509#25968#37327#65306
        ExplicitLeft = 239
      end
      object edtPort: TEdit
        Left = 372
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
        Left = 427
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
        Width = 166
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
        TabOrder = 2
        Text = '127.0.0.1'
      end
      object edtSockNum: TEdit
        Left = 296
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
      DesignSize = (
        505
        34)
      object lblFileInfo: TLabel
        Left = 111
        Top = 11
        Width = 60
        Height = 13
        Caption = #26410#36873#25321#25991#20214
      end
      object btnSend: TButton
        Left = 404
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
      object btnLoadSendFile: TButton
        Left = 3
        Top = 6
        Width = 102
        Height = 25
        Caption = #36873#25321#21457#36865#25991#20214
        TabOrder = 2
        OnClick = btnLoadSendFileClick
      end
    end
  end
  object pgc2: TPageControl
    AlignWithMargins = True
    Left = 3
    Top = 71
    Width = 513
    Height = 224
    ActivePage = tssocklst
    Align = alClient
    TabOrder = 1
    object tsSocket: TTabSheet
      Caption = #36830#25509#21015#34920
      object lvSocket: TListView
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 499
        Height = 190
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
      object lvSockLst: TListView
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 499
        Height = 190
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
    Top = 298
    Width = 519
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object tmrRefreshStatus: TTimer
    OnTimer = tmrRefreshStatusTimer
    Left = 456
    Top = 200
  end
  object dlgOpenFile: TOpenDialog
    Left = 336
    Top = 200
  end
  object pmSockObj: TPopupMenu
    Left = 368
    Top = 200
    object mniCloseSockObj: TMenuItem
      Caption = #20851#38381'(&C)'
      OnClick = mniCloseSockObjClick
    end
  end
  object pmSockLst: TPopupMenu
    Left = 408
    Top = 200
    object mniCloseSockLst: TMenuItem
      Caption = #20851#38381'(&C)'
      OnClick = mniCloseSockLstClick
    end
  end
end
