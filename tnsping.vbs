' VBScript to run tnsping on a list of service names and output results to HTML

Dim fso, inputFile, outputFile, line, shell, outputHTML, timestamp, currentUser, hostname
Dim service, host, command, result

' Set file paths
inputFilePath = "service_name_ora.txt"
outputFilePath = "tnsping_results.html"

' Create FileSystemObject
Set fso = CreateObject("Scripting.FileSystemObject")

' Create Shell object
Set shell = CreateObject("WScript.Shell")

' Get current user and hostname
currentUser = shell.ExpandEnvironmentStrings("%USERNAME%")
hostname = shell.ExpandEnvironmentStrings("%COMPUTERNAME%")

' Open the input file
Set inputFile = fso.OpenTextFile(inputFilePath, 1) ' 1 = ForReading

' Prepare the output HTML file
Set outputFile = fso.CreateTextFile(outputFilePath, True) ' True = Overwrite
outputHTML = "<html><body><table border='1'><tr><th>Date</th><th>Hour</th><th>ServiceName</th><th>Hostname</th><th>WindowsUserID</th><th>Host</th></tr>"

' Read input file and process each line
Do While Not inputFile.AtEndOfStream
    line = inputFile.ReadLine
    timestamp = Now
    service = Trim(line)

    ' Run tnsping and capture the output
    command = "tnsping " & service
    Set exec = shell.Exec(command)
    Do While exec.Status = 0
        WScript.Sleep 100
    Loop
    result = exec.StdOut.ReadAll

    ' Find hostname in the result (modify this part as needed based on your tnsping output format)
    host = "Unknown" ' Default value
    If InStr(result, "HOST=") > 0 Then
        hostStart = InStr(result, "HOST=") + 5
        hostEnd = InStrMid(result, ")", hostStart)
        host = Mid(result, hostStart, hostEnd - hostStart)
    End If

    ' Append result to HTML
    outputHTML = outputHTML & "<tr><td>" & DateValue(timestamp) & "</td><td>" & TimeValue(timestamp) & "</td>"
    outputHTML = outputHTML & "<td>" & service & "</td><td>" & host & "</td><td>" & currentUser & "</td><td>" & hostname & "</td></tr>"
Loop

' Close input file
inputFile.Close

' Finalize HTML and write to output file
outputHTML = outputHTML & "</table></body></html>"
outputFile.Write(outputHTML)

' Close output file
outputFile.Close

' Clean up
Set fso = Nothing
Set shell = Nothing
Set inputFile = Nothing
Set outputFile = Nothing
