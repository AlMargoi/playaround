# Playaround
### This is a test repository used for learning how to trigger an Azure Build Pipeline. Target:
#### - Have a sample .ps1 Powershell Script in the reporsitory (not important what it contains). 
#### - Publish this script inside a Runbook, in an Automation Account on a specific Resource Group in Azure. Build the Azure resources if not already exisitng. Skip creation if already in place. 
#### - All the above must be performed using an Azure Build Pipeline, triggered with each commit to the main branch of the repository. 
#### - For ease, the YAML file should contain one single task, that calls a powershell script which is building the infrastructure.
