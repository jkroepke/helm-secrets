:; exec "$@" #
:; exit $? #

@echo off
%HELM_PLUGIN_DIR%\wrapper\sh.sh %*
exit /b
