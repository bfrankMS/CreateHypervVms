$tmpDir = "c:\temp\" 

#create folder if it doesn't exist
if (!(Test-Path $tmpDir)) { mkdir $tmpDir -Force }

"I was run at $(Get-Date)" | Out-File "$tmpDir\step_AddDateTimeToLog.log" -Force -Append