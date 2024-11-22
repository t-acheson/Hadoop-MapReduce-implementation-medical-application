import pandas as pd

# Load the dataset
file_path = 'data/heart_disease.csv'  
data = pd.read_csv(file_path)

# Define age and cholesterol ranges
def define_age_bucket(age):
    if 20 <= age <= 30:
        return '20-30'
    elif 31 <= age <= 40:
        return '31-40'
    elif 41 <= age <= 50:
        return '41-50'
    elif 51 <= age <= 60:
        return '51-60'
    elif 61 <= age <= 70:
        return '61-70'
    else:
        return '71+'

def define_chol_bucket(chol):
    if 100 <= chol <= 199:
        return '100-199'
    elif 200 <= chol <= 239:
        return '200-239'
    elif 240 <= chol <= 279:
        return '240-279'
    else:
        return '280+'

# Apply the bucket definitions
data['age_bucket'] = data['age'].apply(define_age_bucket)
data['chol_bucket'] = data['chol'].apply(define_chol_bucket)

# Keep only the necessary columns
data_preprocessed = data[['id', 'age', 'age_bucket', 'chol', 'chol_bucket', 'num']]

# Map 'num' to binary heart disease presence (1 if disease is present, 0 if absent)
data_preprocessed['heart_disease'] = data_preprocessed['num'].apply(lambda x: 1 if x > 0 else 0)

# Save the preprocessed data for MapReduce input
preprocessed_file = 'preprocessed_heart_disease_data.csv'
data_preprocessed.to_csv(preprocessed_file, index=False)

print(f"Preprocessed data saved to {preprocessed_file}")
