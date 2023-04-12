VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "HelperDB"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Private conn As New ADODB.Connection
Private pwd As String
Private uuid As String
Private DSN As String

Sub setDsn(str As String)
    DSN = str
End Sub

Sub setPwd(str As String)
    pwd = str
End Sub

Sub setUuid(str As String)
    uuid = str
End Sub

Function GetConnectionString() As String
    Dim connectionString As String
    connectionString = "DSN=" & DSN & ";" & _
                          "Uuid=" & uuid & ";" & _
                          "Pwd=" & pwd & ";"
                          
                          Debug.Print connectionString
                          
    If TestConnectionString(connectionString) Then
        GetConnectionString = connectionString
    Else
        GetConnectionString = ""
    End If

End Function

Public Function TestConnectionString(str As String) As Boolean

    On Error GoTo ErrorHandler
    Dim conn As New ADODB.Connection
    
    conn.connectionString = str
    conn.Open
    conn.Close
    TestConnectionString = True
    Exit Function
    
ErrorHandler:
    Debug.Print "Error connecting to database: " & Err.Description
    TestConnectionString = False

End Function
