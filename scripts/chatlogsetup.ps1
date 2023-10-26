## Set the preference to stop on the first error
$ErrorActionPreference = "Stop"

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
$uniqueId = $backendUri.Split("app-backend-")[1].Split(".azurewebsites.net")[0]

$cosmosDbName = "chatlog-$uniqueId"
$resGrp = $env:AZURE_RESOURCE_GROUP
$loc = $env:AZURE_LOCATION

# print the name of the Cosmos DB instance
Write-Host "Creating Cosmos DB instance:"
Write-Host "  name:     $cosmosDbName"
Write-Host "  group:    $resGrp"
Write-Host "  location: $loc"
Write_Host "..."

az cosmosdb create --name $cosmosDbName `
                   --resource-group $resGrp `
                   --default-consistency-level Eventual `
                   --locations regionName=$loc isZoneRedundant=False `
                   --capabilities EnableServerless

# TODO: create a role so that the backend can write to the Cosmos DB instance
# Write-Host "Creating Cosmos DB role assignment..."
# az cosmosdb sql role assignment create --account-name $cosmosDbName `
#                                        --resource-group $resGrp `
#                                        --scope "/dbs/$cosmosDbName/colls/ChatLog" `
#                                        --principal-id $env:AZURE_BACKEND_CLIENT_ID `
#                                        --role-definition-id "b24988ac-6180-42a0-ab88-20f7382dd24c"