SET ECHO ON
SPOOL ml2_query_spool.txt
SET LINESIZE 200
SET PAGESIZE 100
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

-- Query 1
SELECT f.orderRef.accountRef.clientRef.name AS client,
    f.orderRef.accountRef.accountNo AS account_no,
    f.orderRef.securityRef.tickerSymbol AS ticker,
    f.orderRef.securityRef.exchangeRef.code AS exchange,
    f.quantity, f.price,
    f.orderRef.advisorRef.name AS advisor
FROM   Fill_obj_tab f
WHERE  f.orderRef.side = 'BUY'
AND    f.time >= TIMESTAMP '2026-10-01 00:00:00'
AND    f.time <  TIMESTAMP '2026-11-01 00:00:00'
ORDER  BY f.time;

-- Query 2
SELECT p.securityRef.tickerSymbol AS ticker, p.securityRef.name AS security_name,
    p.tradingDate, p.openPrice, p.closePrice,
    ROUND(p.percentChange(), 2) AS pct_change
FROM   PriceRecord_obj_tab p
ORDER  BY VALUE(p);

-- Query 3
SELECT c.name AS client, c.riskTolerance, c.dateOfBirth,
    c.advisorRef.name AS advisor
FROM   Client_obj_tab c
ORDER  BY VALUE(c);

-- Query 4
SELECT h.accountRef.clientRef.name AS client,
    h.securityRef.tickerSymbol AS ticker,
    h.quantity * h.averageCostPerShare AS invested,
    ROUND(h.securityRef.yearlyFee(h.quantity * h.averageCostPerShare), 2) AS yearly_fee
FROM   Holding_obj_tab h
ORDER  BY h.holdingId;

-- Query 5
SELECT o.orderNo, o.status,
    o.accountRef.clientRef.name AS client,
    o.securityRef.tickerSymbol AS ticker,
    o.quantity, o.filledQuantity() AS filled, o.remainingQuantity() AS remaining
FROM   Order_obj_tab o
ORDER  BY VALUE(o), o.orderNo;

-- Query 6
SELECT a.accountNo, a.type AS acct_type, a.status,
    a.clientRef.name AS client,
    a.clientRef.isAdult() AS adult,
    a.canPlaceOrder() AS can_trade,
    a.coversCost(10000) AS covers_10k,
    a.clientRef.advisorRef.name AS advisor
FROM   Account_obj_tab a
ORDER  BY a.accountNo;

-- Query 7
SELECT f.fillNo, f.orderRef.orderNo AS order_no,
    f.orderRef.side AS side, f.orderRef.type AS order_type,
    f.orderRef.limitPrice AS limit_price, f.price AS fill_price,
    f.orderRef.priceAcceptable(f.price) AS price_ok,
    f.orderRef.accountRef.clientRef.name AS client
FROM   Fill_obj_tab f
ORDER  BY f.fillNo;

-- Query 8
SELECT h.accountRef.clientRef.name AS client,
    h.securityRef.tickerSymbol AS ticker, h.quantity,
    TREAT(h.securityRef AS REF CommonStock_t).earningsPerShare12M AS eps_12m,
    TREAT(h.securityRef AS REF ETF_t).trackedIndex AS tracked_index,
    TREAT(h.securityRef AS REF ETF_t).expenseRatio AS expense_ratio
FROM   Holding_obj_tab h
ORDER  BY h.holdingId;

-- Query 9
SELECT h.accountRef.clientRef.advisorRef.name AS advisor,
    COUNT(*) AS positions,
    SUM(h.quantity * h.averageCostPerShare) AS total_invested
FROM   Holding_obj_tab h
GROUP  BY h.accountRef.clientRef.advisorRef.name
ORDER  BY total_invested DESC;

SPOOL OFF
