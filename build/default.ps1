$psversionTable | out-string | write-host

properties {
  $testFilePattern = "$PSScriptRoot\..\src\targets\tests"
  $toolsDir = "$PSScriptRoot\.tools"
  $nugetPath = "$toolsDir\nuget.exe"
  $tasksSolutionPath = "$PSScriptRoot\..\src\tasks"

  if ($env:CI) {
    $xunitPath = "$env:xunit20\xunit.console"
  } else {
    $xunitPath = "$PSScriptRoot\..\src\tasks\packages\xunit.runner.console.2.3.0\tools\net452\xunit.console.exe"
  }
}

task default -depends Test

task GetNuget {
  if (-not (Test-Path $nugetPath)) {
    if (-not (Test-Path $toolsDir)) {
        mkdir $toolsDir | Out-Null
    }

    Invoke-WebRequest -OutFile "$toolsDir\nuget.exe" -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
  }
}

task Restore -depends GetNuGet {
  if (-not $env:CI) {
    & $nugetPath restore $tasksSolutionPath
  }
}

task BuildTasks -depends Restore {
  & msbuild "$PSScriptRoot\..\src\tasks\RichardSzalay.Helix.Publishing.Tasks.sln" "/P:Configuration=Release" "/m" "/v:m"
}

task TestTasks -depends BuildTasks {
  & $xunitPath "$PSScriptRoot\..\src\tasks\RichardSzalay.Helix.Publishing.Tasks.Tests\bin\Debug\RichardSzalay.Helix.Publishing.Tasks.Tests.dll" -nunit tasks-test-results.xml
}

task Test -depends TestTasks,TestTargets

task TestTargets {
  $res = Invoke-Pester -Script @{ Path = $testFilePattern } -OutputFormat NUnitXml -OutputFile .\ps-results.xml -PassThru
  
  if ($env:APPVEYOR_JOB_ID)
  {
    $wc = New-Object 'System.Net.WebClient'
    $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path .\ps-results.xml))
  }

  if ($res.FailedCount -gt 0) { 
      throw "$($res.FailedCount) tests failed."
  }
}
