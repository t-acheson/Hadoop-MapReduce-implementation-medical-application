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

# Step 5: Ensure /heart_data directory exists in HDFS
echo "Checking if /heart_data directory exists in HDFS..."
DIR_EXISTS=$(docker exec namenode /bin/bash -c "hdfs dfs -test -d /heart_data && echo 'exists' || echo 'does not exist'")

if [ "$DIR_EXISTS" == "exists" ]; then
    echo "/heart_data directory already exists in HDFS."
else
    echo "/heart_data directory does not exist. Creating it..."
    docker exec namenode /bin/bash -c "hdfs dfs -mkdir -p /heart_data"
    echo "/heart_data directory created in HDFS."
fi

# Step 6: Ensure /heart_data_output directory exists in HDFS
echo "Checking if /heart_data_output directory exists in HDFS..."
DIR_EXISTS=$(docker exec namenode /bin/bash -c "hdfs dfs -test -d /heart_data_output && echo 'exists' || echo 'does not exist'")

if [ "$DIR_EXISTS" == "exists" ]; then
    echo "/heart_data_output directory already exists in HDFS."
else
    echo "/heart_data_output directory does not exist. Creating it..."
    docker exec namenode /bin/bash -c "hdfs dfs -mkdir -p /heart_data_output"
    echo "/heart_data_output directory created in HDFS."
fi

# Step 7: Ensure the dataset is available in the container's local filesystem
echo "Copying dataset to /heart_data directory inside the container..."
docker cp ${DATA_FILE} namenode:/heart_data/preprocessed_heart_disease_data.csv

# Verify if the file exists in the container
echo "Verifying dataset in the container's local filesystem..."
docker exec namenode /bin/bash -c "ls /heart_data/preprocessed_heart_disease_data.csv"

# Step 8: Copy dataset to HDFS directly
echo "Copying dataset to HDFS..."
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/preprocessed_heart_disease_data.csv /heart_data/"

# Verify if the file is in HDFS
echo "Verifying dataset in HDFS..."
docker exec namenode /bin/bash -c "hdfs dfs -ls /heart_data"

# Step 9: Copy MapReduce scripts to HDFS
# Verify paths of scripts before copying
echo "Mapper Path: ${APP_DIR}/mapper.py"
echo "Reducer Path: ${APP_DIR}/reducer.py"

# Ensure the MapReduce scripts are available inside the container first
docker cp ${APP_DIR}/mapper.py namenode:/heart_data/mapper.py
docker cp ${APP_DIR}/reducer.py namenode:/heart_data/reducer.py

# Then copy them into HDFS
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/mapper.py /heart_data/"
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/reducer.py /heart_data/"


# Step 10: Ensure script files exist in HDFS before running
echo "Ensuring mapper and reducer scripts are available in HDFS..."
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/mapper.py /heart_data/ || true"
docker exec namenode /bin/bash -c "hdfs dfs -put -f /heart_data/reducer.py /heart_data/ || true"

# deletign output dir if it already exists
echo "Checking if /heart_data_output directory exists in HDFS..."
DIR_EXISTS=$(docker exec namenode /bin/bash -c "hdfs dfs -test -d /heart_data_output && echo 'exists' || echo 'does not exist'")

if [ "$DIR_EXISTS" == "exists" ]; then
    echo "/heart_data_output directory exists. Removing it..."
    docker exec namenode /bin/bash -c "hdfs dfs -rm -r /heart_data_output"
    echo "/heart_data_output directory removed from HDFS."
else
    echo "/heart_data_output directory does not exist in HDFS."
fi


# Step 11: Run MapReduce job
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

# Step 12: Retrieve output from HDFS
echo "Retrieving MapReduce job output..."
mkdir -p ${OUTPUT_DIR}
docker exec namenode /bin/bash -c "hdfs dfs -cat /heart_data_output/part-00000" > ${MAPREDUCE_OUTPUT}

if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve MapReduce job output. Exiting."
    exit 1
fi


#  Run Flask app (outside the Docker container)
echo "Starting Flask app..."
echo "Running Flask app locally..."
python3 ${APP_DIR}/app.py &
echo "Flask app started. You can access it at http://localhost:5001"
echo "MapReduce job complete. Results saved in ${MAPREDUCE_OUTPUT}"