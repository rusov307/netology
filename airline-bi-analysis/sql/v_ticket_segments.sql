set search_path to bookings

-- Продажи билетов

create view v_ticket_segments as
select 
	tt.flight_id,
	s.ticket_no, s.fare_conditions, s.price, 
	t.book_ref, tt.route_no, t.outbound,
	tt.departure_airport, tt.arrival_airport,
	count(*) over (partition by s.ticket_no) as ticket_segment
from segments s
join tickets t on s.ticket_no = t.ticket_no 
join timetable tt on s.flight_id = tt.flight_id 

/* Проверка 

select * -- 3 941 249 строк
from v_ticket_segments 

*/