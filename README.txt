CAIRO METRO OPERATIONS INVESTIGATION — DATASET v2

Dataset follows the station names and branch structure supplied by the instructor in the conversation.
It is an educational simulation. Passenger counts, trips, delays, incidents and severity values are synthetic, not official Cairo Metro operational data.
Station inventory/order follows the provided list and should be treated as the course's agreed project scope, not as an independently verified official current map.

Files:
- Lines.csv: 3 line records
- Stations.csv: unique Arabic station names and station type
- StationLines.csv: station-to-line membership, order, and Line 3 branch labels
- PassengerFlow.csv: passenger counts by station/line/date/time period
- TrainTrips.csv: synthetic trips, scheduled/actual durations and delay
- Incidents.csv: synthetic station incidents

SQL Server workflow:
1. Create database CairoMetroDB.
2. Import CSV files as tables.
3. Set PKs: Lines.LineID; Stations.StationID; PassengerFlow.RecordID; TrainTrips.TripID; Incidents.IncidentID.
4. StationLines can use composite key (LineID, StationID) for this dataset; if repeated station-line membership is allowed, use (LineID, StationID, StationOrder).
5. FKs: StationLines.LineID -> Lines.LineID; StationLines.StationID -> Stations.StationID; PassengerFlow.StationID -> Stations.StationID; PassengerFlow.LineID -> Lines.LineID; TrainTrips.LineID -> Lines.LineID; Incidents.StationID -> Stations.StationID.
6. Analyze using SQL queries, then Python/Pandas, then Power BI.

Suggested tasks:
- Top stations by total passengers.
- Passenger counts by period and line.
- Average delay by line and period.
- Incident counts by type and station.
- Compare passenger volumes and incidents by station.
