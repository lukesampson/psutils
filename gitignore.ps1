$usage = "usage:
gitignore arg ..."

[string[]] $list = $args
$params = $list -join ","

if(!$params) { $usage ;exit 1 }

invoke-WebRequest -Uri "http://gitignore.io/api/$params" | select -expandproperty content

exit 0
