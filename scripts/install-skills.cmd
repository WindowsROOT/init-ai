@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Install agent skills on Windows (CMD). macOS/Linux: use install-skills.sh

set "TARGET=both"
set "METHOD=symlink"
set "REPOS=karpathy,mattpocock,9arm"
set "PROJECT_DIR="
set "DRY_RUN=0"
set "UPDATE=0"

if defined LOCALAPPDATA (
  set "CACHE_ROOT=%LOCALAPPDATA%\init-ai\skills-cache"
) else (
  set "CACHE_ROOT=%USERPROFILE%\.local\share\init-ai\skills-cache"
)
set "CURSOR_DEST=%USERPROFILE%\.cursor\skills"
set "CLAUDE_DEST=%USERPROFILE%\.claude\skills"

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="--target" (
  set "TARGET=%~2"
  shift & shift
  goto parse_args
)
if /i "%~1"=="--method" (
  set "METHOD=%~2"
  shift & shift
  goto parse_args
)
if /i "%~1"=="--repos" (
  set "REPOS=%~2"
  shift & shift
  goto parse_args
)
if /i "%~1"=="--project" (
  set "PROJECT_DIR=%~2"
  shift & shift
  goto parse_args
)
if /i "%~1"=="--dry-run" (
  set "DRY_RUN=1"
  shift
  goto parse_args
)
if /i "%~1"=="--update" (
  set "UPDATE=1"
  shift
  goto parse_args
)
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--help" goto show_help
echo error: unknown option %~1 >&2
goto show_help
:args_done

if /i not "%TARGET%"=="cursor" if /i not "%TARGET%"=="claude" if /i not "%TARGET%"=="both" (
  echo error: invalid --target "%TARGET%" ^(use cursor, claude, or both^) >&2
  exit /b 1
)
if /i not "%METHOD%"=="symlink" if /i not "%METHOD%"=="npx" if /i not "%METHOD%"=="all" (
  echo error: invalid --method "%METHOD%" ^(use symlink, npx, or all^) >&2
  exit /b 1
)

set "REPOS_PAD=,%REPOS%,"
call :validate_repos
if errorlevel 1 exit /b 1

if defined PROJECT_DIR (
  echo !REPOS_PAD! | findstr /C:",karpathy," >nul || (
    echo warning: --project is only used with karpathy; add karpathy to --repos >&2
  )
  pushd "%PROJECT_DIR%" 2>nul || (
    echo error: cannot access project directory "%PROJECT_DIR%" >&2
    exit /b 1
  )
  set "PROJECT_DIR=%CD%"
  popd
)

echo !REPOS_PAD! | findstr /C:",karpathy," >nul && call :ensure_cache karpathy
echo !REPOS_PAD! | findstr /C:",mattpocock," >nul && call :ensure_cache mattpocock
echo !REPOS_PAD! | findstr /C:",9arm," >nul && call :ensure_cache 9arm

if defined PROJECT_DIR (
  echo !REPOS_PAD! | findstr /C:",karpathy," >nul && call :install_karpathy_rule
)

echo !REPOS_PAD! | findstr /C:",mattpocock," >nul && (
  if /i "%METHOD%"=="npx" call :install_mattpocock_npx
  if /i "%METHOD%"=="all" call :install_mattpocock_npx
)

if /i "%TARGET%"=="cursor" call :install_all "%CURSOR_DEST%" "Cursor"
if /i "%TARGET%"=="claude" call :install_all "%CLAUDE_DEST%" "Claude Code"
if /i "%TARGET%"=="both" (
  call :install_all "%CURSOR_DEST%" "Cursor"
  call :install_all "%CLAUDE_DEST%" "Claude Code"
)

echo.
echo ==^> Done.
echo !REPOS_PAD! | findstr /C:",mattpocock," >nul && echo   Matt Pocock: run /setup-matt-pocock-skills once per project.
if not defined PROJECT_DIR (
  echo !REPOS_PAD! | findstr /C:",karpathy," >nul && echo   Karpathy: add --project DIR to copy the Cursor rule into a repo.
)
echo   See EXAMPLES.md for prompt examples.
exit /b 0

:show_help
echo Usage: install-skills.cmd [OPTIONS]
echo.
echo Install agent skills from three GitHub repos into Cursor and/or Claude Code.
echo.
echo Options:
echo   --target TARGET     cursor ^| claude ^| both ^(default: both^)
echo   --method METHOD     symlink ^| npx ^| all ^(default: symlink; npx/all for mattpocock^)
echo   --repos LIST        Comma-separated: karpathy,mattpocock,9arm
echo   --project DIR       Copy Karpathy .cursor/rules into DIR
echo   --dry-run           Print actions only
echo   --update            git pull --ff-only in cache
echo   -h, --help          Show this help
echo.
echo Cache: %CACHE_ROOT%
echo.
echo macOS/Linux: scripts\install-skills.sh
exit /b 0

:validate_repos
for %%K in (karpathy mattpocock 9arm) do (
  echo !REPOS_PAD! | findstr /C:",%%K," >nul && goto :validate_ok
)
echo error: --repos must include at least one of karpathy, mattpocock, 9arm >&2
exit /b 1
:validate_ok
for %%R in (%REPOS%) do (
  set "R=%%R"
  set "R=!R: =!"
  if /i not "!R!"=="karpathy" if /i not "!R!"=="mattpocock" if /i not "!R!"=="9arm" (
    echo error: unknown repo !R! >&2
    exit /b 1
  )
)
exit /b 0

:repo_url
if /i "%~1"=="karpathy" set "REPO_URL=https://github.com/multica-ai/andrej-karpathy-skills.git" & exit /b 0
if /i "%~1"=="mattpocock" set "REPO_URL=https://github.com/mattpocock/skills.git" & exit /b 0
if /i "%~1"=="9arm" set "REPO_URL=https://github.com/thananon/9arm-skills.git" & exit /b 0
exit /b 1

:repo_dir
if /i "%~1"=="karpathy" set "REPO_DIR=%CACHE_ROOT%\andrej-karpathy-skills" & exit /b 0
if /i "%~1"=="mattpocock" set "REPO_DIR=%CACHE_ROOT%\mattpocock-skills" & exit /b 0
if /i "%~1"=="9arm" set "REPO_DIR=%CACHE_ROOT%\9arm-skills" & exit /b 0
exit /b 1

:ensure_cache
set "CACHE_KEY=%~1"
call :repo_url %CACHE_KEY%
call :repo_dir %CACHE_KEY%
if not exist "%REPO_DIR%\.git" (
  if "%DRY_RUN%"=="1" (
    echo ==^> [dry-run] would git clone --depth 1 !REPO_URL! "!REPO_DIR!"
    exit /b 0
  )
  if not exist "%CACHE_ROOT%" mkdir "%CACHE_ROOT%"
  echo ==^> Cloning %CACHE_KEY% from !REPO_URL!
  git clone --depth 1 "!REPO_URL!" "!REPO_DIR!"
  if errorlevel 1 exit /b 1
  exit /b 0
)
if "%UPDATE%"=="1" (
  if "%DRY_RUN%"=="1" (
    echo ==^> [dry-run] would git pull --ff-only in "!REPO_DIR!"
    exit /b 0
  )
  echo ==^> Updating %CACHE_KEY% ^(!REPO_DIR!^)
  git -C "!REPO_DIR!" pull --ff-only
) else (
  echo ==^> Using cached %CACHE_KEY% ^(!REPO_DIR!^)
)
exit /b 0

:install_all
set "DEST=%~1"
set "DEST_LABEL=%~2"
echo ==^> Installing to %DEST_LABEL% ^(%DEST%^)

if not exist "%DEST%" (
  if "%DRY_RUN%"=="1" (
    echo ==^> [dry-run] would mkdir "%DEST%"
  ) else (
    mkdir "%DEST%" 2>nul
  )
)

echo !REPOS_PAD! | findstr /C:",karpathy," >nul && call :install_karpathy_skill "%DEST%"
echo !REPOS_PAD! | findstr /C:",mattpocock," >nul && (
  if /i "%METHOD%"=="symlink" (
    call :repo_dir mattpocock
    call :link_skills_tree "!REPO_DIR!" "%DEST%" "mattpocock"
  )
  if /i "%METHOD%"=="all" (
    call :repo_dir mattpocock
    call :link_skills_tree "!REPO_DIR!" "%DEST%" "mattpocock"
  )
)
echo !REPOS_PAD! | findstr /C:",9arm," >nul && (
  call :repo_dir 9arm
  call :link_skills_tree "!REPO_DIR!" "%DEST%" "9arm"
)
exit /b 0

:install_karpathy_skill
set "DEST=%~1"
call :repo_dir karpathy
set "SRC=!REPO_DIR!\skills\karpathy-guidelines"
set "TARGET=%DEST%\karpathy-guidelines"
if not exist "!SRC!\SKILL.md" (
  echo warning: karpathy: !SRC!\SKILL.md not found — skipping >&2
  exit /b 0
)
call :link_one "karpathy-guidelines" "!SRC!" "!TARGET!"
exit /b 0

:install_karpathy_rule
call :repo_dir karpathy
set "RULE_SRC=!REPO_DIR!\.cursor\rules\karpathy-guidelines.mdc"
set "RULE_DEST=%PROJECT_DIR%\.cursor\rules\karpathy-guidelines.mdc"
if not exist "!RULE_SRC!" (
  echo warning: karpathy: rule not found at !RULE_SRC! — skipping >&2
  exit /b 0
)
if "%DRY_RUN%"=="1" (
  echo ==^> [dry-run] would copy "!RULE_SRC!" to "!RULE_DEST!"
  exit /b 0
)
if not exist "%PROJECT_DIR%\.cursor\rules" mkdir "%PROJECT_DIR%\.cursor\rules"
copy /Y "!RULE_SRC!" "!RULE_DEST!" >nul
echo   copied Karpathy rule -^> !RULE_DEST!
exit /b 0

:install_mattpocock_npx
if "%DRY_RUN%"=="1" (
  echo ==^> [dry-run] would run: npx skills@latest add mattpocock/skills -g -y
  exit /b 0
)
where npx >nul 2>&1 || (
  echo error: npx not found — install Node.js or use --method symlink >&2
  exit /b 1
)
echo ==^> Installing mattpocock/skills via npx skills
call npx skills@latest add mattpocock/skills -g -y
if errorlevel 1 (
  echo warning: mattpocock: npx skills add failed — try --method symlink >&2
  echo   npx skills@latest add mattpocock/skills
  exit /b 0
)
echo ==^> mattpocock: npx skills add succeeded
echo.
echo Next: run /setup-matt-pocock-skills in your project
exit /b 0

:link_skills_tree
set "REPO=%~1"
set "DEST=%~2"
set "LABEL=%~3"
if not exist "%REPO%\skills" (
  echo warning: %LABEL%: no skills\ in %REPO% — skipping >&2
  exit /b 0
)
set "LINKED=0"
set "SKIPPED=0"
for /f "delims=" %%F in ('dir /s /b "%REPO%\skills\SKILL.md" 2^>nul') do (
  set "SKILL_MD=%%F"
  set "SKIP_SKILL=0"
  echo !SKILL_MD! | findstr /i "\\deprecated\\" >nul && set "SKIP_SKILL=1"
  echo !SKILL_MD! | findstr /i "\\in-progress\\" >nul && set "SKIP_SKILL=1"
  echo !SKILL_MD! | findstr /i "\\personal\\" >nul && set "SKIP_SKILL=1"
  echo !SKILL_MD! | findstr /i "\\node_modules\\" >nul && set "SKIP_SKILL=1"
  if "!SKIP_SKILL!"=="0" (
    for %%I in ("%%~dpF..") do set "SRC=%%~fI"
    for %%N in ("!SRC!") do set "NAME=%%~nxN"
    set "TARGET=%DEST%\!NAME!"
    call :link_one "!NAME!" "!SRC!" "!TARGET!"
    if "!LINK_RESULT!"=="linked" set /a LINKED+=1
    if "!LINK_RESULT!"=="skipped" set /a SKIPPED+=1
  )
)
echo ==^> %LABEL%: linked !LINKED! skill^(s^), skipped !SKIPPED!
exit /b 0

:link_one
set "NAME=%~1"
set "SRC=%~2"
set "TARGET=%~3"
set "LINK_RESULT=skipped"

if exist "!TARGET!" (
  dir "!TARGET!" 2>nul | findstr /i "<JUNCTION>" >nul && goto :link_one_check_junction
  dir "!TARGET!" 2>nul | findstr /i "<SYMLINKD>" >nul && goto :link_one_check_junction
  echo warning: !TARGET! exists and is not a link — skipping !NAME! >&2
  exit /b 0
)
goto :link_one_do

:link_one_check_junction
for %%A in ("!TARGET!") do set "TARGET_FULL=%%~fA"
for %%B in ("!SRC!") do set "SRC_FULL=%%~fB"
if /i "!TARGET_FULL!"=="!SRC_FULL!" (
  echo   ok !NAME! ^(already linked^)
  set "LINK_RESULT=skipped"
  exit /b 0
)
echo warning: !NAME! already linked elsewhere — skipping >&2
exit /b 0

:link_one_do
if "%DRY_RUN%"=="1" (
  echo   [dry-run] would link !NAME! -^> !SRC!
  set "LINK_RESULT=linked"
  exit /b 0
)
if exist "!TARGET!" rmdir "!TARGET!" 2>nul
mklink /J "!TARGET!" "!SRC!" >nul 2>&1
if not errorlevel 1 (
  echo   linked !NAME! -^> !SRC! ^(junction^)
  set "LINK_RESULT=linked"
  exit /b 0
)
mklink /D "!TARGET!" "!SRC!" >nul 2>&1
if not errorlevel 1 (
  echo   linked !NAME! -^> !SRC! ^(symlink^)
  set "LINK_RESULT=linked"
  exit /b 0
)
echo warning: mklink failed for !NAME! — copying instead >&2
if exist "!TARGET!" rmdir /s /q "!TARGET!" 2>nul
robocopy "!SRC!" "!TARGET!" /E /NFL /NDL /NJH /NJS /nc /ns /np >nul
if errorlevel 8 (
  echo error: robocopy failed for !NAME! >&2
  exit /b 0
)
echo   copied !NAME! -^> !TARGET!
set "LINK_RESULT=linked"
exit /b 0
