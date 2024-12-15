----- 1) City-Level Fare and Trip Summary Report -------

SELECT 
    city_name,
    total_city_trips,
    ROUND(avg_fare_per_km,2) AS avg_fare_per_km,
    ROUND(avg_fare_per_trip,2) AS avg_fare_per_trip,
   CONCAT(ROUND((total_city_trips * 100.0 / total_trips), 2), ' %') AS pct_contribution_to_total_trips
FROM (
    SELECT 
        city_name,
        COUNT(trip_id) AS total_city_trips,
        AVG(fare_amount/distance_travelled_km) AS avg_fare_per_km,
        AVG(fare_amount) AS avg_fare_per_trip,
        (SELECT COUNT(trip_id) FROM fact_trips) AS total_trips
    FROM fact_trips
    JOIN dim_city
    USING (city_id)
    GROUP BY city_id
) city_summary
ORDER BY pct_contribution_to_total_trips DESC;

----- 2) Monthly City-Level Trips Target Performance Report -------

SELECT 
	c.city_name, 
	date_format(date, '%M') AS month_name,
    COUNT(trip_id) AS actual_trips,
    mt.total_target_trips AS target_trips,
    CASE
		WHEN COUNT(trip_id) > mt.total_target_trips THEN "Above Target"
        WHEN COUNT(trip_id) < mt.total_target_trips THEN "Below Target"
	END AS performance_status,
    CONCAT(ROUND((( COUNT(trip_id) - mt.total_target_trips) *100 /  COUNT(trip_id)),2),' %') AS pct_difference
FROM fact_trips trp
JOIN dim_city c
ON trp.city_id = c.city_id
JOIN targets_db.monthly_target_trips AS mt
ON trp.city_id = mt.city_id AND date_format(trp.date, '%M') = date_format(mt.month, '%M')
GROUP BY trp.city_id, date_format(date, '%M'),total_target_trips
ORDER BY c.city_name DESC;

----- 3) City-Level Repeat Passenger Trip Frequency Report -------

SELECT 
    city_name,
    ROUND (
		(SUM(CASE WHEN trip_count = '2-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `2-Trips`,
     ROUND (
		(SUM(CASE WHEN trip_count = '3-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `3-Trips`,
     ROUND (
		(SUM(CASE WHEN trip_count = '4-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `4-Trips`,
     ROUND (
		(SUM(CASE WHEN trip_count = '5-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `5-Trips`,
     ROUND (
		(SUM(CASE WHEN trip_count = '6-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `6-Trips`,
     ROUND (
		(SUM(CASE WHEN trip_count = '7-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `7-Trips`,
     ROUND (
		(SUM(CASE WHEN trip_count = '8-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `8-Trips`,
    ROUND (
		(SUM(CASE WHEN trip_count = '9-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `9-Trips`,
    ROUND (
		(SUM(CASE WHEN trip_count = '10-Trips' THEN repeat_passenger_count ELSE 0 END) 
			/ SUM(repeat_passenger_count) *100),2
            ) AS `10-Trips`
FROM dim_repeat_trip_distribution
JOIN dim_city
USING (city_id)
GROUP BY city_id;


----- 4) Identify Cities with Highest and Lowest Total New Passengers -------

SELECT city_name, total_new_passengers, city_category
FROM (
	SELECT city_name, 
		SUM(new_passengers) AS total_new_passengers,
		RANK () OVER (ORDER BY SUM(new_passengers) DESC) AS rnk,
		CASE
			WHEN RANK () OVER (ORDER BY SUM(new_passengers) DESC) IN (1,2,3) THEN "Top 3"
			WHEN RANK () OVER (ORDER BY SUM(new_passengers) DESC) IN (8,9,10) THEN "Bottom 3"
		END AS city_category
	FROM fact_passenger_summary 
    JOIN dim_city
    USING (city_id)
	GROUP BY city_id 
	)
city_new_passenger_summary
WHERE city_category IS NOT NULL;

----- 5) Identify Month with Highest Revenue with Each City -------

SELECT city_name, month, revenue, 
	CONCAT(ROUND((revenue * 100 / total_revnue), 2),' %') AS pct_contribution
FROM (
	SELECT 
	city_name,
    date_format(date, '%M') AS month,
    SUM(fare_amount) AS revenue,
    RANK () OVER (PARTITION BY city_name ORDER BY  SUM(fare_amount) DESC) AS rnk,
    (SELECT SUM(fare_amount) FROM fact_trips) AS total_revnue
FROM fact_trips
JOIN dim_city
USING (city_id)
GROUP BY city_name, month
 ) ranked 
 WHERE rnk = 1
ORDER BY pct_contribution DESC;

----- 6) Repeat Passenger Rate Analysis -------

SELECT 
	city_name, 
    date_format(month, '%M') AS month_name, 
    SUM(total_passengers) AS total_passengers, 
    SUM(repeat_passengers) AS repeat_passengers,
	CONCAT(ROUND((SUM(repeat_passengers)/SUM(total_passengers))*100,2),' %') AS monthly_repeat_passengers_rate
FROM fact_passenger_summary
JOIN dim_city
USING (city_id)
GROUP BY city_name, date_format(month, '%M');

SELECT 
	city_name, 
    SUM(total_passengers) AS total_passengers, 
    SUM(repeat_passengers) AS repeat_passengers,
	CONCAT(ROUND((SUM(repeat_passengers)/SUM(total_passengers))*100,2),' %') AS city_repeat_passengers_rate
FROM fact_passenger_summary
JOIN dim_city
USING (city_id)
GROUP BY city_name;

































