<#
.SYNOPSIS
    Script to find out a user's last logon time in a Windows domain.

    3/11/2016: Version 1.0

.DESCRIPTION
    Script to find out a user's last logon time in a Windows domain. 
    Loops through all domain controllers and retrieves last logon date and time or retrieves LastLogonTimestamp, LastLogonDate attribute.

.PARAMETER Credential 
    Credentials of account that have sufficient permissions to read required data from AD.

.PARAMETER Domain
    The domain name in which the verified user account resides. By default domain from Credential parameter will be used.

.PARAMETER User
    Account which data will be retrieved.

.PARAMETER Output
    Output format:
    LastLogonTimestamp - retrieves LastLogonTimestamp attribute
    LastLogonDate - retrieves LastLogonDate attribute
    DateTime - loops through all domain controllers and retrieves last logon date and time.
    DateTimeDC - loops through all domain controllers and retrieves last logon date, time and domain controller that provided last authentication.
    All - retrieves lastlogondate, lastlogontimestamp and lastlogon attributes from all domain controllers.

.NOTES
    Author       : Adam W. Mrowicki
    File Name    : Get-LastLogon.ps1

    Version History:
    1.0 - 3/11/2016
        - Initial release

.EXAMPLE
    .\Get-LastLogon.ps1

.EXAMPLE
    .\Get-LastLogon.ps1 -Credential $Cred

.EXAMPLE
    .\Get-LastLogon.ps1 -Domain "domain.local" -User "DomainUser"

.EXAMPLE
    .\Get-LastLogon.ps1 -User (Get-ADUser DomainUser)

.EXAMPLE
    .\Get-LastLogon.ps1 -Domain "domain.local" -User "DomainUser" -Credential $Cred -Output All
    Example output:

    SamAccountName     : DomainUser
    DC                 : DC01
    LastLogonDateTime  : 23.03.2015 10:16:40
    LastLogonTimestamp : 131020779423212082
    LastLogonDate      : 10.03.2016 11:05:42

    SamAccountName     : DomainUser
    DC                 : DC02
    LastLogonDateTime  : 30.06.2015 11:01:15
    LastLogonTimestamp : 131020779423212082
    LastLogonDate      : 10.03.2016 11:05:42

    SamAccountName     : DomainUser
    DC                 : DC02
    LastLogonDateTime  : 10.09.2015 14:00:07
    LastLogonTimestamp : 131020779423212082
    LastLogonDate      : 10.03.2016 11:05:42

.EXAMPLE
    .\Get-LastLogon.ps1 -Domain "domain.local" -User "DomainUser" -Credential $Cred -Output LastLogonTimestamp
    Example output:
    131020779423212082

.EXAMPLE
    .\Get-LastLogon.ps1 -Domain "domain.local" -User "DomainUser" -Credential $Cred -Output LastLogonDate
    Example output:
    Thursday, 10 march 2016 11:05:42

.EXAMPLE
    .\Get-LastLogon.ps1 -Domain "domain.local" -User "DomainUser" -Credential $Cred -Output DateTime
    Example output:
    Thursday, 10 march 2016 11:05:42

.EXAMPLE
    .\Get-LastLogon.ps1 -Domain "domain.local" -User "DomainUser" -Credential $Cred -Output DateTimeDC
    Example output:
    DC    DateTime           
    --    --------           
    DC01  11.03.2016 09:25:30
#>

function Get-LastLogon{

    Param(
        [Parameter(
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = (Get-Credential),

        [Parameter()]
        $Domain = ($Credential.GetNetworkCredential().domain),

        [Parameter()]
        [ValidateSet("All","DateTime","DateTimeDC","LastLogonTimestamp","LastLogonDate")] 
        $Output = "DateTime",

        [Parameter(
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        $User
    )

    Begin{
        Import-Module ActiveDirectory
        $Controllers = (Get-ADDomainController -Filter * -server $Domain -Credential $Credential)
    }
    
    Process{

        if($Output -eq "LastLogonTimestamp"){
            return (Get-ADUser -Identity $User -Server $Domain -Credential $Credential -Properties lastlogontimestamp).lastlogontimestamp
        }

        elseif($Output -eq "LastLogonDate"){
            return (Get-ADUser -Identity $User -Server $Domain -Credential $Credential -Properties LastLogonDate).LastLogonDate
        }

        elseif($Output -eq "DateTime" -or $Output -eq "DateTimeDC"){
            $time = $null
            $server = $null
            foreach($dc in $controllers){
                try{
                    $user = Get-ADUser -Identity $User -Server $dc.hostname -Credential $Credential -Properties LastLogon
                    if($user.LastLogon -gt $time){
                        $time = $user.LastLogon
                        $server = $dc
                    }            
                }
                catch{
                    Write-Verbose "Error while retrieving user $userName last logon date on $dc : $($Error[0].Exception)"
                }
            }
            if($Output -eq "DateTime"){
                return ([DateTime]::FromFileTime($time))
            }
            elseif($Output -eq "DateTimeDC"){
                $return = New-Object PSObject
                $return | Add-Member NoteProperty DC $server
                $return | Add-Member NoteProperty DateTime ([DateTime]::FromFileTime($time))
                return $return
            }
        }

        elseif($Output -eq "All"){
            $return = @()
            foreach($dc in $controllers){
                try{
                    $user = Get-ADUser -Identity $User -Server $dc.hostname -Credential $Credential -Properties LastLogon, lastlogontimestamp, lastlogondate
                    $UserData = New-Object PSObject
                    $UserData | Add-Member NoteProperty SamAccountName $User.SamAccountName
                    $UserData | Add-Member NoteProperty DC $dc
                    $UserData | Add-Member NoteProperty LastLogonDateTime ([DateTime]::FromFileTime($User.LastLogon))
                    $UserData | Add-Member NoteProperty LastLogonTimestamp $User.lastlogontimestamp
                    $UserData | Add-Member NoteProperty LastLogonDate $User.lastlogondate
                    $return += $UserData
                }
                catch{
                    Write-Verbose "Error while retrieving  user $userName last logon date on $dc : $($Error[0].Exception)"
                }
            }
            return ($return | Sort-Object -Property LastLogonDateTime)
        }
    }
}