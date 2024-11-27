#!/usr/bin/env python3
import sys
import csv

def mapper():
    # Read input line by line
    for line in sys.stdin:
        # Skip the header
        if "id" in line:
            continue

        # Parse the CSV input
        row = list(csv.reader([line.strip()]))[0]
        try:
            age_bucket = row[2]  # age_bucket column
            chol_bucket = row[4]  # chol_bucket column
            heart_disease = int(row[5])  # heart_disease column

            # Ensure heart_disease is binary (0 or 1)
            heart_disease = 1 if heart_disease > 0 else 0
            
            # Emit key-value pair
            print(f"{age_bucket},{chol_bucket}\t{heart_disease}")
        except ValueError:
            continue

if __name__ == "__main__":
    mapper()
