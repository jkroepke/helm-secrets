#!/usr/bin/env sh

{
    printf '#!/usr/bin/env sh\n'
    printf '@ 2>/dev/null # 2>nul & echo off & goto BOF\r\n'
    printf ':\n'
    # shellcheck disable=SC2016
    printf 'cmd="$1"\n'
    printf 'shift\n'
    # shellcheck disable=SC2016
    printf '"$HELM_PLUGIN_DIR/$cmd" "$@"\n'
    printf 'exit $?\n'
    printf '\r\n'
    printf ':BOF\r\n'
    printf '"%%~dp0\sh.cmd" "%%HELM_PLUGIN_DIR%%"/%%*\r\n'
    printf 'exit /B %%errorlevel%%\r\n'
} >run.bat
