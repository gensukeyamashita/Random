Attribute VB_Name = "ModuleODBC"

Function initializeOdbcConWithParam(conn As ADODB.Connection, DSN As String, username As String, password As String) As Boolean
    
    Set conn = CreateObject("ADODB.Connection")
    Dim helperDB As New helperDB
    
    helperDB.setDsn (DSN)
    helperDB.setUuid (username)
    helperDB.setPwd (password)
    conn.connectionString = helperDB.GetConnectionString()
    If conn.connectionString = "" Then
        initializeOdbcConWithParam = False
    Else
        initializeOdbcConWithParam = True
    End If

End Function

Function TestOdbcQuery(ByRef conn As ADODB.Connection, queryString As String) As Boolean

    On Error GoTo ErrorHandler
    conn.BeginTrans
    
    ' SQL statements
    conn.Execute ("Select * FROM Customers")
        
    conn.CommitTrans
    TestOdbcQuery = True
    Exit Function

ErrorHandler:
    Debug.Print "Query error: " & Err.Description
    conn.RollbackTrans
    TestOdbcQuery = False

End Function


