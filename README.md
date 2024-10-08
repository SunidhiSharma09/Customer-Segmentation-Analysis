### Customer Segmentation Analysis
- Live dashboard: [https://app.powerbi.com/reportEmbed?reportId=c7eb66fc-e75e-4190-ac44-e177679486bf&autoAuth=true&ctid=f32b2380-e473-4691-8ba9-71915e0a20cd](https://app.powerbi.com/view?r=eyJrIjoiNmNjNmQ5MjEtNTc3OS00MmQwLTg2OTYtYzBiOWMyOGJiZmI4IiwidCI6ImYzMmIyMzgwLWU0NzMtNDY5MS04YmE5LTcxOTE1ZTBhMjBjZCJ9&pageName=6837edfa9b90521b88ee)
#### Domain: e-commerce
#### Introduction:
In today's highly competitive market, understanding customer behavior and maximizing the lifetime value of each customer is crucial for businesses
to optimize marketing strategies, and enhance overall profitability. Therefore, this project focuses on segmenting customers based on their purchasing patterns and demographics, allowing for targeted marketing strategies to improve customer retention. The main objective is to calculate Customer Lifetime Value (CLV) for each customer, segment the customer base into distinct groups (high, medium, and low-value), and provide actionable insights through advanced data analytics techniques,
#### Objective:
To analyze customer data from an e-commerce platform to segment customers based on purchasing behavior and calculate Customer Lifetime Value (CLV) for inform targeted marketing strategies
and enhance customer retention. 
#### Tools & Techniques Implemented:
- Excel - It is used to clean and transform the data for analysis using Power Query, XLOOKUP for cross-referencing across sheets and VBA to automate the data standardization.
- SQL - A database is created to store all the information of customers and members from the cleaned exccel sheets. A VBA automation is implemented to automatically store the new entry in Customers and Members Sheet to the SQL Server database with all the cleaning.
- Power BI - For better analysis and visualization Power BI is used in which the data is connected live to the SQL Server database via Direct Query mode so that any update of the records get automatically reflected on the dashboard.
- Python - It was used for deeper analysis of the data like statistical analysis for which data is imported from the excel.

NOTE : You can find the workflow, codes screenshot and various outputs in the documentation too. 

