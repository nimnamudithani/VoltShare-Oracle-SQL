/*
   VOLT-SHARE  —  EV CHARGING NETWORK
*/


BEGIN
    FOR t IN (SELECT table_name FROM user_tables) LOOP
        EXECUTE IMMEDIATE
            'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

BEGIN
    FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/



-- STEP 1 :  CREATE TABLES 

-- COUNTRIES
CREATE TABLE countries (
    country_id    NUMBER(4)     PRIMARY KEY,
    country_name  VARCHAR2(100) NOT NULL,
    country_code  CHAR(3)       UNIQUE NOT NULL,
    currency      CHAR(3)       NOT NULL
);

-- CITIES
CREATE TABLE cities (
    city_id     NUMBER(6)     PRIMARY KEY,
    city_name   VARCHAR2(100) NOT NULL,
    country_id  NUMBER(4)     NOT NULL,
    CONSTRAINT fk_city_country
        FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

-- OPERATORS
CREATE TABLE operators (
    operator_id    NUMBER(6)     PRIMARY KEY,
    operator_name  VARCHAR2(150) NOT NULL,
    email          VARCHAR2(100) UNIQUE NOT NULL,
    phone          VARCHAR2(20),
    commission_pct NUMBER(5,2)   DEFAULT 15 NOT NULL,
    status         VARCHAR2(20)  DEFAULT 'ACTIVE' NOT NULL,
    CONSTRAINT ck_op_commission CHECK (commission_pct BETWEEN 0 AND 50),
    CONSTRAINT ck_op_status     CHECK (status IN ('ACTIVE','SUSPENDED'))
);

-- STATIONS
CREATE TABLE stations (
    station_id    NUMBER(8)     PRIMARY KEY,
    station_name  VARCHAR2(150) NOT NULL,
    operator_id   NUMBER(6)     NOT NULL,
    city_id       NUMBER(6)     NOT NULL,
    address       VARCHAR2(250),
    station_type  VARCHAR2(20)  DEFAULT 'PUBLIC' NOT NULL,
    rating        NUMBER(3,1),
    status        VARCHAR2(20)  DEFAULT 'OPEN' NOT NULL,
    CONSTRAINT ck_st_type   CHECK (station_type IN ('PUBLIC','PRIVATE','HIGHWAY')),
    CONSTRAINT ck_st_status CHECK (status IN ('OPEN','CLOSED','MAINTENANCE')),
    CONSTRAINT ck_st_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_st_operator FOREIGN KEY (operator_id) REFERENCES operators(operator_id),
    CONSTRAINT fk_st_city     FOREIGN KEY (city_id)     REFERENCES cities(city_id)
);

-- CHARGER_TYPES
CREATE TABLE charger_types (
    type_id      NUMBER(4)    PRIMARY KEY,
    type_name    VARCHAR2(60) NOT NULL,
    connector    VARCHAR2(30) NOT NULL,
    max_power_kw NUMBER(6,1)  NOT NULL,
    speed_level  VARCHAR2(20) DEFAULT 'FAST' NOT NULL,
    CONSTRAINT ck_ct_speed CHECK (speed_level IN ('SLOW','FAST','ULTRA_FAST'))
);

-- CHARGERS
CREATE TABLE chargers (
    charger_id   NUMBER(8)    PRIMARY KEY,
    station_id   NUMBER(8)    NOT NULL,
    type_id      NUMBER(4)    NOT NULL,
    charger_code VARCHAR2(20) UNIQUE NOT NULL,
    power_kw     NUMBER(6,1)  NOT NULL,
    status       VARCHAR2(20) DEFAULT 'AVAILABLE' NOT NULL,
    CONSTRAINT ck_ch_status CHECK (status IN ('AVAILABLE','IN_USE','FAULTED','OFFLINE')),
    CONSTRAINT ck_ch_power  CHECK (power_kw > 0),
    CONSTRAINT fk_ch_station FOREIGN KEY (station_id) REFERENCES stations(station_id),
    CONSTRAINT fk_ch_type    FOREIGN KEY (type_id)    REFERENCES charger_types(type_id)
);

-- USERS
CREATE TABLE users (
    user_id     NUMBER(8)     PRIMARY KEY,
    full_name   VARCHAR2(150) NOT NULL,
    email       VARCHAR2(150) UNIQUE NOT NULL,
    phone       VARCHAR2(20),
    country_id  NUMBER(4)     NOT NULL,
    member_tier VARCHAR2(20)  DEFAULT 'BASIC' NOT NULL,
    wallet_bal  NUMBER(10,2)  DEFAULT 0 NOT NULL,
    status      VARCHAR2(20)  DEFAULT 'ACTIVE' NOT NULL,
    CONSTRAINT ck_usr_tier   CHECK (member_tier IN ('BASIC','SILVER','GOLD','PLATINUM')),
    CONSTRAINT ck_usr_wallet CHECK (wallet_bal >= 0),
    CONSTRAINT ck_usr_status CHECK (status IN ('ACTIVE','SUSPENDED')),
    CONSTRAINT fk_usr_country FOREIGN KEY (country_id) REFERENCES countries(country_id)
);

-- VEHICLES
CREATE TABLE vehicles (
    vehicle_id  NUMBER(8)    PRIMARY KEY,
    user_id     NUMBER(8)    NOT NULL,
    make        VARCHAR2(50) NOT NULL,
    model       VARCHAR2(60) NOT NULL,
    plate_no    VARCHAR2(20) UNIQUE NOT NULL,
    battery_kwh NUMBER(6,1)  NOT NULL,
    connector   VARCHAR2(30) NOT NULL,
    status      VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL,
    CONSTRAINT ck_veh_battery CHECK (battery_kwh > 0),
    CONSTRAINT ck_veh_status  CHECK (status IN ('ACTIVE','SOLD')),
    CONSTRAINT fk_veh_user    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- CHARGING_SESSIONS
CREATE TABLE charging_sessions (
    session_id    NUMBER(10)   PRIMARY KEY,
    charger_id    NUMBER(8)    NOT NULL,
    vehicle_id    NUMBER(8)    NOT NULL,
    user_id       NUMBER(8)    NOT NULL,
    start_time    TIMESTAMP    NOT NULL,
    end_time      TIMESTAMP,
    energy_kwh    NUMBER(8,2),
    price_per_kwh NUMBER(8,4)  NOT NULL,
    total_amount  NUMBER(10,2),
    status        VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL,
    CONSTRAINT ck_ss_status CHECK (status IN ('ACTIVE','COMPLETED','CANCELLED')),
    CONSTRAINT ck_ss_price  CHECK (price_per_kwh > 0),
    CONSTRAINT fk_ss_charger FOREIGN KEY (charger_id) REFERENCES chargers(charger_id),
    CONSTRAINT fk_ss_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    CONSTRAINT fk_ss_user    FOREIGN KEY (user_id)    REFERENCES users(user_id)
);

-- PAYMENTS
CREATE TABLE payments (
    payment_id NUMBER(10)   PRIMARY KEY,
    session_id NUMBER(10)   NOT NULL,
    user_id    NUMBER(8)    NOT NULL,
    amount     NUMBER(10,2) NOT NULL,
    pay_method VARCHAR2(30) DEFAULT 'WALLET' NOT NULL,
    pay_date   DATE         DEFAULT SYSDATE NOT NULL,
    status     VARCHAR2(20) DEFAULT 'PAID' NOT NULL,
    CONSTRAINT ck_pay_method CHECK (pay_method IN ('WALLET','CARD','APP')),
    CONSTRAINT ck_pay_status CHECK (status IN ('PAID','PENDING','FAILED','REFUNDED')),
    CONSTRAINT ck_pay_amount CHECK (amount > 0),
    CONSTRAINT fk_pay_session FOREIGN KEY (session_id) REFERENCES charging_sessions(session_id),
    CONSTRAINT fk_pay_user    FOREIGN KEY (user_id)    REFERENCES users(user_id)
);

-- Sequences (auto-generate primary keys)
CREATE SEQUENCE seq_country  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_city     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_operator START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_station  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_ctype    START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_charger  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_user     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_vehicle  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_session  START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_payment  START WITH 1 INCREMENT BY 1;



-- STEP 2 :  INSERT DATA  

-- Countries
INSERT INTO countries VALUES (seq_country.NEXTVAL, 'Sri Lanka',    'LKA', 'LKR');
INSERT INTO countries VALUES (seq_country.NEXTVAL, 'Germany',      'DEU', 'EUR');
INSERT INTO countries VALUES (seq_country.NEXTVAL, 'United States','USA', 'USD');
INSERT INTO countries VALUES (seq_country.NEXTVAL, 'Japan',        'JPN', 'JPY');
INSERT INTO countries VALUES (seq_country.NEXTVAL, 'Norway',       'NOR', 'NOK');

-- Cities
INSERT INTO cities VALUES (seq_city.NEXTVAL, 'Colombo',  1);
INSERT INTO cities VALUES (seq_city.NEXTVAL, 'Kandy',    1);
INSERT INTO cities VALUES (seq_city.NEXTVAL, 'Galle',    1);
INSERT INTO cities VALUES (seq_city.NEXTVAL, 'Berlin',   2);
INSERT INTO cities VALUES (seq_city.NEXTVAL, 'New York', 3);
INSERT INTO cities VALUES (seq_city.NEXTVAL, 'Tokyo',    4);
INSERT INTO cities VALUES (seq_city.NEXTVAL, 'Oslo',     5);

-- Operators
INSERT INTO operators VALUES (seq_operator.NEXTVAL, 'VoltGrid Lanka',   'info@voltgrid.lk',   '+94112222222', 12, 'ACTIVE');
INSERT INTO operators VALUES (seq_operator.NEXTVAL, 'FastCharge Europe','ops@fastcharge.de',  '+49301234567', 15, 'ACTIVE');
INSERT INTO operators VALUES (seq_operator.NEXTVAL, 'Nordic Charge AS', 'hi@nordiccharge.no', '+4722000000',  13, 'ACTIVE');
INSERT INTO operators VALUES (seq_operator.NEXTVAL, 'SolarVolt Lanka',  'solar@solarvolt.lk', '+94771111111',  8, 'ACTIVE');

-- Charger Types
INSERT INTO charger_types VALUES (seq_ctype.NEXTVAL, 'AC Level 2',        'Type2',    22.0, 'FAST');
INSERT INTO charger_types VALUES (seq_ctype.NEXTVAL, 'DC Fast (CCS)',      'CCS',     150.0, 'FAST');
INSERT INTO charger_types VALUES (seq_ctype.NEXTVAL, 'DC Ultra (CCS)',     'CCS',     350.0, 'ULTRA_FAST');
INSERT INTO charger_types VALUES (seq_ctype.NEXTVAL, 'CHAdeMO',            'CHAdeMO', 100.0, 'FAST');
INSERT INTO charger_types VALUES (seq_ctype.NEXTVAL, 'Tesla Supercharger', 'Tesla',   250.0, 'ULTRA_FAST');

-- Stations
INSERT INTO stations VALUES (seq_station.NEXTVAL, 'VS Colombo Central', 1, 1, '120 Galle Rd, Colombo',      'PUBLIC',  4.5, 'OPEN');
INSERT INTO stations VALUES (seq_station.NEXTVAL, 'VS Kandy Town',      4, 2, '10 Dalada Veediya, Kandy',   'PUBLIC',  4.2, 'OPEN');
INSERT INTO stations VALUES (seq_station.NEXTVAL, 'VS Galle Solar Hub', 4, 3, 'Marine Drive, Galle',        'PUBLIC',  4.3, 'OPEN');
INSERT INTO stations VALUES (seq_station.NEXTVAL, 'FastCharge Berlin',  2, 4, 'Unter den Linden 1, Berlin', 'PUBLIC',  4.8, 'OPEN');
INSERT INTO stations VALUES (seq_station.NEXTVAL, 'Nordic Oslo Fjord',  3, 7, 'Aker Brygge, Oslo',          'HIGHWAY', 4.9, 'OPEN');
INSERT INTO stations VALUES (seq_station.NEXTVAL, 'VS Airport Colombo', 1, 1, 'BIA Road, Katunayake',       'PUBLIC',  4.4, 'OPEN');

-- Chargers
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 1, 2, 'VS-LK-01-C1', 150.0, 'AVAILABLE');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 1, 2, 'VS-LK-01-C2', 150.0, 'IN_USE');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 1, 1, 'VS-LK-01-C3',  22.0, 'AVAILABLE');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 2, 1, 'VS-LK-02-C1',  22.0, 'AVAILABLE');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 2, 2, 'VS-LK-02-C2', 150.0, 'FAULTED');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 3, 1, 'VS-LK-03-C1',  22.0, 'AVAILABLE');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 4, 3, 'VS-DE-04-C1', 350.0, 'AVAILABLE');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 4, 3, 'VS-DE-04-C2', 350.0, 'IN_USE');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 5, 3, 'VS-NO-05-C1', 350.0, 'AVAILABLE');
INSERT INTO chargers VALUES (seq_charger.NEXTVAL, 6, 2, 'VS-LK-06-C1', 150.0, 'AVAILABLE');

-- Users
INSERT INTO users VALUES (seq_user.NEXTVAL, 'Kavinda Perera',   'kavinda@gmail.com', '+94771111111', 1, 'GOLD',     125.50, 'ACTIVE');
INSERT INTO users VALUES (seq_user.NEXTVAL, 'Nirasha Fernando', 'nirasha@email.lk',  '+94712222222', 1, 'SILVER',    55.00, 'ACTIVE');
INSERT INTO users VALUES (seq_user.NEXTVAL, 'Thilini Bandara',  'thilini@slt.lk',    '+94762222222', 1, 'BASIC',     18.00, 'ACTIVE');
INSERT INTO users VALUES (seq_user.NEXTVAL, 'Hans Mueller',     'hans@web.de',        '+49301111111', 2, 'PLATINUM', 320.00, 'ACTIVE');
INSERT INTO users VALUES (seq_user.NEXTVAL, 'Erik Andersen',    'erik@no.com',        '+4790000001',  5, 'PLATINUM', 500.00, 'ACTIVE');
INSERT INTO users VALUES (seq_user.NEXTVAL, 'Ashan Wijesinghe', 'ashan@email.lk',     '+94755555555', 1, 'SILVER',    42.00, 'ACTIVE');
INSERT INTO users VALUES (seq_user.NEXTVAL, 'Chamari Nonis',    'chamari@email.lk',   '+94744444444', 1, 'GOLD',      98.00, 'ACTIVE');
INSERT INTO users VALUES (seq_user.NEXTVAL, 'Roshan Dias',      'roshan@email.lk',    '+94733333333', 1, 'BASIC',      5.00, 'SUSPENDED');

-- Vehicles
INSERT INTO vehicles VALUES (seq_vehicle.NEXTVAL, 1, 'Tesla',   'Model 3', 'CAR-001', 82.0, 'CCS',     'ACTIVE');
INSERT INTO vehicles VALUES (seq_vehicle.NEXTVAL, 2, 'Nissan',  'Leaf',    'CAR-002', 40.0, 'CHAdeMO', 'ACTIVE');
INSERT INTO vehicles VALUES (seq_vehicle.NEXTVAL, 3, 'Kia',     'EV6',     'CAR-003', 77.4, 'CCS',     'ACTIVE');
INSERT INTO vehicles VALUES (seq_vehicle.NEXTVAL, 4, 'BMW',     'i4',      'B-MU-01', 83.9, 'CCS',     'ACTIVE');
INSERT INTO vehicles VALUES (seq_vehicle.NEXTVAL, 5, 'Audi',    'e-tron',  'N-EV-01', 95.0, 'CCS',     'ACTIVE');
INSERT INTO vehicles VALUES (seq_vehicle.NEXTVAL, 6, 'Hyundai', 'Ioniq 6', 'CAR-006', 77.4, 'CCS',     'ACTIVE');
INSERT INTO vehicles VALUES (seq_vehicle.NEXTVAL, 7, 'MG',      'ZS EV',   'CAR-007', 51.0, 'CCS',     'ACTIVE');

-- Charging Sessions
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 1,  1, 1, TIMESTAMP '2025-01-10 09:00:00', TIMESTAMP '2025-01-10 09:35:00',  50.0, 0.045,   2.25, 'COMPLETED');
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 3,  2, 2, TIMESTAMP '2025-01-11 14:00:00', TIMESTAMP '2025-01-11 15:20:00',  28.0, 0.042,   1.18, 'COMPLETED');
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 7,  4, 4, TIMESTAMP '2025-01-12 08:00:00', TIMESTAMP '2025-01-12 08:50:00',  60.0, 0.550,  33.00, 'COMPLETED');
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 9,  5, 5, TIMESTAMP '2025-01-13 07:00:00', TIMESTAMP '2025-01-13 08:00:00',  80.0, 3.200, 256.00, 'COMPLETED');
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 4,  3, 3, TIMESTAMP '2025-01-14 10:00:00', TIMESTAMP '2025-01-14 11:10:00',  30.0, 0.042,   1.26, 'COMPLETED');
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 10, 6, 6, TIMESTAMP '2025-01-15 16:00:00', TIMESTAMP '2025-01-15 16:40:00',  44.0, 0.045,   1.98, 'COMPLETED');
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 1,  7, 7, TIMESTAMP '2025-01-16 09:30:00', TIMESTAMP '2025-01-16 10:10:00',  36.0, 0.045,   1.62, 'COMPLETED');
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 7,  4, 4, TIMESTAMP '2025-01-17 13:00:00', TIMESTAMP '2025-01-17 13:55:00',  58.0, 0.550,  31.90, 'COMPLETED');
-- Active session (still in progress, no end time)
INSERT INTO charging_sessions VALUES (seq_session.NEXTVAL, 3,  1, 1, TIMESTAMP '2025-01-20 09:00:00', NULL, NULL, 0.045, NULL, 'ACTIVE');

-- Payments
INSERT INTO payments VALUES (seq_payment.NEXTVAL, 1, 1,   2.25, 'WALLET', DATE '2025-01-10', 'PAID');
INSERT INTO payments VALUES (seq_payment.NEXTVAL, 2, 2,   1.18, 'WALLET', DATE '2025-01-11', 'PAID');
INSERT INTO payments VALUES (seq_payment.NEXTVAL, 3, 4,  33.00, 'CARD',   DATE '2025-01-12', 'PAID');
INSERT INTO payments VALUES (seq_payment.NEXTVAL, 4, 5, 256.00, 'APP',    DATE '2025-01-13', 'PAID');
INSERT INTO payments VALUES (seq_payment.NEXTVAL, 5, 3,   1.26, 'WALLET', DATE '2025-01-14', 'PAID');
INSERT INTO payments VALUES (seq_payment.NEXTVAL, 6, 6,   1.98, 'WALLET', DATE '2025-01-15', 'PAID');
INSERT INTO payments VALUES (seq_payment.NEXTVAL, 7, 7,   1.62, 'WALLET', DATE '2025-01-16', 'PAID');
INSERT INTO payments VALUES (seq_payment.NEXTVAL, 8, 4,  31.90, 'CARD',   DATE '2025-01-17', 'PAID');

COMMIT;

-- STEP 3 :  SELECT QUERIES  
-- Q1 : WHERE + JOIN
-- Show all AVAILABLE chargers with station and city.
SELECT  ch.charger_code,
        ct.type_name,
        ch.power_kw,
        st.station_name,
        ci.city_name,
        ch.status
FROM    chargers      ch
JOIN    charger_types ct ON ch.type_id    = ct.type_id
JOIN    stations      st ON ch.station_id = st.station_id
JOIN    cities        ci ON st.city_id    = ci.city_id
WHERE   ch.status = 'AVAILABLE'
ORDER BY ch.power_kw DESC;


-- Q2 : AND + OR + JOIN + ORDER BY
-- Find GOLD or PLATINUM users with wallet balance above $50.
SELECT  u.full_name,
        u.member_tier,
        u.wallet_bal,
        co.country_name
FROM    users     u
JOIN    countries co ON u.country_id = co.country_id
WHERE   (u.member_tier = 'GOLD' OR u.member_tier = 'PLATINUM')
  AND   u.wallet_bal > 50
ORDER BY u.wallet_bal DESC;


-- Q3 : LIKE + JOIN + WHERE
-- Find all stations whose name starts with 'VS'.
SELECT  st.station_name,
        st.station_type,
        st.rating,
        o.operator_name,
        ci.city_name
FROM    stations  st
JOIN    operators o  ON st.operator_id = o.operator_id
JOIN    cities    ci ON st.city_id     = ci.city_id
WHERE   st.station_name LIKE 'VS%'
ORDER BY st.rating DESC;


-- Q4 : GROUP BY + ORDER BY + JOIN
-- Count chargers per station and show total installed power.
SELECT  st.station_name,
        COUNT(ch.charger_id) AS total_chargers,
        SUM(ch.power_kw)     AS total_power_kw,
        AVG(ch.power_kw)     AS avg_power_kw
FROM    stations  st
LEFT JOIN chargers ch ON st.station_id = ch.station_id
GROUP BY st.station_name
ORDER BY total_chargers DESC;


-- Q5 : GROUP BY + HAVING + ORDER BY
-- Show users who completed more than 1 charging session.
SELECT  u.full_name,
        u.member_tier,
        COUNT(cs.session_id)           AS total_sessions,
        ROUND(SUM(cs.energy_kwh),  2)  AS total_kwh,
        ROUND(SUM(cs.total_amount), 2) AS total_spent
FROM    users             u
JOIN    charging_sessions cs ON u.user_id = cs.user_id
WHERE   cs.status = 'COMPLETED'
GROUP BY u.full_name, u.member_tier
HAVING  COUNT(cs.session_id) > 1
ORDER BY total_spent DESC;


-- Q6 : CASE statement
-- Classify each charger by speed and show a readable status label.
SELECT  ch.charger_code,
        ch.power_kw,
        st.station_name,
        CASE
            WHEN ch.power_kw >= 200 THEN 'Ultra Fast'
            WHEN ch.power_kw >= 50  THEN 'Fast'
            WHEN ch.power_kw >= 11  THEN 'Standard'
            ELSE                         'Slow'
        END AS speed_category,
        CASE ch.status
            WHEN 'AVAILABLE' THEN 'Ready to use'
            WHEN 'IN_USE'    THEN 'Occupied'
            WHEN 'FAULTED'   THEN 'Out of service'
            ELSE                  'Offline'
        END AS status_label
FROM    chargers ch
JOIN    stations st ON ch.station_id = st.station_id
ORDER BY ch.power_kw DESC;


-- Q7 : IF/ELSE using DECODE
-- Check wallet health for every active user.
SELECT  u.full_name,
        u.member_tier,
        u.wallet_bal,
        DECODE(
            SIGN(u.wallet_bal - 20),
             1, 'Sufficient',
             0, 'Low - top up soon',
                'Critical - add funds now'
        ) AS wallet_status
FROM    users u
WHERE   u.status = 'ACTIVE'
ORDER BY u.wallet_bal ASC;


-- Q8 : GROUP BY + HAVING + SUM
-- Operator revenue report (only operators with revenue above $1).
SELECT  o.operator_name,
        COUNT(DISTINCT st.station_id)      AS total_stations,
        COUNT(cs.session_id)               AS total_sessions,
        ROUND(SUM(cs.total_amount), 2)     AS gross_revenue,
        ROUND(SUM(cs.total_amount)
              * o.commission_pct / 100, 2) AS commission_earned
FROM    operators         o
JOIN    stations          st ON st.operator_id = o.operator_id
JOIN    chargers          ch ON ch.station_id  = st.station_id
JOIN    charging_sessions cs ON cs.charger_id  = ch.charger_id
WHERE   cs.status = 'COMPLETED'
GROUP BY o.operator_name, o.commission_pct
HAVING  SUM(cs.total_amount) > 1
ORDER BY gross_revenue DESC;


-- Q9 : OR + WHERE + JOIN
-- Show all FAULTED or OFFLINE chargers with operator contact.
SELECT  ch.charger_code,
        ch.status,
        st.station_name,
        ci.city_name,
        o.operator_name,
        o.phone AS contact
FROM    chargers  ch
JOIN    stations  st ON ch.station_id  = st.station_id
JOIN    cities    ci ON st.city_id     = ci.city_id
JOIN    operators o  ON st.operator_id = o.operator_id
WHERE   ch.status = 'FAULTED'
   OR   ch.status = 'OFFLINE'
ORDER BY st.station_name;


-- Q10 : Multi-table JOIN
-- Full session details: driver, vehicle, charger, station, payment.
SELECT  cs.session_id,
        u.full_name                 AS driver,
        v.make || ' ' || v.model   AS vehicle,
        ch.charger_code,
        st.station_name,
        ci.city_name,
        cs.energy_kwh               AS kwh,
        cs.total_amount,
        p.pay_method,
        p.status                    AS payment_status
FROM    charging_sessions cs
JOIN    users             u  ON cs.user_id    = u.user_id
JOIN    vehicles          v  ON cs.vehicle_id = v.vehicle_id
JOIN    chargers          ch ON cs.charger_id = ch.charger_id
JOIN    stations          st ON ch.station_id = st.station_id
JOIN    cities            ci ON st.city_id    = ci.city_id
JOIN    payments          p  ON p.session_id  = cs.session_id
WHERE   cs.status = 'COMPLETED'
ORDER BY cs.session_id;



-- STEP 4 :  PL/SQL BLOCKS

-- BLOCK 1 : VARIABLES
-- Print a station summary using SELECT INTO and %TYPE variables.

DECLARE
    v_station_id     stations.station_id%TYPE  := 1;
    v_station_name   stations.station_name%TYPE;
    v_available      NUMBER := 0;
    v_in_use         NUMBER := 0;
    v_faulted        NUMBER := 0;
    v_total_sessions NUMBER := 0;
    v_total_revenue  NUMBER := 0;
BEGIN
    SELECT station_name
    INTO   v_station_name
    FROM   stations
    WHERE  station_id = v_station_id;

    SELECT SUM(CASE WHEN status = 'AVAILABLE' THEN 1 ELSE 0 END),
           SUM(CASE WHEN status = 'IN_USE'    THEN 1 ELSE 0 END),
           SUM(CASE WHEN status = 'FAULTED'   THEN 1 ELSE 0 END)
    INTO   v_available, v_in_use, v_faulted
    FROM   chargers
    WHERE  station_id = v_station_id;

    SELECT COUNT(*),
           NVL(ROUND(SUM(cs.total_amount), 2), 0)
    INTO   v_total_sessions, v_total_revenue
    FROM   charging_sessions cs
    JOIN   chargers ch ON cs.charger_id = ch.charger_id
    WHERE  ch.station_id = v_station_id
      AND  cs.status     = 'COMPLETED';

    DBMS_OUTPUT.PUT_LINE('=== STATION DASHBOARD ===');
    DBMS_OUTPUT.PUT_LINE('Station  : ' || v_station_name);
    DBMS_OUTPUT.PUT_LINE('Available: ' || v_available  || ' chargers');
    DBMS_OUTPUT.PUT_LINE('In Use   : ' || v_in_use     || ' chargers');
    DBMS_OUTPUT.PUT_LINE('Faulted  : ' || v_faulted    || ' chargers');
    DBMS_OUTPUT.PUT_LINE('Sessions : ' || v_total_sessions);
    DBMS_OUTPUT.PUT_LINE('Revenue  : $' || v_total_revenue);
END;
/


-- BLOCK 2 : EXPLICIT CURSOR  (OPEN / FETCH / CLOSE)
-- List all active users and their wallet balance.

DECLARE
    CURSOR c_users IS
        SELECT u.full_name, u.member_tier,
               u.wallet_bal, co.country_name
        FROM   users u
        JOIN   countries co ON u.country_id = co.country_id
        WHERE  u.status = 'ACTIVE'
        ORDER BY u.wallet_bal DESC;

    v_user  c_users%ROWTYPE;
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ACTIVE USERS WALLET REPORT ===');

    OPEN c_users;
    LOOP
        FETCH c_users INTO v_user;
        EXIT WHEN c_users%NOTFOUND;

        v_count := v_count + 1;
        DBMS_OUTPUT.PUT_LINE(
            v_count || '. '
            || v_user.full_name   || ' | '
            || v_user.member_tier || ' | '
            || '$' || v_user.wallet_bal || ' | '
            || v_user.country_name
        );
    END LOOP;
    CLOSE c_users;

    DBMS_OUTPUT.PUT_LINE('Total active users: ' || v_count);
END;
/



-- BLOCK 3 : EXCEPTION HANDLING
-- Look up a charger. Handle NO_DATA_FOUND and a custom exception.

DECLARE
    v_charger_id   chargers.charger_id%TYPE  := 99; -- does not exist
    v_charger_code chargers.charger_code%TYPE;
    v_station_name stations.station_name%TYPE;
    v_status       chargers.status%TYPE;

    e_faulted EXCEPTION; -- custom exception
BEGIN
    SELECT ch.charger_code, st.station_name, ch.status
    INTO   v_charger_code, v_station_name, v_status
    FROM   chargers ch
    JOIN   stations st ON ch.station_id = st.station_id
    WHERE  ch.charger_id = v_charger_id;

    IF v_status = 'FAULTED' THEN
        RAISE e_faulted;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Charger : ' || v_charger_code);
    DBMS_OUTPUT.PUT_LINE('Station : ' || v_station_name);
    DBMS_OUTPUT.PUT_LINE('Status  : ' || v_status);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Charger ' || v_charger_id || ' not found.');
    WHEN e_faulted THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: ' || v_charger_code || ' is FAULTED.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('UNEXPECTED ERROR: ' || SQLERRM);
END;
/



-- BLOCK 4 : FOR LOOP
-- Loop through all completed sessions and print a summary.

DECLARE
    v_count NUMBER := 0;
    v_total NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== COMPLETED SESSIONS ===');

    FOR rec IN (
        SELECT cs.session_id,
               u.full_name,
               cs.energy_kwh,
               cs.total_amount
        FROM   charging_sessions cs
        JOIN   users u ON cs.user_id = u.user_id
        WHERE  cs.status = 'COMPLETED'
        ORDER BY cs.session_id
    )
    LOOP
        v_count := v_count + 1;
        v_total := v_total + NVL(rec.total_amount, 0);

        DBMS_OUTPUT.PUT_LINE(
            'Session #' || rec.session_id
            || ' | ' || rec.full_name
            || ' | ' || rec.energy_kwh || ' kWh'
            || ' | $' || rec.total_amount
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('--------------------------');
    DBMS_OUTPUT.PUT_LINE('Total sessions : ' || v_count);
    DBMS_OUTPUT.PUT_LINE('Total revenue  : $' || ROUND(v_total, 2));
END;
/


-- STEP 5 :  STORED PROCEDURES  (Input / Output parameters)

-- PROCEDURE 1 : sp_start_session
-- Checks charger, user status, and wallet. Then starts a session.
-- INPUT  : charger_id, vehicle_id, user_id, price_per_kwh
-- OUTPUT : new session_id, status message

CREATE OR REPLACE PROCEDURE sp_start_session (
    p_charger_id    IN  NUMBER,
    p_vehicle_id    IN  NUMBER,
    p_user_id       IN  NUMBER,
    p_price_per_kwh IN  NUMBER,
    p_session_id    OUT NUMBER,
    p_message       OUT VARCHAR2
) AS
    v_ch_status chargers.status%TYPE;
    v_us_status users.status%TYPE;
    v_wallet    users.wallet_bal%TYPE;
BEGIN
    
    SELECT status INTO v_ch_status
    FROM   chargers WHERE charger_id = p_charger_id;

    IF v_ch_status != 'AVAILABLE' THEN
        p_session_id := -1;
        p_message    := 'FAILED: Charger is ' || v_ch_status;
        RETURN;
    END IF;

    
    SELECT status, wallet_bal INTO v_us_status, v_wallet
    FROM   users WHERE user_id = p_user_id;

    IF v_us_status = 'SUSPENDED' THEN
        p_session_id := -1;
        p_message    := 'FAILED: Account is suspended.';
        RETURN;
    END IF;

    IF v_wallet < 1.00 THEN
        p_session_id := -1;
        p_message    := 'FAILED: Wallet $' || v_wallet || ' too low (min $1).';
        RETURN;
    END IF;

    
    INSERT INTO charging_sessions
        (session_id, charger_id, vehicle_id, user_id,
         start_time, price_per_kwh, status)
    VALUES
        (seq_session.NEXTVAL, p_charger_id, p_vehicle_id, p_user_id,
         SYSTIMESTAMP, p_price_per_kwh, 'ACTIVE')
    RETURNING session_id INTO p_session_id;

    UPDATE chargers SET status = 'IN_USE'
    WHERE  charger_id = p_charger_id;

    p_message := 'SUCCESS: Session #' || p_session_id || ' started.';
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_session_id := -1;
        p_message    := 'ERROR: Charger or user not found.';
    WHEN OTHERS THEN
        p_session_id := -1;
        p_message    := 'SYSTEM ERROR: ' || SQLERRM;
        ROLLBACK;
END sp_start_session;
/

-- Test sp_start_session
DECLARE
    v_sid NUMBER;
    v_msg VARCHAR2(200);
BEGIN
    sp_start_session(1, 1, 1, 0.045, v_sid, v_msg);
    DBMS_OUTPUT.PUT_LINE('Result  : ' || v_msg);
    DBMS_OUTPUT.PUT_LINE('Session : ' || v_sid);
END;
/

-- PROCEDURE 2 : sp_end_session
-- Ends a session, applies member discount, deducts wallet,
-- saves payment record.
-- INPUT  : session_id, energy_kwh delivered
-- OUTPUT : total_amount charged, status message

CREATE OR REPLACE PROCEDURE sp_end_session (
    p_session_id   IN  NUMBER,
    p_energy_kwh   IN  NUMBER,
    p_total_amount OUT NUMBER,
    p_message      OUT VARCHAR2
) AS
    v_charger_id  charging_sessions.charger_id%TYPE;
    v_user_id     charging_sessions.user_id%TYPE;
    v_price       charging_sessions.price_per_kwh%TYPE;
    v_sess_status charging_sessions.status%TYPE;
    v_tier        users.member_tier%TYPE;
    v_discount    NUMBER := 0;
BEGIN
  
    SELECT charger_id, user_id, price_per_kwh, status
    INTO   v_charger_id, v_user_id, v_price, v_sess_status
    FROM   charging_sessions
    WHERE  session_id = p_session_id;

    
    IF v_sess_status != 'ACTIVE' THEN
        p_total_amount := 0;
        p_message := 'ERROR: Session is already ' || v_sess_status;
        RETURN;
    END IF;

    
    SELECT member_tier INTO v_tier
    FROM   users WHERE user_id = v_user_id;

    
    IF    v_tier = 'PLATINUM' THEN v_discount := 0.15;
    ELSIF v_tier = 'GOLD'     THEN v_discount := 0.10;
    ELSIF v_tier = 'SILVER'   THEN v_discount := 0.05;
    ELSE                           v_discount := 0;
    END IF;

    
    p_total_amount := ROUND(p_energy_kwh * v_price * (1 - v_discount), 2);


    UPDATE charging_sessions
    SET    end_time     = SYSTIMESTAMP,
           energy_kwh   = p_energy_kwh,
           total_amount = p_total_amount,
           status       = 'COMPLETED'
    WHERE  session_id = p_session_id;


    UPDATE chargers SET status = 'AVAILABLE'
    WHERE  charger_id = v_charger_id;


    UPDATE users SET wallet_bal = wallet_bal - p_total_amount
    WHERE  user_id = v_user_id;


    INSERT INTO payments (payment_id, session_id, user_id,
                          amount, pay_method, pay_date, status)
    VALUES (seq_payment.NEXTVAL, p_session_id, v_user_id,
            p_total_amount, 'WALLET', SYSDATE, 'PAID');

    p_message := 'SUCCESS: ' || p_energy_kwh || ' kWh'
                 || ' | Tier: '     || v_tier
                 || ' | Discount: ' || (v_discount * 100) || '%'
                 || ' | Total: $'   || p_total_amount;
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_total_amount := 0;
        p_message := 'ERROR: Session ' || p_session_id || ' not found.';
    WHEN OTHERS THEN
        p_total_amount := 0;
        p_message := 'SYSTEM ERROR: ' || SQLERRM;
        ROLLBACK;
END sp_end_session;
/


DECLARE
    v_amount NUMBER;
    v_msg    VARCHAR2(200);
BEGIN
    sp_end_session(9, 42.5, v_amount, v_msg);
    DBMS_OUTPUT.PUT_LINE('Result : ' || v_msg);
    DBMS_OUTPUT.PUT_LINE('Amount : $' || v_amount);
END;
/

-- PROCEDURE 3 : sp_station_report


CREATE OR REPLACE PROCEDURE sp_station_report (
    p_station_id     IN  NUMBER,
    p_total_sessions OUT NUMBER,
    p_total_revenue  OUT NUMBER,
    p_message        OUT VARCHAR2
) AS
    v_station_name stations.station_name%TYPE;
BEGIN
    SELECT station_name INTO v_station_name
    FROM   stations WHERE station_id = p_station_id;

    SELECT COUNT(cs.session_id),
           NVL(ROUND(SUM(cs.total_amount), 2), 0)
    INTO   p_total_sessions, p_total_revenue
    FROM   charging_sessions cs
    JOIN   chargers ch ON cs.charger_id = ch.charger_id
    WHERE  ch.station_id = p_station_id
      AND  cs.status     = 'COMPLETED';

    DBMS_OUTPUT.PUT_LINE('=== REPORT: ' || v_station_name || ' ===');
    FOR rec IN (
        SELECT cs.session_id, u.full_name,
               cs.energy_kwh, cs.total_amount
        FROM   charging_sessions cs
        JOIN   chargers ch ON cs.charger_id = ch.charger_id
        JOIN   users     u ON cs.user_id    = u.user_id
        WHERE  ch.station_id = p_station_id
          AND  cs.status     = 'COMPLETED'
        ORDER BY cs.session_id
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            '#' || rec.session_id
            || ' | ' || rec.full_name
            || ' | ' || rec.energy_kwh || ' kWh'
            || ' | $' || rec.total_amount
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Total: ' || p_total_sessions
                         || ' sessions | $' || p_total_revenue);
    p_message := 'Done: ' || v_station_name;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_message := 'ERROR: Station ' || p_station_id || ' not found.';
END sp_station_report;
/


DECLARE
    v_sessions NUMBER;
    v_revenue  NUMBER;
    v_msg      VARCHAR2(200);
BEGIN
    sp_station_report(1, v_sessions, v_revenue, v_msg);
    DBMS_OUTPUT.PUT_LINE(v_msg);
END;
/


-- STEP 6 :  ROLES & PRIVILEGES  (Security)


CREATE ROLE role_driver;
CREATE ROLE role_operator;
CREATE ROLE role_analyst;
CREATE ROLE role_admin;


GRANT SELECT         ON countries         TO role_driver;
GRANT SELECT         ON cities            TO role_driver;
GRANT SELECT         ON stations          TO role_driver;
GRANT SELECT         ON chargers          TO role_driver;
GRANT SELECT         ON charger_types     TO role_driver;
GRANT SELECT, INSERT ON charging_sessions TO role_driver;
GRANT SELECT, INSERT ON payments          TO role_driver;
GRANT SELECT, UPDATE ON vehicles          TO role_driver;
GRANT SELECT, UPDATE ON users             TO role_driver;
GRANT EXECUTE        ON sp_start_session  TO role_driver;
GRANT EXECUTE        ON sp_end_session    TO role_driver;


GRANT SELECT, UPDATE ON stations          TO role_operator;
GRANT SELECT, UPDATE ON chargers          TO role_operator;
GRANT SELECT         ON charging_sessions TO role_operator;
GRANT EXECUTE        ON sp_station_report TO role_operator;


GRANT SELECT ON countries         TO role_analyst;
GRANT SELECT ON cities            TO role_analyst;
GRANT SELECT ON operators         TO role_analyst;
GRANT SELECT ON stations          TO role_analyst;
GRANT SELECT ON charger_types     TO role_analyst;
GRANT SELECT ON chargers          TO role_analyst;
GRANT SELECT ON users             TO role_analyst;
GRANT SELECT ON vehicles          TO role_analyst;
GRANT SELECT ON charging_sessions TO role_analyst;
GRANT SELECT ON payments          TO role_analyst;
GRANT EXECUTE ON sp_station_report TO role_analyst;


GRANT SELECT, INSERT, UPDATE, DELETE ON countries         TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON cities            TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON operators         TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON stations          TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON charger_types     TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON chargers          TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON users             TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON vehicles          TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON charging_sessions TO role_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON payments          TO role_admin;
GRANT EXECUTE ON sp_start_session  TO role_admin;
GRANT EXECUTE ON sp_end_session    TO role_admin;
GRANT EXECUTE ON sp_station_report TO role_admin;

