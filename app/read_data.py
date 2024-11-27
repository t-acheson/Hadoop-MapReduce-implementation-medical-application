import pandas as pd

# Load the dataset
file_path = 'heart_disease.csv'  
data = pd.read_csv(file_path)

# Define age and cholesterol ranges
def define_age_bucket(age):
    if 20 <= age <= 40:
        return '20-40'
    elif 41 <= age <= 60:
        return '41-60'
    else:
        return '61+'

def define_chol_bucket(chol):
    if chol <= 200:
        return '<=200'
    elif 201 <= chol <= 239:
        return '201-239'
    else:
        return '240+'

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
