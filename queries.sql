-- Общее количество покупателей
-- Подсчёт всех записей в таблице customers, включая тех, у кого нет возраста
SELECT
    COUNT(*) AS customers_count
FROM customers;


-- Топ-10 самых прибыльных продавцов
-- Рассчитываем выручку по каждому продавцу как сумму (цена × количество)
-- Сортируем по убыванию и ограничиваем 10 результатами
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
JOIN employees AS e ON s.sales_person_id = e.employee_id
JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;


-- Продавцы с выручкой ниже средней
-- Используем CTE для вычисления средней выручки на сделку по каждому продавцу
-- Затем сравниваем с общим средним и находим тех, кто ниже
WITH seller_avg_income AS (
    SELECT
        e.employee_id,
        TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
        AVG(p.price * s.quantity) AS avg_income_per_sale
    FROM sales AS s
    JOIN employees AS e ON s.sales_person_id = e.employee_id
    JOIN products AS p ON s.product_id = p.product_id
    GROUP BY e.employee_id, seller
),
overall_avg AS (
    -- Вычисляем среднее значение средних выручек всех продавцов
    SELECT AVG(avg_income_per_sale) AS avg_of_averages
    FROM seller_avg_income
)
SELECT
    sai.seller,
    FLOOR(sai.avg_income_per_sale)::INTEGER AS average_income
FROM seller_avg_income AS sai
CROSS JOIN overall_avg AS oa
WHERE sai.avg_income_per_sale < oa.avg_of_averages
ORDER BY average_income ASC;


-- Выручка по дням недели и продавцам
-- Группируем по дню недели (на английском, в нижнем регистре) и продавцу
-- Сортируем по порядку дней: понедельник → воскресенье
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    LOWER(TRIM(TO_CHAR(s.sale_date, 'day'))) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity))::INTEGER AS income
FROM sales AS s
JOIN employees AS e ON s.sales_person_id = e.employee_id
JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    e.first_name,
    e.last_name,
    LOWER(TRIM(TO_CHAR(s.sale_date, 'day')))
ORDER BY
    CASE LOWER(TRIM(TO_CHAR(s.sale_date, 'day')))
        WHEN 'monday' THEN 1
        WHEN 'tuesday' THEN 2
        WHEN 'wednesday' THEN 3
        WHEN 'thursday' THEN 4
        WHEN 'friday' THEN 5
        WHEN 'saturday' THEN 6
        WHEN 'sunday' THEN 7
    END,
    seller;


-- Распределение покупателей по возрастным группам
-- Группы: 16–25, 26–40, 40+
-- Исключаем записи с NULL в поле age
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
WHERE age IS NOT NULL
GROUP BY
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        ELSE '40+'
    END
ORDER BY
    MIN(
        CASE
            WHEN age BETWEEN 16 AND 25 THEN 1
            WHEN age BETWEEN 26 AND 40 THEN 2
            ELSE 3
        END
    );


-- Ежемесячная статистика: количество клиентов и выручка
-- Агрегируем данные по месяцам, считаем уникальных покупателей и общую выручку
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
JOIN products AS p ON s.product_id = p.product_id
WHERE s.sale_date IS NOT NULL
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month;


-- Первые бесплатные покупки клиентов
-- Находим первую по дате покупку каждого клиента, где цена товара = 0
-- Используем ROW_NUMBER() для нумерации покупок
WITH first_sales AS (
    SELECT
        s.customer_id,
        s.sale_date,
        s.sales_person_id AS employee_id,
        s.product_id,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date
        ) AS rn
    FROM sales AS s
    JOIN products AS p ON s.product_id = p.product_id
    WHERE p.price = 0
),
first_free_customers AS (
    -- Оставляем только первую покупку (rn = 1)
    SELECT *
    FROM first_sales
    WHERE rn = 1
)
-- Формируем финальный отчёт: имя клиента, дата покупки, имя продавца
SELECT
    c.first_name || ' ' || c.last_name AS customer,
    fpc.sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM first_free_customers AS fpc
JOIN customers AS c ON fpc.customer_id = c.customer_id
JOIN employees AS e ON fpc.employee_id = e.employee_id
ORDER BY c.customer_id;