trap { "[helm-secrets] powershell errored in line $($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line)"; "[helm-secrets] Error: $_"; exit 1 }

function which([string] $cmd) {
    (Get-Command -ErrorAction "SilentlyContinue" $cmd).Path
}

function shellWindowsNative(
    [string][Parameter(Mandatory, Position=0)] $shell,
    [System.Object[]][Parameter(Mandatory, Position=1)] $args
) {
    $quotedArgs = foreach ($arg in $args) {
        if ($arg -notmatch '[ "]') { $arg }
        else { # must double-quote
            '"{0}"' -f ($arg -replace '"', '\"' -replace '\\$', '\\')
        }
    }

    & $shell $quotedArgs
    exit $LASTEXITCODE
}

function shellWsl(
    [System.Object[]][Parameter(Mandatory, Position=0)] $args
) {
    if ($null -eq $env:HELM_BIN -and $null -eq $env:HELM_SECRETS_HELM_PATH) {
        if ((which helm.exe) -ne $null) {
            $env:HELM_SECRETS_HELM_PATH = "helm.exe"
        }
    }

    if ($null -eq $env:HELM_SECRETS_SOPS_PATH) {
        if ((which sops.exe) -ne $null) {
            $env:HELM_SECRETS_SOPS_PATH = "sops.exe"
        }
    }

    if ($null -eq $env:HELM_SECRETS_VALS_PATH) {
        if ((which vals.exe) -ne $null) {
            $env:HELM_SECRETS_VALS_PATH = "vals.exe"
        }
    }

    if ($null -eq $env:HELM_SECRETS_CURL_PATH) {
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

    $env:WSLENV += ':HELM_BIN'
    $env:WSLENV += if ($env:HELM_BIN -match "\\") {"/p"}
    $env:WSLENV += ':HELM_PLUGIN_DIR'
    $env:WSLENV += if ($env:HELM_PLUGIN_DIR -match "\\") {"/p"}
    $env:WSLENV += ':HELM_SECRETS_HELM_PATH'
    $env:WSLENV += if ($env:HELM_SECRETS_HELM_PATH -match "\\") {"/p"}
    $env:WSLENV += ':HELM_SECRETS_SOPS_PATH'
    $env:WSLENV += if ($env:HELM_SECRETS_SOPS_PATH -match "\\") {"/p"}
    $env:WSLENV += ':HELM_SECRETS_VALS_PATH'
    $env:WSLENV += if ($env:HELM_SECRETS_VALS_PATH -match "\\") {"/p"}
    $env:WSLENV += ':HELM_SECRETS_CURL_PATH'
    $env:WSLENV += if ($env:HELM_SECRETS_CURL_PATH -match "\\") {"/p"}

    if ($args[0] -match "\\") {
        $args[0] = $args[0] -replace "\\","/"
        $args[0] = wsl wslpath "$($args[0])"
    }

    $proc = Start-Process -FilePath "wsl.exe" -ArgumentList $args -NoNewWindow -PassThru
    $proc | Wait-Process
    exit $proc.ExitCode
}

if ('1', 'true' -Contains $env:HELM_DEBUG) {
    Set-PSDebug -Trace 1
}

if ($null -eq $env:SOPS_GPG_EXEC) {
    $env:SOPS_GPG_EXEC = (which gpg.exe)
}

if ($env:HELM_SECRETS_WINDOWS_SHELL -eq 'wsl' ) {
    shellWsl $args
}

$knownShellPaths = @(
    ("$($env:HELM_SECRETS_WINDOWS_SHELL)"),
    ("$($env:ProgramFiles)\Git\bin\bash.exe"),
    ("${$env:ProgramFiles(x86)}\Git\bin\bash.exe"),
    ("$($env:UserProfile)\scoop\shims\bash.exe"),
    ("$($env:UserProfile)\scoop\shims\sh.exe")
)

foreach($knownShellPath in $knownShellPaths) {
    if (Test-Path -Path "$knownShellPath") {
        shellWindowsNative "$knownShellPath" $args
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
