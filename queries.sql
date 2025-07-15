1.
SELECT COUNT(*) AS customers_count
FROM customers;
-- считаем всех покупателей из таблицы customers
-- COUNT(*) — агрегатная функция, подсчитывает все строки в таблице
-- AS customers_count — дает имя для столбца

2.
SELECT
    e.first_name || ' ' || e.last_name AS seller,  -- объединение имени и фамилии продавцов в одну строку
    COUNT(s.sales_id) AS operations,                -- подсчет количества сделок на каждого продавца
    FLOOR(SUM(p.price * s.quantity)) AS income      -- подсчет общей выручки, как цена товара умноженного на количество и округляем вниз до целого числа
FROM
    sales s
-- присоединение таблицы employees, для получения данных о продавце
-- соединеие по ID продавца из sales и employee_id из employees
JOIN
    employees e ON s.sales_person_id = e.employee_id
-- присоединение таблицы products, для получения цены товаров
-- соединение по product_id
JOIN
    products p ON s.product_id = p.product_id
-- группировка результатов по каждому продавцу
GROUP BY
    e.first_name, e.last_name
-- сортировка результатов по убыванию количества денег — лучшие сверху
ORDER BY
    income DESC
-- вывод только первых 10 записей — top-10 продавцов
LIMIT 10;

3.
-- расчет средней выручки каждого продавца
WITH seller_avg_income AS (
    SELECT 
        s.sales_person_id,
        ROUND(AVG(s.quantity), 0) AS average_income -- cредняя выручка продавцов, округлённая до целого
    FROM sales s
    GROUP BY s.sales_person_id -- группировка по ID продавца
),

-- расчет общей средней выручки всех продавцов
total_avg_income AS (
    SELECT 
        AVG(average_income) AS total_avg -- общая средняя выручка по всем продавцам
    FROM seller_avg_income
)

-- главный запрос, выбираем продавцов, чья выручка ниже средней
SELECT 
    e.first_name || ' ' || e.last_name AS seller, -- имя и фамилия продавца
    sa.average_income
FROM 
    seller_avg_income sa
JOIN 
    employees e ON sa.sales_person_id = e.employee_id -- соединяем данные о продавцах из employees
WHERE 
    sa.average_income < (SELECT total_avg FROM total_avg_income) -- фильтруем только тех, у кого ниже среднего
ORDER BY 
    sa.average_income ASC; -- сортируем по возрастанию средней выручки

4.
-- главный запрос, группировка продавцов и дню недели
SELECT 
    e.first_name || ' ' || e.last_name AS seller,  -- объединяем имя и фамилию продавцов
    TRIM(TO_CHAR(s.sale_date, 'Day')) AS day_of_week,  -- получаем день недели, убираем лишние пробелы
    FLOOR(SUM(s.quantity))::INT AS income  -- суммируем количество и обрезаем дробную часть
FROM sales s
-- соединение с таблицей employees, для получения имени и фамилии продавцов
JOIN employees e ON s.sales_person_id = e.employee_id
-- группируем данные, по имени продавцов, по дню недели, по порядковому номеру дня недели (для корректной сортировки)
GROUP BY 
    e.first_name || ' ' || e.last_name,
    TRIM(TO_CHAR(s.sale_date, 'Day')),
    EXTRACT(DOW FROM s.sale_date)
-- фильтруем группы, оставляя только те, у которых сумма quantity > 0
HAVING 
    SUM(s.quantity) > 0
-- сортируем результат, по порядковому номеру дня недели (sunday=0, monday=1 и т.д.), по имени продавца
ORDER BY 
    EXTRACT(DOW FROM s.sale_date),
    seller;

