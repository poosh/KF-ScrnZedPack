@echo off

setlocal
color 07

set KFDIR=D:\Games\kf
set STEAMDIR=c:\Steam\steamapps\common\KillingFloor
rem remember current directory
set CURDIR=%~dp0

cd /D %KFDIR%\System
del ScrnZedPack.u

rem ucc make > %CURDIR%\make.log
ucc make > %CURDIR%\make.log
set ERR=%ERRORLEVEL%
if %ERR% NEQ 0 goto error
color 0A


del KillingFloor.log
del steam_appid.txt

del %STEAMDIR%\System\KillingFloor.log
copy ScrnZedPack.u %STEAMDIR%\System\
copy ScrnZedPack.ucl %STEAMDIR%\System\
copy ScrnZedPack.int %STEAMDIR%\System\

echo --------------------------------
echo Compile successful.
echo --------------------------------
goto end

:error
color 0C

type %CURDIR%\make.log

echo ################################
echo Compile ERROR! Code = %ERR%.
echo ################################

:end
pause

rem return to previous directory
cd /D %CURDIR%

set ERRORLEVEL=%ERR%

endlocal