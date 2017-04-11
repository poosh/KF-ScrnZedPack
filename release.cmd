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
mkdir %outputdir%\uz2


copy /y %KFDIR%\system\ScrnZedPack.* %outputdir%\System\
copy /y %STEAMDIR%\Animations\ScrnZedPack_A.ukx %outputdir%\Animations\
copy /y %STEAMDIR%\KarmaData\FFPKarma.ka %outputdir%\KarmaData\
copy /y %STEAMDIR%\Sounds\ScrnZedPack_S.uax %outputdir%\Sounds\
copy /y %STEAMDIR%\StaticMeshes\ScrnZedPack_SM.usx %outputdir%\StaticMeshes\
copy /y %STEAMDIR%\Textures\ScrnZedPack_T.utx %outputdir%\Textures\
copy /y *.txt  %outputdir%


echo Compressing to .uz2...
%KFDIR%\system\ucc compress %KFDIR%\system\ScrnZedPack.u
%KFDIR%\system\ucc compress %STEAMDIR%\Animations\ScrnZedPack_A.ukx
%KFDIR%\system\ucc compress %STEAMDIR%\Sounds\ScrnZedPack_S.uax
%KFDIR%\system\ucc compress %STEAMDIR%\StaticMeshes\ScrnZedPack_SM.usx
%KFDIR%\system\ucc compress %STEAMDIR%\Textures\ScrnZedPack_T.utx

move /y %KFDIR%\system\ScrnZedPack.u.uz2 %outputdir%\uz2
move /y %STEAMDIR%\Animations\ScrnZedPack_A.ukx.uz2 %outputdir%\uz2
move /y %STEAMDIR%\Sounds\ScrnZedPack_S.uax.uz2 %outputdir%\uz2
move /y %STEAMDIR%\StaticMeshes\ScrnZedPack_SM.usx.uz2 %outputdir%\uz2
move /y %STEAMDIR%\Textures\ScrnZedPack_T.utx.uz2 %outputdir%\uz2

echo Release is ready!

endlocal

pause

:end
