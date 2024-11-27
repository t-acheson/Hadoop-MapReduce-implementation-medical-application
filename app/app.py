from flask import Flask, jsonify, render_template
import requests
import json

app = Flask(__name__)

# Ensure this points to your Docker container network
YARN_API_BASE = "http://resourcemanager:8088/ws/v1/cluster"  # Docker container name

@app.route('/api/data')
def get_data():
    try:
        response = requests.get(f"{YARN_API_BASE}/apps")
        response.raise_for_status()  # Raise an exception for HTTP errors
        apps = response.json().get('apps', {}).get('app', [])

        job_status = []
        for app in apps:
            app_name = app.get('name')
            app_id = app.get('id')
            app_state = app.get('state')
            app_tracking_url = app.get('trackingUrl', 'N/A')

            job_status.append({
                'app_name': app_name,
                'app_id': app_id,
                'app_state': app_state,
                'tracking_url': app_tracking_url
            })

        return jsonify(job_status)

    except requests.exceptions.RequestException as e:
        return jsonify({'error': str(e)}), 500


@app.route('/')
def index():
    return render_template('dashboard.html')  # Serve the dashboard page


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)


# from flask import Flask, jsonify, render_template
# import pandas as pd

# app = Flask(__name__)

# # Load MapReduce output
# RESULT_FILE = 'mapreduce_results.csv'  # TODO Replace with actual file path

# @app.route('/api/data')
# def get_data():
#     # Load the results file into a DataFrame
#     data = pd.read_csv(RESULT_FILE, sep="\t", header=None)
#     data.columns = ['Cluster', 'Summary']

#     # Prepare data for visualization
#     results = []
#     for _, row in data.iterrows():
#         cluster = row['Cluster']
#         summary = row['Summary']

#         # Extract cluster and values
#         age_bucket, chol_bucket = cluster.split(',')
#         total = int(summary.split(',')[0].split(':')[1].strip())
#         heart_disease = int(summary.split(',')[1].split(':')[1].strip())
#         percentage = float(summary.split(',')[2].split(':')[1].strip().replace('%', ''))

#         results.append({
#             'age_bucket': age_bucket,
#             'chol_bucket': chol_bucket,
#             'total': total,
#             'heart_disease': heart_disease,
#             'percentage': percentage
#         })
    
#     return jsonify(results)

# @app.route('/')
# def index():
#     return render_template('dashboard.html')  # Serve the dashboard page

# if __name__ == '__main__':
#     app.run(debug=True)
