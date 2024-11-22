from flask import Flask, jsonify, render_template
import pandas as pd

app = Flask(__name__)

# Load MapReduce output
RESULT_FILE = 'mapreduce_results.csv'  # TODO Replace with your actual file path

@app.route('/api/data')
def get_data():
    # Load the results file into a DataFrame
    data = pd.read_csv(RESULT_FILE, sep="\t", header=None)
    data.columns = ['Cluster', 'Summary']

    # Prepare data for visualization
    results = []
    for _, row in data.iterrows():
        cluster = row['Cluster']
        summary = row['Summary']

        # Extract cluster and values
        age_bucket, chol_bucket = cluster.split(',')
        total = int(summary.split(',')[0].split(':')[1].strip())
        heart_disease = int(summary.split(',')[1].split(':')[1].strip())
        percentage = float(summary.split(',')[2].split(':')[1].strip().replace('%', ''))

        results.append({
            'age_bucket': age_bucket,
            'chol_bucket': chol_bucket,
            'total': total,
            'heart_disease': heart_disease,
            'percentage': percentage
        })
    
    return jsonify(results)

@app.route('/')
def index():
    return render_template('dashboard.html')  # Serve the dashboard page

if __name__ == '__main__':
    app.run(debug=True)
