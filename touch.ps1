$usage = "usage:
touch [-A [-][[hh]mm]SS] [-acm] [-r file] [-t [[CC]YY]MMDDhhmm[.SS]] file ..."

$flags  = 'acm'.tochararray() # defines options without a parameter
$pflags = 'Art'.tochararray() # defines options with a parameter
$opts   = @{}                 # stores parsed options
$files  = @()                 # stored parsed files

function dbg($msg) { write-host $msg -f darkyellow }  # temp debugging

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
            $opts[$arg[1]] = $args[++$i]
        } elseif($flags -ccontains $flag) {
            # flag(s) with no parameters (may be grouped together e.g. -amc)
            $opts[$flag] = $true
            for($j = 2; $j -lt $arg.length; $j++) {
                $flag = $arg[$j]
                if($flags -ccontains $flag) { $opts[$flag] = $true }
                else {
                    "touch: illegal option -- $flag"; $usage; exit 1
                }
            }
        } else {
            "touch: illegal option $($arg[1..($arg.length - 1)])"; $usage; exit 1
        }
    } else {
        $files += $args[$i..($args.length - 1)] # everything else is a file
    }
}

dbg 'first pass:'
$opts

$opts.A = 'test'

dbg "parsing $($opts.A)..."
# parse pflags parameters
if($opts.A) {
    dbg 'opts.A'
    $format = "[-][[hh]mm]SS"
    if($opts.A -match '(?<neg>-?)((?<hh>\d{2})?(?<mm>\d{2}))?(?<SS>\d{2})') {
        $s = 0;
        if($matches.hh) { $s += int.parse($matches.hh) * 3600 }
        if($matches.mm) { $s += int.parse($matches.mm) * 60 }
        if($matches.SS) { $s += int.parse($matches.SS) }
        dbg $s
    } else { "touch: invalid offset spec for A, must be $format" }
}

