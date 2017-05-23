create database uber;


create table if not exists uber.source_green_trip_data_2014_06 (

    vendor_id text,
    lpep_pickup_datetime datetime,
    lpep_dropoff_datetime datetime,
    store_and_fwd_flag text,
    rate_code_id int,
    pickup_longitude text,
    pickup_latitude text,
    dropoff_longitude text,
    dropoff_latitude text,
    passenger_count int,
    trip_distance text,
    fare_amount text,
    extra text,
    mta_tax text,
    tip_amount text,
    tolls_amount text,
    ehail_fee text null,
    total_amount text,
    payment_type int,
    trip_type int null,
    trailing_space text null

) engine = innodb;


load data local infile '/Users/ryanhamill/web_apps/uber/data/green_trip_data_2014_06.csv'

into table uber.source_green_trip_data_2014_06 fields terminated by ','

    enclosed by '"'
    lines terminated by '\r'
    ignore 3 lines

    (
        vendor_id,
        lpep_pickup_datetime,
        lpep_dropoff_datetime,
        store_and_fwd_flag,
        rate_code_id,
        pickup_longitude,
        pickup_latitude,
        dropoff_longitude,
        dropoff_latitude,
        passenger_count,
        trip_distance,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        @ehail_fee,
        total_amount,
        payment_type,
        @trip_type,
        trailing_space
    )

    set trip_type = nullif(@trip_type, '' ),
        ehail_fee = nullif(@ehail_fee, '' );




create table uber.fact_green_trip_data_2014_06 as

    select
        convert(convert(vendor_id, decimal), unsigned) as vendor_id,
        lpep_pickup_datetime,
        lpep_dropoff_datetime,
        store_and_fwd_flag,
        rate_code_id,
        cast(pickup_longitude as decimal(20,15)) as pickup_longitude,
        cast(pickup_latitude as decimal(20,15)) as pickup_latitude,
        cast(dropoff_longitude as decimal(20,15)) as dropoff_longitude,
        cast(dropoff_latitude as decimal(20,15)) as dropoff_latitude,
        passenger_count,
        cast(trip_distance as decimal(10,2)) as trip_distance,
        cast(fare_amount as decimal(10,2)) as fare_amount,
        cast(extra as decimal(10,2)) as extra,
        cast(mta_tax as decimal(10,2)) as mta_tax,
        cast(tip_amount as decimal(10,2)) as tip_amount,
        cast(tolls_amount as decimal(10,2)) as tolls_amount,
        cast(total_amount as decimal(10,2)) as total_amount,
        payment_type,
        trip_type

    from uber.source_green_trip_data_2014_06;


alter table uber.fact_green_trip_data_2014_06
    add index vendor_id (vendor_id),
    add index payment_type (payment_type),
    add index trip_type (trip_type),
    add index rate_code_id (rate_code_id),
    add index passenger_count (passenger_count);




-- Question 1 - Which vendor had the most trips? How many trips were taken?

    select
        vendor_id,
        count(*) as trip_count
    from uber.fact_green_trip_data_2014_06

    group by vendor_id
    order by count(*) desc
    limit 1;

    -- Query Results
        -- vendor_id, trip_count
        -- 2, 1050518




-- Question 2 - Which payment type had the highest average fare?

    select
        payment_type,
        round(avg(fare_amount), 2) as average_fare
    from uber.fact_green_trip_data_2014_06

    group by payment_type
    order by avg(fare_amount) desc
    limit 1;

    -- Query Results
        -- payment_type, average_fare
        -- 1, 15.24




-- Question 3 - Estimate the charged rate for each RateCodeID. (For this question, assume rates are only charged based on distance.)

    select
        rate_code_id,
        round(avg(fare_per_mile), 2) as estimated_rate_per_mile

    from (

        select
            rate_code_id,
            fare_amount/trip_distance as fare_per_mile
        from uber.fact_green_trip_data_2014_06

        where fare_amount > 0
        and trip_distance > 0

    ) rate_per_ride

    group by rate_code_id;

    -- Query Results
        -- rate_code_id, estimated_rate_per_mile
        -- 1, 5.44
        -- 2, 561.34
        -- 3, 122.29
        -- 4, 4.51
        -- 5, 106.57
        -- 6, 7.34




-- Question 4 - What was the average difference between the driven distance and the haversine distance of the trip?

    select
        round(avg(trip_distance - haversine_trip_distance), 3) as average_distance_difference

    from (

        select
            trip_distance,

            (3956 * 2 * ASIN(SQRT( POWER(SIN((pickup_latitude - dropoff_latitude) * pi()/180 / 2), 2) +
            COS(pickup_latitude * pi()/180) * COS(dropoff_latitude* pi()/180) *
            POWER(SIN((pickup_longitude - dropoff_longitude) * pi()/180 / 2), 2) )) * 1.609344) * 0.621371 as haversine_trip_distance

        from uber.fact_green_trip_data_2014_06

        where pickup_longitude != 0
            and dropoff_longitude != 0
            and pickup_latitude != 0
            and dropoff_latitude != 0

    ) distances;

    -- Query Results
        -- average_distance_difference
        -- .900




-- Question 5 - Are there any patterns with tipping over time? If you find one, please provide a possible explanation!

    create table uber.fact_hourly_tip as

        select
            dayname(lpep_pickup_datetime) as pickup_day,
            week(lpep_pickup_datetime) as `week`,
            hour(lpep_pickup_datetime) as pickup_hour,
            day(lpep_pickup_datetime) pickup_date,
            avg(tip_amount) as average_tip_amount,
            sum(case when tip_amount > 0 then 1 else 0 end) as tipped_rides,
            count(*) as total_rides,
            sum(case when tip_amount > 0 then 1 else 0 end) / count(*) as tip_percentage

        from uber.fact_green_trip_data_2014_06

        where fare_amount > 0
            and trip_distance > 0

        group by
            day(lpep_pickup_datetime),
            hour(lpep_pickup_datetime),
            dayname(lpep_pickup_datetime),
            week(lpep_pickup_datetime);


    -- query used to view trends in tip amount per hour per day of the week
    select
        pickup_times.pickup_day,
        pickup_times.pickup_hour,
        case when fht.`week` = 22 then fht.average_tip_amount else null end as week_22_avg_tip_amount,
        case when fht3.`week` = 23 then fht3.average_tip_amount else null end as week_23_avg_tip_amount,
        case when fht4.`week` = 24 then fht4.average_tip_amount else null end as week_24_avg_tip_amount,
        case when fht5.`week` = 25 then fht5.average_tip_amount else null end as week_25_avg_tip_amount,
        case when fht6.`week` = 26 then fht6.average_tip_amount else null end as week_26_avg_tip_amount

    from (

        select
            pickup_day,
            pickup_hour

        from uber.fact_hourly_tip

        group by pickup_day, pickup_hour

    ) pickup_times

    left join uber.fact_hourly_tip fht
        on fht.pickup_day = pickup_times.pickup_day
        and fht.pickup_hour = pickup_times.pickup_hour
        and fht.`week` = 22

    left join uber.fact_hourly_tip fht3
        on fht3.pickup_day = pickup_times.pickup_day
        and fht3.pickup_hour = pickup_times.pickup_hour
        and fht3.`week` = 23

    left join uber.fact_hourly_tip fht4
        on fht4.pickup_day = pickup_times.pickup_day
        and fht4.pickup_hour = pickup_times.pickup_hour
        and fht4.`week` = 24

    left join uber.fact_hourly_tip fht5
        on fht5.pickup_day = pickup_times.pickup_day
        and fht5.pickup_hour = pickup_times.pickup_hour
        and fht5.`week` = 25

    left join uber.fact_hourly_tip fht6
        on fht6.pickup_day = pickup_times.pickup_day
        and fht6.pickup_hour = pickup_times.pickup_hour
        and fht6.`week` = 26;


    -- query used to view trends in tip frequency per hour per day of the week
    select
        pickup_times.pickup_day,
        pickup_times.pickup_hour,
        case when fht.`week` = 22 then fht.tip_percentage else null end as week_22_tip_freqency,
        case when fht3.`week` = 23 then fht3.tip_percentage else null end as week_23_tip_freqency,
        case when fht4.`week` = 24 then fht4.tip_percentage else null end as week_24_tip_freqency,
        case when fht5.`week` = 25 then fht5.tip_percentage else null end as week_25_tip_freqency,
        case when fht6.`week` = 26 then fht6.tip_percentage else null end as week_26_tip_freqency

    from (

        select
            pickup_day,
            pickup_hour

        from uber.fact_hourly_tip

        group by pickup_day, pickup_hour

    ) pickup_times

    left join uber.fact_hourly_tip fht
        on fht.pickup_day = pickup_times.pickup_day
        and fht.pickup_hour = pickup_times.pickup_hour
        and fht.`week` = 22

    left join uber.fact_hourly_tip fht3
        on fht3.pickup_day = pickup_times.pickup_day
        and fht3.pickup_hour = pickup_times.pickup_hour
        and fht3.`week` = 23

    left join uber.fact_hourly_tip fht4
        on fht4.pickup_day = pickup_times.pickup_day
        and fht4.pickup_hour = pickup_times.pickup_hour
        and fht4.`week` = 24

    left join uber.fact_hourly_tip fht5
        on fht5.pickup_day = pickup_times.pickup_day
        and fht5.pickup_hour = pickup_times.pickup_hour
        and fht5.`week` = 25

    left join uber.fact_hourly_tip fht6
        on fht6.pickup_day = pickup_times.pickup_day
        and fht6.pickup_hour = pickup_times.pickup_hour
        and fht6.`week` = 26;




-- Question 6 - Can you predict the length of the trip based on factors that are known at pick-up? How might you use this information?

    create table uber.fact_hourly_trip_distance as

        select
            dayname(lpep_pickup_datetime) as pickup_day,
            week(lpep_pickup_datetime) as `week`,
            hour(lpep_pickup_datetime) as pickup_hour,
            day(lpep_pickup_datetime) pickup_date,
            avg(trip_distance) as average_trip_distance

        from uber.fact_green_trip_data_2014_06

        where fare_amount > 0
            and trip_distance > 0

        group by
            day(lpep_pickup_datetime),
            hour(lpep_pickup_datetime),
            dayname(lpep_pickup_datetime),
            week(lpep_pickup_datetime);


    select
        pickup_times.pickup_day,
        pickup_times.pickup_hour,
        case when fht.`week` = 22 then fht.average_trip_distance else null end as week_22_avg_trip_distance,
        case when fht3.`week` = 23 then fht3.average_trip_distance else null end as week_23_avg_trip_distance,
        case when fht4.`week` = 24 then fht4.average_trip_distance else null end as week_24_avg_trip_distance,
        case when fht5.`week` = 25 then fht5.average_trip_distance else null end as week_25_avg_trip_distance,
        case when fht6.`week` = 26 then fht6.average_trip_distance else null end as week_26_avg_trip_distance

    from (

        select
            pickup_day,
            pickup_hour

        from uber.fact_hourly_trip_distance

        group by pickup_day, pickup_hour

    ) pickup_times

    left join uber.fact_hourly_trip_distance fht
        on fht.pickup_day = pickup_times.pickup_day
        and fht.pickup_hour = pickup_times.pickup_hour
        and fht.`week` = 22

    left join uber.fact_hourly_trip_distance fht3
        on fht3.pickup_day = pickup_times.pickup_day
        and fht3.pickup_hour = pickup_times.pickup_hour
        and fht3.`week` = 23

    left join uber.fact_hourly_trip_distance fht4
        on fht4.pickup_day = pickup_times.pickup_day
        and fht4.pickup_hour = pickup_times.pickup_hour
        and fht4.`week` = 24

    left join uber.fact_hourly_trip_distance fht5
        on fht5.pickup_day = pickup_times.pickup_day
        and fht5.pickup_hour = pickup_times.pickup_hour
        and fht5.`week` = 25

    left join uber.fact_hourly_trip_distance fht6
        on fht6.pickup_day = pickup_times.pickup_day
        and fht6.pickup_hour = pickup_times.pickup_hour
        and fht6.`week` = 26;




-- Question 7 - Get creative! Present any interesting trends, patterns, or predictions that you notice about this dataset.

    -- Are there higher passenger counts on average at certain times during the week? Are there enough passengers that larger vehicles are needed?

    create table uber.fact_hourly_passengers as

        select
            dayname(lpep_pickup_datetime) as pickup_day,
            week(lpep_pickup_datetime) as `week`,
            hour(lpep_pickup_datetime) as pickup_hour,
            day(lpep_pickup_datetime) pickup_date,
            avg(passenger_count) as avg_passenger_count,
            max(passenger_count) as max_passenger_count,
            sum(case when passenger_count > 1 then 1 else 0 end) as multi_passenger_rides,
            count(*) as total_rides,
            sum(case when passenger_count > 1 then 1 else 0 end) / count(*) as percent_of_multi_passenger_rides

        from uber.fact_green_trip_data_2014_06

        where fare_amount > 0
            and trip_distance > 0

        group by
            day(lpep_pickup_datetime),
            hour(lpep_pickup_datetime),
            dayname(lpep_pickup_datetime),
            week(lpep_pickup_datetime);


    select
        pickup_times.pickup_day,
        pickup_times.pickup_hour,
        case when fht.`week` = 22 then fht.percent_of_multi_passenger_rides else null end as week_22_percent_of_multi_passenger_rides,
        case when fht3.`week` = 23 then fht3.percent_of_multi_passenger_rides else null end as week_23_percent_of_multi_passenger_rides,
        case when fht4.`week` = 24 then fht4.percent_of_multi_passenger_rides else null end as week_24_percent_of_multi_passenger_rides,
        case when fht5.`week` = 25 then fht5.percent_of_multi_passenger_rides else null end as week_25_percent_of_multi_passenger_rides,
        case when fht6.`week` = 26 then fht6.percent_of_multi_passenger_rides else null end as week_26_percent_of_multi_passenger_rides

    from (

        select
            pickup_day,
            pickup_hour

        from uber.fact_hourly_passengers

        group by pickup_day, pickup_hour

    ) pickup_times

    left join uber.fact_hourly_passengers fht
        on fht.pickup_day = pickup_times.pickup_day
        and fht.pickup_hour = pickup_times.pickup_hour
        and fht.`week` = 22

    left join uber.fact_hourly_passengers fht3
        on fht3.pickup_day = pickup_times.pickup_day
        and fht3.pickup_hour = pickup_times.pickup_hour
        and fht3.`week` = 23

    left join uber.fact_hourly_passengers fht4
        on fht4.pickup_day = pickup_times.pickup_day
        and fht4.pickup_hour = pickup_times.pickup_hour
        and fht4.`week` = 24

    left join uber.fact_hourly_passengers fht5
        on fht5.pickup_day = pickup_times.pickup_day
        and fht5.pickup_hour = pickup_times.pickup_hour
        and fht5.`week` = 25

    left join uber.fact_hourly_passengers fht6
        on fht6.pickup_day = pickup_times.pickup_day
        and fht6.pickup_hour = pickup_times.pickup_hour
        and fht6.`week` = 26;
