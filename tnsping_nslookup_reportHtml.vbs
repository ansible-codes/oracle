Const ForReading = 1
Const ForWriting = 2
Dim shell, fso, tnspingOutput, nslookupOutput, dbName, host, ip, htmlContent, dbFile, progressBox

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

    ' Show progress
    Set progressBox = CreateObject("WScript.Shell")
    progressBox.Popup "Processing: " & dbName, 2, "Progress", 64

    ' Executing tnsping
    Set tnspingExec = shell.Exec("tnsping " & dbName)
    tnspingOutput = tnspingExec.StdOut.ReadAll()

    ' Parsing the tnsping output to find HOST
    host = ParseHost(tnspingOutput)
    If host <> "" Then
        ' Executing nslookup
        Set nslookupExec = shell.Exec("cmd /c nslookup " & host)
        nslookupOutput = nslookupExec.StdOut.ReadAll()

        ' Parsing the nslookup output to find the second IP address
        ip = ParseIP(nslookupOutput)
    Else
        ip = "Host not found"
    End If

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
    Dim lines, line, ipCount
    lines = Split(output, vbCrLf)
    ParseIP = ""
    ipCount = 0

    For Each line in lines
        If InStr(line, "Address:") > 0 Then
            ipCount = ipCount + 1
            If ipCount = 2 Then ' Get the second IP
                ParseIP = Trim(Mid(line, InStr(line, "Address:") + 9))
                Exit Function
            End If
        End If
    Next
End Function
