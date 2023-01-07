 param (
[String]$server,
[String]$port,
[String]$user,
[String]$pass
)

[String]$Script:UtorrentUrl = "http://$server`:$port/gui/"
[String]$Script:token = ""
$Script:webClient = $null

$baseDate = [datetime]'1/1/1970'
$currentTime = Get-Date
$baseFolder = "E:\Torrents\Finished"



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

function Utorrent-HttpGet {
    param (
    [string]$Command
    )

    if ([string]::IsNullOrEmpty($Script:token) -eq $true -or $Script:webClient -eq $null) {
        $Script:webClient = new-object System.Net.WebClient
        $Script:webClient.Headers.Add("user-agent", "PowerShell Script")
     
        if ([string]::IsNullOrEmpty($User) -eq $false) {
            $Script:webClient.Credentials = new-object System.Net.NetworkCredential($User, $Pass)
        }
 
        $tokenResponse = $Script:webClient.DownloadString($Script:UtorrentUrl + "token.html")
        [string]$cookies =  $Script:webClient.ResponseHeaders["Set-Cookie"]
 
        if ($tokenResponse  -match ".*<div[^>]*id=[`"`']token[`"`'][^>]*>([^<]*)</div>.*") {
            $Script:token = $matches[1]
            $Script:webClient.Headers.Add("Cookie", $cookies)
        }
    }
    $url = "$($UtorrentUrl)?$($Command)&token=$($Script:token)"
    Write-Host ("Calling url`t$url")
    $response = $Script:webClient.DownloadString($url)
    $json = ConvertFrom-JSON $response
    if($json.build -ne $null) {
        Write-Host ("Success $($json.build)")
    }
    return $json
}

function Remove-Torrents {
    param (
        $finishedTorrents
    )
    foreach($torrent in $finishedTorrents){
        Utorrent-HttpGet "action=removedata&hash=$($torrent.Hash)"
    }

    sleep -s 10

    foreach($torrent in $finishedTorrents){
        if($torrent.File){
            Remove-item -Path $torrent.File -Recurse -Force -Confirm:$false
        }
    }
}

Use-RunAs

$torrents = @()
$finishedTorrents = @()

$json = Utorrent-HttpGet "list=1"
$json.torrents | Foreach-object{
    $object = "" | select Name,Hash,Ratio,Status,Added_On,Label,File
    $object.Name = $_[2] 
    $object.Hash = $_[0]
    $object.Ratio = ($_[7]/1000)
    $object.Status = $_[21]
    $object.Added_On = ([TimeZone]::CurrentTimeZone.ToLocalTime($basedate.AddSeconds($_[23])))
    $object.Label = $_[11]
     $object.File = $_[26]
    if ($_[26] -eq $baseFolder){
        $object.File = ""
    }   
    $torrents += $object
}

Foreach($torrent in $torrents){
    if ($torrent.Status -match "Seeding"){
        if ($torrent.Ratio -ge 1.5 -AND $torrent.Label -match "Immortal Seed") {$finishedTorrents += $torrent}
        if ($torrent.Added_On -lt $currentTime.AddHours(-25) -AND $torrent.Label -match "Immortal Seed") {$finishedTorrents += $torrent}
        if ($torrent.Added_On -lt $currentTime.AddHours(-337)) {$finishedTorrents += $torrent}
        if ($torrent.Ratio -ge 2.0) {$finishedTorrents += $torrent}
    }
}

Remove-Torrents $finishedTorrents 
