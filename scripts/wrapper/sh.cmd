@setlocal enableextensions enabledelayedexpansion
@echo off
IF DEFINED HELM_DEBUG (
    IF HELM_DEBUG EQU 1 (
        @echo on
    )
)

IF NOT DEFINED SOPS_GPG_EXEC (
    where /q gpg.exe
    IF %ERRORLEVEL% EQU 0 (
        FOR /F "tokens=* USEBACKQ" %%F IN (`where gpg.exe`) DO (
            SET SOPS_GPG_EXEC=%%F
        )
    )
)

:: If HELM_SECRETS_WINDOWS_SHELL is provided, use it.
if not "%HELM_SECRETS_WINDOWS_SHELL%"=="" GOTO :ENVSH


:: check for wsl
wsl bash -c exit  >nul 2>&1
IF %ERRORLEVEL% EQU 0 GOTO :WSL


:: check for cygwin installation or git for windows is inside %PATH%
"sh" -c exit  >nul 2>&1
IF %ERRORLEVEL% EQU 0 GOTO :SH


:: check for cygwin installation or git for windows is inside %PATH%
"bash" -c exit  >nul 2>&1
IF %ERRORLEVEL% EQU 0 GOTO :BASH


:: check for git-bash
"%programfiles%\Git\bin\bash.exe" -c exit  >nul 2>&1
IF %ERRORLEVEL% EQU 0 GOTO :GITBASH


:: check for git-bash (32-bit)
"%programfiles(x86)%\Git\bin\bash.exe" -c exit  >nul 2>&1
IF %ERRORLEVEL% EQU 0 GOTO :GITBASH32


:: check git for windows
where.exe git.exe  >nul 2>&1
IF %ERRORLEVEL% EQU 0 GOTO :GITBASH_CUSTOM
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
:WSLPATHLOOP
if "%1"=="" goto WSLPATHENDLOOP

:: IF string contains string - https://stackoverflow.com/a/7006016/8087167
SET STR1="%1"
if not "x%STR1:\=%"=="x%STR1%" (
    :: CMD output to variable - https://stackoverflow.com/a/6362922/8087167
    FOR /F "tokens=* USEBACKQ" %%F IN (`wsl wslpath "%STR1:\=/%"`) DO (
        SET WSLPATH="%%F"
    )
) else (
    SET WSLPATH=%STR1%
)
SET ARGS=%ARGS% %WSLPATH%

shift
goto WSLPATHLOOP
:WSLPATHENDLOOP

:: WSL needs .exe suffix for windows binary. Define path only if exists in windows PATH
IF NOT DEFINED HELM_SECRETS_HELM_PATH (
    where /q helm.exe
    IF %ERRORLEVEL% EQU 0 (
        SET HELM_SECRETS_HELM_PATH=helm.exe
    )
)

IF NOT DEFINED HELM_SECRETS_SOPS_PATH (
    where /q sops.exe
    IF %ERRORLEVEL% EQU 0 (
        SET HELM_SECRETS_SOPS_PATH=sops.exe
    )
)

IF NOT DEFINED HELM_SECRETS_VALS_PATH (
    where /q vals.exe
    IF %ERRORLEVEL% EQU 0 (
        SET HELM_SECRETS_VALS_PATH=vals.exe
    )
)

IF NOT DEFINED HELM_SECRETS_CURL_PATH (
    where /q curl.exe
    IF %ERRORLEVEL% EQU 0 (
        SET HELM_SECRETS_CURL_PATH=curl.exe
    )
)

:: https://devblogs.microsoft.com/commandline/share-environment-vars-between-wsl-and-windows/
SET WSLENV=SOPS_AGE_KEY:SOPS_AGE_KEY_FILE:%WSLENV%
IF DEFINED HELM_SECRETS_DEC_SUFFIX (
    SET WSLENV=HELM_SECRETS_DEC_SUFFIX:%WSLENV%
)
IF DEFINED HELM_SECRETS_DEC_PREFIX (
    SET WSLENV=HELM_SECRETS_DEC_PREFIX:%WSLENV%
)
IF DEFINED HELM_SECRETS_QUIET (
    SET WSLENV=HELM_SECRETS_QUIET:%WSLENV%
)
IF DEFINED HELM_SECRETS_DRIVER (
    SET WSLENV=HELM_SECRETS_DRIVER:%WSLENV%
)
IF DEFINED HELM_SECRETS_DRIVER_ARGS (
    SET WSLENV=HELM_SECRETS_DRIVER_ARGS:%WSLENV%
)
IF DEFINED HELM_SECRETS_DEC_DIR (
    SET WSLENV=HELM_SECRETS_DEC_DIR:%WSLENV%
)
IF DEFINED HELM_SECRETS_OUTPUT_DECRYPTED_FILE_PATH (
    SET WSLENV=HELM_SECRETS_OUTPUT_DECRYPTED_FILE_PATH:%WSLENV%
)
IF DEFINED HELM_SECRETS_URL_VARIABLE_EXPANSION (
    SET WSLENV=HELM_SECRETS_URL_VARIABLE_EXPANSION:%WSLENV%
)
IF DEFINED HELM_DEBUG (
    SET WSLENV=HELM_DEBUG:%WSLENV%
)

if not "x%HELM_BIN:\=%"=="x%HELM_BIN%" (
    SET WSLENV=HELM_BIN/p:%WSLENV%
) else (
    SET WSLENV=HELM_BIN:%WSLENV%
)

if not "x%HELM_PLUGIN_DIR:\=%"=="x%HELM_PLUGIN_DIR%" (
    SET WSLENV=HELM_PLUGIN_DIR/p:%WSLENV%
) else (
    SET WSLENV=HELM_PLUGIN_DIR:%WSLENV%
)

if not "x%HELM_SECRETS_HELM_PATH:\=%"=="x%HELM_SECRETS_HELM_PATH%" (
    SET WSLENV=HELM_SECRETS_HELM_PATH/p:%WSLENV%
) else (
    SET WSLENV=HELM_SECRETS_HELM_PATH:%WSLENV%
)

if not "x%HELM_SECRETS_SOPS_PATH:\=%"=="x%HELM_SECRETS_SOPS_PATH%" (
    SET WSLENV=HELM_SECRETS_SOPS_PATH/p:%WSLENV%
) else (
    SET WSLENV=HELM_SECRETS_SOPS_PATH:%WSLENV%
)

if not "x%HELM_SECRETS_VALS_PATH:\=%"=="x%HELM_SECRETS_VALS_PATH%" (
    SET WSLENV=HELM_SECRETS_VALS_PATH/p:%WSLENV%
) else (
    SET WSLENV=HELM_SECRETS_VALS_PATH:%WSLENV%
)

if not "x%HELM_SECRETS_CURL_PATH:\=%"=="x%HELM_SECRETS_CURL_PATH%" (
    SET WSLENV=HELM_SECRETS_CURL_PATH/p:%WSLENV%
) else (
    SET WSLENV=HELM_SECRETS_CURL_PATH:%WSLENV%
)

wsl bash %ARGS%
exit /b %errorlevel%


:NOSHELL
:: If no *nix shell found, raise an error.
echo helm-secrets needs a unix shell. Please install WSL, cygwin or Git for Windows.
exit /b %errorlevel% 1
