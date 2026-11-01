SET ECHO ON
SPOOL ml2_data_insert_spool.txt
SET LINESIZE 200
SET PAGESIZE 100
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

-- step 4: populate the object tables (3-4 objects per table)
-- Load order follows the REFs: a row must exist before anything
-- points at it (advisors -> clients -> accounts -> securities -> price records -> orders -> fills -> holdings)

-- Advisors (BR 5)
INSERT INTO Advisor_obj_tab VALUES (
    Advisor_t(
        1,
        'Laura Bennett',
        'laura.bennett@brokersinteractive.ca',
        '416-555-0101',
        'REG-10021'
    ));
INSERT INTO Advisor_obj_tab VALUES (
    Advisor_t(
        2,
        'Marcus Chen',
        'marcus.chen@brokersinteractive.ca',
        '416-555-0102',
        'REG-10034'
    ));
INSERT INTO Advisor_obj_tab VALUES (
    Advisor_t(
        3,
        'Priya Nair',
        'priya.nair@brokersinteractive.ca',
        '416-555-0103',
        'REG-10057'
    ));

-- Clients (BR 2, 3, 4): all 18+, exactly one advisor each, risk tolerance is LOW, MEDIUM or HIGH
INSERT INTO Client_obj_tab VALUES (
    Client_t(
        1,
        'Daniel Foster',
        DATE '1980-05-14',
        'daniel.foster@mail.com',
        '416-555-0111',
        '12 Maple St, Toronto',
        'MEDIUM',
        (SELECT REF(a) FROM Advisor_obj_tab a WHERE a.advisorNo = 1)
    ));
INSERT INTO Client_obj_tab VALUES (
    Client_t(
        2,
        'Sofia Ramirez',
        DATE '1992-11-02',
        'sofia.ramirez@mail.com',
        '416-555-0112',
        '88 Queen St W, Toronto',
        'HIGH',
        (SELECT REF(a) FROM Advisor_obj_tab a WHERE a.advisorNo = 1)
    ));
INSERT INTO Client_obj_tab VALUES (
    Client_t(
        3,
        'James Okafor',
        DATE '1975-07-23',
        'james.okafor@mail.com',
        '416-555-0113',
        '5 Bay St, Toronto',
        'LOW',
        (SELECT REF(a) FROM Advisor_obj_tab a WHERE a.advisorNo = 2)
    ));
INSERT INTO Client_obj_tab VALUES (
    Client_t(
        4,
        'Emily Tran',
        DATE '2001-01-30',
        'emily.tran@mail.com',
        '416-555-0114',
        '230 King St E, Toronto',
        'MEDIUM',
        (SELECT REF(a) FROM Advisor_obj_tab a WHERE a.advisorNo = 3)
    ));

-- Accounts (BR 1, 6): type is CASH, TFSA or RRSP; status is ACTIVE, FROZEN or CLOSED; every client owns at least one
INSERT INTO Account_obj_tab VALUES (
    Account_t(
        1001,
        DATE '2020-02-10',
        25000.00,
        'TFSA',
        'ACTIVE',
        (SELECT REF(c) FROM Client_obj_tab c WHERE c.clientNo = 1)
    ));
INSERT INTO Account_obj_tab VALUES (
    Account_t(
        1002,
        DATE '2021-06-15',
        8500.50,
        'CASH',
        'ACTIVE',
        (SELECT REF(c) FROM Client_obj_tab c WHERE c.clientNo = 2)
    ));
INSERT INTO Account_obj_tab VALUES (
    Account_t(
        1003,
        DATE '2019-09-01',
        120000.00,
        'RRSP',
        'ACTIVE',
        (SELECT REF(c) FROM Client_obj_tab c WHERE c.clientNo = 3)
    ));
INSERT INTO Account_obj_tab VALUES (
    Account_t(
        1004,
        DATE '2023-03-20',
        0.00,
        'CASH',
        'FROZEN',
        (SELECT REF(c) FROM Client_obj_tab c WHERE c.clientNo = 4)
    ));

-- Common stocks (BR 9, 10, 17): trading status ACTIVE, HALTED or DELISTED
INSERT INTO CommonStock_obj_tab VALUES (
    CommonStock_t(
        'AAPL',
        'Apple Inc.',
        'ACTIVE',
        15000000000,
        6.43
    ));
INSERT INTO CommonStock_obj_tab VALUES (
    CommonStock_t(
        'MSFT',
        'Microsoft Corp.',
        'ACTIVE',
        7430000000,
        11.80
    ));
INSERT INTO CommonStock_obj_tab VALUES (
    CommonStock_t(
        'TSLA',
        'Tesla Inc.',
        'HALTED',
        3170000000,
        3.65
    ));

-- ETFs (BR 9, 10, 19): URTH is DELISTED so all three statuses appear
INSERT INTO ETF_obj_tab VALUES (
    ETF_t(
        'QQQ',
        'Invesco QQQ Trust',
        'ACTIVE',
        'NASDAQ-100',
        0.0020,
        DATE '1999-03-10'
    ));
INSERT INTO ETF_obj_tab VALUES (
    ETF_t(
        'VTI',
        'Vanguard Total Stock Market',
        'ACTIVE',
        'CRSP US Total Market',
        0.0003,
        DATE '2001-05-24'
    ));
INSERT INTO ETF_obj_tab VALUES (
    ETF_t(
        'URTH',
        'iShares MSCI World ETF',
        'DELISTED',
        'MSCI World',
        0.0024,
        DATE '2012-01-10'
    ));

-- Price records (BR 21): one record per ACTIVE security for the trading day 2026-10-30 (TSLA is halted and URTH delisted, so none)
INSERT INTO PriceRecord_obj_tab VALUES (
    PriceRecord_t(
        1,
        DATE '2026-10-30',
        226.10,
        229.10,
        225.80,
        228.45,
        48210000,
        (SELECT REF(s) FROM CommonStock_obj_tab s WHERE s.tickerSymbol = 'AAPL')
    ));
INSERT INTO PriceRecord_obj_tab VALUES (
    PriceRecord_t(
        2,
        DATE '2026-10-30',
        414.00,
        415.30,
        410.90,
        411.20,
        21530000,
        (SELECT REF(s) FROM CommonStock_obj_tab s WHERE s.tickerSymbol = 'MSFT')
    ));
INSERT INTO PriceRecord_obj_tab VALUES (
    PriceRecord_t(
        3,
        DATE '2026-10-30',
        444.20,
        447.90,
        443.10,
        446.85,
        36870000,
        (SELECT REF(e) FROM ETF_obj_tab e WHERE e.tickerSymbol = 'QQQ')
    ));
INSERT INTO PriceRecord_obj_tab VALUES (
    PriceRecord_t(
        4,
        DATE '2026-10-30',
        271.40,
        272.05,
        270.10,
        270.95,
        3410000,
        (SELECT REF(e) FROM ETF_obj_tab e WHERE e.tickerSymbol = 'VTI')
    ));

-- Orders (BR 7, 8, 11, 23-28): only ACTIVE accounts, only ACTIVE securities; limit price only on LIMIT orders; order 5002 was
-- entered by the client herself, so no advisor is recorded (0..1)
INSERT INTO Order_obj_tab VALUES (
    Order_t(
        5001,
        'BUY',
        'LIMIT',
        100,
        TIMESTAMP '2026-10-26 09:35:00',
        9.99,
        'FILLED',
        225.50,
        (SELECT REF(a) FROM Account_obj_tab a WHERE a.accountNo = 1001),
        (SELECT REF(s) FROM CommonStock_obj_tab s WHERE s.tickerSymbol = 'AAPL'),
        (SELECT REF(v) FROM Advisor_obj_tab v WHERE v.advisorNo = 1)
    ));
INSERT INTO Order_obj_tab VALUES (
    Order_t(
        5002,
        'BUY',
        'LIMIT',
        50,
        TIMESTAMP '2026-10-26 10:05:00',
        9.99,
        'PARTIALLY_FILLED',
        410.40,
        (SELECT REF(a) FROM Account_obj_tab a WHERE a.accountNo = 1002),
        (SELECT REF(s) FROM CommonStock_obj_tab s WHERE s.tickerSymbol = 'MSFT'),
        NULL
    ));
INSERT INTO Order_obj_tab VALUES (
    Order_t(
        5003,
        'SELL',
        'LIMIT',
        200,
        TIMESTAMP '2026-10-27 14:20:00',
        14.99,
        'OPEN',
        450.00,
        (SELECT REF(a) FROM Account_obj_tab a WHERE a.accountNo = 1003),
        (SELECT REF(e) FROM ETF_obj_tab e WHERE e.tickerSymbol = 'QQQ'),
        (SELECT REF(v) FROM Advisor_obj_tab v WHERE v.advisorNo = 2)
    ));
INSERT INTO Order_obj_tab VALUES (
    Order_t(
        5004,
        'BUY',
        'MARKET',
        75,
        TIMESTAMP '2026-10-28 11:45:00',
        9.99,
        'FILLED',
        NULL,
        (SELECT REF(a) FROM Account_obj_tab a WHERE a.accountNo = 1003),
        (SELECT REF(e) FROM ETF_obj_tab e WHERE e.tickerSymbol = 'VTI'),
        (SELECT REF(v) FROM Advisor_obj_tab v WHERE v.advisorNo = 2)
    ));

-- Fills (BR 26, 29-32): buy-limit fills at or below the limit price; total filled never exceeds the quantity ordered (5002: 42 of 50)
INSERT INTO Fill_obj_tab VALUES (
    Fill_t(
        9001,
        100,
        225.30,
        TIMESTAMP '2026-10-26 09:36:12',
        (SELECT REF(o) FROM Order_obj_tab o WHERE o.orderNo = 5001)
    ));
INSERT INTO Fill_obj_tab VALUES (
    Fill_t(
        9002,
        30,
        410.15,
        TIMESTAMP '2026-10-26 10:05:40',
        (SELECT REF(o) FROM Order_obj_tab o WHERE o.orderNo = 5002)
    ));
INSERT INTO Fill_obj_tab VALUES (
    Fill_t(
        9003,
        12,
        410.40,
        TIMESTAMP '2026-10-26 10:07:02',
        (SELECT REF(o) FROM Order_obj_tab o WHERE o.orderNo = 5002)
    ));
INSERT INTO Fill_obj_tab VALUES (
    Fill_t(
        9004,
        75,
        269.80,
        TIMESTAMP '2026-10-28 11:46:05',
        (SELECT REF(o) FROM Order_obj_tab o WHERE o.orderNo = 5004)
    ));

-- Holdings (BR 28, 34, 35): the MSFT average cost is the weighteaverage of fills 9002 and 9003; the QQQ holding (400) covers the
-- open sell order for 200
INSERT INTO Holding_obj_tab VALUES (
    Holding_t(
        1,
        (SELECT REF(a) FROM Account_obj_tab a WHERE a.accountNo = 1001),
        (SELECT REF(s) FROM CommonStock_obj_tab s WHERE s.tickerSymbol = 'AAPL'),
        350,
        190.75,
        DATE '2020-03-02'
    ));
INSERT INTO Holding_obj_tab VALUES (
    Holding_t(
        2,
        (SELECT REF(a) FROM Account_obj_tab a WHERE a.accountNo = 1002),
        (SELECT REF(s) FROM CommonStock_obj_tab s WHERE s.tickerSymbol = 'MSFT'),
        42,
        410.22,
        DATE '2026-10-26'
    ));
INSERT INTO Holding_obj_tab VALUES (
    Holding_t(
        3,
        (SELECT REF(a) FROM Account_obj_tab a WHERE a.accountNo = 1003),
        (SELECT REF(e) FROM ETF_obj_tab e WHERE e.tickerSymbol = 'QQQ'),
        400,
        380.10,
        DATE '2019-11-18'
    ));
INSERT INTO Holding_obj_tab VALUES (
    Holding_t(
        4,
        (SELECT REF(a) FROM Account_obj_tab a WHERE a.accountNo = 1003),
        (SELECT REF(e) FROM ETF_obj_tab e WHERE e.tickerSymbol = 'VTI'),
        275,
        245.60,
        DATE '2023-01-09'
    ));

COMMIT;

SPOOL OFF