object frmVCLMemo: TfrmVCLMemo
  Left = 473
  Top = 109
  Width = 333
  Height = 213
  Caption = 'VCL������'
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = '�l�r �o�S�V�b�N'
  Font.Style = []
  Menu = mainMenu
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 12
  object memo: TMemo
    Left = 0
    Top = 0
    Width = 325
    Height = 167
    Align = alClient
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = '�l�r �o�S�V�b�N'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object actionList: TActionList
    Left = 52
    Top = 28
    object actFile: TAction
      Category = 'File'
      Caption = '�t�@�C��(&F)'
    end
    object actEdit: TAction
      Category = 'Edit'
      Caption = '�ҏW(&E)'
    end
    object actFormat: TAction
      Category = 'Format'
      Caption = '����(&O)'
    end
    object actHelp: TAction
      Category = 'Help'
      Caption = '�w���v(&H)'
    end
    object actFileNew: TAction
      Category = 'File'
      Caption = '�V�K(&N)'
      ShortCut = 16462
    end
    object actFileOpen: TAction
      Category = 'File'
      Caption = '�J��(&O)'
      ShortCut = 16463
    end
    object actFileSave: TAction
      Category = 'File'
      Caption = '�㏑���ۑ�(&S)'
      ShortCut = 16467
    end
    object actFileSaveAs: TAction
      Category = 'File'
      Caption = '���O��t���ĕۑ�(&A)...'
    end
    object actFilePage: TAction
      Category = 'File'
      Caption = '�y�[�W�ݒ�(&U)...'
    end
    object actFilePrint: TAction
      Category = 'File'
      Caption = '���(&P)...'
      ShortCut = 16464
    end
    object actFileClose: TAction
      Category = 'File'
      Caption = '�������̏I��(&X)'
    end
    object actEditUndo: TAction
      Category = 'Edit'
      Caption = '���ɖ߂�(&U)'
      ShortCut = 16474
    end
    object actEditCut: TAction
      Category = 'Edit'
      Caption = '�؂���(&T)'
      ShortCut = 16472
    end
    object actEditCopy: TAction
      Category = 'Edit'
      Caption = '�R�s�[(&C)'
      ShortCut = 16451
    end
    object actEditPaste: TAction
      Category = 'Edit'
      Caption = '�\��t��(&P)'
      ShortCut = 16470
    end
    object actEditDelete: TAction
      Category = 'Edit'
      Caption = '�폜(&L)'
      ShortCut = 46
    end
    object actEditFind: TAction
      Category = 'Edit'
      Caption = '����(&F)...'
      ShortCut = 16454
    end
    object actEditFindNext: TAction
      Category = 'Edit'
      Caption = '��������(&N)'
      ShortCut = 114
    end
    object actEditReplace: TAction
      Category = 'Edit'
      Caption = '�u��(&R)...'
      ShortCut = 16456
    end
    object actEditGoto: TAction
      Category = 'Edit'
      Caption = '�s�ֈړ�(&G)'
      ShortCut = 16455
    end
    object actEditSelectAll: TAction
      Category = 'Edit'
      Caption = '���ׂđI��(&A)'
      ShortCut = 16449
    end
    object actEditDateTime: TAction
      Category = 'Edit'
      Caption = '���t�Ǝ���(&D)'
      ShortCut = 116
    end
    object actFormatWordWrap: TAction
      Category = 'Format'
      Caption = '�E�[�Ő܂�Ԃ�(&W)'
    end
    object actFormatFont: TAction
      Category = 'Format'
      Caption = '�t�H���g(&F)...'
    end
    object actHelpTopic: TAction
      Category = 'Help'
      Caption = '�g�s�b�N�̌���(&H)'
    end
    object actHelpAbout: TAction
      Category = 'Help'
      Caption = '�o�[�W�������(&A)'
    end
  end
  object mainMenu: TMainMenu
    Left = 12
    Top = 28
    object actFile1: TMenuItem
      Action = actFile
      object N1: TMenuItem
        Action = actFileNew
      end
      object Open1: TMenuItem
        Action = actFileOpen
      end
      object Save1: TMenuItem
        Action = actFileSave
      end
      object SaveAs1: TMenuItem
        Action = actFileSaveAs
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object PrintSetup1: TMenuItem
        Action = actFilePage
      end
      object Print1: TMenuItem
        Action = actFilePrint
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object X1: TMenuItem
        Action = actFileClose
      end
    end
    object actEdit1: TMenuItem
      Action = actEdit
      object Undo1: TMenuItem
        Action = actEditUndo
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object Cut1: TMenuItem
        Action = actEditCut
      end
      object Cut2: TMenuItem
        Action = actEditCopy
      end
      object Paste1: TMenuItem
        Action = actEditPaste
      end
      object Delete1: TMenuItem
        Action = actEditDelete
      end
      object N5: TMenuItem
        Caption = '-'
      end
      object F1: TMenuItem
        Action = actEditFind
      end
      object FindNext1: TMenuItem
        Action = actEditFindNext
      end
      object Replace1: TMenuItem
        Action = actEditReplace
      end
      object G1: TMenuItem
        Action = actEditGoto
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object SelectAll1: TMenuItem
        Action = actEditSelectAll
      end
      object D1: TMenuItem
        Action = actEditDateTime
      end
    end
    object actFormat1: TMenuItem
      Action = actFormat
      object W1: TMenuItem
        Action = actFormatWordWrap
      end
      object Font1: TMenuItem
        Action = actFormatFont
      end
    end
    object actHelp1: TMenuItem
      Action = actHelp
      object SearchforHelpOn1: TMenuItem
        Action = actHelpTopic
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object About1: TMenuItem
        Action = actHelpAbout
      end
    end
  end
  object openDialog: TOpenDialog
    DefaultExt = 'txt'
    Filter = 'txt|*.txt|*.*|*.*'
    Title = '�J��'
    Left = 28
    Top = 76
  end
  object saveDialog: TSaveDialog
    DefaultExt = 'txt'
    Filter = 'txt|*.txt|*.*|*.*'
    Title = '�ۑ�'
    Left = 60
    Top = 76
  end
  object fontDialog: TFontDialog
    Font.Charset = SHIFTJIS_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = '�l�r �o�S�V�b�N'
    Font.Style = []
    MinFontSize = 0
    MaxFontSize = 0
    Left = 92
    Top = 80
  end
end
