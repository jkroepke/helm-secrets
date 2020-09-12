@setlocal enableextensions enabledelayedexpansion
@echo off

:: If HELM_SECRETS_WINDOWS_SHELL is provided, use it.
if not "%HELM_SECRETS_WINDOWS_SHELL%"=="" GOTO :ENVSH

:: check for cygwin installation or git for windows is inside %PATH%
"sh" -c exit  >nul 2>&1

IF %ERRORLEVEL% EQU 0 GOTO :SH

:: check for git-bash
"%programfiles%\Git\bin\bash.exe" -c exit  >nul 2>&1

IF %ERRORLEVEL% EQU 0 GOTO :GITBASH

:: check for git-bash (32-bit)
"%programfiles(x86)%\Git\bin\bash.exe" -c exit  >nul 2>&1

IF %ERRORLEVEL% EQU 0 GOTO :GITBASH32

:: check for wsl
wsl sh -c exit  >nul 2>&1

IF %ERRORLEVEL% EQU 0 GOTO :WSL

GOTO :NOSHELL

:ENVSH
"%HELM_SECRETS_WINDOWS_SHELL%" "%HELM_PLUGIN_DIR%\scripts\run.sh" %*
GOTO :EOF

:SH
"sh" "%HELM_PLUGIN_DIR%\scripts\run.sh" %*
GOTO :EOF

:GITBASH
"%programfiles%\Git\bin\bash.exe" -x "%HELM_PLUGIN_DIR%\scripts\run.sh" %*
GOTO :EOF

:GITBASH32
"%programfiles(x86)%\Git\bin\bash.exe" "%HELM_PLUGIN_DIR%\scripts\run.sh" %*
GOTO :EOF

:WSL
:: Use WSL, but convert all paths (script + arguments) to wsl paths
SET ARGS=

:: Loop through all parameters - https://stackoverflow.com/a/34019557/8087167
:LOOP
if "%1"=="" goto ENDLOOP

:: CMD output to variable - https://stackoverflow.com/a/6362922/8087167
FOR /F "tokens=* USEBACKQ" %%F IN (`wsl wslpath "%1"`) DO (
  SET WSLPATH=%%F
)
SET ARGS=%ARGS% %WSLPATH%

shift
goto LOOP
:ENDLOOP

wsl bash -x -c "%ARGS%"
GOTO :EOF

:NOSHELL
:: If no *nix shell found, raise an error.
echo helm-secrets needs a unix shell. Please install WSL, cygwin or Git for Windows.
exit /B 1
GOTO :EOF
