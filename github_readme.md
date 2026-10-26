# 🚇 Cairo Metro Operations Intelligence & Transit Analytics Case Study

[![SQL Server](https://img.shields.io/badge/SQL%20Server-2019%2B-CC292B?logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/sql-server)
[![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)](https://python.org)
[![Pandas](https://img.shields.io/badge/Pandas-2.0%2B-150458?logo=pandas&logoColor=white)](https://pandas.pydata.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status: Completed](https://img.shields.io/badge/Status-Completed-success.svg)]()

> An end-to-end data analytics and relational engineering investigation auditing **14.9M+ simulated passenger trips** and operational incident logs across the Cairo Metro network. This case study diagnoses transit friction, prevents Cartesian join distortions, models temporal delay cascades, and uncovers actionable operational bottlenecks.

---

## 📌 Executive Summary

Urban mass-transit networks depend on rigorous operational visibility to maintain high line throughput and service reliability. This project examines high-density operations across Cairo Metro corridors to evaluate schedule adherence, platform density, and incident propagation.

Key analytical achievements include:
- **Scalable Query Engineering:** Pre-aggregated transactional metrics across lines and schedules, preventing multi-table join duplication.
- **Dynamic Cascade Modeling:** Detected delay propagation patterns using sequential window functions, isolating systematic line friction from isolated incidents.
- **Root-Cause Attribution:** Quantified operational friction drivers, identifying that **54.2%** of logged incidents originated from platform overcrowding and service delay feedback loops.

---

## 🛠️ Architecture & Tech Stack

```
┌───────────────────────────┐      ┌───────────────────────────────┐      ┌───────────────────────────────┐
│     Raw Data Ingestion    │ ───► │  Data Normalization & Audit   │ ───► │    T-SQL Analytical Engine    │
│  (14.9M+ Trips / Logs)    │      │  (Pandas / NumPy in Jupyter)  │      │   (Multi-CTEs / Window Funcs) │
└───────────────────────────┘      └───────────────────────────────┘      └───────────────────────────────┘
                                                                                          │
                                                                                          ▼
                                                                          ┌───────────────────────────────┐
                                                                          │  Executive Intelligence Deck  │
                                                                          │  (PDF Operational Deck)       │
                                                                          └───────────────────────────────┘
```

| Layer | Technology | Primary Functionality |
| :--- | :--- | :--- |
| **ETL & Data Wrangling** | Python (`pandas`, `numpy`) | Data profiling, timestamp casting, schema normalization, and outlier auditing via Jupyter Notebook (`main.ipynb`). |
| **Relational Database** | Microsoft SQL Server (T-SQL) | DDL schema architecture, indexed table constraints, relational key modeling, and bulk ingestion. |
| **Analytical Querying** | Advanced T-SQL | Multi-CTE modular pipelines, analytical window functions (`LAG`, `OVER`, `PARTITION BY`), and conditional aggregation. |
| **Executive Reporting** | Slide & Narrative Documentation | Executive case study slide deck with actionable operational recommendations (`Cairo-Metro-Operations-SQL-Case-Study.pdf`). |

---

## ⚙️ Key Engineering Challenges & Solutions

### 1. The Many-to-Many Join Fan-Out Trap
* **The Engineering Problem:** Directly joining high-frequency trip logs (`PassengerFlow.csv`, `TrainTrips.csv`) with timetable intervals and incident logs created a multi-table Cartesian fan-out. This artificially duplicated trip records, distorting aggregate passenger volumes and variance metrics.
* **The Solution:** Implemented a modular **Multi-CTE architecture**. Aggregations on trips, station dwell times, and incident frequency were calculated independently inside isolated CTEs *prior* to joining on line keys and station IDs:
```sql
WITH PreAggregatedTrips AS (
    SELECT 
        LineID,
        StationID,
        DATEPART(HOUR, DepartureTime) AS DepartureHour,
        COUNT_BIG(TripID) AS TotalTrips,
        AVG(ActualDurationMinutes - ScheduledDurationMinutes) AS AvgDelayMinutes
    FROM dbo.TrainTrips
    GROUP BY LineID, StationID, DATEPART(HOUR, DepartureTime)
),
PreAggregatedIncidents AS (
    SELECT 
        LineID,
        StationID,
        DATEPART(HOUR, IncidentTimestamp) AS IncidentHour,
        COUNT(IncidentID) AS IncidentCount
    FROM dbo.Incidents
    GROUP BY LineID, StationID, DATEPART(HOUR, IncidentTimestamp)
)
SELECT 
    t.LineID,
    t.StationID,
    t.DepartureHour,
    t.TotalTrips,
    t.AvgDelayMinutes,
    ISNULL(i.IncidentCount, 0) AS IncidentCount
FROM PreAggregatedTrips t
LEFT JOIN PreAggregatedIncidents i 
    ON t.LineID = i.LineID 
    AND t.StationID = i.StationID 
    AND t.DepartureHour = i.IncidentHour;
```
* **Impact:** Maintained **100% calculation accuracy** and ensured deterministic metrics across 14.9M+ trip logs without metric duplication.

---

### 2. Hourly Delay Cascade Modeling via `LAG()`
* **The Engineering Problem:** Transit supervisors needed to verify whether line delays occurred as isolated events or propagated down the corridor as systemic chain reactions.
* **The Solution:** Leveraged the `LAG()` analytical window function partitioned by line and corridor to compute consecutive headway deltas across sequential operational hours:
```sql
WITH HourlyLinePerformance AS (
    SELECT 
        LineID,
        OperationalHour,
        AVG(TripDelayMinutes) AS AvgDelay
    FROM dbo.vw_LineTripSummaries
    GROUP BY LineID, OperationalHour
)
SELECT 
    LineID,
    OperationalHour,
    AvgDelay,
    LAG(AvgDelay, 1) OVER (
        PARTITION BY LineID 
        ORDER BY OperationalHour
    ) AS PrevHourDelay,
    ROUND(AvgDelay - LAG(AvgDelay, 1) OVER (
        PARTITION BY LineID 
        ORDER BY OperationalHour
    ), 2) AS DelayPropagationDelta
FROM HourlyLinePerformance;
```
* **Impact:** Identified the morning commuter peak (**08:00 AM**) as the primary choke point, exhibiting an average trip delay of **6.21 minutes** and an acceleration rate of **+2.4 minutes** compared to the preceding hour.

---

### 3. Incident Root Cause Diagnosis
* **The Engineering Problem:** Categorical logs lacked unified operational impact ratings, complicating prioritization for maintenance and crowd-control assets.
* **The Solution:** Segmented event descriptions and mapped severity weightings against station geometry and trip volume density.
* **Findings:**
  * **54.2%** of all operational incident reports were driven by station overcrowding and service delays.
  * **Peripheral & Transfer Nodes:** Intersecting transfer stations absorbed peak passenger volume surges, whereas peripheral terminals experienced the widest operational response latency.

---

## 📂 Repository Structure

```text
Cairo_Metro_Operations_Investigation/
│
├── cairo_metro_investigation.sql          # End-to-end T-SQL scripts (Schema, CTEs, Windowing, Analysis)
├── main.ipynb                             # Python ETL, data cleansing, normalization & validation
├── Cairo-Metro-Operations-SQL-Case-Study.pdf # Complete presentation deck & executive insights
│
├── Incidents.csv                          # Operational incident events and classifications
├── Lines.csv                              # Metro network line metadata and terminus definitions
├── PassengerFlow.csv                      # Simulated passenger gate throughput and tap volumes
├── StationLines.csv                       # Junction table modeling line-to-station relationships
├── Stations.csv                           # Station master dimension (Geographic & Operational)
├── TrainTrips.csv                         # Scheduled vs. actual train trips (14.9M+ trips modeled)
└── README.md                              # Production documentation and project overview
```

---

## 🚀 Setup & Execution Guide

### Prerequisites
* **SQL Server** 2017+ or Azure SQL Database
* **SQL Server Management Studio (SSMS)** or Azure Data Studio
* **Python** 3.9+ with `pandas` and `jupyter`

### 1. Data Cleaning & Pre-processing (Python)
To inspect the initial normalization and validation pipeline:
```bash
# Clone the repository
git clone https://github.com/MohamedGomaa11111/cairo-metro-operations-intelligence.git
cd cairo-metro-operations-intelligence

# Install Python dependencies
pip install pandas numpy jupyter

# Launch Jupyter Notebook
jupyter notebook main.ipynb
```

### 2. Database Ingestion & Analysis (SQL Server)
1. Open **SSMS** and connect to your SQL Server instance.
2. Create the target database:
   ```sql
   CREATE DATABASE CairoMetroAnalytics;
   GO
   USE CairoMetroAnalytics;
   GO
   ```
3. Use the SQL Server Import and Export Wizard (or `BULK INSERT`) to import the CSV files into their respective staging tables.
4. Open and execute `cairo_metro_investigation.sql` to run the analysis scripts and generate the output reporting tables.

---

## 📊 Deliverables & Case Study Report

For the executive presentation, visual breakdown of line bottlenecks, and operational recommendations:
👉 **[View the Complete PDF Case Study Presentation](Cairo-Metro-Operations-SQL-Case-Study.pdf)**

---

## 👤 Author

**Mohamed Gomaa Mohamed**
* **Role:** Data Analyst & BI Specialist
* **LinkedIn:** [linkedin.com/in/mohamed-gomaa-b405582a](https://linkedin.com/in/mohamed-gomaa-b405582a)
* **GitHub:** [github.com/MohamedGomaa11111](https://github.com/MohamedGomaa11111)
* **Portfolio:** [Mohamed Gomaa Analytics Portfolio](https://mohamedgomaa11111.github.io/portfolio/)

---

## 📜 License
This project is open-source and licensed under the [MIT License](LICENSE).