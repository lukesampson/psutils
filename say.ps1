# note: requires getopt.ps1 in the same directory
# `scoop install say` takes care of this
. "$psscriptroot\getopt.ps1"

function show_help {
	"
usage: say [-v voice] [-r rate] [-f file | <string> ...]

OPTIONS:
  <string>
    Specify the text to speak on the command line. This can consist of multiple arguments, which are
    considered to be separated by spaces.

  -f file, --input-file=file
    Specify a file to be spoken. If file is - or neither this parameter nor a message is specified,
    read from standard input.

  -v <voice>, --voice <voice>
    Specify the voice to be used. Default is the voice selected in the Control Panel. To obtain a
    list of voices installed in the system, specify '?' as the voice name.

  -r <rate>, --rate <rate>
    Speech rate to be used, where -10 is the slowest and 10 is the fastest. Default is 0.
"
}

function get_message($in, $ar, $file) {
	if($file) {
		if($file -eq '-') { return $null }
		return gc $file -raw
	}

	if(!$ar) { return $in } 

	[string]::join(' ', ($ar | % {
		if($_ -is [array]) { [string]::join(', ', $_ ) }
		else { $_ }
	}) )
}

function cleanup($voice) {
	$null = [Runtime.Interopservices.Marshal]::ReleaseComObject($voice)
	$voice = $null
}
function voices($voice) {
	$voice.getvoices() | % { $_.getattribute('name') }
}
function select_voice($voice, $voice_name) {
	$voice.getvoices() | ? { $_.getattribute('name') -like $voice_name }
} 
function speak($voice, $msg) { $null = $voice.speak($msg, 0) }


$opt, $args, $err = getopt $args 'hf:v:r:' @('input-file=','voice=','rate=', 'help')
if($err) { "say: $err"; exit 1 }

# look at options
$file = $opt.f
if($opt['input-file']) { $file = $opt['input-file'] }
$voice_name = $opt.v
if($opt.voice) { $voice_name = $opt.voice }
$rate = $opt.r
if($opt.rate) { $rate = $opt.rate }

if($opt.h -or $opt.help) { show_help; exit 0 }

if($file -and !(test-path $file)) {
	"say: couldn't find input file: '$file'"; exit 1
}

$voice = new-object -com sapi.spvoice

if($voice_name) {
	if($voice_name -eq '?') {
		voices $voice; cleanup $voice; exit 0
	}
	$new_voice = select_voice $voice $voice_name
	if(!$new_voice) { "say: unknown voice: '$voice_name'"; cleanup $voice; exit 1; }
	$voice.voice = $new_voice
}

if($rate) {	$voice.rate = $rate }

$msg = get_message $input $args $file

if($msg) {
	speak $voice $msg
} else {
	while(1) {
		$msg = read-host
		speak $voice $msg
	}
}

cleanup $voice

