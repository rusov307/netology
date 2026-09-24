set search_path to bookings

-- Продажи сегментов по классу обслуживания бизнес/комфорт/эконом

-- 3 941 249 строк 
create view v_booking_analysis as 
select
	s.fare_conditions,
    count(*) as segment_count,
    count(distinct s.ticket_no) as ticket_count,
    sum(s.price) as segment_revenue,
    round(avg(s.price), 2) as avg_segment_price
from segments s
join tickets t on s.ticket_no = t.ticket_no 
join bookings b on t.book_ref = b.book_ref  
group by s.fare_conditions
