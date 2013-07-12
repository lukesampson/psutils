if(!$args) { "usage: sudo <cmd...>"; exit 1 }

$a = $args | % { if($_ -match '\s') { "`"$_`""} else { $_ } }
$a = [string]::join(' ', $a)
$prompt = 'write-host ''press any key to close this window...'' -nonewline; $null = $host.ui.rawui.readkey(''NoEcho,IncludeKeyDown'')'

start powershell.exe -arg "-nologo $a;$prompt" -verb runas