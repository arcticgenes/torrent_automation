param(
	[string]$file = "", 
	[string]$dir = "",
	[string]$title = "",
	[string]$state = "",
	[string]$kind = ""
	)
  
<#
 
  How to call from utorrent
	called from Completed
	  C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy unrestricted -file "E:\Scripts\utorrent_amc.ps1" -file "%F" -dir "%D" -title "%N" -state "%S" -kind "%K"
 
#>

$Filebot = "C:\Program Files\Filebot\filebot.exe"
$plexIP = "10.10.0.40"
$nasFolder = "\\arcticnas\NAS_Storage"

if ($kind -match "multi"){
	if (-not (gci -path $dir -Include *.rar -Recurse)){ 
        $action = "copy"
    }
    else {
        $action = "move"
    }
}
if ($kind -match "single"){
	$action = "copy"
}

& $filebot -script fn:amc --output $nasFolder --log-file $nasFolder\amc.log --action $action --conflict override -non-strict --def plex=$plexIP "movieFormat=Movies/{n} - {y} ({vf})" unsorted=y "ut_state=$state" "ut_title=$title" "ut_kind=$kind" "ut_file=$file" "ut_dir=$dir"
