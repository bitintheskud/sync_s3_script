<#
Author : Alban MUSSI
Date   : 12 oct 17

Why this script:
We needed a script to periodically sync dir from on prem to S3.
This script will list directory in the local directory and run "aws s3 sync" command
in parallele.

for example if you have 3 directory :

myimages/dir1
myimages/dir2
myimages/dir3

The script will run 3 instances of "aws s3 sync" command. The limit of command
you can run is provided by the maxConcurrentCmd option (no more than)

This script does the following:

1. Get a list of folders from a specified PATH
3. Upload the folders in parallele.

Pre-requisites :
1. AWS powershell extension is install
2. AWS Cli is install
3. The "aws configure" has been run with valid keypair/region for the account.

Example:
sync_s3.ps1 -rootFolder 'D:\Shares\images ' -bucketName somebucketname -maxConcurrentCmd 5 -logfileName sync.log
#>
param (
  [Parameter(Mandatory=$true)]
  [string]$exportFolder,
  [Parameter(Mandatory=$true)]
  [string]$bucketName,
  [Parameter(Mandatory=$true)]
  [ValidateRange(1, 10)]
  [int]$maxConcurrentCmd
)

#--------------
# Variables

# Logs parameters
$workingDir = "C:\Scripts\sync_s3"
$logDir = "C:\logs\sync_s3"
$logFile = "$logDir\sync_s3.log"
$date = Get-Date -format ddMy-Hmmss


# list the directory to sync and count them.
$directoryListing = Get-ChildItem -Path $exportFolder  -Directory | Select  -ExpandProperty FullName
$numberOfDirectoryInListing = (Get-ChildItem -Path $exportFolder  -Directory | measure).count

#--------------
# Functions

# Detect the number of instance for a command running on the system.
# if > x  return True else return False
function countProcess( [string]$process ) {
  $n = @(get-process -ea silentlycontinue $process).count
  return [int]$n
}

# Return Date for for log
function dateLog() {
  Get-Date -format "dd/M/y - hh:mm:ss"
}

# Log message
function logMsg([string]$msg ) {
  # Write on terminal
  Write-Host $msg
  # Write to file
  Add-Content $logFile -Value $out
}

#--------------
# Main

$waitTime = 900  # 15mn
$awsCmd = "aws"

foreach ($dir in $directoryListing) {
  # aws cli command and args
  $baseName = (Get-Item $dir).BaseName
  # Output will be log into a log file separetly
  $standardOutput = "$logDir\aws_s3_sync_" + $baseName + "-" + $date + ".log"
  $standardError = "$logDir\aws_s3_sync_" + $baseName + "-" + $date + ".errors.log"
  $awsCmdArgs = "s3 sync $dir s3://$bucketName/$baseName --only-show-errors"

  # We count the number of process running and wait if necessary
  [int]$n = countProcess -process $awsCmd
  while ($n -ge $maxConcurrentCmd) {
    $out = (dateLog) + " INFO: reach max sync command running ($n) - Waiting $waitTime second"
    logMsg($out)
    Start-Sleep -s $waitTime
	  [int]$n = countProcess -process $awsCmd
  }

  $out = (dateLog) + " INFO: Starting sync for directory: $dir"
  logMsg($out)

  $out = (dateLog) + " INFO: running $awsCmd $awsCmdArgs"
  logMsg($out)

  Start-Process $awsCmd -ArgumentList $awsCmdArgs -RedirectStandardOutput $standardOutput -RedirectStandardError $standardError
  Start-Sleep 5
}
