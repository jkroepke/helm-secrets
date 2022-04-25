:<<BATCH
    @echo off
    "%~dp0\sh.cmd" "%HELM_PLUGIN_DIR%"/%*
    exit /b %errorlevel%
BATCH

cmd="$1"
shift
"$HELM_PLUGIN_DIR/$cmd" "$@"
exit $?

:: .bat bash hybrid script
:: https://stackoverflow.com/a/17510832/8087167
