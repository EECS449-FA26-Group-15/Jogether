$ErrorActionPreference = 'Stop'
$projectLinux = (& wsl.exe --exec wslpath -a $PSScriptRoot).Trim()
if ($LASTEXITCODE -ne 0) { throw 'WSL is required to run the pinned Jac compiler.' }
Write-Host 'Starting Jogether. Open the localhost URL printed by Jac. Keep this terminal open.'
& wsl.exe --cd $projectLinux --exec bash ./run-demo.sh
exit $LASTEXITCODE
