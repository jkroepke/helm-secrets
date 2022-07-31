Param(
    [parameter(ValueFromRemainingArguments = $true)]
    [string[]]$
)

function startShell() {
    Param(
        [string] $shell,
        [parameter(ValueFromRemainingArguments = $true)]
        [string[]]$shellArguments
    )

    $proc = Start-Process -FilePath $shell -NoNewWindow -PassThru -Wait -Argumentlist @shellArguments
    exit $p.ExitCode
}

function shellFromEnvironment() {
    if ("wsl" -eq $env:HELM_SECRETS_WINDOWS_SHELL) {
        shellWsl @Args
    } else {
        startShell $env:HELM_SECRETS_WINDOWS_SHELL @Args
    }
}

if ($null -eq $env:SOPS_GPG_EXEC) {
    $env:SOPS_GPG_EXEC = (Get-Command gpg).Path
}

if ($null -eq $env:HELM_SECRETS_WINDOWS_SHELL) {
    shellFromEnvironment @Args
}
