## Why this script:

Transferring small file to aws S3 can be very slow. I wrote this script to
run several instances of "aws s3 sync" in parallele so we maximize our bandwidth.

Each instances will sync a subdirectory inside the root directory. So yes, it
will only work if you have subdirectory. If you have only one big directory with
all the files, it's worthless.

For example if you have the following directory :

```
Directory: D:\filerprod\images

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----       13/10/2017     17:42                football
d-----       13/10/2017     17:43                motogp
d-----       13/10/2017     17:42                tennis
d-----       13/10/2017     17:42                volley
```

In this case, the script can run up to 4 instances of "aws s3 sync" command
(or less), each one will sync one of the directory (football, motogp, etc).

The limit of command you can run is provided by the *maxConcurrentCmd* option.

This script does the following:

1. Get a list of folders from a specified PATH
3. Upload the folders in parallele.

## Pre-requisites

2. AWS ClI is install
3. The "aws configure" has been run with valid keypair/region for the account.

The AWS S3 cli, provide additional configuration values you can use to tune
your transfer. Have a look to :

  - max_concurrent_requests
  - use_accelerate_endpoint

See: http://docs.aws.amazon.com/cli/latest/topic/s3-config.html

## How to use the script

Just ran the command in PS shell.

Example:
```powershell
./sync_s3.ps1 -rootFolder 'D:\Shares\images' -bucketName somebucketname -maxConcurrentCmd 5
```

## What's next

- [ ] Add dryrun option (default valued to False)
- [ ] Add logging for command
- [ ] Add verbose switch
