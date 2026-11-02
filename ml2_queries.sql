SET ECHO ON
SPOOL ml2_query_spool.txt
SET LINESIZE 200
SET PAGESIZE 100
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

-- Working with Your Database: 9 queries
-- Every query reads more than one object table by following REFs with dot notation (no joins, no nested queries).

COLUMN client          FORMAT A15
COLUMN advisor         FORMAT A15
COLUMN ticker          FORMAT A6
COLUMN security_name   FORMAT A28
COLUMN riskTolerance   FORMAT A13
COLUMN acct_type       FORMAT A9
COLUMN status          FORMAT A16
COLUMN side            FORMAT A4
COLUMN order_type      FORMAT A10
COLUMN adult           FORMAT A5
COLUMN can_trade       FORMAT A9
COLUMN covers_10k      FORMAT A10
COLUMN price_ok        FORMAT A8
COLUMN tracked_index   FORMAT A22
COLUMN pct_change      FORMAT 990.00
COLUMN expense_ratio   FORMAT 0.0000
COLUMN exchange        FORMAT A8

-- Q1: query specified by the instructor (ML1 feedback)
-- Fills of BUY orders executed in October 2026, with the client, account, ticker, exchange code, fill quantity and price,
-- and the advisor who entered the order. Every column is reached by following REFs from the fill through its order.
-- Order 5002 was entered by the client herself, so its advisor is blank (BR 27, 0..1)
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

-- Q2: MAP method (PriceRecord_t.percentChange) with ORDER BY VALUE
-- Daily price records ranked from biggest loser to biggest gainer (BR 21, 22); follows securityRef into both security tables
SELECT p.securityRef.tickerSymbol AS ticker, p.securityRef.name AS security_name,
    p.tradingDate, p.openPrice, p.closePrice,
    ROUND(p.percentChange(), 2) AS pct_change
FROM   PriceRecord_obj_tab p
ORDER  BY VALUE(p);

-- Q3: ORDER method (Client_t.compareRisk) with ORDER BY VALUE
-- Clients ranked by risk tolerance (LOW < MEDIUM < HIGH), older client first within the same level; follows advisorRef
SELECT c.name AS client, c.riskTolerance, c.dateOfBirth,
    c.advisorRef.name AS advisor
FROM   Client_obj_tab c
ORDER  BY VALUE(c);

-- Q4: overridden method (Security_t.yearlyFee, overridden in CommonStock_t and ETF_t)
-- Yearly fee on each position: securityRef is declared as REF Security_t, so Oracle runs the yearlyFee of each row's
-- actual subtype (stocks pay no fee, ETFs pay amount x expense ratio, BR 20)
SELECT h.accountRef.clientRef.name AS client,
    h.securityRef.tickerSymbol AS ticker,
    h.quantity * h.averageCostPerShare AS invested,
    ROUND(h.securityRef.yearlyFee(h.quantity * h.averageCostPerShare), 2) AS yearly_fee
FROM   Holding_obj_tab h
ORDER  BY h.holdingId;

-- Q5: order book sorted by unfilled shares (Order_t's MAP method remainingQuantity)
-- filledQuantity() reads Fill_obj_tab; client is reached through accountRef -> clientRef (BR 29, 32, 33)
SELECT o.orderNo, o.status,
    o.accountRef.clientRef.name AS client,
    o.securityRef.tickerSymbol AS ticker,
    o.quantity, o.filledQuantity() AS filled, o.remainingQuantity() AS remaining
FROM   Order_obj_tab o
ORDER  BY VALUE(o), o.orderNo;

-- Q6: trading eligibility of every account (BR 3, 7, 8)
-- Methods called on the account and, through clientRef, on its owner; advisor reached through clientRef -> advisorRef
SELECT a.accountNo, a.type AS acct_type, a.status,
    a.clientRef.name AS client,
    a.clientRef.isAdult() AS adult,
    a.canPlaceOrder() AS can_trade,
    a.coversCost(10000) AS covers_10k,
    a.clientRef.advisorRef.name AS advisor
FROM   Account_obj_tab a
ORDER  BY a.accountNo;

-- Q7: fill audit: did every fill respect its order's limit price? (BR 26)
-- Each fill's price is passed to priceAcceptable() on its order; follows orderRef -> accountRef -> clientRef
SELECT f.fillNo, f.orderRef.orderNo AS order_no,
    f.orderRef.side AS side, f.orderRef.type AS order_type,
    f.orderRef.limitPrice AS limit_price, f.price AS fill_price,
    f.orderRef.priceAcceptable(f.price) AS price_ok,
    f.orderRef.accountRef.clientRef.name AS client
FROM   Fill_obj_tab f
ORDER  BY f.fillNo;

-- Q8: subtype details of every holding using TREAT (BR 17, 19)
-- securityRef is a REF Security_t; TREAT exposes CommonStock_t or ETF_t attributes, and returns null for the other subtype
SELECT h.accountRef.clientRef.name AS client,
    h.securityRef.tickerSymbol AS ticker, h.quantity,
    TREAT(h.securityRef AS REF CommonStock_t).earningsPerShare12M AS eps_12m,
    TREAT(h.securityRef AS REF ETF_t).trackedIndex AS tracked_index,
    TREAT(h.securityRef AS REF ETF_t).expenseRatio AS expense_ratio
FROM   Holding_obj_tab h
ORDER  BY h.holdingId;

-- Q9: total invested per advisor across all of their clients' holdings (BR 4, 34, 35)
-- One REF chain through four tables: holding -> account -> client -> advisor
SELECT h.accountRef.clientRef.advisorRef.name AS advisor,
    COUNT(*) AS positions,
    SUM(h.quantity * h.averageCostPerShare) AS total_invested
FROM   Holding_obj_tab h
GROUP  BY h.accountRef.clientRef.advisorRef.name
ORDER  BY total_invested DESC;

SPOOL OFF
