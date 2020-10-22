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
Write-Output "`n > Start: Check/Create Resource Group: $ResourceGroupName...    "
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
Write-Output "`n > Start Check/Create Automation Account $AutomationAccount..."
if(Get-AzAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue){
    Write-Output "Automation Account $AutomationAccountName exists. Skipping creation"
}
else{
    try{
        New-AzAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName -Location $Location -ErrorAction STOP
        Write-Output "Automation Account $AutomationAccountName created."
    }
    catch{
        $Exception = $_.Exception
        Write-Output "ERROR: Couldn't create Automation Account: $($Exception.GetType()) - $($Exception.Message)"
        throw $Exception
    }
}
#endregion check/create Automation Account

#region import Runbook
Write-Output "`n > Start check/create $RunbookName runbook."
if($Runbook = Get-AzAutomationRunbook -Name $RunbookName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -ErrorAction SilentlyContinue){
    Write-Output "Automation Runbook $RunbookName exists. Creation time: $($Runbook.CreationTime). Last modified time: $($Runbook.LastModifiedTime)"
    Write-Output "Will attept to overwrite with newest version from the Devops Git Repo."
}else{
    Write-Output "Automation Runbook $RunbookName does not exist. Attempting import."
}

Write-Output "`n > Start importing the [Repository\$($RunbookPath)] script into the Runbook."
try{
    Import-AzAutomationRunbook -Name $RunbookName -Path $RunbookPath -ResourceGroupName $ResourceGroupName `
         -AutomationAccountName $AutomationAccountName -Type $RunbookType  -Force -ErrorAction STOP | Out-Null
    Write-Output "Automation Runbook $RunbookName successfully imported."
}catch{
    $Exception = $_.Exception
    Write-Output "ERROR: cannot import the Automation Runbook: $($Exception.GetType()) - $($Exception.Message)"
    throw $Exception
}
#endregion import Runbook

#region publish the automation runbook
Write-Output "`n > Start publishing the $RunbookName runbook."
try{
    Publish-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name $RunbookName -ResourceGroupName $ResourceGroupName -ErrorAction STOP | Out-Null
    Write-Output "Succesfully published the automation runbook."
}catch{
    $Exception = $_.Exception
    Write-Output "ERROR: cannot publish the automation runbook: $($Exception.GetType()) - $($Exception.Message)"
    throw $Exception
}
#endregion publish the automation runbook

#region check/create webhook
Write-Output "`n > Start check/create $WebhookName webook."
$Webhook = Get-AzAutomationWebhook -RunbookName $RunbookName -AutomationAccountName $AutomationAccountName `
             -ResourceGroupName $ResourceGroupName  -ErrorAction SilentlyContinue | Where-Object {$_.Name -eq $WebhookName}
if($Webhook){
    Write-Output "Webhook $Webhook already exists. Skipping creation. (!!! Warning: we should remove webhook and create new one if the current one is close to expiry... NOTE: It needs to be replaced on the Logic App as well.)."
}else{  
    try{
        Write-Output "Attempting to create $WebhookName webhook." 
        $Webhook = New-AzAutomationWebhook -Name $WebhookName -IsEnabled $True -ExpiryTime (Get-Date).AddYears(1) -RunbookName $RunbookName -ResourceGroup $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force
        Write-Output "Webhook $($Webhook.Name) successfully created. WebhookURI: $($Webhook.WebhookURI)" 
    }catch{
        $Exception = $_.Exception
        Write-Output "ERROR: cannot create webhook: $($Exception.GetType()) - $($Exception.Message)"
        throw $Exception
    }
}
#endregion check/create webhook
