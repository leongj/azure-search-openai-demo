import azure.cosmos.documents as documents
import azure.cosmos.cosmos_client as cosmos_client
import azure.cosmos.exceptions as exceptions
from azure.cosmos.partition_key import PartitionKey

class CosmosDBClient:
    def __init__(self, host: str, key: str, database_id:str, container_id:str):
        self.client = cosmos_client.CosmosClient(host, {'masterKey': key}, user_agent="OpenAIChat", user_agent_overwrite=True)
        
        self.database = self.client.create_database_if_not_exists(id=database_id)
        self.container = self.database.create_container_if_not_exists(
            id=container_id, 
            partition_key=PartitionKey(path='/partitionKey')
        )

    def upsert_item(self, doc):
        response = self.container.upsert_item(body=doc)
