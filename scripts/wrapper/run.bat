#!/usr/bin/env -S sh # 2>nul & echo off & goto BOF
:
cmd="$1"
shift
"$HELM_PLUGIN_DIR/$cmd" "$@"
exit $?

:BOF
"%~dp0\sh.cmd" "%HELM_PLUGIN_DIR%"/%*
exit /B %errorlevel%
