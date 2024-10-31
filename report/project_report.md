# Project Title: Hadoop/MapReduce Implementation for Medical Application

## Application Overview
This project aims to analyze the UCI Heart Disease dataset using the Hadoop/MapReduce framework to predict the presence of heart disease based on various medical attributes.

## Objectives
1. **Goal**: Build a predictive model that identifies whether a patient has heart disease.
   - **Completed**: Implemented using MapReduce with logistic regression and decision trees.
   
2. **Goal**: Describe the problem and the dataset.
   - **Completed**: Detailed the dataset features, including age, cholesterol levels, and blood pressure.
   
3. **Goal**: Explain the methodology.
   - **Completed**: Logistic regression and Random Forests were selected for their effectiveness in binary classification.

## Methodology and Implementation
- Implemented a MapReduce job with Mapper and Reducer scripts.
- Utilized logistic regression for binary classification.

## Suitability of the Tool
MapReduce is appropriate for batch processing large datasets, providing scalability and fault tolerance.

## System Functionality
The system processes data in Hadoop, performs analysis with MapReduce, and allows for visualization via a web dashboard.

## Worked Example
An example of data flow includes loading data into HDFS, processing with MapReduce, and retrieving results for visualization.

## Conclusion
The analysis provides insights into heart disease prediction, and future improvements may include using more complex models and additional features.

## References
- UCI Heart Disease Dataset: [Kaggle](https://www.kaggle.com/datasets/redwankarimsony/heart-disease-data)
