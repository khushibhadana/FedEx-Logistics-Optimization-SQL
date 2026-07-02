FedEx Logistics Optimization — SQL Project

🏢 Company

FedEx

❓ Problem Statement

FedEx manages large-scale logistics operations involving multiple warehouses, delivery routes, and agents. The objective of this project was to use SQL to analyze shipment data and uncover operational inefficiencies in delivery performance, route delays, and warehouse utilization, in order to support data-driven logistics optimization decisions.

🎯 Objective


Analyze on-time delivery performance across routes and agents
Identify routes and warehouses causing delays or underutilization
Provide insights to improve overall logistics efficiency


🛠️ Tools Used


MySQL / MySQL Workbench
SQL (Joins, Aggregations, Subqueries, Grouping)


📂 Dataset Overview

A relational dataset built across 5 tables, covering:


1,000 shipments
20 delivery routes
10 warehouses
50 delivery agents


🔧 Process


Designed and queried a normalized 5-table schema (shipments, routes, warehouses, agents, and related transactional data)
Wrote SQL queries to calculate on-time delivery rate across routes and agents
Analyzed route-wise delay patterns to identify bottleneck routes
Evaluated warehouse utilization to flag over- and under-utilized warehouses
Used joins and aggregations across tables to connect shipment outcomes to specific routes, warehouses, and agents


📊 Key Insights


Certain routes consistently showed higher delay rates than others, pointing to specific bottlenecks in the network
On-time delivery rate varied significantly by agent and route combination
A subset of warehouses were operating well above or below optimal utilization, indicating scope for load rebalancing


✅ Recommendations


Reallocate shipment load from over-utilized to under-utilized warehouses
Prioritize route-level interventions (rescheduling, agent reassignment) for the highest-delay routes
Set up recurring on-time delivery tracking by route and agent to catch performance drops early


🧠 Skills Demonstrated

SQL Querying · Relational Database Design · Joins & Aggregations · Logistics/Operations Analysis · Business Insight Generation
