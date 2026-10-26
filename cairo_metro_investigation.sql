
--Top 5 Stations by Passenger Flow
SELECT TOP 5 
    s.StationNameArabic,
    s.StationTypeArabic,
    FORMAT(SUM(p.PassengerCount), 'N0') AS TotalPassengers,
    FORMAT(SUM(p.PassengerCount) * 1.0 / (SELECT SUM(PassengerCount) FROM PassengerFlow), 'P2') AS PassengerPercentage
FROM PassengerFlow p
JOIN Stations s ON p.StationID = s.StationID
GROUP BY s.StationNameArabic, s.StationTypeArabic
ORDER BY SUM(p.PassengerCount) DESC;  

---
SELECT 
    l.LineNameArabic,
    FORMAT(SUM(p.PassengerCount), 'N0') AS TotalPassengers,
    FORMAT(SUM(p.PassengerCount) * 1.0 / (SELECT SUM(PassengerCount) FROM PassengerFlow), 'P2') AS LineSharePercentage
FROM PassengerFlow p
JOIN Lines l ON p.LineID = l.LineID
GROUP BY l.LineNameArabic
ORDER BY SUM(p.PassengerCount) DESC; 

--- أداء الرحلات ومعدلات التأخير لكل خط
SELECT 
    l.LineNameArabic,
    COUNT(t.TripID) AS TotalTrips,
    FORMAT(AVG(t.DelayMinutes * 1.0), 'N1') AS AvgDelayMinutes,
    MAX(t.DelayMinutes) AS MaxDelayMinutes,
    FORMAT(AVG(t.DelayPercentage * 1.0) / 100.0, 'P2') AS AvgDelayPercentage,
    FORMAT(SUM(CASE WHEN t.DelayMinutes > 0 THEN 1.0 ELSE 0.0 END) / COUNT(t.TripID), 'P2') AS DelayedTripsRate
FROM TrainTrips t
JOIN Lines l ON t.LineID = l.LineID
GROUP BY l.LineNameArabic
ORDER BY AVG(t.DelayPercentage) DESC;  

-----Peak Hour Crisis
WITH PassengerSummary AS (
    SELECT 
        TimePeriod,
        SUM(PassengerCount) AS TotalPassengers
    FROM PassengerFlow
    GROUP BY TimePeriod
),
TripSummary AS (
    SELECT 
        TimePeriod,
        COUNT(TripID) AS TotalTrips,
        AVG(DelayMinutes * 1.0) AS AvgDelayMinutes,
        SUM(CASE WHEN DelayMinutes > 0 THEN 1.0 ELSE 0.0 END) / COUNT(TripID) AS DelayedTripsRate
    FROM TrainTrips
    GROUP BY TimePeriod
)
SELECT 
    p.TimePeriod,
    FORMAT(p.TotalPassengers, 'N0') AS TotalPassengers,
    FORMAT(t.AvgDelayMinutes, 'N1') AS AvgDelayMinutes,
    FORMAT(t.DelayedTripsRate, 'P2') AS DelayedTripsRate
FROM PassengerSummary p
JOIN TripSummary t ON p.TimePeriod = t.TimePeriod
ORDER BY t.AvgDelayMinutes DESC; 

-- Incident Root Causes
SELECT 
    IncidentType,
    COUNT(IncidentID) AS TotalIncidents,
    FORMAT(COUNT(IncidentID) * 1.0 / (SELECT COUNT(*) FROM Incidents), 'P2') AS IncidentPercentage,
    SUM(CASE WHEN Severity = 'High' THEN 1 ELSE 0 END) AS HighSeverityCount
FROM Incidents
GROUP BY IncidentType
ORDER BY TotalIncidents DESC;  


-- Station Safety Risks
SELECT TOP 5 
    s.StationNameArabic,
    s.StationTypeArabic,
    COUNT(i.IncidentID) AS TotalIncidents,
    SUM(CASE WHEN i.Severity = 'High' THEN 1 ELSE 0 END) AS HighSeverityIncidents
FROM Incidents i
JOIN Stations s ON i.StationID = s.StationID
GROUP BY s.StationNameArabic, s.StationTypeArabic
ORDER BY TotalIncidents DESC; 



-- Hourly Delay Cascade
WITH HourlyMetrics AS (
    SELECT 
        DATEPART(HOUR, DepartureTime) AS OperationHour,
        COUNT(TripID) AS TripsCount,
        ROUND(AVG(DelayMinutes * 1.0), 2) AS CurrentHourAvgDelay
    FROM TrainTrips
    GROUP BY DATEPART(HOUR, DepartureTime)
)
SELECT 
    OperationHour,
    TripsCount,
    CurrentHourAvgDelay,
    LAG(CurrentHourAvgDelay) OVER (ORDER BY OperationHour) AS PreviousHourAvgDelay,
    ROUND(CurrentHourAvgDelay - LAG(CurrentHourAvgDelay) OVER (ORDER BY OperationHour), 2) AS DelayChange
FROM HourlyMetrics
ORDER BY OperationHour;

;