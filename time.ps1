Set-StrictMode -Off;

# see http://stackoverflow.com/a/3513669/87453
$cmd, $args = $args
$args = @($args)
$sw = [diagnostics.stopwatch]::startnew()
& $cmd @args
$sw.stop()

"$($sw.elapsed)"