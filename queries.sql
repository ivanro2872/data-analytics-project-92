-- общее количество покупателей 
SELECT COUNT(*) AS customers_count
FROM customers;
-- считаем всех покупателей из таблицы customers
-- COUNT(*) — агрегатная функция, подсчитывает все строки в таблице
-- AS customers_count — дает имя для столбца

-- продавцы у которых наибольшая выручка
SELECT
    e.first_name || ' ' || e.last_name AS seller,  -- объединение имени и фамилии продавцов в одну строку
    COUNT(s.sales_id) AS operations,                -- подсчет количества сделок на каждого продавца
    FLOOR(SUM(p.price * s.quantity)) AS income      -- подсчет общей выручки, как цена товара умноженного на количество и округляем вниз до целого числа
FROM
    sales s
-- присоединение таблицы employees, для получения данных о продавце
-- соединение по ID продавца из sales и employee_id из employees
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

-- продавцы с выручкой ниже средней
WITH seller_avg_income AS (
    -- вычисляем среднюю выручку по каждой сделке каждого продавца
    SELECT 
        e.employee_id,
        TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
        AVG(p.price * s.quantity) AS avg_income_per_sale
    FROM 
        sales s
    JOIN 
        employees e ON s.sales_person_id = e.employee_id
    JOIN 
        products p ON s.product_id = p.product_id
    GROUP BY 
        e.employee_id, seller
),
-- вычисляем общее среднее значение средних выручек всех продавцов
overall_avg AS (
    SELECT AVG(avg_income_per_sale) AS avg_of_averages
    FROM seller_avg_income
)
-- выбираем продавцов у которых средняя выручка ниже общего среднего
-- и округляем в меньшую сторону (FLOOR)
SELECT 
    sai.seller,
    FLOOR(sai.avg_income_per_sale)::INTEGER AS average_income
FROM 
    seller_avg_income sai,
    overall_avg oa
WHERE 
    sai.avg_income_per_sale < oa.avg_of_averages  -- ниже среднего
ORDER BY 
    average_income ASC;  -- от самого низкого к более высокому

-- отчет по выручке по каждому продавцу и дню недели
SELECT 
    -- объединение имени и фамилии продавца в одну колонку seller
    e.first_name || ' ' || e.last_name AS seller,
    -- получаем день недели на английском и убираем пробелы функцией TRIM
    LOWER(TRIM(TO_CHAR(s.sale_date, 'day'))) AS day_of_week,
    -- вычисляем выручку, цена * количество, округляем вниз до целого числа и приводим к INTEGER
    FLOOR(SUM(p.price * s.quantity))::INTEGER AS income
-- объединяем три таблицы для получения необходимых данных
FROM sales s
-- присоединяем таблицу сотрудников для получения ФИО продавца
JOIN employees e ON s.sales_person_id = e.employee_id
-- присоединяем таблицу продуктов для получения цены товара
JOIN products p ON s.product_id = p.product_id
-- группируем данные по продавцу и дню недели для суммирования выручки
GROUP BY e.first_name, e.last_name, LOWER(TRIM(TO_CHAR(s.sale_date, 'day')))
-- сортируем результаты сначала по порядковому номеру дня недели и по имени продавца
ORDER BY 
    -- даем явный порядок сортировки дней недели от понедельника к воскресенью
    CASE LOWER(TRIM(TO_CHAR(s.sale_date, 'day')))
        WHEN 'monday' THEN 1    -- Понедельник - первый
        WHEN 'tuesday' THEN 2   -- Вторник - второй
        WHEN 'wednesday' THEN 3 -- Среда - третий
        WHEN 'thursday' THEN 4  -- Четверг - четвертый
        WHEN 'friday' THEN 5    -- Пятница - пятая
        WHEN 'saturday' THEN 6  -- Суббота - шестая
        WHEN 'sunday' THEN 7    -- Воскресенье - седьмое
    END,
    -- внутри одного дня сортируем по имени продавца
    e.first_name || ' ' || e.last_name;

-- выбираем возрастные группы и количество покупателей в каждой группе
SELECT
    -- определяем возрастную группу на основе возраста покупателей
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,

    -- подсчитываем количество покупателей в каждой группе
    COUNT(*) AS age_count
FROM customers

-- фильтруем - исключаем записи, где возраст не указан
WHERE age IS NOT NULL

-- группируем результат по возрастным группам
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
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM') -- группируем по месяцам
ORDER BY selling_month; -- сортируем результаты по дате по возрастанию

-- находим все покупки клиентов, где цена товара равна 0
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
