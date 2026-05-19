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


Use-RunAs

$torrents = @()

$json = @(qbt torrent list -F json | convertfrom-json)

$json| Foreach-object{
    $object = "" | select Name,Hash,Ratio,Status,CompletedDate,Tags
    $object.Name = $_.name
    $object.Hash = $_.hash
    $object.Ratio = $_.ratio
    $object.Status = $_.state
    $object.CompletedDate = [TimeZone]::CurrentTimeZone.ToLocalTime((Get-Date "1970-01-01T00:00:00").AddSeconds($_.completion_on))
    $object.Tags = $_.tags
    
    $torrents += $object
}

$finishedTorrents = @()

Foreach($torrent in $torrents){
    if ($torrent.Status -match "stalledUp|uploading"){
        if ($torrent.Ratio -ge 1.5 -AND $torrent.Tags -contains "Immortal Seed") {$finishedTorrents += $torrent}
        elseif ($torrent.CompletedDate -lt $currentTime.AddHours(-25) -AND $torrent.Tags -contains "Immortal Seed") {$finishedTorrents += $torrent}
        elseif ($torrent.CompletedDate -lt $currentTime.AddHours(-337)) {$finishedTorrents += $torrent}
        elseif ($torrent.Ratio -ge 2.0) {$finishedTorrents += $torrent}
    }
}


Foreach($torrent in $finishedTorrents){

    qbt torrent delete -f $torrent.Hash
}
