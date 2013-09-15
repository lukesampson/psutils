if(!$args) { "usage: sudo <cmd...>"; exit 1 }

function sudo_do($parent_pid, $cmd) {
	$a = @($a)
	"parent pid: $parent_pid"
	$c = new-object io.pipes.namedpipeclientstream '.', "/tmp/sudo/$parent_pid", 'out', 'none', 'anonymous'
	try {
		$c.connect()
		write-host "connected" -f red
		$sw = new-object io.streamwriter $c
		function global:write-output($inputobject) {
			@($inputobject) | % { if($_) { $sw.writeline($_.tostring()) } } 
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
"serialized: $a"

$s = new-object io.pipes.namedpipeserverstream "/tmp/sudo/$pid", 'in'
try {
	$p = start powershell.exe -arg "-noexit -nologo & '$pscommandpath' -do $pwd $pid $a" -verb runas -passthru
	$s.waitforconnection()
	"client connected"
	$sr = new-object io.streamreader $s
	$line = $null
	while($line = $sr.readline()) {
		"client said: $line"
	}
} catch [InvalidOperationException] {
	# user didn't provide consent: ignore
} finally {
	if($s) { $s.dispose() }
}