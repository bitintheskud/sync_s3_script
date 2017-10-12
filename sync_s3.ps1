<#
Author : Alban MUSSI
Date   : 12 oct 17

Why this script:
We needed a script to periodically sync dir before going live on AWS.
This script look at directory in the root dir to sync and run aws s3 sync in //
for those particular directory.

for example if you have :

rootdir/dir1
rootdir/dir2
rootdir/dir3

then the script will run 3 instance of "aws s3 sync" command and no more than
the maxConcurrentCmd number you provide to avoid contention.


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

# Detect the number of instance for a command running on the system.
# if > x  return True else return False
function countProcess( [string]$process ) {
  $n = @(get-process -ea silentlycontinue $process).count
  Write-Host "enter countProcess function. return : $n"
  return [int]$n
}

# Generate a list of directory to sync and how much.
$directoryListing = Get-ChildItem -Path C:\  -Directory | Select  -ExpandProperty FullName
$numberOfDirectoryInListing = (Get-ChildItem -Path C:\  -Directory | measure).count

# aws cli command and args
#$awsCmd = "aws"
#$awsCmdArgs = "s3 sync $exportFolder s3://$bucketName --dryrun"
$awsCmd = "notepad"
$awsCmdArgs = "C:\Users\amussi\out.txt"

$waitTime = 5
$counter = 0
foreach ($dir in $directoryListing) {
  while ($counter -lt $numberOfDirectoryInListing) {
    [int]$y = countProcess -process $awsCmd
    if ($y -lt $maxConcurrentCmd) {
      Write-Host "Starting sync for directory: $dir"
      Write-Host "running : $awsCmd $awsCmdArgs"
      Start-Process $awsCmd -ArgumentList $awsCmdArgs
      $counter++
      Start-Sleep -s 3
    } else {
      Write-Host "Waiting $waitTime second"
      Start-Sleep -s $waitTime
    }
  }
}
