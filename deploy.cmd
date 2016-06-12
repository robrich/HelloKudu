@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: ----------------------
:: KUDU Deployment Script
:: Version: 1.0.6
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)
IF NOT DEFINED DEPLOYMENT_TEMP (
  SET DEPLOYMENT_TEMP=%temp%\___deployTemp%random%
  SET CLEAN_LOCAL_DEPLOYMENT_TEMP=true
)

IF DEFINED CLEAN_LOCAL_DEPLOYMENT_TEMP (
  IF EXIST "%DEPLOYMENT_TEMP%" rd /s /q "%DEPLOYMENT_TEMP%"
  mkdir "%DEPLOYMENT_TEMP%"
)

IF DEFINED MSBUILD_PATH goto MsbuildPathDefined
SET MSBUILD_PATH=%ProgramFiles(x86)%\MSBuild\14.0\Bin\MSBuild.exe
:MsbuildPathDefined

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Handling .NET Web Application deployment.

:: 1. Restore NuGet packages
IF /I "HelloKudu.sln" NEQ "" (
  call :ExecuteCmd nuget restore "%DEPLOYMENT_SOURCE%\HelloKudu.sln"
  IF !ERRORLEVEL! NEQ 0 goto error
)

:: 2. Set GITHASH in AssemblyInfo.cs
call :ExecuteCmd PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -Command "(Get-Content src\Web\Properties\AssemblyInfo.cs).replace('GITHASH', (git rev-parse --short HEAD)) | Set-Content src\Web\Properties\AssemblyInfo.cs"

:: 3. Run ESLint and Gulp
:: upgrade npm
call npm cache clean
call npm install -g npm
pushd "%DEPLOYMENT_SOURCE%"
call npm install
IF !ERRORLEVEL! NEQ 0 goto error
call npm test
IF !ERRORLEVEL! NEQ 0 goto error
call npm run build
IF !ERRORLEVEL! NEQ 0 goto error
popd

:: 4. Build SolutionDir
call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\HelloKudu.sln" /nologo /maxcpucount /verbosity:m /property:Configuration=Release /property:ToolsVersion=12.0 %SCM_BUILD_ARGS%
IF !ERRORLEVEL! NEQ 0 goto error

:: 5. Run unit tests
"%DEPLOYMENT_SOURCE%\packages\xunit.runner.console.2.1.0\tools\xunit.console.exe" "%DEPLOYMENT_SOURCE%\src\Web.Tests\bin\Release\HelloKudu.Web.Tests.dll"
IF !ERRORLEVEL! NEQ 0 goto error

:: 6. Migrate database
:: Parse "%SQLAZURECONNSTR_DefaultConnectionString%" into %server%, %db%, %user%, %password%
:: pushd "%DEPLOYMENT_SOURCE%"
:: call tools\sqlcompare-11.2.3.12\sqlcompare.exe /scripts1:sql /server2:%server% /db2:%db% /username2:%user% /password2:%password% /sync /Include:Identical /exclude:role /exclude:user
:: IF !ERRORLEVEL! NEQ 0 goto error
:: call tools\sqldatacompare-11.2.3.12\sqldatacompare.exe /scripts1:sql /server2:%server% /db2:%db% /username2:%user% /password2:%password% /sync /Include:Identical /AbortOnWarnings
:: IF !ERRORLEVEL! NEQ 0 goto error
:: popd

:: 7. Build site to the temporary path
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\src\Web\Web.csproj" /nologo /verbosity:m /t:Build /t:pipelinePreDeployCopyAllFilesToOneFolder /p:_PackageTempDir="%DEPLOYMENT_TEMP%";AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false /p:SolutionDir="%DEPLOYMENT_SOURCE%\.\\" %SCM_BUILD_ARGS%
) ELSE (
  call :ExecuteCmd "%MSBUILD_PATH%" "%DEPLOYMENT_SOURCE%\src\Web\Web.csproj" /nologo /verbosity:m /t:Build /p:AutoParameterizationWebConfigConnectionStrings=false;Configuration=Release;UseSharedCompilation=false /p:SolutionDir="%DEPLOYMENT_SOURCE%\.\\" %SCM_BUILD_ARGS%
)
IF !ERRORLEVEL! NEQ 0 goto error

:: 8. KuduSync content into place
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_TEMP%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
  IF !ERRORLEVEL! NEQ 0 goto error
)

:: 9. Test website
:: https://www.amido.com/code/powershell-win32-internal-error-the-handle-is-invalid-0x6/
call :ExecuteCmd PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -Command "$ProgressPreference = 'SilentlyContinue'; exit ((invoke-webrequest -method head -uri 'http://%WEBSITE_HOSTNAME%/' -UseBasicParsing).statuscode - 200)"
IF !ERRORLEVEL! NEQ 0 goto error


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Post deployment stub
IF DEFINED POST_DEPLOYMENT_ACTION call "%POST_DEPLOYMENT_ACTION%"
IF !ERRORLEVEL! NEQ 0 goto error

goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal
echo Finished successfully.
