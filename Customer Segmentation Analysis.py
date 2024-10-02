#!/usr/bin/env python
# coding: utf-8

# #### Customer Segmentation Analysis 

# In[ ]:





# The following tasks have been performed using this Python script -
# 1. Calculation of Customer Lifetime Value(CLV)
# 2. Segmentation based on CLV
# 3. Statistical analysis
# 4. Interactive visualization.

# In[1]:


#importing libraries

import pandas as pd
import time
import matplotlib.pyplot as plt
import seaborn as sns
import plotly.express as px
import ipywidgets as widgets
from IPython.display import display
from datetime import datetime

# Timing decorator function for individual record processing
def timing_decorator(func):
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        execution_time = end_time - start_time
        print(f"Execution time: {execution_time:.11f} seconds")
        return result
    return wrapper

class Customer:
    print("CLV & Customer Segment for each Customer ID\n")
    def __init__(self, customer_id, total_purchases, total_spent, years_active):
        self.customer_id = customer_id
        self.total_purchases = total_purchases
        self.total_spent = total_spent
        self.years_active = years_active

    def calculate_clv(self):      # function to calculate customer lifetime value(clv)
        if self.total_purchases > 0 and self.years_active > 0:
            return round((self.total_spent / self.total_purchases) * self.years_active, 2)
        return 0

    def segment_customer(self):    # function to segment cutomers based on clv.
        clv = self.calculate_clv()
        if clv > 2000:
            return 'High Value'
        elif 1000 <= clv <= 2000:
            return 'Medium Value'
        else:
            return 'Low Value'

class CustomerAnalysis:
    def __init__(self, file_path):
        self.file_path = file_path
        self.combined_data = self.load_and_combine_data()
        self.segments, self.clv_values = self.process_customers()

    def load_and_combine_data(self):   #function to combine data from customers and members sheet to create a final data.
        customers_df = pd.read_excel(self.file_path, sheet_name='Customers', 
                                     usecols=['Customer Id', 'Total Purchase', 'Total Spent', 'Customer Since'])
        members_df = pd.read_excel(self.file_path, sheet_name='Members', 
                                   usecols=['Customer Id', 'Total Purchase', 'Total Spent', 'Member Since'])

        combined_df = pd.concat([customers_df, members_df])

        # Handling missing values for 'Customer Since' and 'Member Since' columns
        combined_df['Customer Since'] = pd.to_numeric(combined_df['Customer Since'], errors='coerce')
        combined_df['Member Since'] = pd.to_numeric(combined_df['Member Since'], errors='coerce')

        # Determining the earliest year for each customer
        combined_df['Earliest Since'] = combined_df[['Customer Since', 'Member Since']].min(axis=1)

        # Calculating the number of active years (current year - earliest year)
        current_year = datetime.now().year
        combined_df['Years Active'] = current_year - combined_df['Earliest Since']

        # Aggregation by customer ID
        aggregated_df = combined_df.groupby('Customer Id').agg({
            'Total Purchase': 'sum',
            'Total Spent': 'sum',
            'Years Active': 'max'  # Use the max because years_active should be consistent for each customer
        }).reset_index()

        return aggregated_df

    def customer_generator(self):      #Generator function to yield customer records one at a time
        for _, row in self.combined_data.iterrows():
            yield row

    @timing_decorator
    def process_single_customer(self, record):
        customer = Customer(record['Customer Id'], record['Total Purchase'], record['Total Spent'], record['Years Active'])
        clv = customer.calculate_clv()
        segment = customer.segment_customer()
        print(f"Customer ID: {customer.customer_id}, CLV: {clv}, Customer Segment: {segment}, Years Active: {customer.years_active}")
        return segment, clv

    def process_customers(self):
        segments = []
        clv_values = []
        for record in self.customer_generator():
            segment, clv = self.process_single_customer(record)
            segments.append(segment)
            clv_values.append(clv)
        return segments, clv_values

    def summary_statistics(self):  # function to generate summary statistics 
        print("\nSummary Statistics:")
        self.combined_data['CLV'] = self.clv_values  
        print(self.combined_data.describe())

    def interactive_visualizations(self):   # function to create interactive visualizations
        # Create a dataframe combining data with segments
        segment_df = pd.DataFrame({'Customer Segment': self.segments, 'CLV': self.clv_values})
        combined_with_segments = pd.concat([self.combined_data, segment_df], axis=1)

        segment_dropdown = widgets.Dropdown(
            options=['All', 'High Value', 'Medium Value', 'Low Value'],
            value='All',
            description='Segment:'
        )

        start_date = widgets.DatePicker(
            description='Start Date',
            disabled=False
        )
        end_date = widgets.DatePicker(
            description='End Date',
            disabled=False
        )

        # Function to update the visualizations based on selected filters
        def update_visualizations(segment, start_date, end_date):
            filtered_data = combined_with_segments.copy()

            # Filter by segment
            if segment != 'All':
                filtered_data = filtered_data[filtered_data['Customer Segment'] == segment]

            # Interactive Donut Chart for Customer Count by Segment
            print("\nVisualizations") 
            segment_counts = filtered_data['Customer Segment'].value_counts()
            fig = px.pie(values=segment_counts, names=segment_counts.index, title="Total Customers by Customer Segment", 
                         hole=0.4, labels={'Customer Segment': 'Segment'}, 
                         color_discrete_sequence=px.colors.qualitative.Set3)
            fig.show()

            # Donut chart for Total Spent by Segment
            fig = px.pie(filtered_data, names='Customer Segment', values='Total Spent', title='Total Spent by Customer Segment', hole=0.4)
            fig.show()

            # Donut chart for Total Purchases by Segment
            fig = px.pie(filtered_data, names='Customer Segment', values='Total Purchase', title='Total Purchases by Customer Segment', hole=0.4)
            fig.show()

            # Scatter plot for Total Purchase vs Total Spent
            plt.figure(figsize=(8, 6))
            sns.scatterplot(x='Total Purchase', y='Total Spent', data=filtered_data)
            plt.title('Total Purchase vs Total Spent')
            plt.xlabel('Total Purchase')
            plt.ylabel('Total Spent')
            plt.show()

        # Interactive Output
        interactive_out = widgets.interactive_output(update_visualizations, {
            'segment': segment_dropdown,
            'start_date': start_date,
            'end_date': end_date
        })

        # Display widgets and interactive output
        display(widgets.VBox([segment_dropdown, start_date, end_date]), interactive_out)

    def correlation_matrix(self):  #function to generate correlation matrix for combined data.
        correlation = self.combined_data[['Total Purchase', 'Total Spent']].corr()

        # Displaying correlation matrix as a table
        print("\nPurchase vs Spent - Correlation Matrix Table:")
        print(correlation)

        # Displaying correlation matrix as a heatmap
        plt.figure(figsize=(6, 4))
        sns.heatmap(correlation, annot=True, cmap='coolwarm', fmt='.2f')
        plt.title('Purchase vs Spent - Correlation Matrix Heatmap')
        plt.show()

# data file path
file_path = r'C:\Users\DELL\Documents\CUSTOMERS DATA.xlsx'
analysis = CustomerAnalysis(file_path)

# Generating output by calling class and each function
segments, clv_values = analysis.process_customers()
analysis.summary_statistics()
analysis.correlation_matrix()
analysis.interactive_visualizations()


# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:




