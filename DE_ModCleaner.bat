@ECHO OFF
CLS
SETLOCAL ENABLEEXTENSIONS DISABLEDELAYEDEXPANSION
SET "$SCRIPTVERSION=v1.4"
SET "$TITLEHEADER=DE ModCleaner %$SCRIPTVERSION%-BATCH"

REM | Check for command-line parameters
:CHECK_PARAMS
REM | Check for "help" argument
IF /I "x%~1" EQU "x--help" (
	CALL :RUN_HELP
	EXIT /B
)
IF /I "x%~1" EQU "x-h" (
	CALL :RUN_HELP
	EXIT /B
)
IF /I "x%~1" EQU "x-?" (
	CALL :RUN_HELP
	EXIT /B
)
IF /I "x%~1" EQU "x/?" (
	CALL :RUN_HELP
	EXIT /B
)
REM | Standard arguments
IF /I "x%~1" EQU "x-q" (
	SET "$QUIETMODE=Y"
	SHIFT
	GOTO CHECK_PARAMS
)
IF /I "x%~1" EQU "x--quiet" (
	SET "$QUIETMODE=Y"
	SHIFT
	GOTO CHECK_PARAMS
)
IF /I "x%~1" EQU "x--dry-run" (
	SET "$DRYRUN=Y"
	SHIFT
	GOTO CHECK_PARAMS
)

REM | Aliases and other variables
SET "$ECHO_Q=IF NOT DEFINED $QUIETMODE ECHO"
SET "$ORIGDIR=%CD%"

REM | Set and create temp dirs/files
:SET_TEMPDIR
SET "$TEMPDIR=%TEMP%\DE_ModCleaner_%RANDOM:~-1%%RANDOM:~-1%%RANDOM:~-1%%RANDOM:~-1%%RANDOM:~-1%"
IF EXIST "%$TEMPDIR%" GOTO SET_TEMPDIR
SET "$LIST=%$TEMPDIR%\temp.txt"
MKDIR "%$TEMPDIR%"

REM | Display script banner
IF NOT DEFINED $QUIETMODE CALL :BANNER

REM | Tool check
%$ECHO_Q% Checking for required tools...
%$ECHO_Q%.
FOR %%A IN (FIND;FINDSTR;POWERSHELL;XCOPY) DO (CALL :CHECK_FOR_TOOL "%%~A" || GOTO END_SCRIPT)
FOR /F "tokens=*" %%A IN ('POWERSHELL -Command "[system.console]::title"') DO SET "$ORIGTITLE=%%~A"
TITLE %$TITLEHEADER%

REM | Generate and parse sorted resource-load list
CALL :GENERATE_ORDERFILE >"%$TEMPDIR%\order.txt"

ECHO. >"%$LIST%"
FOR /F "tokens=*" %%A IN (%$TEMPDIR%\order.txt) DO (
	IF "x%%~A" NEQ "x=" (
		IF EXIST "%$ORIGDIR%\%%~nA" (
			SET "$FOUND=Y"
			CD /D "%$ORIGDIR%\%%~nA" >NUL
			%$ECHO_Q% == %%~A ==
			TITLE %$TITLEHEADER% ^| %%~A ^| Generating file list...
			XCOPY /L /S /Y /R ".\*.*" "%$TEMPDIR%" | FIND ".\" >"%$TEMPDIR%\filelist.txt"
			FOR /F "tokens=*" %%B IN (%$TEMPDIR%\filelist.txt) DO (
				SET "$SKIPCHECK="
				FOR %%C IN (json) DO IF /I "x%%~xB" EQU "x.%%~C" SET "$SKIPCHECK=Y"
				IF NOT DEFINED $SKIPCHECK (CALL :TEST_FOR_DUPE "%%~B" "%%~A" || GOTO END_SCRIPT)
			)
			CD /D "%$ORIGDIR%" >NUL
			%$ECHO_Q%.
		)
	) ELSE (
		ECHO. >"%$LIST%"
	)
)

REM | Clean any empty directories after processing
IF "x%$FOUND%" EQU "xY" (
	TITLE %$TITLEHEADER% ^| Cleaning empty directories...
	%$ECHO_Q% Cleaning empty directories...
	IF NOT DEFINED $DRYRUN FOR /F "tokens=*" %%A IN ('DIR /S /B /AD ^| SORT /R') DO RMDIR /Q "%%~A" 2>NUL
	%$ECHO_Q%.
)
TITLE %$TITLEHEADER% ^| Search completed!
%$ECHO_Q% Search completed!
GOTO END_SCRIPT

REM | Check temp.txt for a line containing the given string
:TEST_FOR_DUPE
TITLE %$TITLEHEADER% ^| %~2 ^| %~1
FINDSTR /X /C:"%~1" "%$LIST%" >NUL
IF "x%ERRORLEVEL%" EQU "x0" (
	%$ECHO_Q% * Dupe found: %~1
	IF NOT DEFINED $DRYRUN (
		DEL /Q "%~1"
		IF EXIST "%~1" (
			ECHO !! CRITICAL: File removal failed!
			EXIT /B 1
		)
	)
) ELSE (
	ECHO %~1>>"%$LIST%"
)
EXIT /B 0

REM | Check for given tool; exit if fail
:CHECK_FOR_TOOL
WHERE "%~1" >NUL 2>&1
IF "x%ERRORLEVEL%" NEQ "x0" (
	ECHO !! CRITICAL: %~1 not found!
	EXIT /B 1
)
EXIT /B 0

REM | Help prompt
:RUN_HELP
CALL :BANNER
ECHO     Usage:
ECHO.
ECHO         DE_ModCleaner [--help ^| -h ^| -? ^| /?] [-q ^| --quiet] [--dry-run]
ECHO.
ECHO     Options:
ECHO.
ECHO         --help ^| -h ^| -? ^| /?
ECHO             Runs this help prompt and exits.
ECHO.
ECHO         -q ^| --quiet
ECHO             Suppresses script output and prompts (not including critical errors).
ECHO.
ECHO         --dry-run
ECHO             Simulates how the script would run without deleting any files/directories.
EXIT /B

REM | The priority order list; sets are separated with '='
:GENERATE_ORDERFILE
ECHO gameresources_patch1
ECHO gameresources_patch2
ECHO gameresources
ECHO =
::ECHO meta
::ECHO =
::ECHO warehouse
::ECHO =
ECHO hub
ECHO hub_patch1
ECHO =
ECHO e1m1_intro_patch1
ECHO e1m1_intro_patch2
ECHO e1m1_intro
ECHO =
ECHO e1m2_battle_patch2
ECHO e1m2_battle_patch1
ECHO e1m2_battle
ECHO =
ECHO e1m3_cult_patch3
ECHO e1m3_cult_patch2
ECHO e1m3_cult_patch1
ECHO e1m3_cult
ECHO =
ECHO e1m4_boss_patch2
ECHO e1m4_boss_patch1
ECHO e1m4_boss
ECHO =
ECHO e2m1_nest_patch1
ECHO e2m1_nest_patch2
ECHO e2m1_nest
ECHO =
ECHO e2m2_base_patch1
ECHO e2m2_base_patch2
ECHO e2m2_base
ECHO =
ECHO e2m3_core_patch3
ECHO e2m3_core_patch2
ECHO e2m3_core_patch1
ECHO e2m3_core
ECHO =
ECHO e2m4_boss_patch2
ECHO e2m4_boss_patch1
ECHO e2m4_boss
ECHO =
ECHO e3m1_slayer_patch2
ECHO e3m1_slayer_patch1
ECHO e3m1_slayer
ECHO =
ECHO e3m2_hell_patch2
ECHO e3m2_hell_patch1
ECHO e3m2_hell
ECHO =
ECHO e3m2_hell_b_patch2
ECHO e3m2_hell_b_patch1
ECHO e3m2_hell_b
ECHO =
ECHO e3m3_maykr_patch1
ECHO e3m3_maykr_patch2
ECHO e3m3_maykr
ECHO =
ECHO e3m4_boss_patch2
ECHO e3m4_boss_patch1
ECHO e3m4_boss
ECHO =
ECHO dlc_hub_patch1
ECHO dlc_hub
ECHO =
ECHO e4m1_rig_patch2
ECHO e4m1_rig_patch1
ECHO e4m1_rig
ECHO =
ECHO e4m2_swamp_patch1
ECHO e4m2_swamp_patch2
ECHO e4m2_swamp
ECHO =
ECHO e4m3_mcity_patch1
ECHO e4m3_mcity
ECHO =
ECHO e5m1_spear_patch1
ECHO e5m1_spear
ECHO =
ECHO e5m2_earth_patch1
ECHO e5m2_earth
ECHO =
ECHO e5m3_hell_patch1
ECHO e5m3_hell
ECHO =
ECHO e5m4_boss_patch1
ECHO e5m4_boss
ECHO =
ECHO pvp_bronco_patch1
ECHO pvp_bronco
ECHO =
ECHO pvp_darkmetal
ECHO =
ECHO pvp_deathvalley_patch1
ECHO pvp_deathvalley
ECHO =
ECHO pvp_inferno_patch1
ECHO pvp_inferno
ECHO =
ECHO pvp_laser_patch1
ECHO pvp_laser
ECHO =
ECHO pvp_shrapnel_patch1
ECHO pvp_shrapnel
ECHO =
ECHO pvp_thunder_patch1
ECHO pvp_thunder
ECHO =
ECHO pvp_zap_patch1
ECHO pvp_zap
ECHO =
::ECHO tutorial_sp
::ECHO =
::ECHO tutorial_demons
::ECHO =
ECHO tutorial_pvp_laser_patch1
ECHO tutorial_pvp_laser
ECHO =
ECHO shell_patch1
ECHO shell
EXIT /B

REM | Extra comment to fill space because Batch is fucking weird

REM | Da banner
:BANNER
ECHO.
ECHO #############################
ECHO #                           #
ECHO #       DE ModCleaner       #
ECHO #           %$SCRIPTVERSION%            #
ECHO #                           #
ECHO #            by             #
ECHO #       Wryyyong#2935       #
ECHO #                           #
ECHO #############################
ECHO.
EXIT /B

REM | Cleanup and exiting
:END_SCRIPT
RMDIR /S /Q "%$TEMPDIR%"
CD /D "%$ORIGDIR%"
IF NOT DEFINED $QUIETMODE (
	ECHO.
	ECHO Press any key to exit.
	PAUSE >NUL
)
IF DEFINED $ORIGTITLE TITLE %$ORIGTITLE%