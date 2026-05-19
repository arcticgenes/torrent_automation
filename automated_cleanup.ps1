# User CLI found at https://github.com/fedarovich/qbittorrent-cli/wiki/Getting-Started

$currentTime = Get-Date

function Use-RunAs {    
    # Check if script is running as Adminstrator and if not use RunAs 
    # Use Check Switch to check if admin 
     
    param([Switch]$Check) 
     
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()` 
        ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator") 
         
    if ($Check) { return $IsAdmin }     
 
    if ($MyInvocation.ScriptName -ne "") {  
        if (-not $IsAdmin) {  
            try {  
                $arg = "-file `"$($MyInvocation.ScriptName)`"" 
                Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
            } 
            catch { 
                Write-Warning "Error - Failed to restart script with runas"  
                break               
            } 
            exit # Quit this session of powershell 
        }  
    }  
    else {  
        Write-Warning "Error - Script must be saved as a .ps1 file first"  
        break  
    }  
} 

function Convert-TimeStamp {
	param([int]$timestamp)
	
	[TimeZone]::CurrentTimeZone.ToLocalTime((Get-Date "1970-01-01T00:00:00").AddSeconds($timestamp))
	
}


Use-RunAs

$torrents = @(qbt torrent list -F json | convertfrom-json)

$finishedTorrents = @()

Foreach($torrent in $torrents){
    if ($torrent.state -match "stalledUp|uploading"){
        if ($torrent.ratio -ge 1.5 -AND $torrent.tags -contains "Immortal Seed") {$finishedTorrents += $torrent}
        elseif ((Convert-TimeStamp($torrent.completion_on)) -lt $currentTime.AddHours(-25) -AND $torrent.tags -contains "Immortal Seed") {$finishedTorrents += $torrent}
        elseif ((Convert-TimeStamp($torrent.completion_on)) -lt $currentTime.AddHours(-337)) {$finishedTorrents += $torrent}
        elseif ($torrent.ratio -ge 2.0) {$finishedTorrents += $torrent}
    }
}


Foreach($torrent in $finishedTorrents){

    qbt torrent delete -f $torrent.Hash
}
