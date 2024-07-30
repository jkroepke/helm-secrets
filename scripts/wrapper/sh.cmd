@echo off

SETLOCAL DisableDelayedExpansion

IF DEFINED HELM_DEBUG (
    IF "%HELM_DEBUG%"=="1" (
        @echo on
    )
    IF "%HELM_DEBUG%"=="true" (
        @echo on
    )
)

IF NOT DEFINED SOPS_GPG_EXEC (
    where /q gpg.exe
    IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 (
        FOR /F "tokens=* USEBACKQ" %%F IN (`where gpg.exe`) DO (
            SET SOPS_GPG_EXEC=%%F
        )
    )
)

:: Some environment name it gpg2.exe
IF NOT DEFINED SOPS_GPG_EXEC (
    where /q gpg2.exe
    IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 (
        FOR /F "tokens=* USEBACKQ" %%F IN (`where gpg.exe`) DO (
            SET SOPS_GPG_EXEC=%%F
        )
    )
)

:: If HELM_SECRETS_WINDOWS_SHELL is provided, use it.
if not "%HELM_SECRETS_WINDOWS_SHELL%"=="" GOTO :ENVSH


:: check for git-bash
"%programfiles%\Git\bin\bash.exe" -c exit  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :GITBASH


:: check for bash via scoop
"%userprofile%\scoop\shims\bash.exe" -c exit  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :SCOOP_BASH


:: check for sh via scoop
"%userprofile%\scoop\shims\sh.exe" -c exit  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :SCOOP_SH


:: check for git-bash via scoop
"%userprofile%\scoop\shims\git-bash.exe" -c exit  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :SCOOP_GITBASH


:: check for git-bash (32-bit)
"%programfiles(x86)%\Git\bin\bash.exe" -c exit  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :GITBASH32


:: check git for windows
where.exe git.exe  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :GITBASH_CUSTOM
:RETURN_GITBASH


:: check for wsl
wsl bash -c exit  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :WSL


:: check for cygwin installation or git for windows is inside %PATH%
"sh" -c exit  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :SH


:: check for cygwin installation or git for windows is inside %PATH%
"bash" -c exit  >nul 2>&1
IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 GOTO :BASH

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



:SCOOP_BASH
"%userprofile%\scoop\shims\bash.exe" %*
exit /b %errorlevel%



:SCOOP_SH
"%userprofile%\scoop\shims\sh.exe" %*
exit /b %errorlevel%



:SCOOP_GITBASH
"%userprofile%\scoop\shims\git-bash.exe" %*
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
exit /b %ERRORLEVEL%


:WSL

:: WSL needs .exe suffix for windows binary. Define path only if exists in windows PATH
IF NOT DEFINED HELM_BIN (
    IF NOT DEFINED HELM_SECRETS_HELM_PATH (
        where /q helm.exe
        IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 (
            SET HELM_SECRETS_HELM_PATH=helm.exe
        )
    )
)

IF NOT DEFINED HELM_SECRETS_SOPS_PATH (
    where /q sops.exe
    IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 (
        SET HELM_SECRETS_SOPS_PATH=sops.exe
    )
)

IF NOT DEFINED HELM_SECRETS_VALS_PATH (
    where /q vals.exe
    IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 (
        SET HELM_SECRETS_VALS_PATH=vals.exe
    )
)

IF NOT DEFINED HELM_SECRETS_CURL_PATH (
    where /q curl.exe
    IF ERRORLEVEL 0 IF NOT ERRORLEVEL 1 (
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
IF DEFINED HELM_SECRETS_BACKEND (
    SET WSLENV=HELM_SECRETS_BACKEND:%WSLENV%
)
IF DEFINED HELM_SECRETS_BACKEND_ARGS (
    SET WSLENV=HELM_SECRETS_BACKEND_ARGS:%WSLENV%
)
IF DEFINED HELM_SECRETS_ALLOWED_BACKENDS (
    SET WSLENV=HELM_SECRETS_ALLOWED_BACKENDS:%WSLENV%
)
IF DEFINED HELM_SECRETS_DEC_DIR (
    SET WSLENV=HELM_SECRETS_DEC_DIR:%WSLENV%
)
IF DEFINED HELM_SECRETS_URL_VARIABLE_EXPANSION (
    SET WSLENV=HELM_SECRETS_URL_VARIABLE_EXPANSION:%WSLENV%
)
IF DEFINED HELM_DEBUG (
    SET WSLENV=HELM_DEBUG:%WSLENV%
)
IF DEFINED HELM_SECRETS_IGNORE_MISSING_VALUES (
    SET WSLENV=HELM_SECRETS_IGNORE_MISSING_VALUES:%WSLENV%
)
IF DEFINED HELM_SECRETS_EVALUATE_TEMPLATES (
    SET WSLENV=HELM_SECRETS_EVALUATE_TEMPLATES:%WSLENV%
)
IF DEFINED HELM_SECRETS_EVALUATE_TEMPLATES_DECODE_SECRETS (
    SET WSLENV=HELM_SECRETS_EVALUATE_TEMPLATES_DECODE_SECRETS:%WSLENV%
)

IF NOT DEFINED HELM_BIN GOTO END_HELM_BIN
IF "x%HELM_BIN:\=%"=="x%HELM_BIN%" (
    SET WSLENV=HELM_BIN:%WSLENV%
) else (
    SET WSLENV=HELM_BIN/p:%WSLENV%
)
:END_HELM_BIN

IF NOT DEFINED HELM_PLUGIN_DIR GOTO END_HELM_PLUGIN_DIR
IF "x%HELM_PLUGIN_DIR:\=%"=="x%HELM_PLUGIN_DIR%" (
    SET WSLENV=HELM_PLUGIN_DIR:%WSLENV%
) else (
    SET WSLENV=HELM_PLUGIN_DIR/p:%WSLENV%
)
:END_HELM_PLUGIN_DIR

IF NOT DEFINED HELM_SECRETS_HELM_PATH GOTO END_HELM_SECRETS_HELM_PATH
IF "x%HELM_SECRETS_HELM_PATH:\=%"=="x%HELM_SECRETS_HELM_PATH%" (
    SET WSLENV=HELM_SECRETS_HELM_PATH:%WSLENV%
) else (
    SET WSLENV=HELM_SECRETS_HELM_PATH/p:%WSLENV%
)
:END_HELM_SECRETS_HELM_PATH

IF NOT DEFINED HELM_SECRETS_SOPS_PATH GOTO END_HELM_SECRETS_SOPS_PATH
IF "x%HELM_SECRETS_SOPS_PATH:\=%"=="x%HELM_SECRETS_SOPS_PATH%" (
    SET WSLENV=HELM_SECRETS_SOPS_PATH:%WSLENV%
) else (
    SET WSLENV=HELM_SECRETS_SOPS_PATH/p:%WSLENV%
)
:END_HELM_SECRETS_SOPS_PATH

IF NOT DEFINED HELM_SECRETS_VALS_PATH GOTO END_HELM_SECRETS_VALS_PATH
IF "x%HELM_SECRETS_VALS_PATH:\=%"=="x%HELM_SECRETS_VALS_PATH%" (
    SET WSLENV=HELM_SECRETS_VALS_PATH:%WSLENV%
) else (
    SET WSLENV=HELM_SECRETS_VALS_PATH/p:%WSLENV%
)
:END_HELM_SECRETS_VALS_PATH

IF NOT DEFINED HELM_SECRETS_CURL_PATH GOTO END_HELM_SECRETS_CURL_PATH
IF "x%HELM_SECRETS_CURL_PATH:\=%"=="x%HELM_SECRETS_CURL_PATH%" (
    SET WSLENV=HELM_SECRETS_CURL_PATH:%WSLENV%
) else (
    SET WSLENV=HELM_SECRETS_CURL_PATH/p:%WSLENV%
)
:END_HELM_SECRETS_CURL_PATH

SET HELM_SECRET_WSL_INTEROP=1
SET WSLENV=HELM_SECRET_WSL_INTEROP:%WSLENV%

SET SCRIPT="%1"
if not [x%SCRIPT:'=%]==[x%SCRIPT%] (
    SET SCRIPT="%SCRIPT:'=%"
)
if not [x%SCRIPT:\=%]==[x%SCRIPT%] (
    SET SCRIPT="%SCRIPT:'=%"
    :: CMD output to variable - https://stackoverflow.com/a/6362922/8087167
    FOR /F "tokens=* USEBACKQ" %%F IN (`wsl wslpath %SCRIPT:\=/%`) DO (
        SET SCRIPT="%%F"
    )
)

wsl bash %SCRIPT% %*
exit /b %ERRORLEVEL%


:NOSHELL
:: If no *nix shell found, raise an error.
echo helm-secrets needs a unix shell. Please install WSL, cygwin or Git for Windows.
exit /b 1
