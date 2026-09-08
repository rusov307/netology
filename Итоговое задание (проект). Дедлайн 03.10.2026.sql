set search_path to hr

-- проверка подключения
select *
from person

-- Задание 1. Вывести список сотрудников старше 65 лет. 
-- 724 строки

select concat(p.first_name,' ', p.middle_name,' ', p.last_name) fio, 
	p.dob, 
	extract(year from age(CURRENT_DATE, p.dob)) as years   
from person p
where p.dob < CURRENT_DATE - INTERVAL '66 years'
order by years

--Задание 2. Вывести количество вакантных должностей. (Таблица с вакансиями может содержать недостоверные данные, решение должно быть без этой таблицы).

select count(*)
from position p
left join employee e on p.pos_id = e.pos_id
where emp_id is null

-- Задание 3. Вывести список проектов и количество сотрудников, задействованных на этих проектах.

select p.name, p.employees_id, p.assigned_id, count(DISTINCT e.person_id) as emp_count
from projects p
left join hours h on p.project_id = h.project_id
left join employee e on e.emp_id = h.emp_id 
group by  p.name, p.project_id


-- Задание 4. Получить список сотрудников у которых было повышение заработной платы на 25%

with salary_changes as (
    select
        emp_id,
        salary,
        effective_from,
        LAG(salary) over (
            partition by emp_id
            order by effective_from
        ) as prev_salary
    from employee_salary
)
select
    e.emp_id,
    --p.first_name,
    --p.last_name,
    sc.salary,
    sc.prev_salary,
    (sc.salary / prev_salary)*100 - 100 as change_percent 
from salary_changes sc
join employee e on sc.emp_id = e.emp_id
join person p on e.person_id = p.person_id
where sc.salary = sc.prev_salary * 1.25;

-- Задание 5. Вывести среднее значение суммы договора на каждый год, округленное до сотых.

select 
	extract(year from created_at) as year,
	round(avg(amount), 2) as avg_amount
from projects
group by extract(year from created_at)
order by year

-- Задание 6. Одним запросом вывести ФИО сотрудников с самым низким и самым высоким окладами за все время.

select concat(p.last_name,' ',p.first_name,' ',p.middle_name) as ФИО, es.salary
from person p
left join employee e on p.person_id = e.person_id
left join employee_salary es on e.emp_id = es.emp_id
where es.salary = (
	select max(salary)
    from employee_salary) 
   or
    es.salary = (
	select min(salary)
    from employee_salary)
order by es.salary desc


-- Задание 7. Вывести текущий оклад сотрудников и в формате строки вывести зарплатные грейды, в которые попадает текущий оклад.

-- Сначала текущий оклад через сte каждого сотрудника

with curr_salary as (
	select *,
	row_number() over (partition by emp_id order by effective_from desc) as rn
	from employee_salary es 
)
-- Проверка отображения select * from curr_salary where rn = 1
-- Далее основной запрос и дополнение данными в диапазоне оклада в разрезе грейда
select cs.emp_id, cs.salary, STRING_AGG(gs.grade::text, ', ' ORDER BY gs.grade DESC) AS grades_as_string
from curr_salary cs
left join grade_salary gs on cs.salary between gs.min_salary and gs.max_salary
where rn = 1 and gs.grade is not null
group by cs.emp_id, cs.salary
order by cs.emp_id desc

/* Задание 8. Создайте представление, которое будет содержать следующую информацию:

ФИО сотрудника - 	person
должность сотрудника - 	position pos_title
структурное подразделение, где числится сотрудник - 	structure position pos_category
количество полных лет сотрудника - 	person dob
количество месяцев, сколько сотрудник работает в компании - 	employee hire_date
текущий оклад сотрудника - 	employee_salary salary сортировка по последней ЗП
массив со списком проектов на которых задействован сотрудник - 	projects - employees_id
*/

CREATE VIEW employee_info AS

SELECT
    CONCAT(p.last_name, ' ',  p.first_name, ' ', p.middle_name) AS "ФИО",
    pos.pos_title AS "должность",
    s.unit_title AS "подразделение",
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.dob))::int AS "кол-во лет",
    (EXTRACT(YEAR FROM AGE(CURRENT_DATE, e.hire_date)) * 12
        +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, e.hire_date)
    ))::int AS "кол-во месяцев",
    es.salary AS "оклад",
    COALESCE(
        ARRAY_AGG(
            DISTINCT pr.project_id
            ORDER BY pr.project_id
        ) FILTER (WHERE pr.project_id IS NOT NULL),
        ARRAY[]::integer[]
    ) AS "массив с проектами"
FROM employee e
JOIN employee_salary es
    ON e.emp_id = es.emp_id
JOIN person p
    ON e.person_id = p.person_id
JOIN position pos
    ON e.pos_id = pos.pos_id
JOIN structure s
    ON pos.unit_id = s.unit_id
LEFT JOIN hours h
    ON e.emp_id = h.emp_id
LEFT JOIN projects pr
    ON pr.project_id = h.project_id 
GROUP BY
    e.emp_id,
    p.first_name,
    p.middle_name,
    p.last_name,
    p.dob,
    e.hire_date,
    es.salary,
    pos.pos_title,
    s.unit_title;


