CREATE DATABASE fedex_project;
USE fedex_project;
SELECT COUNT(*) FROM Orders;        -- Should show 300
SELECT COUNT(*) FROM Shipments;     -- Should show 1000
SELECT COUNT(*) FROM Routes;        -- Should show 20
SELECT COUNT(*) FROM Warehouses;    -- Should show 10
SELECT COUNT(*) FROM Delivery_Agents; -- Should show 50


-- check duplicate order ids:
SELECT Order_ID, COUNT(*) AS cnt
FROM orders
GROUP BY Order_ID
HAVING cnt > 1;


-- check duplicate shipment IDs:
SELECT Shipment_ID, COUNT(*) AS cnt
FROM shipments
GROUP BY Shipment_ID
HAVING cnt > 1;


-- check Null values in delay hours:
SELECT COUNT(*) AS null_count
FROM shipments
WHERE Delay_Hours IS NULL;



-- convert dates into proper format
SELECT
    Order_ID,
    DATE_FORMAT(Order_Date, '%Y-%m-%d %H:%i:%s') AS Order_Date_Formatted
FROM orders
LIMIT 5;

SELECT
    Shipment_ID,
    DATE_FORMAT(Pickup_Date, '%Y-%m-%d %H:%i:%s') AS Pickup_Date_Formatted,
    DATE_FORMAT(Delivery_Date, '%Y-%m-%d %H:%i:%s') AS Delivery_Date_Formatted
FROM shipments
LIMIT 5;


-- flag records where delhiwery date is berofe pickup date;
SELECT Shipment_ID, Order_ID, Pickup_Date, Delivery_Date,
    'INVALID - Delivery before Pickup' AS Flag
FROM shipments
WHERE Delivery_Date < Pickup_Date;


-- check referential integrity;
-- order to routes
SELECT o.Order_ID, o.Route_ID
FROM orders o
LEFT JOIN routes r ON o.Route_ID = r.Route_ID
WHERE r.Route_ID IS NULL;

-- orders to warehouse
SELECT o.Order_ID, o.Warehouse_ID
FROM orders o
LEFT JOIN warehouses w ON o.Warehouse_ID = w.Warehouse_ID
WHERE w.Warehouse_ID IS NULL;

-- shipment to orders
SELECT s.Shipment_ID, s.Order_ID
FROM shipments s
LEFT JOIN orders o ON s.Order_ID = o.Order_ID
WHERE o.Order_ID IS NULL;

-- shipment to agents
SELECT s.Shipment_ID, s.Agent_ID
FROM shipments s
LEFT JOIN delivery_agents a ON s.Agent_ID = a.Agent_ID
WHERE a.Agent_ID IS NULL;


-- TASK 2 : DELHIVERY DELAY ANALYSIS
-- calculate delay in hours for each shipment
SELECT
    Shipment_ID,
    Order_ID,
    Route_ID,
    Pickup_Date,
    Delivery_Date,
    ROUND(TIMESTAMPDIFF(HOUR, Pickup_Date, Delivery_Date), 2) AS Actual_Transit_Hours,
    Delay_Hours
FROM shipments
ORDER BY Delay_Hours DESC;

-- top 10 most delayed routes;
SELECT
    s.Route_ID,
    r.Source_City,
    r.Destination_City,
    ROUND(AVG(s.Delay_Hours), 2) AS Avg_Delay_Hours,
    COUNT(*) AS Total_Shipments
FROM shipments s
JOIN routes r ON s.Route_ID = r.Route_ID
GROUP BY s.Route_ID, r.Source_City, r.Destination_City
ORDER BY Avg_Delay_Hours DESC
LIMIT 10;

-- rank shipment by delay within each warehoue(window function)
SELECT
    Shipment_ID,
    Warehouse_ID,
    Delay_Hours,
    RANK() OVER (
        PARTITION BY Warehouse_ID
        ORDER BY Delay_Hours DESC
    ) AS Delay_Rank
FROM shipments
ORDER BY Warehouse_ID, Delay_Rank;

USE fedex_project
-- Average delay by delivery type
SELECT
    o.Delivery_Type,
    ROUND(AVG(s.Delay_Hours), 2) AS Avg_Delay_Hours,
    COUNT(*) AS Total_Shipments
FROM shipments s
JOIN orders o ON s.Order_ID = o.Order_ID
GROUP BY o.Delivery_Type
ORDER BY Avg_Delay_Hours DESC;

-- TASK 3:ROUTE OPTIMAIZATION INSIGHTS
-- Full route analysis with all metrics
SELECT
    r.Route_ID,
    r.Source_City,
    r.Source_Country,
    r.Destination_City,
    r.Destination_Country,
    r.Distance_KM,
    r.Avg_Transit_Time_Hours,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, s.Pickup_Date, s.Delivery_Date)), 2) AS Actual_Avg_Transit_Hours,
    ROUND(AVG(s.Delay_Hours), 2) AS Avg_Delay_Hours,
    ROUND(r.Distance_KM / r.Avg_Transit_Time_Hours, 2) AS Efficiency_Ratio,
    COUNT(*) AS Total_Shipments,
    SUM(CASE WHEN s.Delay_Hours > 0 THEN 1 ELSE 0 END) AS Delayed_Shipments,
    ROUND(100.0 * SUM(CASE WHEN s.Delay_Hours > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS Delay_Pct
FROM shipments s
JOIN routes r ON s.Route_ID = r.Route_ID
GROUP BY r.Route_ID, r.Source_City, r.Source_Country,
         r.Destination_City, r.Destination_Country,
         r.Distance_KM, r.Avg_Transit_Time_Hours
ORDER BY Efficiency_Ratio ASC;

-- 3 routes with worst efficiency ratio
SELECT
    Route_ID,
    CONCAT(Source_City, ' → ', Destination_City) AS Route,
    Distance_KM,
    Avg_Transit_Time_Hours,
    ROUND(Distance_KM / Avg_Transit_Time_Hours, 2) AS Efficiency_Ratio
FROM routes
ORDER BY Efficiency_Ratio ASC
LIMIT 3;

-- routes where more than 20 % shipments are delayed 
SELECT
    r.Route_ID,
    r.Source_City,
    r.Destination_City,
    COUNT(*) AS Total_Shipments,
    SUM(CASE WHEN s.Delay_Hours > 0 THEN 1 ELSE 0 END) AS Delayed_Shipments,
    ROUND(100.0 * SUM(CASE WHEN s.Delay_Hours > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS Delay_Pct
FROM shipments s
JOIN routes r ON s.Route_ID = r.Route_ID
GROUP BY r.Route_ID, r.Source_City, r.Destination_City
HAVING Delay_Pct > 20
ORDER BY Delay_Pct DESC;

-- recommendation to write in ppt 

-- TASK 4 WAREHOUSES WITH HIGHEST AVG DELAY
SELECT
    s.Warehouse_ID,
    w.City,
    w.Country,
    ROUND(AVG(s.Delay_Hours), 2) AS Avg_Delay_Hours,
    COUNT(*) AS Total_Shipments
FROM shipments s
JOIN warehouses w ON s.Warehouse_ID = w.Warehouse_ID
GROUP BY s.Warehouse_ID, w.City, w.Country
ORDER BY Avg_Delay_Hours DESC
LIMIT 3;

-- TOTAL VS DELAYED SHIPMENT PER WARE HOUSE
SELECT
    s.Warehouse_ID,
    w.City,
    COUNT(*) AS Total_Shipments,
    SUM(CASE WHEN s.Delay_Hours > 0 THEN 1 ELSE 0 END) AS Delayed_Shipments,
    ROUND(100.0 * SUM(CASE WHEN s.Delay_Hours > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS Delayed_Pct
FROM shipments s
JOIN warehouses w ON s.Warehouse_ID = w.Warehouse_ID
GROUP BY s.Warehouse_ID, w.City
ORDER BY Delayed_Pct DESC;

-- CTE to find warehouses above global average delay
USE fedex_project;
WITH global_avg AS (
    SELECT AVG(Delay_Hours) AS g_avg
    FROM shipments
),
warehouse_avg AS (
    SELECT
        Warehouse_ID,
        ROUND(AVG(Delay_Hours), 2) AS avg_delay
    FROM shipments
    GROUP BY Warehouse_ID
)
SELECT
    wa.Warehouse_ID,
    w.City,
    wa.avg_delay AS Warehouse_Avg_Delay,
    ROUND(g.g_avg, 2) AS Global_Avg_Delay
FROM warehouse_avg wa
JOIN warehouses w ON wa.Warehouse_ID = w.Warehouse_ID
CROSS JOIN global_avg g
WHERE wa.avg_delay > g.g_avg
ORDER BY wa.avg_delay DESC;


-- TASK 5 — Delivery Agent Performance
-- Rank agents per route by on-time delivery %
SELECT
    a.Agent_ID,
    a.Agent_Name,
    s.Route_ID,
    COUNT(*) AS Total_Shipments,
    SUM(CASE WHEN s.Delivery_Status = 'Delivered' AND s.Delay_Hours = 0 THEN 1 ELSE 0 END) AS OnTime_Count,
    ROUND(100.0 * SUM(CASE WHEN s.Delivery_Status = 'Delivered' AND s.Delay_Hours = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS OnTime_Pct,
    RANK() OVER (
        PARTITION BY s.Route_ID
        ORDER BY SUM(CASE WHEN s.Delivery_Status = 'Delivered' AND s.Delay_Hours = 0 THEN 1 ELSE 0 END) / COUNT(*) DESC
    ) AS Route_Rank
FROM shipments s
JOIN delivery_agents a ON s.Agent_ID = a.Agent_ID
GROUP BY a.Agent_ID, a.Agent_Name, s.Route_ID
ORDER BY s.Route_ID, Route_Rank;


-- Agents with on-time % below 85%
SELECT
    a.Agent_ID,
    a.Agent_Name,
    COUNT(*) AS Total_Shipments,
    ROUND(100.0 * SUM(CASE WHEN s.Delivery_Status = 'Delivered' AND s.Delay_Hours = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS OnTime_Pct,
    a.Experience_Years,
    a.Avg_Rating
FROM shipments s
JOIN delivery_agents a ON s.Agent_ID = a.Agent_ID
GROUP BY a.Agent_ID, a.Agent_Name, a.Experience_Years, a.Avg_Rating
HAVING OnTime_Pct < 85
ORDER BY OnTime_Pct ASC;

-- Top 5 vs Bottom 5 agents using subqueries
SELECT
    'Top 5' AS Agent_Group,
    ROUND(AVG(Avg_Rating), 2) AS Avg_Rating,
    ROUND(AVG(Experience_Years), 2) AS Avg_Experience_Years
FROM delivery_agents
WHERE Agent_ID IN (
    SELECT Agent_ID FROM (
        SELECT s.Agent_ID,
            SUM(CASE WHEN s.Delivery_Status = 'Delivered' AND s.Delay_Hours = 0 THEN 1 ELSE 0 END) / COUNT(*) AS OnTime_Pct
        FROM shipments s
        GROUP BY s.Agent_ID
        ORDER BY OnTime_Pct DESC
        LIMIT 5
    ) AS top5
)

UNION ALL

SELECT
    'Bottom 5',
    ROUND(AVG(Avg_Rating), 2),
    ROUND(AVG(Experience_Years), 2)
FROM delivery_agents
WHERE Agent_ID IN (
    SELECT Agent_ID FROM (
        SELECT s.Agent_ID,
            SUM(CASE WHEN s.Delivery_Status = 'Delivered' AND s.Delay_Hours = 0 THEN 1 ELSE 0 END) / COUNT(*) AS OnTime_Pct
        FROM shipments s
        GROUP BY s.Agent_ID
        ORDER BY OnTime_Pct ASC
        LIMIT 5
    ) AS bottom5
);


-- TASK 6 — Shipment Tracking Analytics
-- Latest status and delivery date for each shipment
use fedex_project

SELECT
    Shipment_ID,
    Order_ID,
    Delivery_Status,
    DATE_FORMAT(Delivery_Date, '%Y-%m-%d %H:%i:%s') AS Latest_Delivery_Date
FROM shipments
ORDER BY Delivery_Date DESC;


--  Routes where majority of shipments are In Transit or Returned
WITH route_status AS (
    SELECT Route_ID, Delivery_Status, COUNT(*) AS cnt
    FROM shipments
    GROUP BY Route_ID, Delivery_Status
),
route_total AS (
    SELECT Route_ID, SUM(cnt) AS total
    FROM route_status
    GROUP BY Route_ID
)
SELECT
    rs.Route_ID,
    rs.Delivery_Status,
    rs.cnt,
    ROUND(100.0 * rs.cnt / rt.total, 1) AS Pct
FROM route_status rs
JOIN route_total rt ON rs.Route_ID = rt.Route_ID
WHERE rs.Delivery_Status IN ('In Transit', 'Returned')
AND 100.0 * rs.cnt / rt.total > 50
ORDER BY Pct DESC;


-- Most frequent delay reasons
SELECT
    Delay_Reason,
    COUNT(*) AS Count,
    ROUND(100.0 * COUNT(*) / (
        SELECT COUNT(*) FROM shipments WHERE Delay_Reason IS NOT NULL
    ), 1) AS Percentage
FROM shipments
WHERE Delay_Reason IS NOT NULL
GROUP BY Delay_Reason
ORDER BY Count DESC;


--  Orders with delay more than 120 hours
SELECT
    s.Shipment_ID,
    s.Order_ID,
    s.Route_ID,
    s.Warehouse_ID,
    s.Delay_Hours,
    s.Delivery_Status,
    s.Delay_Reason
FROM shipments s
WHERE s.Delay_Hours > 120
ORDER BY s.Delay_Hours DESC;

-- TASK 7 — Advanced KPI Reporting
-- KPI 1 — Average delivery delay per Source Country
SELECT
    r.Source_Country,
    ROUND(AVG(s.Delay_Hours), 2) AS Avg_Delay_Hours,
    COUNT(*) AS Total_Shipments
FROM shipments s
JOIN routes r ON s.Route_ID = r.Route_ID
GROUP BY r.Source_Country
ORDER BY Avg_Delay_Hours DESC;

-- KPI 2 — Overall On-Time Delivery Percentage
SELECT
    SUM(CASE WHEN Delivery_Status = 'Delivered' AND Delay_Hours = 0 THEN 1 ELSE 0 END) AS OnTime_Deliveries,
    COUNT(*) AS Total_Deliveries,
    ROUND(100.0 * SUM(CASE WHEN Delivery_Status = 'Delivered' AND Delay_Hours = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS OnTime_Pct
FROM shipments;SELECT
    SUM(CASE WHEN Delivery_Status = 'Delivered' AND Delay_Hours = 0 THEN 1 ELSE 0 END) AS OnTime_Deliveries,
    COUNT(*) AS Total_Deliveries,
    ROUND(100.0 * SUM(CASE WHEN Delivery_Status = 'Delivered' AND Delay_Hours = 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS OnTime_Pct
FROM shipments;


-- KPI 3 — Average delay per Route ID with category
SELECT
    Route_ID,
    ROUND(AVG(Delay_Hours), 2) AS Avg_Delay_Hours,
    COUNT(*) AS Total_Shipments,
    CASE
        WHEN AVG(Delay_Hours) > 30 THEN 'Critical'
        WHEN AVG(Delay_Hours) > 20 THEN 'High'
        WHEN AVG(Delay_Hours) > 10 THEN 'Medium'
        ELSE 'Low'
    END AS Delay_Category
FROM shipments
GROUP BY Route_ID
ORDER BY Avg_Delay_Hours DESC; 

-- KPI 4 — Warehouse Utilization Percentage
SELECT
    s.Warehouse_ID,
    w.City,
    w.Country,
    COUNT(s.Shipment_ID) AS Shipments_Handled,
    w.Capacity_per_day,
    ROUND(100.0 * COUNT(s.Shipment_ID) / w.Capacity_per_day, 2) AS Utilization_Pct,
    CASE
        WHEN 100.0 * COUNT(s.Shipment_ID) / w.Capacity_per_day > 10 THEN 'Medium'
        WHEN 100.0 * COUNT(s.Shipment_ID) / w.Capacity_per_day > 5 THEN 'Low'
        ELSE 'Very Low'
    END AS Utilization_Category
FROM shipments s
JOIN warehouses w ON s.Warehouse_ID = w.Warehouse_ID
GROUP BY s.Warehouse_ID, w.City, w.Country, w.Capacity_per_day
ORDER BY Utilization_Pct DESC;
 