
function shellFromEnvironment() {
    if ("wsl" -eq $env:HELM_SECRETS_WINDOWS_SHELL) {
        shellWsl
    } else {

    }
}

if ($null -eq $env:SOPS_GPG_EXEC) {
    $env:SOPS_GPG_EXEC = (Get-Command gpg).Path
}

if ($null -eq $env:HELM_SECRETS_WINDOWS_SHELL) {
    shellFromEnvironment
}
