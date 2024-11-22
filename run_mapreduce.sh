#!/bin/bash

# Root directory of the project
PROJECT_ROOT="$(dirname "$(realpath "$0")")"

# Paths
DOCKER_HADOOP_DIR="${PROJECT_ROOT}/docker-hadoop"
DATA_FILE="./preprocessed_heart_disease_data.csv"

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
for i in {1..10}; do
    docker exec namenode /bin/bash -c "hdfs dfs -ls /" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "HDFS is ready for input!"
        break
    else
        echo "Attempt $i: HDFS is not ready yet, retrying..."
        sleep 5
    fi
done

if [ $i -eq 10 ]; then
    echo "Error: HDFS is still not ready after 10 attempts. Exiting."
    exit 1
fi

# Step 4: Check if Hadoop is in Safe Mode and leave if necessary
echo "Checking HDFS Safe Mode..."
SAFE_MODE_STATUS=$(docker exec namenode /bin/bash -c "hdfs dfsadmin -safemode get")
if [[ "$SAFE_MODE_STATUS" == *"ON"* ]]; then
    echo "HDFS is in Safe Mode. Attempting to leave Safe Mode..."
    docker exec namenode /bin/bash -c "hdfs dfsadmin -safemode leave"
    if [ $? -ne 0 ]; then
        echo "Error: Unable to leave Safe Mode. Exiting."
        exit 1
    fi
    echo "HDFS has exited Safe Mode."
fi

# Step 5: Ensure /heart_data directory exists
echo "Ensuring /heart_data directory exists..."
docker exec namenode /bin/bash -c "hdfs dfs -mkdir -p /heart_data"

# Step 6: Ensure HDFS directories are correctly created
echo "Ensuring required HDFS directories are created..."
docker exec namenode /bin/bash -c "hdfs dfs -mkdir -p /heart_data_output"

# Step 7: Copy dataset to HDFS
echo "Copying dataset to HDFS..."
docker cp ${DATA_FILE} namenode:/heart_data/
docker exec namenode /bin/bash -c "ls /heart_data" # Check if the file exists in the container

# Retry logic for copying dataset if directory is not ready
for i in {1..10}; do
    docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/preprocessed_heart_disease_data.csv /heart_data/"
    if [ $? -eq 0 ]; then
        echo "Dataset copied to HDFS."
        break
    else
        echo "Error: Dataset copy failed, retrying..."
        sleep 5
    fi
done

# Check if the dataset was successfully copied
if [ $i -eq 10 ]; then
    echo "Error: Failed to copy dataset to HDFS after 10 attempts. Exiting."
    exit 1
fi

# Step 8: Copy MapReduce scripts
echo "Copying MapReduce scripts to Namenode..."
docker cp ${APP_DIR}/mapper.py namenode:/heart_data/
docker cp ${APP_DIR}/reducer.py namenode:/heart_data/

# Step 9: Ensure script files exist in HDFS before running
echo "Ensuring mapper and reducer scripts are available in HDFS..."
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/mapper.py /heart_data/ || true"
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/reducer.py /heart_data/ || true"

# Step 10: Run MapReduce job
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

# Step 11: Retrieve output
echo "Retrieving MapReduce job output..."
mkdir -p ${OUTPUT_DIR}
docker exec namenode /bin/bash -c "hdfs dfs -cat /heart_data_output/part-00000" > ${MAPREDUCE_OUTPUT}

if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve MapReduce job output. Exiting."
    exit 1
fi

# Step 12: Final status
echo "MapReduce job complete. Results saved in ${MAPREDUCE_OUTPUT}"
