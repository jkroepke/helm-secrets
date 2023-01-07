function which([string] $cmd) {
    gcm -ErrorAction "SilentlyContinue" $cmd | ft Definition
}

function shellEnv {
    param(
        [string][Parameter(Mandatory, Position=0)] $path,
        [string[]][Parameter(Position=1, ValueFromRemainingArguments)] $args
    )
    process {
        if ($path -eq "wsl") {
            shellWsl $args
        } else {
            shellWindowsNative $path $args
        }
    }
}

function shellWindowsNative {
    param(
        [string][Parameter(Mandatory, Position=0)] $path,
        [string[]][Parameter(Position=1, ValueFromRemainingArguments)] $args
    )
    process {
        $proc = Start-Process -FilePath $path -ArgumentList $args -NoNewWindow -Wait -PassThru
        $proc.WaitForExit();
        exit $proc.ExitCode
    }
}

function shellWsl {
    param(
        [string[]][Parameter(Position=1, ValueFromRemainingArguments)] $args
    )
    process {
        $wslArgs = @("bash")
        $proc = Start-Process -FilePath "wsl.exe" -ArgumentList $args -NoNewWindow -Wait -PassThru
        $proc.WaitForExit();
        exit $proc.ExitCode
    }
}

if ($env:HELM_DEBUG -eq '1' -or $env:HELM_DEBUG -eq 'true') {
    Set-PSDebug -Trace 1
}

if ($null -eq $env:SOPS_GPG_EXEC) {
    $env:SOPS_GPG_EXEC = (which gpg.exe)
}

if ($null -ne $env:HELM_SECRETS_WINDOWS_SHELL) {
    shellEnv $env:HELM_SECRETS_WINDOWS_SHELL $args
}

if (Test-Path -Path "$($env:ProgramFiles)\Git\bin\bash.exe") {
    shellWindowsNative "$($env:ProgramFiles)\Git\bin\bash.exe" $args
}

if (Test-Path -Path "$($env:UserProfile)\scoop\shims\bash.exe") {
    shellWindowsNative "$($env:UserProfile)\scoop\shims\bash.exe" $args
}

if (Test-Path -Path "$($env:UserProfile)\scoop\shims\sh.exe") {
    shellWindowsNative "$($env:UserProfile)\scoop\shims\sh.exe" $args
}

if (Test-Path -Path "${$env:ProgramFiles(x86)}\Git\bin\bash.exe") {
    shellWindowsNative "${$env:ProgramFiles(x86)}\Git\bin\bash.exe" $args
}

$gitPath = (which git.exe)
if (Test-Path -Path "$gitPath\..\bin\bash.exe") {
    shellWindowsNative "$gitPath\..\bin\bash.exe" $args
}

if ((which wsl.exe) -ne $null) {
    shellWsl $args
}

$shPath = (which sh.exe)
if ($shPath -ne $null) {
    shellWindowsNative $shPath $args
}

$bashPath = (which bash.exe)
if ($bashPath -ne $null) {
    shellWindowsNative $bashPath $args
}

echo "helm-secrets needs a unix shell. Please install WSL, cygwin or Git for Windows."
exit 1
