#!/usr/bin/env python3
import sys

def reducer():
    current_key = None
    total_patients = 0
    heart_disease_count = 0

    # Iterate over each line of the input
    for line in sys.stdin:
        line = line.strip()
        
        if not line:  # Skip empty lines
            continue
        
        # Split key and value from the tab-separated input
        key, value = line.split("\t")
        
        # Cast the value into an integer
        value = int(value)
        
        # When the key changes, process the previous bucket
        if key != current_key and current_key is not None:
            # Calculate the percentage of heart disease cases
            percentage = (heart_disease_count / total_patients) * 100
            print(f"{current_key}\tTotal: {total_patients}, Heart Disease: {heart_disease_count}, Percentage: {percentage:.2f}%")
            
            # Reset counts for the new key
            total_patients = 0
            heart_disease_count = 0
        
        # Update the counts
        current_key = key
        total_patients += 1
        heart_disease_count += value
    
    # After the loop, process the last key
    if current_key is not None:
        percentage = (heart_disease_count / total_patients) * 100
        print(f"{current_key}\tTotal: {total_patients}, Heart Disease: {heart_disease_count}, Percentage: {percentage:.2f}%")

if __name__ == "__main__":
    reducer()
