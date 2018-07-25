Set-StrictMode -Off;

$usage = "usage:
gitignore arg ..."

[string[]] $list = $args
$params = $list -join ","

if(!$params) { $usage ;exit 1 }

invoke-restmethod -uri "https://www.gitignore.io/api/$params"

exit 0
