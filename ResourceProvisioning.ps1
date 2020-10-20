param(
    [string][Parameter(Mandatory=$true)]$ResourceGroupName,
    [string][Parameter(Mandatory=$true)]$AutomationAccountName,
    [string][Parameter(Mandatory=$true)]$Location,
    [string][Parameter(Mandatory=$true)]$RunbookName,
    [string][Parameter(Mandatory=$true)]$RunbookType,
    [string][Parameter(Mandatory=$true)]$RunbookPath,
    [string][Parameter(Mandatory=$true)]$WebhookName
    
)

#region check/create Resource Group
if(Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue){
    Write-Output "ResourceGroup $ResourceGroupName exists. Skipping creation"
}
else{
    try{
        New-AZResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction STOP
        Write-Output "Successfully created Resource Group: $ResourceGroupName, location: $Location"
    }
    catch{
        $Exception = $_.Exception
        Write-Output "ERROR: couldn't create Resource Group: $($Exception.GetType()) - $($Exception.Message)"
        throw $Exception
    }
}
#endregion check/create Resource Group

#region check/create Automation Account
if(Get-AzAutomationAccount -Name $AutomationAccountName-ResourceGroupName $ResourceGroupName){
    Write-Output "Automation Account $AutomationAccountNameexists. Skipping creation"
}
else{
    try{
        New-AzAutomationAccount -Name $AutomationAccountName-ResourceGroupName $ResourceGroupName -Location $Location -ErrorAction STOP
        Write-Output "Automation Account $AutomationAccountNamecreated."
    }
    catch{
        $Exception = $_.Exception
        Write-Output "ERROR: Couldn't create Automation Account: $($Exception.GetType()) - $($Exception.Message)"
        throw $Exception
    }
}
#endregion check/create Automation Account

#region import Runbook
if($Runbook = Get-AzAutomationRunbook -Name $RunbookName-ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccount){
    Write-Output "Automation Runbook $RunbookNameexists. Creation time: $($Runbook.CreationTime). Last modified time: $($Runbook.LastModifiedTime)"
    Write-Output "Will attept to overwrite with newest version from the Devops Git Repo."
}else{
    Write-Output "Automation Runbook $RunbookNamedoes not exist. Attempting import."
}

try{
    Import-AzAutomationRunbook -Name $RunbookName-Path $RunbookPath -ResourceGroupName $ResourceGroupName `
         -AutomationAccountName $AutomationAccountName-Type $RunbookType  -Force -ErrorAction STOP
    Write-Output "Automation Runbook $RunbookNamesuccessfully imported."
}catch{
    $Exception = $_.Exception
    Write-Output "ERROR: cannot import the Automation Runbook: $($Exception.GetType()) - $($Exception.Message)"
    throw $Exception
}
#endregion import Runbook

#region publish the automation runbook
try{
    Publish-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name $RunbookName-ResourceGroupName $ResourceGroupName
    Write-Output "Succesfully published the automation runbook."
}catch{
    $Exception = $_.Exception
    Write-Output "ERROR: cannot publish the automation runbook: $($Exception.GetType()) - $($Exception.Message)"
    throw $Exception
}
#endregion publish the automation runbook

#region check/create webhook
if(Get-AzAutomationWebhook -Name $WebhookName -RunbookName $RunbookName-AutomationAccountName $AutomationAccountName-ResourceGroupName $ResourceGroupName){
    Write-Output "Webhook $Webhook already exists. Skipping creation. (!!! Warning: we should remove webhook and create new one if the current one is close to expiry... NOTE: It needs to be replaced on the Logic App as well.)."
}else{  
    try{
        Write-Output "Attempting to create $WebhookName webhook." 
        $Webhook = New-AzAutomationWebhook -Name $WebhookName -IsEnabled $True -ExpiryTime (Get-Date).AddYears(1) -RunbookName $RunbookName-ResourceGroup $ResourceGroupName -AutomationAccountName $AutomationAccountName-Force
        Write-Output "Webhook $Webhook successfully created. WebhookURI: $($Webhook.WebhookURI)" 
    }catch{
        $Exception = $_.Exception
        Write-Output "ERROR: cannot create webhook: $($Exception.GetType()) - $($Exception.Message)"
        throw $Exception
    }
}
#endregion check/create webhook
