ls "$psscriptroot\sudo\" '*.in' | % {
	$name = $_.name -replace '\.in$', ''
	$path = $_.fullname
	$expect = gc ($path -replace '\.in$', '.out')

	$arguments = gc $path
	$out = & "$psscriptroot\..\sudo.ps1" $arguments

	$diff = compare-object $expect $out
	$eq = !$diff
	write-host "$name`: $eq"
	if(!$eq) {
		$diff
	}
}

