-- общее количество покупателей
SELECT COUNT(*) AS customers_count
FROM customers;

-- продавцы у которых наибольшая выручка
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;

-- продавцы с выручкой ниже средней
WITH seller_avg_income AS (
    SELECT
        e.employee_id,
        AVG(p.price * s.quantity) AS avg_income_per_sale
    FROM sales AS s
    INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p ON s.product_id = p.product_id
    GROUP BY e.employee_id
)

SELECT
    TRIM(CONCAT(e.first_name, ' ', e.last_name)) AS seller,
    FLOOR(sai.avg_income_per_sale) AS average_income
FROM seller_avg_income AS sai
INNER JOIN employees AS e ON sai.employee_id = e.employee_id
WHERE sai.avg_income_per_sale < (
    SELECT AVG(sai2.avg_income_per_sale)
    FROM seller_avg_income AS sai2
)
ORDER BY average_income ASC;

-- отчет по выручке по каждому продавцу и дню недели
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    TO_CHAR(s.sale_date, 'day') AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.first_name, e.last_name, s.sale_date
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    e.first_name || ' ' || e.last_name;

-- выбираем возрастные группы и количество покупателей в каждой группе
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
ORDER BY age_category;

-- выбираем данные по месяцам - год и месяц из даты продажи
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month;

-- находим все покупки клиентов, где цена товара равна 0
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
    INNER JOIN products AS p ON s.product_id = p.product_id
    WHERE p.price = 0
)

SELECT
    fs.sale_date,
    c.first_name || ' ' || c.last_name AS customer,
    e.first_name || ' ' || e.last_name AS seller
FROM first_sales AS fs
INNER JOIN customers AS c ON fs.customer_id = c.customer_id
INNER JOIN employees AS e ON fs.employee_id = e.employee_id
WHERE fs.rn = 1
ORDER BY c.customer_id;

