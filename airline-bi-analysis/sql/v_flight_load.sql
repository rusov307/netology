-- Загрузка самолетов

set search_path to bookings

create view v_flight_load as 
with seat_capacity as (
    -- Количество мест по коду самолета
	select s.airplane_code, count(*) as seat_capacity
	from seats s 
	group by s.airplane_code 
),
flight_passengers as (
    -- Количество пассажиров на каждом рейсе
	select bp.flight_id, count(distinct bp.ticket_no) as passenger	
	from boarding_passes bp 
	group by bp.flight_id
)
select 
	t.flight_id, 
	sc.seat_capacity, 
	coalesce(fp.passenger, 0) as passenger_count, 
	round(
	100.0 * fp.passenger / nullif(sc.seat_capacity, 0),
	2) as load_factor
from timetable t 
left join seat_capacity sc on t.airplane_code = sc.airplane_code
left join flight_passengers fp on t.flight_id = fp.flight_id 
order by load_factor