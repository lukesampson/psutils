if(!$args) { "usage: sudo <cmd...>"; exit 1 }

function sudo_do($parent_pid, $cmd) {
	$a = @($a)
	$c = new-object io.pipes.namedpipeclientstream '.', "/tmp/sudo/$parent_pid", 'out', 'none', 'anonymous'
	try {
		$c.connect()
		$sw = new-object io.streamwriter $c
		function global:write-host($object) {
			if(!$object) { return }
			$sw.writeline($object.tostring())
		}
		function global:write-output (
			[Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
			[allownull()]
			[allowemptycollection()]
			[psobject[]]
			$inputobject) {
				$inputobject | % { if($_) {	$sw.writeline("$_")	}
			}
		}
		write-output (iex "$cmd")
		
	} finally {
		if($sw) { $sw.flush() }
		if($c -and $c.isconnected) { $c.dispose() }
	}
}

function serialize($a) {
	if($a -is [string] -and $a -match '\s') { return "'$a'" }
	if($a -is [array]) {
		return $a | % { (serialize $_) -join ', ' }
	}
	return $a
}

if($args[0] -eq '-do') {
	$_, $dir, $parent_pid, $cmd = $args
	$cmd = serialize $cmd
	cd $dir
	$null = sudo_do $parent_pid $cmd
	exit
}

$a = serialize $args

$s = new-object io.pipes.namedpipeserverstream "/tmp/sudo/$pid", 'in'
try {
	$p = start powershell.exe -arg "-nologo -window minimized & '$pscommandpath' -do $pwd $pid $a" -verb runas -passthru
	$s.waitforconnection()
	$sr = new-object io.streamreader $s
	$line = $null
	while($line = $sr.readline()) {	$line }
} catch [InvalidOperationException] {
	# user didn't provide consent: ignore
} finally {
	if($s) { $s.dispose() }
}