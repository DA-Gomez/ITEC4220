SET ECHO ON
SPOOL ml2_data_insert_spool.txt APPEND
SET LINESIZE 200
SET PAGESIZE 100
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

-- step 5: demonstrate that every object table is populated
-- Tables that hold REFs are displayed by following the REFs with dot notation, not with joins.
COLUMN name              FORMAT A28
COLUMN email             FORMAT A36
COLUMN phone             FORMAT A12
COLUMN address           FORMAT A24
COLUMN registrationNo    FORMAT A14
COLUMN client            FORMAT A15
COLUMN advisor           FORMAT A15
COLUMN ticker            FORMAT A6
COLUMN acct_type         FORMAT A9
COLUMN order_type        FORMAT A10
COLUMN side              FORMAT A4
COLUMN status            FORMAT A16
COLUMN trackedIndex      FORMAT A22
COLUMN sharesOutstanding FORMAT 99,999,999,999
COLUMN expenseRatio      FORMAT 0.0000

-- Advisor_obj_tab
SELECT a.advisorNo, a.name, a.email, a.phone, a.registrationNo
FROM   Advisor_obj_tab a
ORDER  BY a.advisorNo;

-- Client_obj_tab (follows advisorRef)
SELECT c.clientNo, c.name, c.dateOfBirth, c.email, c.phone, c.address,
    c.riskTolerance, c.advisorRef.name AS advisor
FROM   Client_obj_tab c
ORDER  BY c.clientNo;

-- Account_obj_tab (follows clientRef)
SELECT a.accountNo, a.openingDate, a.cashBalance, a.type AS acct_type,
    a.status, a.clientRef.name AS client
FROM   Account_obj_tab a
ORDER  BY a.accountNo;

-- CommonStock_obj_tab
SELECT s.tickerSymbol, s.name, s.tradingStatus, s.sharesOutstanding,
    s.earningsPerShare12M
FROM   CommonStock_obj_tab s
ORDER  BY s.tickerSymbol;

-- ETF_obj_tab
SELECT e.tickerSymbol, e.name, e.tradingStatus, e.trackedIndex,
    e.expenseRatio, e.inceptionDate
FROM   ETF_obj_tab e
ORDER  BY e.tickerSymbol;

-- PriceRecord_obj_tab (follows securityRef into either subtype table)
SELECT p.priceRecordNo, p.securityRef.tickerSymbol AS ticker, p.tradingDate,
    p.openPrice, p.highPrice, p.lowPrice, p.closePrice, p.volume
FROM   PriceRecord_obj_tab p
ORDER  BY p.priceRecordNo;

-- Order_obj_tab (follows accountRef, securityRef and advisorRef)
SELECT o.orderNo, o.side, o.type AS order_type, o.quantity, o.timePlaced,
    o.commission, o.status, o.limitPrice,
    o.accountRef.accountNo     AS account_no,
    o.securityRef.tickerSymbol AS ticker,
    o.advisorRef.name          AS advisor
FROM   Order_obj_tab o
ORDER  BY o.orderNo;

-- Fill_obj_tab (follows orderRef, then the order's securityRef)
SELECT f.fillNo, f.orderRef.orderNo AS order_no,
    f.orderRef.securityRef.tickerSymbol AS ticker,
    f.quantity, f.price, f.time AS fill_time
FROM   Fill_obj_tab f
ORDER  BY f.fillNo;

-- Holding_obj_tab (follows accountRef -> clientRef, and securityRef)
SELECT h.holdingId, h.accountRef.accountNo AS account_no,
    h.accountRef.clientRef.name AS client,
    h.securityRef.tickerSymbol  AS ticker,
    h.quantity, h.averageCostPerShare, h.dateFirstBought
FROM   Holding_obj_tab h
ORDER  BY h.holdingId;

SPOOL OFF