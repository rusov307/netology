set search_path to bookings

-- Эффективность использования авиапарка

DROP VIEW v_flight_performance;

create view v_flight_performance as 
select 
-- ориентир на уникальные значения
	t.flight_id,
	t.route_no,
-- аэропорт вылета
	t.departure_airport,
    dep.airport_name AS departure_airport_name,
    dep.city AS departure_city,
    dep.country AS departure_country,
-- аэоропорт прибытия
    t.arrival_airport,
    arr.airport_name AS arrival_airport_name,
    arr.city AS arrival_city,
    arr.country AS arrival_country,
-- модели самолетов
    t.airplane_code,
    a.model AS airplane_model,
    a.range,
    a.speed,
-- статус рейса
    t.status,
-- время вылета план/факт
    t.scheduled_departure,
    t.actual_departure,
-- время прилета план/факт
    t.scheduled_arrival,
    t.actual_arrival, 
-- время полета
    t.actual_arrival - t.actual_departure as flight_time,
-- расчет задержки вылета
   	extract ( epoch from (t.actual_departure - t.scheduled_departure)) / 60 AS departure_delay_min,
-- расчет задержки прибытия 
	extract ( epoch from (t.actual_arrival - t.scheduled_arrival)) / 60 AS arrival_delay_min
from timetable t
join airports dep on t.departure_airport = dep.airport_code
join airports arr on t.arrival_airport = arr.airport_code
join airplanes a  on t.airplane_code  = a.airplane_code;

/* проверка
select *
from v_flight_performance */

DROP VIEW v_flights_delays_15

-- Представление расчет задержки рейсов больше 15 мин
create view v_flights_delays_15 as 
select flight_id, route_no, departure_airport, arrival_airport, departure_delay_min, arrival_delay_min,
	case 
		when departure_delay_min <= 15 then 'своевременно'
		when departure_delay_min is NULL then 'нет факта'
		else'задержка'
	end as departure_status,
	case 
		when arrival_delay_min <= 15 then 'своевременно'
		when arrival_delay_min is NULL then 'нет факта'
		else'задержка'
	end as arrival_status
from v_flight_performance;

/* проверка
select *
from v_flights_delays_15 

select * --614 рейсов с задержкой
from v_flights_delays_15
where (departure_delay_min > 15) or (arrival_delay_min > 15); */