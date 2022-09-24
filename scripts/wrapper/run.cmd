#!/usr/bin/env sh
@ 2>/dev/null # 2>nul & echo off & goto BOF
:
cmd="$1"
shift
"$HELM_PLUGIN_DIR/$cmd" "$@"
exit $?

:BOF
@echo off
"%~dp0\sh.cmd" "%HELM_PLUGIN_DIR%"/%*
exit /b %errorlevel%

:: .bat bash hybrid script
:: https://stackoverflow.com/a/17510832/8087167
