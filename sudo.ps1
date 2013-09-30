if(!$args) { "usage: sudo <cmd...>"; exit 1 }

$id = [Security.Principal.WindowsIdentity]::GetCurrent()

function sudo_do($parent_pid, $dir, $cmd) {
	$src = 'using System.Runtime.InteropServices;
	public class Kernel {
		[DllImport("kernel32.dll", SetLastError = true)]
		public static extern bool AttachConsole(uint dwProcessId);

		[DllImport("kernel32.dll", SetLastError = true, ExactSpelling = true)]
		public static extern bool FreeConsole();
	}'

	$kernel = add-type $src -passthru

	$kernel::freeconsole()
	$kernel::attachconsole($parent_pid)
		
	$p = new-object diagnostics.process; $start = $p.startinfo
	$start.filename = "powershell.exe"
	$start.arguments = "-noprofile $cmd`nexit `$lastexitcode"
	$start.useshellexecute = $false
	$start.workingdirectory = $dir
	$p.start()
	$p.waitforexit()
}

function serialize($a) {
	if($a -is [string] -and $a -match '\s') { return "'$a'" }
	if($a -is [array]) {
		return $a | % { (serialize $_) -join ', ' }
	}
	return $a
}

if($args[0] -eq '-do') {
	$null, $dir, $parent_pid, $cmd = $args
	$null = sudo_do $parent_pid $dir (serialize $cmd)
	exit
}

$a = serialize $args

$p = new-object diagnostics.process; $start = $p.startinfo
$start.filename = "powershell.exe"
$start.arguments = "-noprofile -noexit & '$pscommandpath' -do $pwd $pid $a"
$start.verb = 'runas'
$start.windowstyle = 'hidden'
try { $null = $p.start() }
catch { exit 1 } # user didn't provide consent
$p.waitforexit()