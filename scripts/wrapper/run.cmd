:; exec "$@" #
:; exit $? #

@echo off
%HELM_PLUGIN_DIR%\wrapper\sh.cmd %*
exit /b
