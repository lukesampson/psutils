# Starts Vim on a copy of the tutor file.
# Usage: vimtutor [xx]
#
# xx is a language code like "es" or "nl".
# When no xx argument is supplied, it will use the current UI culture.
#
# Adapted from the vimtutor.bat included with Vim for Windows, modified to
# work with Scoop in Powershell
param($xx)

Set-StrictMode -Off;

if(!$xx) { $xx = (get-uiculture).twoLetterISOLanguageName }

$vim = scoop which vim
if(!$vim) {
    try { $vim = (gcm vim -ea 0).path } # fallback, not using scoop
    catch { "vim isn't installed."; exit 1 }
}

$vimdir = split-path $vim

$tutorcopy = "$env:temp\`$tutor`$"

# use environment variables so that Vim can access them
$env:tutorcopy = $tutorcopy # where to copy the tutor file to
$env:xx = $xx               # language code

# tutor.vim works out which tutor file to use (based on $env:xx)
# and then copies it to $env:tutorcopy
vim -u NONE -c "so $vimdir\tutor\tutor.vim"

# Start vim without any .vimrc, set 'nocompatible'
vim -u NONE -c "set nocp" -c "set shell=powershell" "$tutorcopy"

if(test-path $tutorcopy) { rm $tutorcopy }
