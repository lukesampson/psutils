Set-StrictMode -Off;

$usage = "usage:
touch [-A [-][[hh]mm]SS] [-acm] [-r file] [-t [[CC]YY]MMDDhhmm[.SS]] file ..."

$flags  = 'acm'.tochararray()              # defines options without a parameter
$pflags = 'Art'.tochararray()              # defines options with a parameter
$opts   = new-object collections.hashtable # stores parsed options (case-sensitive keys)
$files  = @()                              # stored parsed files

function dbg($msg) { write-host $msg -f darkyellow }  # for debugging
function expand($path) {
    $executionContext.sessionState.path.getUnresolvedProviderPathFromPSPath($path)
}

# parse flags
for($i = 0; $i -lt $args.length; $i++) {
    $arg = $args[$i]
    if($arg.startswith('-')) {
        $flag = $arg[1]

        if(($pflags -ccontains $flag) -and ($arg.length -eq 2)) {
            # flag with a parameter
            if($i -eq $args.length - 1) {
                "touch: $flag requires a parameter"; $usage; exit 1
            }
            $opts[[string]$arg[1]] = $args[++$i]
        } elseif($flags -ccontains $flag) {
            # flag(s) with no parameters (may be grouped together e.g. -amc)
            $opts[[string]$flag] = $true
            for($j = 2; $j -lt $arg.length; $j++) {
                $flag = $arg[$j]
                if($flags -ccontains $flag) { $opts[[string]$flag] = $true }
                else {
                    "touch: illegal option -- $flag"; $usage; exit 1
                }
            }
        } else {
            "touch: illegal option $($arg[1..($arg.length - 1)])"; $usage; exit 1
        }
    } else {
        $files += $args[$i..($args.length - 1)]; break # everything else is a file
    }
}

# parse pflags parameters
if($opts.A) { 
    $format = "[-][[hh]mm]SS"
    if($opts.A -match '^(?<neg>-?)((?<hh>\d{2})?(?<mm>\d{2}))?(?<SS>\d{2})$') {
        $s = 0;
        if($matches.hh) { $s += [int]::parse($matches.hh) * 3600 }
        if($matches.mm) { $s += [int]::parse($matches.mm) * 60 }
        if($matches.SS) { $s += [int]::parse($matches.SS) }
        if($matches.neg) { $s = -$s }
        $opts.A = [timespan]::fromseconds($s)
    } else { "touch: invalid offset spec for A, must be $format" }
}

if($opts.t) {
    $format = "[[CC]YY]MMDDhhmm[.SS]"
    $err = "touch: out of range or illegal time specification: $format"
    if($opts.t -match '^((?<CC>\d{2})?(?<YY>\d{2}))?(?<MDhm>\d{8})(?:\.(?<SS>\d{2}))?$') {
        $d = @{} # store date parts
        @('CC','YY','MDhm','SS') | % { 
            $val = 0;
            [int]::tryparse($matches.$_, [ref]$val); $d.$_ = $val;
        }
        # fill in missing values
        $now = [datetime]::now
        if(!$d.yy) {
            $d.yy = $now.year % 1000; $d.cc = [int][math]::floor($now.year / 100)
        } elseif(!$d.cc) {
            if(($d.yy -gt 69) -and ($d.yy -lt 99)) { $d.cc = 19 } else { $d.cc = 20 }
        }
        $datef = "{0:d2}{1:d2}{2:d8}.{3:d2}" -f $d.cc, $d.yy, $d.mdhm, $d.ss
        dbg $datef
        $culture = [cultureinfo]::invariantculture
        try {
            $opts.t = [datetime]::parseexact($datef, "yyyyMMddHHmm.ss", $culture)
        } catch {
            $err; exit 1;
        }
    } else { $err; exit }
}

if(!$files) { $usage ;exit 1 }

$mod = $acc = [datetime]::now;
if($opts.r) {
    if(!$(test-path $opts.r)) { "touch: $($opts.r): no such file or directory"; exit 1 }
    $f = (gp $opts.r)
    $mod, $acc = $f.lastwritetime, $f.lastaccesstime
}
if($opts.t) { $mod = $acc = $opts.t }
if($opts.A) { $mod -= $opts.A; $acc -= $opts.A }

foreach($file in $files) {
    if(!(test-path $file)) { # file doesn't exist
        if($opts.c -or $opts.A) { continue } # A implies c: silently ignore these
        [io.file]::create((expand $file)).close() # create 0-byte file
    }
    
    # set timestamps
    if($opts.a -or !$opts.c) { sp $file lastaccesstime "$acc" }
    if($opts.c -or !$opts.a) { sp $file lastwritetime "$mod" }
}

exit 0