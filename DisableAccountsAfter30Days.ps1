 $searchBase = "OU=UAT,OU=Accounts,OU=AWS,DC=LEO,DC=INFRA,DC=COM"
 Search-ADAccount -SearchBase $searchBase -UsersOnly -AccountInactive -TimeSpan ([timespan]30d) | Set-ADUser -Enabled $false