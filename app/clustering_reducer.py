import sys
from collections import defaultdict

# Dictionary to store counts for each (age_bucket, chol_bucket)
bucket_counts = defaultdict(int)

# Read input
for line in sys.stdin:
    key, value = line.strip().split("\t")
    bucket_counts[key] += int(value)

# Output the results
for key, count in bucket_counts.items():
    print(f"{key}\t{count}")
