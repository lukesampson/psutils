param($path, [switch]$help)

$usage = "usage: shim <path>"

function create_shim($path) {
	if(!(test-path $path)) { "shim: couldn't find $path"; exit 1 }
	$path = resolve-path $path # ensure full path

	$shimdir = "~/appdata/local/shims"
	if(!(test-path $shimdir)) { mkdir $shimdir > $null }
	$shimdir = resolve-path $shimdir
	ensure_in_path $shimdir

	$fname_stem = [io.path]::getfilenamewithoutextension($path).tolower()

	$shim = "$shimdir\$fname_stem.ps1"

	echo "`$path = '$path'" > $shim
	echo 'if($myinvocation.expectingInput) { $input | & $path @args } else { & $path @args }' >> $shim

	if($path -match '\.((exe)|(bat)|(cmd))$') {
		# shim .exe, .bat, .cmd so they can be used by programs with no awareness of PSH
		"@`"$path`" %*" | out-file "$shimdir\$fname_stem.cmd" -encoding oem
	} elseif($path -match '\.ps1$') {
		# make ps1 accessible from cmd.exe
		"@powershell -noprofile -ex unrestricted `"& '$path' %*;exit `$lastexitcode`"" | out-file "$shimdir\$fname_stem.cmd" -encoding oem
	}
}

function env($name,$val='__get') {
	$target = 'User'
	if($val -eq '__get') { [environment]::getEnvironmentVariable($name,$target) }
	else { [environment]::setEnvironmentVariable($name,$val,$target) }
}

function ensure_in_path($dir) {
	$path = env 'path'
	$dir = resolve-path $dir
	if($path -notmatch [regex]::escape($dir)) {
		echo "adding $dir to your path"
		
		env 'path' "$dir;$path" # for future sessions...
		$env:path = "$dir;$env:path" # for this session
	}
}

if('/?', '--help' -contains $path -or $help) { $usage; exit }
if(!$path) { "shim: path missing"; $usage; exit 1; }


create_shim $path