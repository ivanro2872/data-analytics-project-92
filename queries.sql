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


5.
-- выбираем возрастные группы и количество покупателей в каждой группе
SELECT
    -- определяем возрастную группу на основе возраста покупателей
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,

    -- подсчитываем количество покупателей в каждой групе
    COUNT(*) AS age_count
FROM customers

-- фильтруем - исключаем записи, где возраст не указан
WHERE age IS NOT NULL

-- групируем результат по возрастным группам
GROUP BY
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END

-- сортируем результаты в нужном нам порядке - 1. '16-25', 2. '26-40', 3. '40+'
ORDER BY
    MIN(
        CASE
            WHEN age BETWEEN 16 AND 25 THEN 1
            WHEN age BETWEEN 26 AND 40 THEN 2
            ELSE 3
        END
    );


6.
-- выбираем данные по месяцам - год и месяц из даты продажи
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,

    -- подсчитаем количество уникальных покупателей за месяц
    COUNT(DISTINCT s.customer_id) AS total_customers,

    -- посчитаем общую выручку за месяц как сумму (количество * цена товара)
    -- потом округляем результат вниз до ближайшего целого числа с помощью FLOOR()
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales s
-- объединяем таблицу продаж с таблицей товаров, чтобы получить цену товара
JOIN products p ON s.product_id = p.product_id
WHERE s.sale_date IS NOT NULL
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM') -- групируем по месяцам
ORDER BY selling_month; -- сортируем резултаты по дате по возрастанию


7.
-- делаем временную таблицу CTE first_sales - находим все покупки клиентов, где цена товара равна 0
-- и нумеруем их по дате, чтобы определить первую покупку клиента
WITH first_sales AS (
    SELECT
        s.customer_id,               -- ID покупателя
        s.sale_date,                 -- дата покупки
        s.sales_person_id AS employee_id, -- ID продавца
        s.product_id,                -- ID товара
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id  -- группируем по покупателю
            ORDER BY s.sale_date        -- сортируем по дате покупки
        ) AS rn                      -- номер покупки клиента (1 — первая)
    FROM sales s
    JOIN products p ON s.product_id = p.product_id  -- соединяем с таблицей товаров
    WHERE p.price = 0  -- выбираем только бесплатные товары
),

-- делаем временную таблицу CTE first_free_customers - оставляем только первую покупку каждого клиента
first_free_customers AS (
    SELECT *
    FROM first_sales
    WHERE rn = 1  -- фильтруем только первую покупку покупателя
)

-- выводим имя покупателя, дату первой бесплатной покупки и имя продавца
SELECT
    c.first_name || ' ' || c.last_name AS customer,  -- имя и фамилия покупателя
    fpc.sale_date,                                  -- дата покупки
    e.first_name || ' ' || e.last_name AS seller    -- имя и фамилия продавца
FROM first_free_customers fpc
-- соединяем с таблицей customers, чтобы получить имя покупателя
JOIN customers c ON fpc.customer_id = c.customer_id
-- соединяем с таблицей employees, чтобы получить имя продавца
JOIN employees e ON fpc.employee_id = e.employee_id
-- сортируем результат по ID покупателя
ORDER BY c.customer_id;

