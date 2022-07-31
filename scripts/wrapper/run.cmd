:<<BATCH
    @echo off
    setlocal enabledelayedexpansion

    set argCount=0
    for %%x in (%*) do (
       set /A argCount+=1
       set "argVec[!argCount!]=%%~x"
    )

    echo Number of processed arguments: %argCount%

    for /L %%i in (1,1,%argCount%) do echo %%i- "!argVec[%%i]!"

    "%~dp0\sh.cmd" "%HELM_PLUGIN_DIR%"/%*
    exit /b %errorlevel%
BATCH

cmd="$1"
shift
"$HELM_PLUGIN_DIR/$cmd" "$@"
exit $?

:: .bat bash hybrid script
:: https://stackoverflow.com/a/17510832/8087167
