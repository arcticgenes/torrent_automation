param(
	[string]$dir = "", 
	[string]$title = "",
	[string]$label = ""
	)
  
<#
 
  How to call from utorrent
	called from Completed
	  C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy unrestricted -file "E:\Scripts\qbtorrent_amc.ps1" -title "%N" -dir "%F" -label "%L""
 
#>

$Filebot = "C:\Program Files\Filebot\filebot.exe"
$plexIP = "10.10.0.40"
$nasFolder = "\\vault10g\NAS_Storage"


& $filebot -script fn:amc --output $nasFolder --log-file $nasFolder\amc.log --action duplicate --conflict auto -non-strict --def plex=$plexIP movieFormat="Movies/{n} - {y} ({vf})" seriesFormat="TV Shows/{plex.tail}" animeFormat="Anime/{plex.tail}" unsorted=y "ut_title=$title" "ut_dir=$dir" "ut_kind=multi" "ut_label=$label"
