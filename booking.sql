CREATE DATABASE `booking`;

USE `booking`;

--
-- Таблица клиентов.
--
CREATE TABLE IF NOT EXISTS customers (
    id INT NOT NULL AUTO_INCREMENT,             -- Идентификатор.
    first_name VARCHAR(64) NOT NULL,            -- Имя клиента.
    last_name VARCHAR(64) NOT NULL,             -- Фамилия клиента.
    phone_number VARCHAR(32) NOT NULL,          -- Номер телефона.
    CONSTRAINT pk_customers PRIMARY KEY (id)    -- Первичный ключ.
);

--
-- Заказы (бронирования).
--
CREATE TABLE IF NOT EXISTS orders (
    id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    CONSTRAINT pk_orders PRIMARY KEY (id)
);

ALTER TABLE orders
    ADD CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
;

-- !!! СЛОЖНАЯ РЕАЛИЗАЦИЯ
--
-- Таблица цен.
--
-- Цены хранятся в временных промежутках для сокращения количества записей в базе данных.
-- Вместо создания множества записей с дублирующимися ценами создаются записи с ценами
-- в определенный период времени.
--
-- CREATE TABLE IF NOT EXISTS prices (
--     id INT NOT NULL AUTO_INCREMENT,         -- Идентификатор.
--     start_at DATETIME NOT NULL,             -- Начало периода.
--     end_at DATETIME NOT NULL,               -- Окончание периода.
--     price INT NOT NULL,                     -- Цена в копейках (для точности вычислений).
--     CONSTRAINT pk_prices PRIMARY KEY (id)   -- Первичный ключ.
-- );

--
-- Вставка записей в таблицу.
--
-- INSERT INTO prices (start_at, end_at, price)
--     VALUE ('2022-04-01', '2022-04-10', '240000');   -- С 1 апреля по 10 апреля цена 2400.00 рублей.
-- INSERT INTO prices (start_at, end_at, price)
--     VALUE ('2022-04-11', '2022-04-18', '220000');   -- С 11 апреля по 18 апреля цена 2200.00 рублей.
-- INSERT INTO prices (start_at, end_at, price)
--     VALUE ('2022-04-19', '2022-04-20', '260000');   -- С 19 апреля по 20 апреля цена 2600.00 рублей.
--
-- -- Небольшое окошко для выполнения запроса добавления цены (с 21 апреля по 26 апреля).
--
-- INSERT INTO prices (start_at, end_at, price)
--     VALUE ('2022-04-27', '2022-04-30', '270000');   -- С 27 апреля по 30 апреля цена 2700.00 рублей.
-- INSERT INTO prices (start_at, end_at, price)
--     VALUE ('2022-05-01', '2022-05-09', '350000');   -- С 1 мая по 9 мая цена 3500.00 рублей.

--
-- Таблица цен.
--
CREATE TABLE IF NOT EXISTS dates (
    id INT NOT NULL AUTO_INCREMENT,         -- Идентификатор.
    price_at DATETIME NOT NULL,             -- Цена в день.
    price INT NOT NULL,                     -- Цена в копейках (для точности вычислений).
    order_id INT,                           -- Внешний ключ
    CONSTRAINT pk_prices PRIMARY KEY (id)   -- Первичный ключ.
);

ALTER TABLE dates
    ADD CONSTRAINT fk_dates_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE SET NULL
;

--
-- Чеки оплаты (включает в себя только оплаченные чеки).
--
CREATE TABLE IF NOT EXISTS checks (
    id INT NOT NULL AUTO_INCREMENT,
    order_id int NOT NULL,
    CONSTRAINT pk_checks PRIMARY KEY (id)
);

ALTER TABLE checks
    ADD CONSTRAINT fk_check_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE SET NULL
;

--
-- Вставка записей в таблицу.
--
INSERT INTO customers (id, first_name, last_name, phone_number)
VALUE
    (1, 'Адам', 'Вагин', '325-223-9829'),
    (2, 'Капитолина', 'Горбунова', '508-862-2279'),
    (3, 'Устиния', 'Кольцова', '310-322-4732'),
    (4, 'Ася', 'Воронина', '410-654-3567'),
    (5, 'Рашид', 'Беляков', '708-642-7722'),
    (6, 'Ростислав', 'Волошин', '609-690-7229'),
    (7, 'Алексей', 'Соломин', '719-227-1529')
;

INSERT INTO orders (id, customer_id)
VALUE
    (1, 2),
    (2, 4),
    (3, 5),
    (4, 7)
;

INSERT INTO dates (price_at, price, order_id)
VALUE
    ('2022-04-01', '240000', NULL),
    ('2022-04-02', '300000', 1),
    ('2022-04-03', '300000', 1),
    ('2022-04-04', '240000', NULL),
    ('2022-04-05', '240000', NULL),
    ('2022-04-06', '240000', NULL),
    ('2022-04-07', '240000', NULL),
    ('2022-04-08', '240000', NULL),
    ('2022-04-09', '300000', 2),
    ('2022-04-10', '300000', 2),
    ('2022-04-11', '240000', NULL),
    ('2022-04-12', '240000', NULL),
    ('2022-04-13', '240000', 3),
    ('2022-04-14', '240000', 3),
    ('2022-04-15', '240000', 3),
    ('2022-04-16', '300000', 3),
    ('2022-04-17', '300000', NULL),
    ('2022-04-18', '240000', NULL),
    ('2022-04-19', '240000', NULL),
    ('2022-04-20', '240000', 4),
    ('2022-05-21', '240000', 4),
    ('2022-05-22', '240000', NULL),
    ('2022-05-23', '240000', NULL)
;

INSERT INTO checks (id, order_id)
VALUE
    (1, 1),
    (2, 2)
;

--
-- Найти свободные даты c ценами.
--
SELECT
    DATE_FORMAT(dates.price_at, '%d.%m.%Y') AS date,
    ROUND(dates.price / 100, 2) AS price
FROM dates
WHERE
    ('2022-04-12' <= dates.price_at AND dates.price_at <= '2022-04-18')
    AND dates.order_id IS NULL
;

--
-- Подсчитать стоимость бронирования.
--
SELECT
    customers.first_name,
    customers.last_name,
    customers.phone_number,
    ROUND(SUM(dates.price) / 100, 2) AS total
FROM orders
LEFT JOIN dates ON orders.id = dates.order_id
LEFT JOIN customers ON customers.id = orders.customer_id
WHERE
    orders.id = 3 -- Идентификатор бронирования
;

--
-- Поиск клиентов с неоплаченными бронированиями.
--
SELECT
    customers.first_name,
    customers.last_name,
    customers.phone_number,
    ROUND(SUM(dates.price) / 100, 2) AS total
FROM orders
LEFT JOIN dates ON orders.id = dates.order_id
LEFT JOIN checks ON orders.id = checks.order_id
LEFT JOIN customers ON customers.id = orders.customer_id
WHERE checks.id IS NULL
GROUP BY customers.id
;
