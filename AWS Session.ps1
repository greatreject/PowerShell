Install-Module -Name AWS.Tools.Installer
cls
$accesskey = Read-Host -Prompt "Enter Access Key"
$secretaccesskey = Read-Host -Prompt "Enter Secret Access Key"
$sessiontoken = Read-Host -Prompt "Enter Session Token"
cls
Set-AWSCredential -AccessKey $accesskey -SecretKey $secretaccesskey -SessionToken $sessiontoken
