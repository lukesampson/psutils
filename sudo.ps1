if(!$args) { "usage: sudo <cmd...>"; exit 1 }

function sudo_do($parent_pid, $dir, $cmd) {
	$a = @($a)
	$c = new-object io.pipes.namedpipeclientstream '.', "/tmp/sudo/$parent_pid", 'out', 'none', 'anonymous'
	try {
		$c.connect()
		$global:sw = new-object io.streamwriter $c # global so event handler can access
		
		$p = new-object diagnostics.process; $start = $p.startinfo
		$start.filename = "powershell.exe"
		write-host "cmd: $cmd"
		$start.arguments = "-nologo $cmd;exit `$lastexitcode"
		$start.useshellexecute = $false
		$start.redirectstandardoutput = $true
		$start.redirectstandarderror = $true
		$start.workingdirectory = $dir
		register-objectevent $p errordatareceived -action {
			$global:sw.writeline("2$($eventargs.data)"); $global:sw.flush();
		}
		$p.start()

		$p.beginerrorreadline()
		$line = $null
		while($line = $p.standardoutput.readline()) {
			$sw.writeline("1$line"); $sw.flush()
		}
		$p.waitforexit()
		write-host "" -nonewline # for some reason, errors aren't written without this
		$sw.writeline("0$($p.exitcode)"); $sw.flush() # can't seem to access exitcode for process started with runas
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
	sudo_do $parent_pid $dir $cmd
	exit
}

$a = serialize $args

$exitcode = 0
$s = new-object io.pipes.namedpipeserverstream "/tmp/sudo/$pid", 'in'
try {
	$p = start powershell.exe -arg "-nologo -window minimized & '$pscommandpath' -do $pwd $pid $a" -verb runas -passthru
	$s.waitforconnection()
	$sr = new-object io.streamreader $s
	$line = $null
	while($line = $sr.readline()) {
		$stream = $line[0]
		$line = $line.substring(1)
		if($stream -eq '1') { $line }
		elseif($stream -eq '2') { [console]::error.writeline($line) }
		elseif($stream -eq '0') { $exitcode = [int]$line }
		else { "$stream$line" }
	}
} catch [InvalidOperationException] {
	# user didn't provide consent: ignore
} finally {
	if($s) { $s.dispose() }
}

exit $exitcode