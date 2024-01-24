Const ForReading = 1
Const ForWriting = 2
Dim shell, fso, tnspingOutput, nslookupOutput, dbName, host, ip, htmlContent, dbFile, dbLine

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Check if dbnames.txt exists
If Not fso.FileExists("dbnames.txt") Then
    WScript.Echo "dbnames.txt not found."
    WScript.Quit
End If

' Read dbnames.txt file
Set dbFile = fso.OpenTextFile("dbnames.txt", ForReading)

' Start HTML content
htmlContent = "<html><body><table border='1'><tr><th>DB Name</th><th>HOST</th><th>HOST IP</th></tr>"

Do Until dbFile.AtEndOfStream
    dbName = dbFile.ReadLine

    ' Executing tnsping
    Set tnspingExec = shell.Exec("tnsping " & dbName)
    tnspingOutput = tnspingExec.StdOut.ReadAll()

    ' Parsing the tnsping output to find HOST
    host = ParseHost(tnspingOutput)

    ' Executing nslookup
    Set nslookupExec = shell.Exec("nslookup " & host)
    nslookupOutput = nslookupExec.StdOut.ReadAll()

    ' Parsing the nslookup output to find IP address
    ip = ParseIP(nslookupOutput)

    ' Adding row to HTML content
    htmlContent = htmlContent & "<tr><td>" & dbName & "</td><td>" & host & "</td><td>" & ip & "</td></tr>"
Loop

' Finish HTML content
htmlContent = htmlContent & "</table></body></html>"

' Close dbnames.txt
dbFile.Close

' Writing to an HTML file
Dim htmlFile
Set htmlFile = fso.OpenTextFile("output.html", ForWriting, True)
htmlFile.Write(htmlContent)
htmlFile.Close

Function ParseHost(output)
    Dim lines, line, startPos, endPos
    lines = Split(output, vbCrLf)
    ParseHost = ""
    For Each line in lines
        If InStr(line, "HOST=") > 0 Then
            startPos = InStr(line, "HOST=") + 5
            endPos = InStr(startPos, line, ")") - startPos
            ParseHost = Mid(line, startPos, endPos)
            Exit Function
        End If
    Next
End Function

Function ParseIP(output)
    Dim lines, line
    lines = Split(output, vbCrLf)
    ParseIP = ""
    For Each line in lines
        If InStr(line, "Address:") > 0 Then
            ParseIP = Trim(Mid(line, InStr(line, "Address:") + 9))
            Exit Function
        End If
    Next
End Function
