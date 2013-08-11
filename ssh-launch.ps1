# starts ssh-agent and records environment variables so that ssh works in powershell

# check agent already running
if($env:SSH_AGENT_PID) {
    $p = try { ps -id $env:SSH_AGENT_PID -ea stop } catch { $null }
    if($p) { "Agent (pid $env:SSH_AGENT_PID) is already running"; exit 1 }
}

$script = ssh-agent # returns a unix shell script to set env vars

# convert the script to powershell
$script = $script -creplace '([A-Z_]+)=([^;]+).*', '$$env:$1="$2"' `
    -creplace 'echo ([^;]+);', 'echo "$1"'
$script = [string]::join("`n", $script)

iex $script