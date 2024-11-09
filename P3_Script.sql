-- Q1. Fetch all the paintings which are not displayed on any museums?

Select * from work
where museum_id IS NULL

-- Q2. Are there museums without any paintings?

select museum_id, count(*) as total_listed_paintings from work
group by museum_id
order by total_listed_paintings asc

-- Alternate 

select * from museum m
where not exists (select 1 from work w
                   where w.museum_id = m.museum_id)

-- No

-- Q3. How many paintings have an asking price of more than their regular price?

Select * from product_size
where sale_price > regular_price

-- Q4. Identify the paintings whose asking price is less than 50% of its regular price

select * from product_size
where sale_price < ((regular_price*50)/100)

-- Q5.  Which canva size costs the most?

select * from canvas_size
where size_id IN 
(
    select size_id from product_size
    order by sale_price desc
    fetch first row only
)

-- Q6. Identify the museums with invalid city information in the given dataset

Select * from museum
where not regexp_like (city, '[[:alpha:]]' )


-- Q7. Fetch the top 10 most famous painting subject


select subject, count(*) as dummy from subject
group by subject
order by dummy desc
fetch first 10 row with ties;

-- Alternate

select * from
(
select s.subject, count(s.subject) as no_of_paintings,
rank () over (order by count(s.subject) desc) as ranking
from work w
join subject s on s.work_id = w.work_id
group by s.subject
) x
where ranking <=10


-- Q8. Identify the museums which are open on both Sunday and Monday. Display museum name, city


select unique m.name as museum_name, m.city, m.state, m.country
from museum m
join museum_hours mh1 on m.museum_id = mh1.museum_id     
where day = 'Sunday'
and exists
(
    select museum_id from museum_hours mh2
    where mh1.museum_id = mh2.museum_id
    and mh2.day = 'Monday'
)

-- firstly, we are selecting all the museums which are open on Sunday - since more museums are open on Sunday as compared to Monday.
-- And then we are asking SQL to check whether the say museum id exists in the table when we apply the filter for Monday.

-- Q9. How many museums are open every single day?

With dummy as
(
    Select museum_id, day, row_number() over (partition by museum_id order by museum_id ) as win_rnk
    from museum_hours
)
Select d.museum_id, m.name 
from dummy d
join museum m on m.museum_id = d.museum_id
where win_rnk = 7
order by d.museum_id asc

-- Q10. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

select m.museum_id, m.name, count (w.work_id) as no_of_pictures
from work w
join museum m on w.museum_id = m.museum_id
group by m.museum_id, m.name
order by no_of_pictures desc
Fetch first 5 rows only

-- Q11. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

select a.artist_id, a.full_name, count (w.name) as no_of_paintings
from work w
JOIN artists a on w.artist_id = a.artist_id
group by a.artist_id, a.full_name
order by no_of_paintings desc
Fetch first 5 rows only


-- Q12. Display the 3 least popular canva sizes

select label, no_of_paintings, ranking from
    (
    select cs.size_id, cs.label, count(cs.size_id) as no_of_paintings,
    dense_rank() over(order by count(cs.size_id) asc ) as ranking
    from canvas_size cs
    join product_size ps on cs.size_id = ps.size_id
    group by cs.size_id, cs.label
    ) x
where x.ranking <= 3

-- Q13. Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

with dummy as
(
select museum_id, day,(close - open) as duration
from museum_hours
)

select museum_id, day, duration, rank() over(order by duration desc) as rank
from dummy
fetch first row only

-- alternate select query

select * from dummy where duration = (select max(duration) from dummy)


-- Q14. Which museum has the most no of most popular painting style?

with mps as
(
select style, count(style) as most_popular
from work
-- where museum_id IS NOT NULL
GROUP BY style
order by most_popular desc
Fetch first row only
)

Select m.name, count (m.name) as no_of_imp
from museum m
join work w on m.museum_id = w.museum_id
where w.style IN (Select mps.style from mps)
group by m.name
order by no_of_imp desc
fetch first row only


-- Q15. Identify the artists whose paintings are displayed in multiple countries

with cte as
(
select distinct a.full_name as artist, m.country
from work w
join museum m on w.museum_id = m.museum_id
join artists a on w.artist_id = a.artist_id
)

select artist, count(artist) as no_of_countries
from cte
group by artist
having count(artist) >= 2


-- Q16. Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country.
-- If there are multiple value, seperate them with comma.

with country as
            (
            select country, count (*) as total_count from museum
            group by country
            order by total_count desc
            fetch first row with ties
            ),
    city as
            (
            select city, count (*) as total_count from museum
            where country IN ( 
                                select country from museum
                                group by country
                                order by COUNT (country) desc
                                fetch first row with ties
                              )
            group by city
            order by total_count desc
            fetch first row with ties
            )
select country, city
from country
cross join city

-- Alternative

with country as
            (
            select country, count (*) as total_count from museum
            group by country
            order by total_count desc
            fetch first row with ties
            ),
    city as
            (
            select city, count (*) as total_count from museum
            group by city
            order by total_count desc
            fetch first row with ties
            )
select listagg (country, ', ') as country, listagg(city, ', ') as city
from country
cross join city


-- Q17. Identify the artist and the museum where the most expensive and least expensive painting is placed. 
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label

with painting as
(
select distinct w.name, ps.sale_price, a.full_name, m.name as museum,
rank() over (order by ps.sale_price desc) as rnk
from work w
join product_size ps on w.work_id = ps.work_id
join artists a on w.artist_id = a.artist_id
join museum m on w.museum_id = m.museum_id
where  ps.sale_price = (Select max(ps.sale_price) from product_size ps )
or ps.sale_price = (Select min(ps.sale_price) from product_size ps )
)

Select full_name as artist_name, museum, name as painting, sale_price,
case when rnk = 1 then 'Most Expensive Painting' Else 'Least Expensive Painting' end as remarks
from painting



-- Q18. Which country has the 5th highest no of paintings?

select m.country, count (w.name) as no_of_paintings
from work w
join museum m on w.museum_id = m.museum_id
group by m.country
order by count (w.name) desc
OFFSET 4 rows
Fetch first row only

-- Q19. Which are the 3 most popular and 3 least popular painting styles?

with cte as
(
select style, count (style) as popularity,
rank () over (order by count (style) desc ) as rnk,
count(style) over () as no_of_records
from work
where style is not null
group by style
)
select style,
case when rnk <=3 then '3 Most Popular' Else '3 Least Popular' end as remarks
from cte
where rnk <=3 or rnk > (no_of_records - 3)


-- Q20. Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality

with cte as
(
select a.full_name, a.nationality, m.country, w.name
from work w
join museum m on w.museum_id = m.museum_id
join artists a on w.artist_id = a.artist_id
where m.country <> 'USA'
)

Select full_name, nationality, count(name) as no_of_paintings
from cte
group by full_name, nationality
order by count(name) desc
Fetch first row only


SAVEPOINT A
