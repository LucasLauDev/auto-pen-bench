@echo off
setlocal enabledelayedexpansion

rem =====================================================================
rem  Windows batch equivalent of the original Makefile.
rem  Usage examples:
rem     make.bat build
rem     make.bat install
rem     make.bat test      category task_type vm
rem     make.bat create    category task_type vm
rem =====================================================================

set "BENCHMARK=benchmark"
set "MACHINES=%BENCHMARK%\machines"
set "SOLUTIONS=%BENCHMARK%\solutions"
set "MILESTONES=%BENCHMARK%\milestones"
set "CMD_MILESTONES=%MILESTONES%\command_milestones"
set "STG_MILESTONES=%MILESTONES%\stage_milestones"

set "TARGET=%~1"
set "CATEGORY=%~2"
set "TASK_TYPE=%~3"
set "VM=%~4"

if /I "%TARGET%"=="build"   goto :build
if /I "%TARGET%"=="install" goto :install
if /I "%TARGET%"=="test"    goto :test
if /I "%TARGET%"=="create"  goto :create

echo Unknown target: %TARGET%
echo Valid targets: build, install, test, create
exit /b 1

rem -----------------------------------------------------------------
rem build: find every docker-compose.yml under benchmark, except the
rem one under benchmark\machines, and build them all together.
rem -----------------------------------------------------------------
:build
set "DC="
for /f "delims=" %%F in ('dir /s /b "%BENCHMARK%\docker-compose.yml" 2^>nul') do (
    if /I not "%%F"=="%CD%\%MACHINES%\docker-compose.yml" (
        set "DC=!DC! -f "%%F""
    )
)
docker-compose -f "%MACHINES%\docker-compose.yml" !DC! build
goto :eof

rem -----------------------------------------------------------------
rem install: depends on build, then runs setup\setup.sh
rem NOTE: setup.sh is a shell script; on Windows this requires
rem WSL, Git Bash, or Cygwin to be installed and on PATH.
rem -----------------------------------------------------------------
:install
call :build
bash setup\setup.sh
goto :eof

rem -----------------------------------------------------------------
rem test: category task_type vm
rem -----------------------------------------------------------------
:test
if "%CATEGORY%"=="" (
    echo Usage: make.bat test category task_type vm
    exit /b 1
)
docker-compose -f "%MACHINES%\docker-compose.yml" -f "%MACHINES%\%CATEGORY%\%TASK_TYPE%\docker-compose.yml" build
python3 benchmark\tests\machine_test.py %CATEGORY% %TASK_TYPE% %VM%
goto :eof

rem -----------------------------------------------------------------
rem create: category task_type vm
rem -----------------------------------------------------------------
:create
if "%CATEGORY%"=="" (
    echo Usage: make.bat create category task_type vm
    exit /b 1
)
call :create_structure
goto :eof

:create_structure
echo Creating directories for %CATEGORY%, %TASK_TYPE%, %VM%...
call :ensure_vm
echo All folders created. Doing final task in %VM%...
goto :eof

rem -----------------------------------------------------------------
rem Dependency chain (mimics Make's prerequisite targets):
rem   ensure_vm -> ensure_task_type -> ensure_category
rem -----------------------------------------------------------------

:ensure_category
if not exist "%MACHINES%\%CATEGORY%" (
    mkdir "%MACHINES%\%CATEGORY%"
    mkdir "%CMD_MILESTONES%\%CATEGORY%"
    mkdir "%STG_MILESTONES%\%CATEGORY%"
    mkdir "%SOLUTIONS%\%CATEGORY%"
)
goto :eof

:ensure_task_type
call :ensure_category
if not exist "%MACHINES%\%CATEGORY%\%TASK_TYPE%" (
    mkdir "%MACHINES%\%CATEGORY%\%TASK_TYPE%"
    mkdir "%CMD_MILESTONES%\%CATEGORY%\%TASK_TYPE%"
    mkdir "%STG_MILESTONES%\%CATEGORY%\%TASK_TYPE%"
    mkdir "%SOLUTIONS%\%CATEGORY%\%TASK_TYPE%"

    python3 setup\manage_docker_compose.py create %BENCHMARK% %CATEGORY% %TASK_TYPE% %VM%
)
goto :eof

:ensure_vm
call :ensure_task_type
if not exist "%MACHINES%\%CATEGORY%\%TASK_TYPE%\vm%VM%" (
    rem Create empty Dockerfile and flag for the machine to develop
    mkdir "%MACHINES%\%CATEGORY%\%TASK_TYPE%\vm%VM%"
    type nul > "%MACHINES%\%CATEGORY%\%TASK_TYPE%\vm%VM%\flag.txt"
    type nul > "%MACHINES%\%CATEGORY%\%TASK_TYPE%\vm%VM%\Dockerfile"

    rem Create empty files for milestones and solutions
    type nul > "%CMD_MILESTONES%\%CATEGORY%\%TASK_TYPE%\vm%VM%.txt"
    type nul > "%STG_MILESTONES%\%CATEGORY%\%TASK_TYPE%\vm%VM%.txt"
    type nul > "%SOLUTIONS%\%CATEGORY%\%TASK_TYPE%\vm%VM%.txt"

    rem Update the docker-compose with a default service
    python3 setup\manage_docker_compose.py update %BENCHMARK% %CATEGORY% %TASK_TYPE% %VM%
    rem Update the input file
    python3 setup\manage_input_data.py %CATEGORY% %TASK_TYPE% %VM%
)
goto :eof