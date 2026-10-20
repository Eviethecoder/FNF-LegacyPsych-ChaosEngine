@echo off
setlocal
color 40
set buildplat=0
set buildtype=0
set buildtelem=0
goto start-prog

:start-prog
echo ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo ³ FNF: Project CHORUS Building Program ³
echo ³    Last updated 20 October 2026      ³
echo ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
echo:
echo This process will create a hardcoded Project: CHORUS distributable build.
echo The build will be located in the "export" folder.
echo Debug builds will be located in "export/debug"; all other builds will be located in "export/release".
echo If creating a telemetry build (for tracy or hxScout), "-tel" will be appended to the folder name (example: "export/release-tel").
echo Your build will then be located in a folder named for your platform of choice.
echo:
echo ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ!! WARNING !!ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
echo This program will overwrite any releases in the build's path.
echo ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
echo:
CHOICE /c wml /n /m "What platform are you building for ([W]indows, [M]ac, [L]inux)?"
if %errorlevel% == 0 goto cancel-prog
if %errorlevel% == 1 (
  set buildplat=Windows
  goto inquire-debug
)
if %errorlevel% == 2 (
  set buildplat=Mac
  goto inquire-debug
)
if %errorlevel% == 3 (
  set buildplat=Linux
  goto inquire-debug
)
if %errorlevel% == 255 goto error-prog

:inquire-debug
echo Build platform set for %buildplat%.
echo:
CHOICE /c dr /n /m "Is this a [D]ebug or [R]elease build?"
if %errorlevel% == 0 goto cancel-prog
if %errorlevel% == 1 (
  set buildtype=Debug
  goto inquire-telem
)
if %errorlevel% == 2 (
  set buildtype=Release
  goto inquire-telem
)
if %errorlevel% == 255 goto error-prog

:inquire-telem
echo Build set for %buildtype% build.
echo:
CHOICE /m "Is this a hxTelemetry (hxScout, tracy, etc) build "
if %errorlevel% == 0 goto cancel-prog
if %errorlevel% == 1 (
  set buildtelem=On
  goto inquire-confirm
)
if %errorlevel% == 2 (
  set buildtelem=Off
  goto inquire-confirm
)
if %errorlevel% == 255 goto error-prog

:inquire-confirm
echo:
echo ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo ³          Settings for Build:         ³
echo ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
echo   Platform:  %buildplat%
echo   Type:      %buildtype%
echo   Telemetry? %buildtelem%
echo ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
echo:
CHOICE /c yrc /n /m "Create a build using the above settings ([Y]es, [R]estart Program/No, [C]ancel Program)?"
if %errorlevel% == 255 goto error-prog
if %errorlevel% == 3 (
  echo:
  goto cancel-prog
)
if %errorlevel% == 2 (
  cls
  goto start-prog
)
if %errorlevel% == 1 (
  cls
  goto create-build
)
if %errorlevel% == 0 goto cancel-prog


:create-build
echo:
echo  Creating %buildtype% build for %buildplat% with telemetry %buildtelem%...
echo ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ
if %buildplat%==Windows (
  if %buildtype%==Release (
    if %buildtelem%==On (
      haxelib run lime build windows -Dtelemetry -Djs-source-map -clean
      echo:
      echo Successfully created build for Windows with Telemetry functions.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/release-tel/windows/bin".
    )
    if %buildtelem%==Off (
      haxelib run lime build windows -Djs-source-map -clean
      echo:
      echo Successfully created build for Windows.
      echo If you choose to distribute this build, zip and distrubute the contents of "export/release-tel/windows/bin".
    )
  )
  if %buildtype%==Debug (
    if %buildtelem%==On (
      haxelib run lime build windows -debug -Dtelemetry -Djs-source-map -clean
      echo:
      echo Successfully created debug build for Windows with Telemetry functions.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/debug-tel/windows/bin".
    )
    if %buildtelem%==Off (
      haxelib run lime build windows -debug -Djs-source-map -clean
      echo:
      echo Successfully created debug build for Windows.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/debug/windows/bin".
    )
  )
)
if %buildplat%==Mac (
  if %buildtype%==Release (
    if %buildtelem%==On (
      haxelib run lime build macos -Dtelemetry -Djs-source-map -clean
      echo:
      echo Successfully created build for Mac with Telemetry functions.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/release-tel/macos/bin".
    )
    if %buildtelem%==Off (
      haxelib run lime build macos -Djs-source-map -clean
      echo:
      echo Successfully created build for Mac.
      echo If you choose to distribute this build, zip and distrubute the contents of "export/release-tel/macos/bin".
    )
  )
  if %buildtype%==Debug (
    if %buildtelem%==On (
      haxelib run lime build macos -debug -Dtelemetry -Djs-source-map -clean
      echo:
      echo Successfully created debug build for Mac with Telemetry functions.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/debug-tel/macos/bin".
    )
    if %buildtelem%==Off (
      haxelib run lime build macos -debug -Djs-source-map -clean
      echo:
      echo Successfully created debug build for Mac.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/debug/macos/bin".
    )
  )
)
if %buildplat%==Linux (
  if %buildtype%==Release (
    if %buildtelem%==On (
      haxelib run lime build linux -Dtelemetry -Djs-source-map -clean
      echo:
      echo Successfully created build for Linux with Telemetry functions.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/release-tel/linux/bin".
    )
    if %buildtelem%==Off (
      haxelib run lime build linux -Djs-source-map -clean
      echo:
      echo Successfully created build for Linux.
      echo If you choose to distribute this build, zip and distrubute the contents of "export/release-tel/linux/bin".
    )
  )
  if %buildtype%==Debug (
    if %buildtelem%==On (
      haxelib run lime build linux -debug -Dtelemetry -Djs-source-map -clean
      echo:
      echo Successfully created debug build for Linux with Telemetry functions.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/debug-tel/linux/bin".
    )
    if %buildtelem%==Off (
      haxelib run lime build linux -debug -Djs-source-map -clean
      echo:
      echo Successfully created debug build for Linux.
      echo It's not recommended to distribute this build.
      echo Executable file is located in "export/debug/linux/bin".
    )
  )
)
echo ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo ³ Thank you, and enjoy Project: Chorus! ³
echo ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
goto finale

:cancel-prog
echo ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo ³ ! Build program cancelled. ! ³
echo ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
goto finale

:error-prog
echo ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
echo ³ ! Error running build program. ! ³
echo ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
goto finale

:finale
echo:
pause
