@echo off
color 40
cd ..
echo ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo ³ FNF: Project CHORUS Dependency Installer ³
echo ³      Last updated 1 November 2026        ³
echo ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
echo:
echo This process will install dependencies into a local .haxelib folder.
echo The local folder will ensure that this build doesn't interfere with other projects.
echo If a .haxelib folder exists, this program will overwrite any dependencies stored in the existing folder.
echo:
CHOICE /M "Create build dependencies "
echo %errorlevel%
if errorlevel == 2 (
  goto cancel-program
)
if errorlevel == 1 (
  goto dependency-build
)
if errorlevel == 0 (
  goto cancel-program
)

:dependency-build
echo:
echo Creating .haxelib folder...
mkdir ".haxelib"
echo:
echo Installing hmm installer...
haxelib install hmm
echo:
echo Installing dependencies...
haxelib run hmm install
echo:
echo Removing hmm installer...
haxelib remove hmm
echo:
echo Updating haxelib library as a failsafe...
haxelib fixrepo
echo:
echo ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo ³ All dependencies installed successfully! ³
echo ³  Thank you, and enjoy Project: Chorus!   ³
echo ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
echo:
pause

:cancel-program
echo:
echo Program has been cancelled.
pause
