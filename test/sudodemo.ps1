$name = read-host "enter your name"
write-host "hi, $name" -f darkgreen
for($i = 1; $i -lt 6; $i++) {
	write-host $i
	start-sleep -m 100
}

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$admin = ([Security.Principal.WindowsPrincipal]($id)).isinrole("Administrators")

"admin? $admin"

write-error "error!"

exit 123