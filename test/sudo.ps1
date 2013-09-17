ls "$psscriptroot\sudo\" '*.in' | % {
	$name = $_.name -replace '\.in$', ''
	$path = $_.fullname
	$outpath = $path -replace '\.in$', '.out'
	if(test-path $outpath) { $expect = gc ($outpath) }

	$arguments = gc $path
	$out = iex "$psscriptroot\..\sudo.ps1 $arguments"

	write-host "$name`: " -nonewline
	if($expect) {
		$diff = compare-object $expect $out
		$eq = !$diff
		if($eq) { write-host "pass" -f darkgreen }
		else { write-host "fail" -f darkred }
	} else {
		write-host "error: no .out file" -f darkyellow
	}
	
	if(!$eq) {
		$diff
	}
}

