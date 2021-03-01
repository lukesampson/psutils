Set-StrictMode -Off;

# bodge the ln command
$usage = "usage: ln [-s] <target> [link_name]"

$src = '
using System;
using System.Runtime.InteropServices;
public class kernel {
	[DllImport("kernel32.dll")]
	[return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.I1)]
	public static extern bool CreateSymbolicLink(string lpSymlinkFileName, string lpTargetFileName, uint dwFlags);

	[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
	public static extern bool CreateHardLink(string lpFileName, string lpExistingFileName, IntPtr lpSecurityAttributes);
}'

function isadmin {
	$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$p = new-object System.Security.Principal.WindowsPrincipal $id
	$p.isinrole([security.principal.windowsbuiltinrole]::administrator)
}

function symlink($target, $link_name, $is_dir) {
	# CreateSymbolicLink:
	#     http://msdn.microsoft.com/en-us/library/aa363866.aspx
	$dwFlags = 2
	if($is_dir) { $dwFlags = 3 }

	$kernel = add-type $src -passthru
	$result = $kernel::createsymboliclink($link_name, $target, $dwFlags)

	if(!$result) {
		if(!(isadmin)) {
			if(gcm 'sudo' -ea silent) {
				"ln: Must run elevated: try using 'sudo ln ...'."
			} else {
				if(gcm 'scoop' -ea silent) {
					"ln: Must run elevated: you can install 'sudo' by running 'scoop install sudo'."
				} else { "ln: Must run elevated" }
			}
		} else { "failed!" } # mysterious
		exit 1
	}
}

function hardlink($target, $link_name) {
	# CreateHardLink:
	#     http://msdn.microsoft.com/en-us/library/aa363860.aspx
	$kernel = add-type $src -passthru
	$result = $kernel::createhardlink($link_name, $target, [intptr]::zero)

	if(!$result) { "failed!"; exit 1 } # mysterious
}

$symbolic = $false
$target = $args[0]
$link_name = $args[1]
$is_dir = $false

if($target -like '-s') {
	$symbolic = $true
	$target = $args[1]
	$link_name = $args[2]
}

if(!$target) { "ln: target is required"; $usage; exit 1 }
if(!$link_name) {
	# create link in working dir, with same name as target
	$link_name = "$pwd\$(split-path $target -leaf)"
} elseif(!([io.path]::ispathrooted($link_name))) {
	$link_name = "$pwd\$link_name"
}

if(!(test-path $target)) {
	"ln: $target`: No such file or directory"; exit 1
}

if(test-path $link_name) {
	"ln: $link_name`: File exists"
}

$abstarget = "$(resolve-path $target)"
if([io.directory]::exists($abstarget)) {
	$is_dir = $true
}

if($abstarget -eq $link_name) {
	"ln: target and link_name are the same"; $usage; exit 1
}

if(!$symbolic -and $is_dir) {
	"ln: Can't create hard links for directories: use -s for symbolic link"; $usage; exit 1
}

if($symbolic) {
	symlink $target $link_name $is_dir
} else {
	hardlink $target $link_name
}

exit 0
