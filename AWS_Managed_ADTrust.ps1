function Show-Menu
{
     param (
           [string]$Title = 'Menu'
     )
     cls
     Write-Host "================ $Title ================"
    
     Write-Host "1: Press '1' To create a Two-Way Trust"
     Write-Host "2: Press '2' To verify a Trust"
     Write-Host "3: Press '3' To delete a Trust"
     Write-Host "q: Press 'q' to Quit"
}


Function Trust {
#Enter domain FQDN's
$domain1 = Read-Host -Prompt "Please type in the FQDN for Domain1"
$domain2 = Read-Host -Prompt "Please type in the FQDN for Domain2"
#Password for the Trust
$trustpass = read-host -Prompt "Please type in the trust password"

#Domain 1 variables
$Directory1 = Get-DSDirectory | Where-Object -FilterScript {$_.Name -eq $domain1} | Select-Object -ExpandProperty DirectoryId
$remotename1 = Get-DSDirectory | Where-Object -FilterScript {$_.Name -eq $domain1} | Select-Object -ExpandProperty Name
$conditionalforwarder1 = Get-DSDirectory | Where-Object -FilterScript {$_.Name -eq $domain1} | Select-Object -ExpandProperty DnsIpAddrs

#Domain 2 variables
$Directory2 = Get-DSDirectory | Where-Object -FilterScript {$_.Name -eq $domain2} | Select-Object -ExpandProperty DirectoryId
$remotename2 = Get-DSDirectory | Where-Object -FilterScript {$_.Name -eq $domain2} | Select-Object -ExpandProperty Name
$conditionalforwarder2 = Get-DSDirectory | Where-Object -FilterScript {$_.Name -eq $domain2} | Select-Object -ExpandProperty DnsIpAddrs

#Creates Domain trust for both domains using variables from both Domains
New-DSTrust -DirectoryId $Directory1 -RemoteDomainName $remotename2 -TrustPassword $trustpass -TrustDirection Two-Way -ConditionalForwarderIpAddr $conditionalforwarder2
New-DSTrust -DirectoryId $Directory2 -RemoteDomainName $remotename1 -TrustPassword $trustpass -TrustDirection Two-Way -ConditionalForwarderIpAddr $conditionalforwarder1
}


Function Verify {
cls
Get-DSTrust | Approve-DSTrust
}


Function RemoveTrust {
cls
Get-DSTrust | Remove-DSTrust -Force
}

#Main menu loop
do
{
     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input)
     {
           '1' {
                cls
                Trust
          } '2' {
                cls
                Verify
          } '3' {
                cls
                RemoveTrust           
           } 'q' {
                return
           }
     }
     pause
}
until ($input -eq 'q')