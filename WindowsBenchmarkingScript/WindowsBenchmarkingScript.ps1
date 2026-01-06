# Monitor-ProcessIO.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$ProcessName,
    [string]$OutputFile = "process_io.csv"
)

# Create CSV header
"Timestamp,ReadBytesPerSec,WriteBytesPerSec" | Out-File -FilePath $OutputFile -Encoding UTF8

$counters = @(
    "\Process($ProcessName)\IO Read Bytes/sec",
    "\Process($ProcessName)\IO Write Bytes/sec"
)

$pidFound = $false
$lastValidSamples = $null
while ($true) {
    try {
        $samples = (Get-Counter -Counter $counters -ErrorAction SilentlyContinue).CounterSamples
        
        # Find samples matching PID
        $pidSamples = $samples

        if ($pidSamples) {
            $readValue = ($pidSamples | Where-Object { $_.Path -like "*Read*" }).CookedValue
            $writeValue = ($pidSamples | Where-Object { $_.Path -like "*Write*" }).CookedValue

            if ($readValue -ge 0 -and $writeValue -ge 0) {
                $lastValidSamples = @($readValue, $writeValue)
                $pidFound = $true
            }
        }

        if ($pidFound) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $line = "$timestamp,$($lastValidSamples[0]),$($lastValidSamples[1])"
            $line | Out-File -FilePath $OutputFile -Encoding UTF8 -Append
            Write-Host "Collected: $line"
        } else {
            Write-Host "Process ID $ProcessId not found in performance counters. Retrying..."
        }
    }
    catch {
        Write-Host "Error: $_"
    }
    
    Start-Sleep -Seconds 5
}