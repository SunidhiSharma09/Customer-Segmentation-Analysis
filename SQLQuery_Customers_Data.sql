-- END CAPSTONE-2 : CUSTOMER SEGMENTATION ANALYSIS

CREATE DATABASE Customer_info;

USE Customer_info;

SELECT * FROM Customers -- customer info table

SELECT * FROM Members -- member info table

/* Perform an INNER JOIN on the two tables based on customer email. */

SELECT * FROM Customers AS c
JOIN Members AS m 
ON c.Customer_Id = m.Customer_Id;



/* Write a SQL function calculate_avg_purchase_value that takes a customer ID as input and returns the average purchase value for that customer.
Ensure the function handles cases where there are no purchases (e.g., returns NULL or a default value). */

CREATE FUNCTION calculate_avg_purchase_value (@Customer_Id varchar(70))
RETURNS DECIMAL(10,2)
AS 
BEGIN
    DECLARE @Total_Spent DECIMAL(10,2);
    DECLARE @Total_Purchase INT;
    DECLARE @Average_Purchase_Value DECIMAL(10,2);

    -- combining customers data from both tables to create final table
    SELECT @Total_Spent = SUM(c.Total_Spent), @Total_Purchase = SUM(c.Total_Purchase)
    FROM (
        SELECT Total_Spent, Total_Purchase
        FROM Customers
        WHERE Customer_Id = @Customer_Id

        UNION ALL

        SELECT Total_Spent, Total_Purchase
        FROM Members
        WHERE Customer_Id = @Customer_Id
    ) c;

    -- Handling null or zero purchases
    IF @Total_Purchase IS NULL OR @Total_Purchase = 0
    BEGIN 
        SET @Average_Purchase_Value = 0;
    END
    ELSE
    BEGIN
        SET @Average_Purchase_Value = @Total_Spent / @Total_Purchase;
    END

    RETURN @Average_Purchase_Value;
END;

-- to execute
SELECT dbo.calculate_avg_purchase_value('Alex Brown-alex.brown@gmail.com') AS Average_Purchase_Value ;



/* Write a SQL view segmented_customers that categorizes customers into 'High Spenders', 'Medium Spenders', and 'Low Spenders'. 
The categorization should be based on the total amount spent by each customer, with defined thresholds for each segment.*/

CREATE VIEW segmented_customers AS
WITH Combined_Spent AS (                               -- combining both the tables to create final table of customer data.
    SELECT 
        Customer_Id,
        SUM(COALESCE(Total_Spent, 0)) AS Total_Spent
    FROM (
        SELECT Customer_Id, Total_Spent
        FROM Customers
        UNION ALL
        SELECT Customer_Id, Total_Spent
        FROM Members
    ) AS Combined
    GROUP BY Customer_Id
)
-- Categorizing customers based on total spent
SELECT 
    Customer_Id,
    Total_Spent,
    CASE 
        WHEN Total_Spent > 30000 THEN 'High Spenders'
        WHEN Total_Spent BETWEEN 10000 AND 30000 THEN 'Medium Spenders'
        ELSE 'Low Spenders'
    END AS Spending_Category
FROM Combined_Spent;

-- to execute
SELECT * FROM segmented_customers;



/* Calculate customer segments (e.g., 'High Value', 'Medium Value','Low Value') based on Total Spent and Total Purchases. 
Implement a column to classify customers into these segments.*/

CREATE VIEW customer_value_segment AS
WITH Combined_Data AS (
    SELECT 
        Customer_Id,
        SUM(COALESCE(Total_Spent, 0)) AS Total_Spent,
        SUM(COALESCE(Total_Purchase, 0)) AS Total_Purchase
    FROM (
        SELECT Customer_Id, Total_Spent, Total_Purchase
        FROM Customers
        UNION ALL
        SELECT Customer_Id, Total_Spent, Total_Purchase
        FROM Members
    ) AS Combined
    GROUP BY Customer_Id
),
Percentile_Data AS (
    SELECT
        Customer_Id,
        Total_Spent,
        Total_Purchase,
        PERCENT_RANK() OVER (ORDER BY Total_Spent) AS Spent_Percentile,
        PERCENT_RANK() OVER (ORDER BY Total_Purchase) AS Purchase_Percentile
    FROM Combined_Data
)
SELECT 
    Customer_Id,
    Total_Spent,
    Total_Purchase,
    CASE
        WHEN Spent_Percentile >= 0.75 AND Purchase_Percentile >= 0.75 THEN 'High Value'
        WHEN Spent_Percentile BETWEEN 0.25 AND 0.75 AND Purchase_Percentile BETWEEN 0.25 AND 0.75 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Value_Segment
FROM Percentile_Data;

-- to execute
SELECT * FROM customer_value_segment
WHERE Customer_Value_Segment='High Value'


/* Create a data model that includes relationships between the tables.*/

ALTER TABLE Customers
ADD CONSTRAINT FK_Member_Customers
FOREIGN KEY (Customer_Id)
REFERENCES Members_data(Customer_Id)



/* Generate calculated tables to support specific analysis requirements (e.g., a table for Top 10 Customers by Revenue). Use these tables in the
data model and visualizations.*/

-- Combined Data Table
CREATE VIEW Combined_Customers_List 
AS
    SELECT 
        Customer_Id,
        SUM(COALESCE(Total_Spent, 0)) AS Total_Spent,
        SUM(COALESCE(Total_Purchase, 0)) AS Total_Purchase,
		Customer_Since as Customer_Since,
		Member_Since as Member_Since
    FROM (
        SELECT Customer_Id, Total_Spent, Total_Purchase, Customer_Since, Member_Since
        FROM Customers
        UNION ALL
        SELECT Customer_Id, Total_Spent, Total_Purchase, Customer_Since, Member_Since
        FROM Members
    ) AS Combined
    GROUP BY Customer_Id, Customer_Since,Member_Since


SELECT * FROM Combined_Customers_List ORDER BY Total_Spent DESC;

SELECT TOP 10 * FROM Combined_Customers_List ORDER BY Total_Spent DESC; -- to see top 10 customers by spent

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Customer Life-Time Value(CLV) Calculation table and segmentation based on CLV

CREATE VIEW Customers_clv AS
WITH CLV_Calculation AS (
    SELECT 
        Customer_Id,
        Total_Purchase,
        Total_Spent,
        
        -- Determining the first year the customer started (either as Customer or Member)
        CASE 
            WHEN Customer_Since IS NULL THEN Member_Since
            WHEN Member_Since IS NULL THEN Customer_Since
            ELSE CASE 
                    WHEN Customer_Since < Member_Since THEN Customer_Since
                    ELSE Member_Since
                 END
        END AS First_Year,
        
        -- Calculating Customer Lifespan in Years taking 2024 as current yrar
        CASE 
            WHEN Customer_Since IS NULL THEN 2024 - Member_Since
            WHEN Member_Since IS NULL THEN 2024 - Customer_Since
            ELSE CASE 
                    WHEN Customer_Since < Member_Since THEN 2024 - Customer_Since
                    ELSE 2024 - Member_Since
                 END
        END AS Customer_Lifespan_Years,
        
        -- Calculating CLV using the formula (Total Spent / Total Purchases) * Customer Lifespan
        CASE 
            WHEN Total_Purchase > 0 THEN (Total_Spent / Total_Purchase) * 
                 CASE 
                    WHEN Customer_Since IS NULL THEN 2024 - Member_Since
                    WHEN Member_Since IS NULL THEN 2024 - Customer_Since
                    ELSE CASE 
                            WHEN Customer_Since < Member_Since THEN 2024 - Customer_Since
                            ELSE 2024 - Member_Since
                         END
                 END
            ELSE 0
        END AS CLV1

    FROM combined_customers_list
)

SELECT 
    Customer_Id,
    Total_Purchase,
    Total_Spent,
    First_Year,
    Customer_Lifespan_Years,
    
    -- Formatting the CLV to 2 decimal places
    ROUND(CLV1, 2) AS CLV,

    -- Classifying customers into High, Medium, and Low value based on CLV
    CASE 
        WHEN ROUND(CLV1, 2) > 2000 THEN 'High Value'
        WHEN ROUND(CLV1, 2) BETWEEN 1000 AND 2000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Segment

FROM CLV_Calculation;

SELECT*FROM Customers_CLV -- to execute
