:; exec "$@" #
:; exit $? #

:: .bat bash hybrid script
:: https://stackoverflow.com/a/17623721

@echo off
%HELM_PLUGIN_DIR%\scripts\wrapper\sh.cmd %*
exit /b %errorlevel%
