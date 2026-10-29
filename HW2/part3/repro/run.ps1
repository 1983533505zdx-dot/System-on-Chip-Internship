param(
 [ValidateSet('sim','hardware','sdk','open','wave-debounce','wave-irq','program','read','prepare-prebuilt','diagram')][string]$Action='sim',
 [string]$BuildDir='D:\hw2_rebuild',
 [string]$VivadoRoot='D:\Xilinx_Vivado_SDK_2018.3_1207_2324.tar\Vivado\2018.3',
 [string]$SdkRoot='D:\Xilinx_Vivado_SDK_2018.3_1207_2324.tar\SDK\2018.3'
)
$ErrorActionPreference='Stop'
$repoRoot=$PSScriptRoot
$env:HW2_BUILD_DIR=[IO.Path]::GetFullPath($BuildDir)
$env:HW2_SDK_ROOT=$SdkRoot
if($env:HW2_BUILD_DIR -match '[^\x00-\x7F]' -or $env:HW2_BUILD_DIR -match ' '){throw 'Choose an ASCII build directory without spaces, for example D:\hw2_rebuild'}
New-Item -ItemType Directory -Force -Path $BuildDir,(Join-Path $BuildDir 'Evidence'),(Join-Path $BuildDir 'Export/Board') | Out-Null
if($Action -eq 'prepare-prebuilt'){
 Copy-Item -LiteralPath (Join-Path $repoRoot 'prebuilt/hw2_board.hdf') -Destination (Join-Path $BuildDir 'Export/Board/hw2_board.hdf') -Force
 Copy-Item -LiteralPath (Join-Path $repoRoot 'prebuilt/system_wrapper.bit') -Destination (Join-Path $BuildDir 'Export/Board/system_wrapper.bit') -Force
 Write-Output 'Prebuilt hardware prepared. Run sdk next, then program.';exit 0
}
$jobs=@{'sim'='simulate.tcl';'hardware'='build_hardware.tcl';'sdk'='build_sdk.tcl';'open'='open_project.tcl';'wave-debounce'='view_debounce.tcl';'wave-irq'='view_irq.tcl';'program'='program_run_board.tcl';'read'='read_board_state.tcl';'diagram'='export_diagram.tcl'}
$scriptFile=Join-Path $repoRoot ('scripts/'+$jobs[$Action])
if($Action -in @('sdk','program','read')){
 $tool=Join-Path $SdkRoot 'bin/xsct.bat'
 if(!(Test-Path -LiteralPath $tool)){throw "SDK 2018.3 not found at $SdkRoot"}
 & $tool $scriptFile
 if($LASTEXITCODE -ne 0){throw "SDK action failed: $Action"}
}else{
 $tool=Join-Path $VivadoRoot 'bin/vivado.bat'
 if(!(Test-Path -LiteralPath $tool)){throw "Vivado 2018.3 not found at $VivadoRoot"}
 $mode=if($Action -in @('open','wave-debounce','wave-irq','diagram')){'gui'}else{'batch'}
 Push-Location $BuildDir
 try{
  & $tool -mode $mode -source $scriptFile -log (Join-Path $BuildDir "Evidence/$Action.log") -journal (Join-Path $BuildDir "Evidence/$Action.jou")
  if($LASTEXITCODE -ne 0){throw "Vivado action failed: $Action"}
 }finally{Pop-Location}
}
