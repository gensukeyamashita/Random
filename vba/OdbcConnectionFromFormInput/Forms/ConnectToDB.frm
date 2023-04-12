VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ConnectToDB 
   Caption         =   "ConnectToDB"
   ClientHeight    =   3390
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   3675
   OleObjectBlob   =   "ConnectToDB.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "ConnectToDB"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Sub Clear_Click()
    Debug.Print "Clear button clicked"
    
    Debug.Print TextBoxDSN.Value
    TextBoxDSN.Value = ""
    TextBoxUsername.Value = ""
    TextBoxPassword.Value = ""
End Sub

Private Sub Connect_Click()
    Debug.Print "Connect button clicked"
    
    Dim conn As ADODB.Connection
    
    Debug.Print TextBoxUsername.Value
    
    Debug.Print TextBoxDSN.Value
    
    Debug.Print TextBoxPassword.Value
    
    If initializeOdbcConWithParam(conn, TextBoxDSN.Value, TextBoxUsername.Value, TextBoxPassword.Value) = True Then
        Debug.Print "Initialized with parameters"
    Else
        Debug.Print "Initialization failed"
    End If
    
    conn.Open
    conn.Close
    
End Sub


Private Sub TextBoxDSN_Change()

    If Not TextBoxDSN = "" And Not TextBoxPassword = "" And Not TextBoxUsername = "" Then
        Connect.Enabled = True
    ElseIf TextBoxDSN = "" Or TextBoxPassword = "" Or TextBoxUsername = "" Then
        Connect.Enabled = False
    End If
    
End Sub

Private Sub TextBoxUsername_Change()

    If Not TextBoxDSN = "" And Not TextBoxPassword = "" And Not TextBoxUsername = "" Then
        Connect.Enabled = True
    ElseIf TextBoxDSN = "" Or TextBoxPassword = "" Or TextBoxUsername = "" Then
        Connect.Enabled = False
    End If
    
End Sub

Private Sub TextBoxPassword_Change()

    If Not TextBoxDSN = "" And Not TextBoxPassword = "" And Not TextBoxUsername = "" Then
        Connect.Enabled = True
    ElseIf TextBoxDSN = "" Or TextBoxPassword = "" Or TextBoxUsername = "" Then
        Connect.Enabled = False
    End If
    
End Sub


