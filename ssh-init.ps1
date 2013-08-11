# based on script from here:
# https://help.github.com/articles/working-with-ssh-key-passphrases#platform-windows


# Note: ~/.ssh/environment should not be used, as it
#       already has a different purpose in SSH.
$envfile="~/.ssh/agent.env.ps1"

# Note: Don't bother checking SSH_AGENT_PID. It's not used
#       by SSH itself, and it might even be incorrect
#       (for example, when using agent-forwarding over SSH).
function agent_is_running() {
    if($env:SSH_AUTH_SOCK) {
        # ssh-add returns:
        #   0 = agent running, has keys
        #   1 = agent running, no keys
        #   2 = agent not running
        ssh-add -l 2>&1 > $null;
        $lastexitcode -ne 2
    } else {
        $false
    }
}

function agent_has_keys {
    ssh-add -l 2>&1 > $null; $lastexitcode -eq 0
}

function agent_load_env {
    if(test-path $envfile) { . $envfile > $null }
}

function agent_start {
    $script = ssh-agent

    # translate bash script to powershell
    $script = $script -creplace '([A-Z_]+)=([^;]+).*', '$$env:$1="$2"' `
        -creplace 'echo ([^;]+);', 'echo "$1"'

    $script > $envfile
    . $envfile > $null
}

$agentcmd = try { gcm ssh-agent -ea stop } catch { $null }
if(!$agentcmd) { "couldn't find ssh-agent in path"; exit 1 }

if(!(agent_is_running)) {
    agent_load_env 
}

if(!(agent_is_running)) {
    agent_start
    ssh-add
} elseif(!(agent_has_keys)) {
    ssh-add
}