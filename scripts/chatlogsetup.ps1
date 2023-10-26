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

$cosmosAccName = "chatlog-$uniqueId"
$resGrp = $env:AZURE_RESOURCE_GROUP
$loc = $env:AZURE_LOCATION

# print the name of the Cosmos DB instance
Write-Host "Creating Cosmos DB instance:"
Write-Host "  name:     $cosmosAccName"
Write-Host "  group:    $resGrp"
Write-Host "  location: $loc"
Write_Host "..."

az cosmosdb create --name $cosmosAccName `
                   --resource-group $resGrp `
                   --default-consistency-level Eventual `
                   --locations regionName=$loc isZoneRedundant=False `
                   --capabilities EnableServerless

# TODO
# - Create the DB - default name "ChatLog"
# - Create the Container - default name "Chats"
# - Store variables back into AZD ENV
# - Add variables as config settings on the AppService

# - create the SQL Custom Role and assign to AppService MI (app-backend-BACKEND_URI)
#   - https://learn.microsoft.com/en-us/azure/cosmos-db/nosql/quickstart-python?tabs=azure-portal%2Cpasswordless%2Cwindows%2Csign-in-azure-cli%2Csync#create-the-custom-role