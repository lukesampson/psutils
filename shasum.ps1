. "$psscriptroot\getopt.ps1"

function usage {
"Usage: shasum [OPTION] [FILE]...
   or: shasum [OPTION] --check [FILE]
Print or check SHA checksums.
With no FILE, or when FILE is -, read standard input.

 -a, --algorithm    1 (default), 256, 384, 512
 -b, --binary       read files in binary mode (default)
 -c, --check        check SHA sums against given list
 -t, --text         read files in text mode
 -p, --portable     read files in portable mode
                        produces same digest on Windows/Unix/Mac

The following two options are useful only when verifying checksums:

 -s, --status       don't output anything, status code shows success
 -w, --warn         warn about improperly formatted SHA checksum lines

 -h, --help         display this help and exit
 -v, --version      output version information and exit

The sums are computed as described in FIPS PUB 180-2.  When checking,
the input should be a former output of this program.  The default mode
is to print a line with checksum, a character indicating type (`*'
for binary, `?' for portable, ` ' for text), and name for each FILE."
}

function compute_hash($file, $algname) {
	$alg = [system.security.cryptography.hashalgorithm]::create($algname)
	$fs = [system.io.file]::openread($file)
	try {
		$hexbytes = $alg.computehash($fs) | % { $_.tostring('x2') }
		[string]::join('', $hexbytes)
	} finally {
		$fs.dispose()
		$alg.dispose()
	}
}

function write_hash($file, $alg, $mode) {
	if($file -match '\*') { "shasum: $file`: invalid argument"; return }
	if(!(test-path $file -pathtype leaf)) { "shasum: $file`: no such file"; return }
	
	$hash = compute_hash (resolve-path $file) "SHA$alg"
	$mode_indicator = switch($mode) {
		'binary' { '*' }
		'text' { ' '}
		'portable' { '?' }
	}
	"$hash $mode_indicator$file"
}

$opt, $files, $err = getopt $args 'a:bcpth' @('algorithm=','binary','check','text','portable','help')
if($err) { "shasum: $err"; exit 1 }

if($opt.h -or $opt.help) { usage; exit 0 }

if(!$files) { "shasum: file is required"; exit 1 }

$alg = $opt.algorithm;
if(!$alg) { $alg = $opt.a }
if(!$alg) { $alg = 1 }
if(@(1,256,384,512) -notcontains $alg) { "shasum: invalid algorithm"; exit 1 }

$mode = 'binary'
if($opt.t -or $opt.text) { $mode = 'text' }
if($opt.p -or $opt.portable) { $mode = 'portable' }

if($mode -eq 'text') { "shasum: text mode not implemented!"; exit 1 }

$check = $opt.c -or $opt.check
if($check) { "shasum: check not implemented!"; exit 1 }

$files | % { write_hash $_ $alg $mode }