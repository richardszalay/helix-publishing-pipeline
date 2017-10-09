$psversionTable | out-string | write-host

properties {
  $testFilePattern = "$PSScriptRoot\..\src\tests"
}

task default -depends Test

task Test {
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
