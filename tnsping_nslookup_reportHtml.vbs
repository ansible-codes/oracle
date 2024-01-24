Const ForReading = 1
Const ForWriting = 2
Dim shell, fso, tnspingOutput, nslookupOutput, dbName, host, port, ip, htmlContent, dbFile, dbNames, progressMessage, i

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Check if dbnames.txt exists
If Not fso.FileExists("dbnames.txt") Then
    WScript.Echo "dbnames.txt not found."
    WScript.Quit
End If

' Read dbnames.txt file
Set dbFile = fso.OpenTextFile("dbnames.txt", ForReading)
dbNames = Split(dbFile.ReadAll, vbCrLf)
dbFile.Close

' Start HTML content
htmlContent = "<html><body><table border='1'><tr><th>DB Name</th><th>HOST</th><th>PORT</th><th>HOST IP</th></tr>"

For i = 0 To UBound(dbNames)
    dbName = dbNames(i)

    ' Update and show progress
    progressMessage = "Processing Databases:" & vbCrLf
    For j = 0 To UBound(dbNames)
        If j = i Then
            progressMessage = progressMessage & dbNames(j) & " ******" & vbCrLf
        Else
            progressMessage = progressMessage & dbNames(j) & vbCrLf
        End If
    Next
    shell.Popup progressMessage, 2, "Progress", 64

    ' Executing tnsping
    Set tnspingExec = shell.Exec("tnsping " & dbName)
    tnspingOutput = tnspingExec.StdOut.ReadAll()

    ' Parsing the tnsping output to find HOST and PORT
    host = ParseValue(tnspingOutput, "HOST=")
    port = ParseValue(tnspingOutput, "PORT=")

    If host <> "" Then
        ' Executing nslookup
        Set nslookupExec = shell.Exec("cmd /c nslookup " & host)
        nslookupOutput = nslookupExec.StdOut.ReadAll()

        ' Parsing the nslookup output to find IP addresses
        ip = ParseIPs(nslookupOutput)
    Else
        ip = "Host not found"
    End If

    ' Adding row to HTML content
    htmlContent = htmlContent & "<tr><td>" & dbName & "</td><td>" & host & "</td><td>" & port & "</td><td>" & ip & "</td></tr>"
Next

' Finish HTML content
htmlContent = htmlContent & "</table></body></html>"

' Writing to an HTML file
Dim htmlFile
Set htmlFile = fso.OpenTextFile("tnsping_nslookup_report_output.html", ForWriting, True)
htmlFile.Write(htmlContent)
htmlFile.Close

Function ParseValue(output, key)
    Dim lines, line, startPos, endPos
    lines = Split(output, vbCrLf)
    ParseValue = ""
    For Each line in lines
        If InStr(line, key) > 0 Then
            startPos = InStr(line, key) + Len(key)
            endPos = InStr(startPos, line, ")") - startPos
            ParseValue = Mid(line, startPos, endPos)
            Exit Function
        End If
    Next
End Function

Function ParseIPs(output)
    Dim lines, line, foundNonAuthAnswer, ipList
    lines = Split(output, vbCrLf)
    ParseIPs = ""
    foundNonAuthAnswer = False

    For Each line in lines
        If InStr(line, "Non-authoritative answer") > 0 Then
            foundNonAuthAnswer = True
        ElseIf foundNonAuthAnswer Then
            If InStr(line, "Address:") > 0 Then
                ipList = ipList & Trim(Mid(line, InStr(line, "Address:") + 9)) & ", "
            End If
        End If
    Next

    If Len(ipList) > 0 Then
        ' Remove trailing comma and space
        ParseIPs = Left(ipList, Len(ipList) - 2)
    End If
End Function
