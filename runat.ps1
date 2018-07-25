Set-StrictMode -Off;

$usage = "usage: runat (time) (command)
    
e.g. runat 2am shutdown -r -f -c ""restart""";

function esc($s) { [regex]::escape($s) }

$t = $args[0] # time

if($args.length -gt 1) { # command
  $c = $args[1..($args.length-1)] | % { if($_ -match '\s') { "`"$_`"" } else { $_ } }
  $c = [string]::join(' ', $c)
}

try { $d = get-date $t } # parse time
catch { echo "error: invalid time: '$t'"; $usage; exit 1 }

if($d -lt [DateTime]::Now) { $d = $d.AddDays(1) }
if($d -lt [DateTime]::Now) { echo "error: invalid time: '$t'"; $usage; exit 1 }

if(!$d -or !$c) { $usage; exit 1; }

# /query for unused task name (returns exit code 1 when not found)
$tn='';
for($i=1;$true;$i++) {
    try { & schtasks /query /tn "runat$i" 2>&1 | out-null } catch { }
    if($lastexitcode -eq 1) { $tn = "runat$i"; break }
}

# coerce system date format for schtasks, doubling-up 'd' and 'M'
$df = (get-culture).datetimeformat.shortdatepattern -replace '(?<![Md])(M|d)(?!\1)', '$1$1'

# create the task
& schtasks /create /ru system /rl highest /sc once /tn $tn /tr `"$($c -replace '"', '\"')`" /st $d.tostring("HH:mm") /sd $d.tostring($df)

if($lastexitcode -eq 0) { echo "Task will run '$c' at $d"; exit 0 }
exit 1;