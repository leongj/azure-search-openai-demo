# TODO list for chat logging

To install
1. Clone
2. `azd auth login`
3. `azd up`
4. Have a beer

## Minimum
1. Create CosmosDB instance
    - Scripted using azcli
    - append new `COSMOS` environment variables in `/.azure/<env name>/.env` (probably manual)
    - configure Managed Identity to allow AppService to write to the DB
2. Modify `app.py`
    - Look at `setup_clients()`
    - Load env vars
    - Instantiate CosmosClient
    - Setup database
    - figure out where the session/threadId would come from? *
    - in `chat()`
        - write user message to DB
        - deal with streaming generator object *
        - write full completion to DB


