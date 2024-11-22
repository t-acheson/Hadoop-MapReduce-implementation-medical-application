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
docker-compose up -d

# Step 2: Verify containers
echo "Checking if Namenode container is running..."
docker ps | grep namenode
if [ $? -ne 0 ]; then
    echo "Error: Namenode container not running. Exiting."
    exit 1
fi

# Step 3: Copy dataset to HDFS
echo "Copying dataset to HDFS..."
docker cp ${DATA_FILE} namenode:/heart_data/
docker exec namenode /bin/bash -c "hdfs dfs -mkdir -p /heart_data && hdfs dfs -put /heart_data/preprocessed_heart_disease_data.csv /heart_data/"

# Step 4: Copy MapReduce scripts
echo "Copying MapReduce scripts to Namenode..."
docker cp ${APP_DIR}/mapper.py namenode:/heart_data/
docker cp ${APP_DIR}/reducer.py namenode:/heart_data/

# Step 5: Run MapReduce job
echo "Running Hadoop Streaming job..."
docker exec namenode /bin/bash -c "hadoop jar /opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar \
    -input /heart_data/preprocessed_heart_disease_data.csv \
    -output /heart_data_output \
    -mapper /heart_data/mapper.py \
    -reducer /heart_data/reducer.py \
    -file /heart_data/mapper.py \
    -file /heart_data/reducer.py"

# Step 6: Retrieve output
echo "Retrieving MapReduce job output..."
mkdir -p ${OUTPUT_DIR}
docker exec namenode /bin/bash -c "hdfs dfs -cat /heart_data_output/part-00000" > ${MAPREDUCE_OUTPUT}

# Step 7: Final status
echo "MapReduce job complete. Results saved in ${MAPREDUCE_OUTPUT}"
