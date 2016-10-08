<#
	The sample scripts are not supported under any Microsoft standard support 
	program or service. The sample scripts are provided AS IS without warranty  
	of any kind. Microsoft further disclaims all implied warranties including,  
	without limitation, any implied warranties of merchantability or of fitness for 
	a particular purpose. The entire risk arising out of the use or performance of  
	the sample scripts and documentation remains with you. In no event shall 
	Microsoft, its authors, or anyone Else involved in the creation, production, or 
	delivery of the scripts be liable for any damages whatsoever (including, 
	without limitation, damages for loss of business profits, business interruption, 
	loss of business information, or other pecuniary loss) arising out of the use 
	of or inability to use the sample scripts or documentation, even If Microsoft 
	has been advised of the possibility of such damages 
#>

#Azure authentication information from a file using Resource Manager.Save-AzureRmProfile https://portal.azure.com
$RmProfilePath = "C:\Work\PS\azureaccount.json" 
#Publish-settings file with a certificate to connect to your Windows Azure account using Server Manager.https://manage.windowsazure.com/publishsettings/
$PublishSettingsFilePath = "C:\Work\AzureCredentials\Visual Studio Ultimate with MSDN-8-2-2016-credentials.publishsettings" 

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

GetAzureResourceList -RmProfilePath $RmProfilePath -PublishSettingsFilePath $PublishSettingsFilePath 
Write-Host "Done"