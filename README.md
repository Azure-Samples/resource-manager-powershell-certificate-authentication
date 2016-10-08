---
services: resource manager
platforms: powershell
author: msonecode
---

# Access Azure resource data by certificate authentication in Powershell

## Introduction
This sample demonstrates how to automatically get a list of all the resources (VMs, Storage Accounts, Databases, App Services) and status via Powershell by certificate authentication. 

## Scenarios
In some cases, IT admins would like to have the statistics of all azure resources (VMs, Storage Accounts, Databases, App Services) and status information. This Windows PowerShell script will help IT admins to get resources info.

## Prerequisite 
Install Azure Powershell according to [https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/](https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/)

## Script
- Save the current Resource Manager authentication information  
```ps1
Login-AzureRmAccount 
Save-AzureRmProfile -Path “C:\Work\PS\azureaccount.json”
```
- Download your subscription certificate for Azure Server Manager from [https://manage.windowsazure.com/publishsettings/](https://manage.windowsazure.com/publishsettings/)
- Open the script file GetAzureResourceList.ps1, edit the variable $RmProfilePath and $PublishSettingsFilePath and then save the file  
```ps1
GetAzureResourceList -RmProfilePath $RmProfilePath -PublishSettingsFilePath $PublishSettingsFilePath
```
- Open the powershell and run the script file GetAzureResourceList.ps1  
![][1]  
- After the script has finished its job, you will see the similar file output as this one  
![][2]
- Here are some code snippets for your reference 
```ps1
function GetAzureResourceList() 
{ 
    param 
    ( 
        [string] 
        $RmProfilePath =$(throw "Parameter missing: -RmProfilePath RmProfilePath"),  
        [string] 
        $PublishSettingsFilePath = $(throw "Parameter missing: -PublishSettingsFilePath PublishSettingsFilePath"), 
        [string] 
        $OutFilePath = "c:\AzureResourceList.csv" 
    ) 
      
    Try 
    { 
        #Loads Azure authentication information from a file using Resource Manager.https://portal.azure.com 
        Select-AzureRmProfile –Path $RmProfilePath -ErrorAction Stop 
 
        #Imports a publish-settings file with a certificate to connect to your Windows Azure account using Server Manager.https://manage.windowsazure.com/publishsettings/ 
        Import-AzurePublishSettingsFile -PublishSettingsFile $PublishSettingsFilePath -ErrorAction Stop 
 
        "Resource Type,Resource Name,Resource Status" | out-file $OutFilePath -encoding ascii -append 
        #Get classic VM list 
        ForEach ($classicVM in Get-AzureVM)  
        { 
            "Virtual machines(classic)," + $classicVM.Name + "," + $classicVM.Status | out-file $OutFilePath -encoding ascii -append 
        } 
        #Get resource manager VM  
        ForEach ($rmVM in Get-AzureRmVM)  
        { 
            $statuses = (Get-AzureRmVM -ResourceGroupName $rmVM.ResourceGroupName -Name $rmVM.Name -Status).Statuses  
            "Virtual machines," + $rmVM.Name + "," + $statuses.DisplayStatus | out-file $OutFilePath -encoding ascii -append 
        } 
 
        #Get classic storage accounts list 
        ForEach ($storageAccount in Get-AzureStorageAccount)  
        { 
            "Storage Account(classic)," + $storageAccount.StorageAccountName + ",Available" | out-file $OutFilePath -encoding ascii -append 
        } 
        #Get resource manager storage accounts list 
        ForEach ($rmStorageAccount in Get-AzureRmStorageAccount)  
        { 
            "Storage Account," + $rmStorageAccount.StorageAccountName + "," +  $rmStorageAccount.StatusOfPrimary | out-file $OutFilePath -encoding ascii -append 
        } 
        #Get SQL databases 
        ForEach ($sqlServer in Get-AzureSqlDatabaseServer)  
        { 
            ForEach($sqlDatabase in Get-AzureSqlDatabase -ServerName $sqlServer.ServerName) 
            { 
                If($sqlDatabase.Name -ine "master") 
                { 
                    "SQL databases," + $sqlDatabase.Name + ",Online"  | out-file $OutFilePath -encoding ascii -append 
                } 
            } 
        }     
        #Get-AzureRmResource cmdlet can get all azure resources 
        #Get App Services 
        ForEach ($resource in Get-AzureRmResource)  
        { 
            If($resource.ResourceType -ieq "Microsoft.Web/sites") 
            { 
                $webApp = Get-AzureRmWebApp -Name $resource.ResourceName 
                "App Services," + $resource.ResourceName + "," +  $webApp.State | out-file $OutFilePath -encoding ascii -append 
            } 
        }         
    } 
    Catch 
    {         
          Write-Host -ForegroundColor Red $_.Exception.Message 
    } 
} 
 
GetAzureResourceList -RmProfilePath "C:\Work\PS\azureaccount.json" -PublishSettingsFilePath "C:\Work\AzureCredentials\Visual Studio Ultimate with MSDN-8-2-2016-credentials.publishsettings" 
Write-Host "Done"
```

## Additional Resources 

- Persistent Azure PowerShell logins: [https://blogs.msdn.microsoft.com/stuartleeks/2015/12/11/persisting-azure-powershell-logins/][4]
- Download and import Publish Settings and Subscription Information [https://msdn.microsoft.com/en-us/library/dn385850(v=nav.70).aspx][3]

[1]: images/1.png
[2]: images/2.png
[3]: https://msdn.microsoft.com/en-us/library/dn385850(v=nav.70).aspx
[4]: https://blogs.msdn.microsoft.com/stuartleeks/2015/12/11/persisting-azure-powershell-logins/
