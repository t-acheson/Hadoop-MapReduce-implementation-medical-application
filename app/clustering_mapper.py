import sys

# Define the ranges for age and cholesterol
def get_age_bucket(age):
    if age < 30:
        return "20-29"
    elif 30 <= age < 40:
        return "30-39"
    elif 40 <= age < 50:
        return "40-49"
    elif 50 <= age < 60:
        return "50-59"
    elif 60 <= age < 70:
        return "60-69"
    else:
        return "70+"

def get_chol_bucket(chol):
    if chol < 200:
        return "0-199"
    elif 200 <= chol < 240:
        return "200-239"
    else:
        return "240+"

# Read input
for line in sys.stdin:
    # Skip header line
    if line.startswith("id"):
        continue
    columns = line.strip().split(',')
    
    try:
        age = int(columns[1])  # age is the second column
        cholesterol = int(columns[6])  # cholesterol is the seventh column
        age_bucket = get_age_bucket(age)
        chol_bucket = get_chol_bucket(cholesterol)

        # Emit the age-cholesterol bucket as the key and 1 as the value
        print(f"{age_bucket}-{chol_bucket}\t1")
    except (ValueError, IndexError):
        continue  # Skip invalid lines
