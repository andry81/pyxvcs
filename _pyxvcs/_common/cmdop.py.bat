@echo off

rem rem implementation through the `python` 3.x + `plumbum` module
rem 
rem setlocal
rem 
rem call "%%~dp0__init__.bat" || exit /b
rem 
rem "%PYTHON_EXE_PATH%" "%~dp0cmdop.xsh" %*
rem exit /b

setlocal

call "%%~dp0__init__.bat" || goto INIT_EXIT

if %IMPL_MODE%0 NEQ 0 goto IMPL

rem no local logging if nested call
set WITH_LOGGING=0
if %NEST_LVL%0 EQU 0 set WITH_LOGGING=1

if %WITH_LOGGING% EQU 0 goto IMPL

if not exist "%CONFIGURE_DIR%\.log" mkdir "%CONFIGURE_DIR%\.log"

rem use stdout/stderr redirection with logging
call "%%CONTOOLS_ROOT%%\get_datetime.bat"
set "LOG_FILE_NAME_SUFFIX=%RETURN_VALUE:~0,4%'%RETURN_VALUE:~4,2%'%RETURN_VALUE:~6,2%_%RETURN_VALUE:~8,2%'%RETURN_VALUE:~10,2%'%RETURN_VALUE:~12,2%''%RETURN_VALUE:~15,3%"

set IMPL_MODE=1
"%COMSPEC%" /C call %0 %* 2>&1 | "%CONTOOLS_ROOT%\wtee.exe" "%CONFIGURE_DIR%\.log\%LOG_FILE_NAME_SUFFIX%.%~nx0.log"
exit /b

:IMPL
set /A NEST_LVL+=1

rem no local logging if nested call
call :CMD "%%PYTHON_EXE_PATH%%" "%%~dp0cmdop.xsh" %%*
goto EXIT

:CMD
echo.^>%*
echo.
(
  %*
)
exit /b

:EXIT
set LASTERROR=%ERRORLEVEL%

rem to prevent pause call under logging
set /A NEST_LVL-=1

if %NEST_LVL% LEQ 0 pause

exit /b %LASTERROR%

:INIT_EXIT
set LASTERROR=%ERRORLEVEL%

if %NEST_LVL%0 EQU 0 pause

exit /b %LASTERROR%
