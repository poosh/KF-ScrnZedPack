@echo off

setlocal
set KFDIR=d:\Games\kf
set STEAMDIR=c:\Steam\steamapps\common\KillingFloor
set outputdir=D:\KFOut\ScrnZedPack

echo Removing previous release files...
del /S /Q %outputdir%\*


echo Compiling project...
call make.cmd
if %ERRORLEVEL% NEQ 0 goto end

echo Exporting .int file...
%KFDIR%\system\ucc dumpint ScrnZedPack.u

echo.
echo Copying release files...
mkdir %outputdir%\Animations
mkdir %outputdir%\KarmaData
mkdir %outputdir%\Sounds
mkdir %outputdir%\StaticMeshes
mkdir %outputdir%\System
mkdir %outputdir%\Textures
REM mkdir %outputdir%\uz2


copy /y %KFDIR%\system\ScrnZedPack.* %outputdir%\System\
copy /y %STEAMDIR%\Animations\ScrnZedPack_A.ukx %outputdir%\Animations\
copy /y %STEAMDIR%\KarmaData\FFPKarma.ka %outputdir%\KarmaData\
copy /y %STEAMDIR%\Sounds\ScrnZedPack_S.uax %outputdir%\Sounds\
copy /y %STEAMDIR%\StaticMeshes\ScrnZedPack_SM.usx %outputdir%\StaticMeshes\
copy /y %STEAMDIR%\Textures\ScrnZedPack_T.utx %outputdir%\Textures\
copy /y *.txt  %outputdir%


REM echo Compressing to .uz2...
REM %KFDIR%\system\ucc compress %KFDIR%\system\ScrnZedPack.u
REM %KFDIR%\system\ucc compress %STEAMDIR%\Animations\ScrnZedPack_A.ukx
REM %KFDIR%\system\ucc compress %STEAMDIR%\Sounds\ScrnZedPack_S.uax
REM %KFDIR%\system\ucc compress %STEAMDIR%\StaticMeshes\ScrnZedPack_SM.usx
REM %KFDIR%\system\ucc compress %STEAMDIR%\Textures\ScrnZedPack_T.utx
REM
REM move /y %KFDIR%\system\ScrnZedPack.u.uz2 %outputdir%\uz2
REM move /y %STEAMDIR%\Animations\ScrnZedPack_A.ukx.uz2 %outputdir%\uz2
REM move /y %STEAMDIR%\Sounds\ScrnZedPack_S.uax.uz2 %outputdir%\uz2
REM move /y %STEAMDIR%\StaticMeshes\ScrnZedPack_SM.usx.uz2 %outputdir%\uz2
REM move /y %STEAMDIR%\Textures\ScrnZedPack_T.utx.uz2 %outputdir%\uz2

echo Release is ready!

endlocal

pause

:end
