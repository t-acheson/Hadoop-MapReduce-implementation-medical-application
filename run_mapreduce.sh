#!/bin/bash

# Root directory of the project
PROJECT_ROOT="$(dirname "$(realpath "$0")")"

# Paths
DOCKER_HADOOP_DIR="${PROJECT_ROOT}/docker-hadoop"
DATA_FILE="${PROJECT_ROOT}/preprocessed_heart_disease_data.csv"
APP_DIR="${PROJECT_ROOT}/app"
OUTPUT_DIR="${PROJECT_ROOT}/output"
MAPREDUCE_OUTPUT="${OUTPUT_DIR}/mapreduce_results.csv"

# Step 1: Start Hadoop containers
echo "Starting Hadoop containers..."
cd ${DOCKER_HADOOP_DIR}
docker-compose up -d --build

# Step 2: Wait for Namenode to become healthy
echo "Waiting for Namenode to become healthy..."
NAMENODE_HEALTH="starting"
until [ "$NAMENODE_HEALTH" == "healthy" ]; do
    NAMENODE_HEALTH=$(docker inspect -f '{{.State.Health.Status}}' namenode 2>/dev/null)
    if [ "$NAMENODE_HEALTH" == "unhealthy" ]; then
        echo "Error: Namenode container is unhealthy. Exiting."
        exit 1
    fi
    echo "Still initializing..."
    sleep 5
done
echo "Namenode is healthy!"

# Step 3: Wait for HDFS to be ready
echo "Waiting for HDFS to be ready for input..."
until docker exec namenode /bin/bash -c "hdfs dfs -ls /" >/dev/null 2>&1; do
    echo "Waiting for HDFS to be ready..."
    sleep 5
done
echo "HDFS is ready for input!"

# Step 4: Ensure /heart_data directory exists
echo "Ensuring /heart_data directory exists..."
docker exec namenode /bin/bash -c "hdfs dfs -mkdir -p /heart_data"

# Step 5: Ensure HDFS directories are correctly created
echo "Ensuring required HDFS directories are created..."
docker exec namenode /bin/bash -c "hdfs dfs -mkdir -p /heart_data_output"

# Step 6: Copy dataset to HDFS
echo "Copying dataset to HDFS..."
docker cp ${DATA_FILE} namenode:/heart_data/
docker exec namenode /bin/bash -c "hdfs dfs -rm -r /heart_data_output || true && \
    hdfs dfs -put -f /heart_data/preprocessed_heart_disease_data.csv /heart_data/"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy dataset to HDFS. Exiting."
    exit 1
fi

# Step 7: Copy MapReduce scripts
echo "Copying MapReduce scripts to Namenode..."
docker cp ${APP_DIR}/mapper.py namenode:/heart_data/
docker cp ${APP_DIR}/reducer.py namenode:/heart_data/

# Step 8: Ensure script files exist in HDFS before running
echo "Ensuring mapper and reducer scripts are available in HDFS..."
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/mapper.py /heart_data/ || true"
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/reducer.py /heart_data/ || true"

# Step 9: Run MapReduce job
echo "Running Hadoop Streaming job..."
docker exec namenode /bin/bash -c "hadoop jar /opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar \
    -input /heart_data/preprocessed_heart_disease_data.csv \
    -output /heart_data_output \
    -mapper /heart_data/mapper.py \
    -reducer /heart_data/reducer.py \
    -file /heart_data/mapper.py \
    -file /heart_data/reducer.py"

if [ $? -ne 0 ]; then
    echo "Error: MapReduce job failed. Exiting."
    exit 1
fi

# Step 10: Retrieve output
echo "Retrieving MapReduce job output..."
mkdir -p ${OUTPUT_DIR}
docker exec namenode /bin/bash -c "hdfs dfs -cat /heart_data_output/part-00000" > ${MAPREDUCE_OUTPUT}

if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve MapReduce job output. Exiting."
    exit 1
fi

# Step 11: Final status
echo "MapReduce job complete. Results saved in ${MAPREDUCE_OUTPUT}"
