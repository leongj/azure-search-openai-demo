###
# This script adds a Cosmos DB instance for storing chat logs.
# The instance will be named "chatlog-<uid>" where <uid> is based on unique value on the app service.
# The feature will start working as soon as AZURE_COSMOS_ACCOUNT_NAME variable is set.
# Clear this value to disable the feature.


## Set the preference to stop on the first error
$ErrorActionPreference = "Stop"

# DEFAULT VALUES
$dbName = "ChatLog"
$containerName = "Chats"

Write-Host "Loading azd .env file from current environment"
$output = azd env get-values
foreach ($line in $output) {
    if (!$line.Contains('=')) {
    continue
    }

    $name, $value = $line.Split("=")
    $value = $value -replace '^\"|\"$'
    [Environment]::SetEnvironmentVariable($name, $value)
}

# For consistent naming, we're going to borrow the unique name from the BACKEND_URI
# (this is the one most likely to be unique to this env, even if the solution is re-using other cogseach/aoai services)
$backendUri = $env:BACKEND_URI
$backendName = $backendUri.Split("https://")[1].Split(".azurewebsites.net")[0]
$uniqueId = $backendName.Split("app-backend-")[1]

Write-Host "Found App Backend: $backendName with unique ID: $uniqueId"

# Setup Variables
$cosmosAccName = "chatlog-$uniqueId"
$resGrp = $env:AZURE_RESOURCE_GROUP
$loc = $env:AZURE_LOCATION


# Verify with user
Write-Host "Ready to create Cosmos DB instance:"
Write-Host "  name:     $cosmosAccName"
Write-Host "  group:    $resGrp"
Write-Host "  location: $loc"
Write-Host "  database: $dbName"
Write-Host "  container:$containerName"
$response = Read-Host -Prompt "Does this look ok? Enter 'y' to continue, anything else to exit."
if ($response -ne "y") {
    exit
}

# Create the Cosmos Account
Write-Host "Creating Cosmos account: $cosmosAccName ..."
az cosmosdb create --name $cosmosAccName `
                   --resource-group $resGrp `
                   --default-consistency-level Session `
                   --locations regionName=$loc isZoneRedundant=False `
                   --capabilities EnableServerless

# Create the DB
Write-Host "Creating Cosmos DB database: $dbName ..."
az cosmosdb sql database create --account-name $cosmosAccName `
                                --resource-group $resGrp `
                                --name $dbName

# Create the container
Write-Host "Creating Cosmos DB container: $containerName ..."
az cosmosdb sql container create --account-name $cosmosAccName `
                                 --resource-group $resGrp `
                                 --database-name $dbName `
                                 --partition-key-path "/id" `
                                 --name $containerName

# Store the environment varaibles back into AZD
Write-Host "Storing Cosmos DB variables in AZD environment..."
azd env set AZURE_COSMOS_ACCOUNT_NAME $cosmosAccName
azd env set AZURE_COSMOS_DATABASE_NAME $dbName
azd env set AZURE_COSMOS_CONTAINER_NAME $containerName

# Set the config on the AppService
Write-Host "Setting the config on AppService..."
az webapp config appsettings set --name $backendName `
                                 --resource-group $resGrp `
                                 --settings AZURE_COSMOS_ACCOUNT_NAME=$cosmosAccName `
                                            AZURE_COSMOS_DATABASE_NAME=$dbName `
                                            AZURE_COSMOS_CONTAINER_NAME=$containerName

# Get the appservice managed identity principal id
$appServiceMI = az webapp identity show --name $backendName `
                                        --resource-group $resGrp `
                                        --query principalId `
                                        --output tsv

Write-Host "Assigning AppService Principal $appServiceMI the SQL role 'Cosmos DB Built-in Data Contributor'..."
az cosmosdb sql role assignment create --account-name $cosmosAccName `
                                       --resource-group $resGrp `
                                       --scope "/" `
                                       --principal-id $appServiceMI `
                                       --role-definition-id 00000000-0000-0000-0000-000000000002

# Assign to the currently-logged in user as well
$userId = az ad signed-in-user show --query id --output tsv

Write-Host "Assigning logged-in user $userId the SQL role 'Cosmos DB Built-in Data Contributor'..."
az cosmosdb sql role assignment create --account-name $cosmosAccName `
                                       --resource-group $resGrp `
                                       --scope "/" `
                                       --principal-id $userId `
                                       --role-definition-id 00000000-0000-0000-0000-000000000002

Write-Host "All done!"