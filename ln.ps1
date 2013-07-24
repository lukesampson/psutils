# bodge the ln command
$usage = "usage: ln [-s] TARGET LINK_NAME"

# original Invoke-WindowsAPI by Lee Holmes
# http://poshcode.org/2189
function pinvoke {
    param(
        ## The name of the DLL that contains the Windows API, such as "kernel32"
        [string] $DllName,

        ## The return type expected from Windows API
        [Type] $ReturnType,

        ## The name of the Windows API
        [string] $MethodName,

        ## The types of parameters expected by the Windows API
        [Type[]] $ParameterTypes,

        ## Parameter values to pass to the Windows API
        [Object[]] $Parameters
    )

    Set-StrictMode -Version Latest

    ## Begin to build the dynamic assembly
    $domain = [AppDomain]::CurrentDomain
    $name = New-Object Reflection.AssemblyName 'PInvokeAssembly'
    $assembly = $domain.DefineDynamicAssembly($name, 'Run')
    $module = $assembly.DefineDynamicModule('PInvokeModule')
    $type = $module.DefineType('PInvokeType', "Public,BeforeFieldInit")

    ## Go through all of the parameters passed to us.  As we do this,
    ## we clone the user's inputs into another array that we will use for
    ## the P/Invoke call.
    $inputParameters = @()
    $refParameters = @()

    for($counter = 1; $counter -le $parameterTypes.Length; $counter++)
    {
        ## If an item is a PSReference, then the user
        ## wants an [out] parameter.
        if($parameterTypes[$counter - 1] -eq [Ref])
        {
            ## Remember which parameters are used for [Out] parameters
            $refParameters += $counter

            ## On the cloned array, we replace the PSReference type with the
            ## .Net reference type that represents the value of the PSReference,
            ## and the value with the value held by the PSReference.
            $parameterTypes[$counter - 1] =
                $parameters[$counter - 1].Value.GetType().MakeByRefType()
            $inputParameters += $parameters[$counter - 1].Value
        }
        else
        {
            ## Otherwise, just add their actual parameter to the
            ## input array.
            $inputParameters += $parameters[$counter - 1]
        }
    }

    ## Define the actual P/Invoke method, adding the [Out]
    ## attribute for any parameters that were originally [Ref]
    ## parameters.
    $method = $type.DefineMethod(
        $methodName, 'Public,HideBySig,Static,PinvokeImpl',
        $returnType, $parameterTypes)
    foreach($refParameter in $refParameters)
    {
        [void] $method.DefineParameter($refParameter, "Out", $null)
    }

    ## Apply the P/Invoke constructor
    $ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([string])
    $attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, $dllName
    $method.SetCustomAttribute($attr)

    ## Create the temporary type, and invoke the method.
    $realType = $type.CreateType()

    $realType.InvokeMember($methodName, 'Public,Static,InvokeMethod', $null, $null,$inputParameters)

    ## Finally, go through all of the reference parameters, and update the
    ## values of the PSReference objects that the user passed in.
    foreach($refParameter in $refParameters)
    {
        $parameters[$refParameter - 1].Value = $inputParameters[$refParameter - 1]
    }
}

function isadmin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = new-object System.Security.Principal.WindowsPrincipal $id
    $p.IsInRole("Administrators")
}

function symlink($target, $link_name, $is_dir) {
    $dwFlags = 0
    if($is_dir) { $dwFlags = 1 }
    $parameterTypes = [string], [string], [int]
    $parameters = [string] $link_name, [string] $target, $dwFlags

    # CreateSymbolicLink:
    #     http://msdn.microsoft.com/en-us/library/aa363866.aspx
    $result = pinvoke "kernel32" ([bool]) "CreateSymbolicLink" $parameterTypes $parameters

    if(!$result) { "failed!"; exit 1 } # mysterious
}

function hardlink($target, $link_name) {
    $parameterTypes = [string], [string], [intptr]
    $parameters = [string] $link_name, [string] $target, [intptr]::zero

    # CreateHardLink:
    #     http://msdn.microsoft.com/en-us/library/aa363860.aspx
    $result = pinvoke "kernel32" ([bool]) "CreateHardLink" $parameterTypes $parameters

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

if(!$target) { "ln: TARGET is required"; $usage; exit 1 }
if(!$link_name) { "ln: LINK_NAME is required"; $usage; exit 1 }

if(!([io.path]::ispathrooted($link_name))) {
    $link_name = "$psscriptroot\$link_name"
}

if(!(test-path $target)) {
    "ln: TARGET doesn't exist!"; exit 1
}

$target = "$(resolve-path $target)"
if([io.directory]::exists($target)) {
    $is_dir = $true
}

if($target -eq $link_name) {
    "ln: TARGET and LINK_NAME are the same"; exit 1
}

if(!$symbolic -and $is_dir) {
    "ln: can't create hard links for directories. use -s for symbolic link"; $usage; exit 1
}

if(!(isadmin)) {
    if(gcm 'sudo' -ea silent) {
        "ln: must run elevated: try using 'sudo ln ...'."
    } else {
        if(gcm 'scoop' -ea silent) {
            "ln: must run elevated: you can install 'sudo' by running 'scoop install sudo'."
        } else { "ln: must run elevated" }
    }
    exit 1
}

if($symbolic) {
    symlink $target $link_name $is_dir
} else {
    hardlink $target $link_name
}

exit 0
