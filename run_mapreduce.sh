#!/bin/bash

# Step 1: Start Hadoop using Docker Compose if not already running
echo "Starting Hadoop containers..."
docker-compose up -d

# Step 2: Verify containers are running
echo "Checking running containers..."
docker ps

# Step 3: Copy dataset to Hadoop NameNode container
echo "Copying dataset to HDFS..."
docker cp /Users/taraacheson/Desktop/cloud_project/preprocessed_heart_disease_data.csv namenode:/heart_data/

# Step 4: Enter NameNode container
echo "Entering NameNode container..."
docker exec -it namenode /bin/bash -c "hdfs dfs -mkdir -p /heart_data"
docker exec -it namenode /bin/bash -c "hdfs dfs -put /heart_data/preprocessed_heart_disease_data.csv /heart_data/"

# Step 5: Copy MapReduce scripts to NameNode container
echo "Copying MapReduce scripts to NameNode..."
docker cp /Users/taraacheson/Desktop/cloud_project/app/mapper.py namenode:/heart_data/
docker cp /Users/taraacheson/Desktop/cloud_project/app/reducer.py namenode:/heart_data/

# Step 6: Run MapReduce job using Hadoop Streaming
echo "Running Hadoop Streaming job..."
docker exec -it namenode /bin/bash -c "hadoop jar /opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar \
    -input /heart_data/preprocessed_heart_disease_data.csv \
    -output /heart_data_output \
    -mapper /heart_data/mapper.py \
    -reducer /heart_data/reducer.py \
    -file /heart_data/mapper.py \
    -file /heart_data/reducer.py"

# Step 7: Verify output directory and view results
echo "Checking output directory..."
docker exec -it namenode /bin/bash -c "hdfs dfs -ls /heart_data_output"
docker exec -it namenode /bin/bash -c "hdfs dfs -cat /heart_data_output/part-00000"

# Step 8: Copy output file to local system for dashboard
echo "Copying results back to local system..."
docker cp namenode:/heart_data_output/part-00000 /path/to/your/local/directory/mapreduce_results.csv

echo "MapReduce job complete. Results saved in mapreduce_results.csv"








