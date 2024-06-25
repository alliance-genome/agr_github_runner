#!/bin/bash

NEO_ENV_IMAGE="100225593120.dkr.ecr.us-east-1.amazonaws.com/agr_neo4j_env:stage"
NEO_SERVER_NAME="stage-neo4j.alliancegenome.org"
NEO_VOLUME_NAME="/data"
NET="host"
NEO_MAX_HEAP="31GB"
NEO_OFF_HEAP_MAX="0GB"
NEO_ON_OFF_HEAP="OFF_HEAP"
NEO_TRANSACTION="0"
NEO4J_AUTH="none"

echo "Pulling Neo4j environment image..."
docker pull $NEO_ENV_IMAGE

echo "Starting Neo4j environment..."
docker run --rm -d \
    --name $NEO_SERVER_NAME \
    -p 7474:7474 \
    -p 7687:7687 \
    -v $NEO_VOLUME_NAME:/var/lib/neo4j/import \
    --network $NET \
    -e NEO4J_server_memory_heap_max__size=$NEO_MAX_HEAP \
    -e NEO4J_server_memory_heap_initial__size=$NEO_MAX_HEAP \
    -e NEO4J_server_memory_off__heap_max__size=$NEO_OFF_HEAP_MAX \
    -e NEO4J_db_tx__state_memory__allocation=$NEO_ON_OFF_HEAP \
    -e NEO4J_dbms_memory_transaction_total_max=$NEO_TRANSACTION \
    -e NEO4J_db_memory_transaction_total_max=$NEO_TRANSACTION \
    -e NEO4J_db_memory_transaction_max=$NEO_TRANSACTION \
    -e NEO4J_AUTH=$NEO4J_AUTH \
    $NEO_ENV_IMAGE
