if(!$args) { "usage: sudo <cmd...>"; exit 1 }

function sudo_do($parent_pid, $cmd, $a) {
	$a = @($a)
	"parent pid: $parent_pid"
	$c = new-object io.pipes.namedpipeclientstream '.', "/tmp/sudo/$parent_pid", 'out', 'none', 'anonymous'
	try {
		$c.connect()
		write-host "connected" -f red
		$sw = new-object io.streamwriter $c
		function global:write-output($inputobject) {
			@($inputobject) | % { $sw.writeline($_.tostring()) }
		}

		& $cmd @($a)
		
	} finally {
		if($sw) { $sw.flush() }
		if($c -and $c.isconnected) { $c.dispose() }
	}
}

if($args[0] -eq '-do') {
	$_, $dir, $parent_pid, $cmd, $a = $args
	"args: $args, $($args.length)"
	"a: $a"
	$a.gettype()
	$a.length
	cd $dir
	sudo_do $parent_pid $cmd $a
	exit
}

function serialize($a) {
	if($a -is [string] -and $a -match '\s') { return "'$a'" }
	if($a -is [array]) {
		return $a | % { (serialize $_) -join ', ' }
	}
	return $a
}

$a = serialize $args
"serialized: $a"

$s = new-object io.pipes.namedpipeserverstream "/tmp/sudo/$pid", 'in'
try {
	"-noexit -nologo $pwd\testsudo.ps1 -do $pwd $pid $a"
	start powershell.exe -arg "-noexit -nologo $pwd\testsudo.ps1 -do $pwd $pid $a" -verb runas
	$s.waitforconnection()
	"client connected"
	$sr = new-object io.streamreader $s
	$line = $null
	while($line = $sr.readline()) {
		"client said: $line"
	}
} finally {
	if($s) { $s.dispose() }
}