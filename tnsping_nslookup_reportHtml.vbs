Const ForReading = 1
Const ForWriting = 2
Dim shell, fso, tnspingOutput, nslookupOutput, dbName, host, port, ip, htmlContent, dbFile, dbNames, progressMessage, i, fileName, dbSet

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Start HTML content
htmlContent = "<html><body>"

' Process each file
For Each fileName In Array("griffinDBnames.txt", "griffinAnalyticsDBnames.txt")
    If Not fso.FileExists(fileName) Then
        WScript.Echo fileName & " not found."
        WScript.Quit
    End If

    ' Initialize a dictionary to track unique db names
    Set dbSet = CreateObject("Scripting.Dictionary")

    ' Read dbnames file
    Set dbFile = fso.OpenTextFile(fileName, ForReading)
    dbNames = Split(dbFile.ReadAll, vbCrLf)
    dbFile.Close

    ' Validate and filter dbNames
    For i = LBound(dbNames) To UBound(dbNames)
        dbName = Trim(dbNames(i))
        If Len(dbName) = 0 Then
            WScript.Echo "Empty or blank line found in " & fileName & "."
            WScript.Quit
        ElseIf dbSet.Exists(dbName) Then
            WScript.Echo "Duplicate DB name found: " & dbName & " in " & fileName & "."
            WScript.Quit
        Else
            dbSet.Add dbName, True
        End If
    Next

    ' Add table title and header
    htmlContent = htmlContent & "<h3>" & fileName & "</h3>"
    htmlContent = htmlContent & "<table id='" & fileName & "' border='1'><tr><th>DB Name</th><th>HOST</th><th>PORT</th><th>HOST IP</th></tr>"

    ' Process each dbName
    For Each dbName In dbSet.Keys

        ' Update and show progress
        progressMessage = "Processing " & fileName & ": " & vbCrLf & dbName & " ******" & vbCrLf
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

            ' Parsing the nslookup output to find the second IP address
            ip = ParseSecondIP(nslookupOutput)
        Else
            ip = "Host not found"
        End If

        ' Adding row to HTML content
        htmlContent = htmlContent & "<tr><td>" & dbName & "</td><td>" & host & "</td><td>" & port & "</td><td>" & ip & "</td></tr>"
    Next

    ' Close table
    htmlContent = htmlContent & "</table><br>"
Next

' Add copy button
htmlContent = htmlContent & "<button onclick='copyTables()'>Copy Tables</button>"

' Add script to copy tables content
htmlContent = htmlContent & "<script>"
htmlContent = htmlContent & "function copyTables() {"
htmlContent = htmlContent & "    var range = document.createRange();"
htmlContent = htmlContent & "    range.selectNode(document.body);"
htmlContent = htmlContent & "    window.getSelection().removeAllRanges();"
htmlContent = htmlContent & "    window.getSelection().addRange(range);"
htmlContent = htmlContent & "    document.execCommand('copy');"
htmlContent = htmlContent & "    alert('Tables copied!');"
htmlContent = htmlContent & "}"
htmlContent = htmlContent & "</script>"

' Finish HTML content
htmlContent = htmlContent & "</body></html>"

' Writing to an HTML file
Dim htmlFile
Set htmlFile = fso.OpenTextFile("output.html", ForWriting, True)
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

Function ParseSecondIP(output)
    Dim lines, line, addressCount
    lines = Split(output, vbCrLf)
    ParseSecondIP = ""
    addressCount = 0

    For Each line in lines
        If InStr(line, "Address:") > 0 Then
            addressCount = addressCount + 1
            If addressCount = 2 Then
                ParseSecondIP = Trim(Mid(line, InStr(line, "Address:") + 9))
                Exit Function
            End If
        End If
    Next
End Function
