<#
Author : Alban MUSSI
Date   : 12 oct 17

Why this script:
We needed a script to periodically sync dir from on prem to S3.
This script will list directory in the local directory and run "aws s3 sync" command
in parallele.

for example if you have 3 directory :

rootdir/dir1
rootdir/dir2
rootdir/dir3

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


#-----
# Variables

# Logs parameters
$workingDir = C:\Temp

# date format is (day)(month)(year)-(hour)(minute)(second)
$date = Get-Date  -format dMyyyy-hhhmss

# list the directory to sync and count them.
$directoryListing = Get-ChildItem -Path C:\  -Directory | Select  -ExpandProperty FullName
$numberOfDirectoryInListing = (Get-ChildItem -Path C:\  -Directory | measure).count

# aws cli command and args
$awsCmd = "aws"
$awsCmdArgs = "s3 sync $exportFolder s3://$bucketName --dryrun --only-show-errors"


#------
# Functions

# Detect the number of instance for a command running on the system.
# if > x  return True else return False
function countProcess( [string]$process ) {
  $n = @(get-process -ea silentlycontinue $process).count
  Write-Host "enter countProcess function. return : $n"
  return [int]$n
}

#------
# Main

$waitTime = 5
$counter = 0
foreach ($dir in $directoryListing) {
  while ($counter -lt $numberOfDirectoryInListing) {
    [int]$y = countProcess -process $awsCmd
    if ($y -lt $maxConcurrentCmd) {
      $logFile = "aws_s3_sync_" + $dir + "-" + $date + ".log"
      Write-Host "Starting sync for directory: $dir"
      Write-Host "running : $awsCmd $awsCmdArgs"
      #Start-Process $awsCmd -ArgumentList $awsCmdArgs -WorkingDirectory $workingDir -RedirectStandardOutput $logFile
      $counter++
      Start-Sleep -s 15
    } else {
      Write-Host "Waiting $waitTime second"
      Start-Sleep -s $waitTime
    }
  }
}
