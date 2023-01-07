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
        if ($null -ne $env:HELM_BIN -and $null -ne $env:HELM_SECRETS_HELM_PATH) {
            if ((which helm.exe) -ne $null) {
                $env:HELM_SECRETS_HELM_PATH = "helm.exe"
            }
        }

        if ($null -ne $env:HELM_SECRETS_SOPS_PATH) {
            if ((which sops.exe) -ne $null) {
                $env:HELM_SECRETS_SOPS_PATH = "sops.exe"
            }
        }

        if ($null -ne $env:HELM_SECRETS_VALS_PATH) {
            if ((which vals.exe) -ne $null) {
                $env:HELM_SECRETS_VALS_PATH = "vals.exe"
            }
        }

        if ($null -ne $env:HELM_SECRETS_CURL_PATH) {
            if ((which curl.exe) -ne $null) {
                $env:HELM_SECRETS_CURL_PATH = "curl.exe"
            }
        }

        $env:WSLENV += ':SOPS_AGE_KEY:SOPS_AGE_KEY_FILE'
        $env:WSLENV += ':HELM_SECRETS_DEC_SUFFIX'
        $env:WSLENV += ':HELM_SECRETS_QUIET'
        $env:WSLENV += ':HELM_SECRETS_BACKEND'
        $env:WSLENV += ':HELM_SECRETS_BACKEND_ARGS'
        $env:WSLENV += ':HELM_SECRETS_DEC_DIR'
        $env:WSLENV += ':HELM_SECRETS_URL_VARIABLE_EXPANSION'
        $env:WSLENV += ':HELM_DEBUG'
        $env:WSLENV += ':HELM_SECRETS_EVALUATE_TEMPLATES'
        $env:WSLENV += ':HELM_SECRETS_EVALUATE_TEMPLATES_DECODE_SECRETS'

        $env:WSLENV += if ($env:HELM_BIN -match "\\") {":HELM_PLUGIN_DIR/p"} else {":HELM_PLUGIN_DIR"}
        $env:WSLENV += if ($env:HELM_PLUGIN_DIR -match "\\") {":HELM_PLUGIN_DIR/p"} else {":HELM_PLUGIN_DIR"}
        $env:WSLENV += if ($env:HELM_SECRETS_HELM_PATH -match "\\") {":HELM_SECRETS_HELM_PATH/p"} else {":HELM_SECRETS_HELM_PATH"}
        $env:WSLENV += if ($env:HELM_SECRETS_SOPS_PATH -match "\\") {":HELM_SECRETS_SOPS_PATH/p"} else {":HELM_SECRETS_SOPS_PATH"}
        $env:WSLENV += if ($env:HELM_SECRETS_VALS_PATH -match "\\") {":HELM_SECRETS_VALS_PATH/p"} else {":HELM_SECRETS_VALS_PATH"}
        $env:WSLENV += if ($env:HELM_SECRETS_CURL_PATH -match "\\") {":HELM_SECRETS_CURL_PATH/p"} else {":HELM_SECRETS_VALS_PATH"}

        if ($args[0] -match "\\") {
            $args[0] = wsl wslpath "$(arg[0])"
        }

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

@(
    ("$($env:ProgramFiles)\Git\bin\bash.exe"),
    ("${$env:ProgramFiles(x86)}\Git\bin\bash.exe"),
    ("$($env:UserProfile)\scoop\shims\bash.exe"),
    ("$($env:UserProfile)\scoop\shims\sh.exe")
) | % {
    if (Test-Path -Path "$_") {
        shellWindowsNative "$_" $args
    }
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
