@echo off
color 40
cd ..
echo FNF: Project CHORUS Dependency Installer
echo Last updated 16 October 2026
echo Creating .haxelib folder and installing dependencies...
mkdir ".haxelib"
haxelib install hmm
haxelib run hmm install
haxelib remove hmm
echo All dependencies installed successfully!
echo Thank you, and enjoy Project: Chorus!
pause
