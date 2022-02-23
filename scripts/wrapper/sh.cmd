@setlocal enableextensions enabledelayedexpansion
@echo off

:: If HELM_SECRETS_WINDOWS_SHELL is provided, use it.
if not "%HELM_SECRETS_WINDOWS_SHELL%"=="" GOTO :ENVSH


:: check for wsl
wsl bash -c exit  >nul 2>&1
IF NOT ERRORLEVEL 1 GOTO :WSL


:: check for cygwin installation or git for windows is inside %PATH%
"sh" -c exit  >nul 2>&1
IF NOT ERRORLEVEL 1 GOTO :SH


:: check for cygwin installation or git for windows is inside %PATH%
"bash" -c exit  >nul 2>&1
IF NOT ERRORLEVEL 1 GOTO :BASH


:: check for git-bash
"%programfiles%\Git\bin\bash.exe" -c exit  >nul 2>&1
IF NOT ERRORLEVEL 1 GOTO :GITBASH


:: check for git-bash (32-bit)
"%programfiles(x86)%\Git\bin\bash.exe" -c exit  >nul 2>&1
IF NOT ERRORLEVEL 1 GOTO :GITBASH32


:: check git for windows
where.exe git.exe  >nul 2>&1
IF NOT ERRORLEVEL 1 GOTO :GITBASH_CUSTOM
:RETURN_GITBASH

GOTO :NOSHELL



:ENVSH
IF "%HELM_SECRETS_WINDOWS_SHELL%"=="wsl" GOTO :WSL

"%HELM_SECRETS_WINDOWS_SHELL%" %*
exit /b %errorlevel%


:SH
"sh" %*
exit /b %errorlevel%


:BASH
"bash" %*
exit /b %errorlevel%


:GITBASH
"%programfiles%\Git\bin\bash.exe" %*
exit /b %errorlevel%



:GITBASH32
"%programfiles(x86)%\Git\bin\bash.exe" %*
exit /b %errorlevel%


:GITBASH_CUSTOM
:: CMD output to variable - https://stackoverflow.com/a/6362922/8087167
FOR /F "tokens=* USEBACKQ" %%F IN (`where.exe git.exe`) DO (
  SET GIT_FILEPATH=%%F
)

IF "%GIT_FILEPATH%"=="" GOTO :RETURN_GITBASH

FOR %%F in ("%GIT_FILEPATH%") DO SET GIT_DIRPATH=%%~dpF

:: check for git-bash
"%GIT_DIRPATH%..\bin\bash.exe" -c exit  >nul 2>&1

IF ERRORLEVEL 1 GOTO :RETURN_GITBASH

"%GIT_DIRPATH%..\bin\bash.exe" %*
exit /b %errorlevel%


:WSL
:: Use WSL, but convert all paths (script + arguments) to wsl paths
SET ARGS=

:: Loop through all parameters - https://stackoverflow.com/a/34019557/8087167
:LOOP
if "%1"=="" goto ENDLOOP

:: IF string contains string - https://stackoverflow.com/a/7006016/8087167
SET STR1="%1"
if not "x%STR1:\=%"=="x%STR1%" (
    :: CMD output to variable - https://stackoverflow.com/a/6362922/8087167
    FOR /F "tokens=* USEBACKQ" %%F IN (`wsl wslpath "%1"`) DO (
      SET WSLPATH="%%F"
    )
) else (
    SET WSLPATH=%1
)
SET ARGS=%ARGS% %WSLPATH%

shift
goto LOOP
:ENDLOOP

where /q sops.exe
IF ERRORLEVEL 1 (
    IF "%HELM_SECRETS_SOPS_PATH%"=="" SET HELM_SECRETS_SOPS_PATH=sops.exe
)
wsl bash %ARGS%
exit /b %errorlevel%


:NOSHELL
:: If no *nix shell found, raise an error.
echo helm-secrets needs a unix shell. Please install WSL, cygwin or Git for Windows.
exit /b %errorlevel% 1
