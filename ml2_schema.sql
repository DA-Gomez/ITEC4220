SET ECHO ON
SPOOL ml2_logical_schema_spool.txt
SET SQLBLANKLINES ON
SET DEFINE OFF


-- --------------------------------------- types ---------------------------------------
CREATE OR REPLACE TYPE Advisor_t AS OBJECT (
    advisorNo       NUMBER,
    name            VARCHAR2(100),
    email           VARCHAR2(100),
    phone           VARCHAR2(20),
    registrationNo  VARCHAR2(50)
);
/

CREATE OR REPLACE TYPE Client_t AS OBJECT (
    clientNo        NUMBER,
    name            VARCHAR2(100),
    dateOfBirth     DATE,
    email           VARCHAR2(100),
    phone           VARCHAR2(20),
    address         VARCHAR2(200),
    riskTolerance   VARCHAR2(20),
    advisorRef      REF Advisor_t,
    MEMBER FUNCTION isAdult RETURN VARCHAR2,
    ORDER MEMBER FUNCTION compareRisk(other IN Client_t) RETURN INTEGER
);
/

CREATE OR REPLACE TYPE Account_t AS OBJECT (
    accountNo       INTEGER,
    openingDate     DATE,
    cashBalance     NUMBER(12, 2),
    type            VARCHAR2(20),
    status          VARCHAR2(20),
    clientRef       REF Client_t,
    MEMBER FUNCTION canPlaceOrder RETURN VARCHAR2,
    MEMBER FUNCTION coversCost(estimatedCost NUMBER) RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE Exchange_t AS OBJECT (
    code            VARCHAR2(10),
    name            VARCHAR2(60),
    openingTime     INTERVAL DAY(0) TO SECOND(0),
    closingTime     INTERVAL DAY(0) TO SECOND(0),
    MEMBER FUNCTION isOpen(t TIMESTAMP) RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE Security_t AS OBJECT (
    tickerSymbol    NVARCHAR2(6),
    name            VARCHAR2(32),
    tradingStatus   VARCHAR2(20),
    exchangeRef     REF Exchange_t,
    MEMBER FUNCTION isTradable RETURN VARCHAR2,
    NOT INSTANTIABLE MEMBER FUNCTION yearlyFee(amount NUMBER) RETURN NUMBER
) NOT INSTANTIABLE NOT FINAL;
/

CREATE OR REPLACE TYPE CommonStock_t UNDER Security_t (
    sharesOutstanding   INTEGER,
    earningsPerShare12M NUMBER(8, 2),
    OVERRIDING MEMBER FUNCTION yearlyFee(amount NUMBER) RETURN NUMBER
);
/

CREATE OR REPLACE TYPE ETF_t UNDER Security_t (
    trackedIndex    VARCHAR2(100),
    expenseRatio    NUMBER(5, 4),
    inceptionDate   DATE,
    OVERRIDING MEMBER FUNCTION yearlyFee(amount NUMBER) RETURN NUMBER
);
/

CREATE OR REPLACE TYPE Order_t AS OBJECT (
    orderNo        INTEGER,
    side           VARCHAR2(32),
    type           VARCHAR2(32),
    quantity       INTEGER,
    timePlaced     TIMESTAMP,
    commission     NUMBER(10, 2),
    status         VARCHAR2(32),
    limitPrice     NUMBER(10, 2),
    accountRef     REF Account_t,
    securityRef    REF Security_t,
    advisorRef     REF Advisor_t,
    MEMBER FUNCTION priceAcceptable(price NUMBER) RETURN VARCHAR2,
    MEMBER FUNCTION filledQuantity RETURN NUMBER,
    MAP MEMBER FUNCTION remainingQuantity RETURN NUMBER
);
/

CREATE OR REPLACE TYPE Fill_t AS OBJECT (
    fillNo         INTEGER,
    quantity       INTEGER,
    price          NUMBER(10, 2),
    time           TIMESTAMP,
    orderRef       REF Order_t 
);
/

CREATE OR REPLACE TYPE Holding_t AS OBJECT (
    holdingId           INTEGER,
    accountRef          REF Account_t,
    securityRef         REF Security_t,
    quantity            INTEGER,
    averageCostPerShare NUMBER(10, 2),
    dateFirstBought     DATE,
    MEMBER FUNCTION marketValue(latestClose NUMBER) RETURN NUMBER,
    MEMBER FUNCTION hasSufficientShares(reqQuantity INTEGER) RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE PriceRecord_t AS OBJECT (
    priceRecordNo	INTEGER,
    tradingDate     DATE,
    openPrice       NUMBER(10, 2),
    highPrice       NUMBER(10, 2),
    lowPrice        NUMBER(10, 2),
    closePrice      NUMBER(10, 2),
    volume		INTEGER,
    securityRef     REF Security_t,
    MAP MEMBER FUNCTION percentChange RETURN NUMBER
);
/


-- --------------------------------------- object tables ---------------------------------------
CREATE TABLE Advisor_obj_tab OF Advisor_t (
    CONSTRAINT pk_advisor PRIMARY KEY (advisorNo)
);

CREATE TABLE Client_obj_tab OF Client_t (
    CONSTRAINT pk_client PRIMARY KEY (clientNo),
    CONSTRAINT fk_client_advisor FOREIGN KEY (advisorRef) REFERENCES Advisor_obj_tab
);

CREATE TABLE Account_obj_tab OF Account_t (
    CONSTRAINT pk_account PRIMARY KEY (accountNo),
    CONSTRAINT fk_account_client FOREIGN KEY (clientRef) REFERENCES Client_obj_tab
);

CREATE TABLE Exchange_obj_tab OF Exchange_t (
    CONSTRAINT pk_exchange PRIMARY KEY (code)
);

CREATE TABLE CommonStock_obj_tab OF CommonStock_t (
    CONSTRAINT pk_commonstock PRIMARY KEY (tickerSymbol),
    CONSTRAINT fk_commonstock_exchange FOREIGN KEY (exchangeRef) REFERENCES Exchange_obj_tab
);

CREATE TABLE ETF_obj_tab OF ETF_t (
    CONSTRAINT pk_etf PRIMARY KEY (tickerSymbol),
    CONSTRAINT fk_etf_exchange FOREIGN KEY (exchangeRef) REFERENCES Exchange_obj_tab
);

CREATE TABLE PriceRecord_obj_tab OF PriceRecord_t (
    CONSTRAINT pk_pricerecord PRIMARY KEY (priceRecordNo)
);

CREATE TABLE Order_obj_tab OF Order_t (
    CONSTRAINT pk_order PRIMARY KEY (orderNo),
    CONSTRAINT fk_order_account FOREIGN KEY (accountRef) REFERENCES Account_obj_tab,
    CONSTRAINT fk_order_advisor FOREIGN KEY (advisorRef) REFERENCES Advisor_obj_tab
);

CREATE TABLE Fill_obj_tab OF Fill_t (
    CONSTRAINT pk_fill PRIMARY KEY (fillNo),
    CONSTRAINT fk_fill_order FOREIGN KEY (orderRef) REFERENCES Order_obj_tab
);

CREATE TABLE Holding_obj_tab OF Holding_t (
    CONSTRAINT pk_holding PRIMARY KEY (holdingId),
    CONSTRAINT fk_holding_account FOREIGN KEY (accountRef) REFERENCES Account_obj_tab
);


-- --------------------------------------- type bodies ---------------------------------------
CREATE OR REPLACE TYPE BODY Client_t AS
    MEMBER FUNCTION isAdult RETURN VARCHAR2 IS
        age NUMBER;
    BEGIN
        age := MONTHS_BETWEEN(SYSDATE, dateOfBirth) / 12;
        IF age>= 18 THEN
        RETURN 'TRUE';
        ELSE
        RETURN 'FALSE';
        END IF;
    END;

    ORDER MEMBER FUNCTION compareRisk(other IN Client_t) RETURN INTEGER IS
        myRank    INTEGER;
        otherRank INTEGER;
    BEGIN
        myRank 	 := CASE SELF.riskTolerance  WHEN 'LOW' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END;
        otherRank := CASE other.riskTolerance WHEN 'LOW' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END;

        IF    myRank < otherRank THEN RETURN -1;
        ELSIF myRank > otherRank THEN RETURN 1;
        ELSIF SELF.dateOfBirth < other.dateOfBirth THEN RETURN -1;
        ELSIF SELF.dateOfBirth > other.dateOfBirth THEN RETURN 1;
        ELSE  RETURN 0;
        END IF;
    END;
END;
/

CREATE OR REPLACE TYPE BODY Account_t AS
    MEMBER FUNCTION canPlaceOrder RETURN VARCHAR2 IS
    BEGIN
        IF SELF.status = 'ACTIVE' THEN
        RETURN 'TRUE';
        ELSE
        RETURN 'FALSE';
        END IF;
    END;

    MEMBER FUNCTION coversCost(estimatedCost NUMBER) RETURN VARCHAR2 IS
    BEGIN
        IF cashBalance >= estimatedCost THEN
        RETURN 'TRUE';
        ELSE
        RETURN 'FALSE';
        END IF;
    END;
END;
/

CREATE OR REPLACE TYPE BODY Exchange_t AS
    MEMBER FUNCTION isOpen(t TIMESTAMP) RETURN VARCHAR2 IS
        timeOfDay INTERVAL DAY TO SECOND;
    BEGIN
        timeOfDay := t - CAST(TRUNC(t) AS TIMESTAMP);
        IF timeOfDay >= SELF.openingTime AND timeOfDay < SELF.closingTime THEN
            RETURN 'TRUE';
        ELSE
            RETURN 'FALSE';
        END IF;
    END;
END;
/

CREATE OR REPLACE TYPE BODY Security_t AS
    MEMBER FUNCTION isTradable RETURN VARCHAR2 IS
    BEGIN
        IF SELF.tradingStatus = 'ACTIVE' THEN
        RETURN 'TRUE';
        ELSE
        RETURN 'FALSE';
        END IF;
    END;
END;
/

CREATE OR REPLACE TYPE BODY CommonStock_t AS
    OVERRIDING MEMBER FUNCTION yearlyFee(amount NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN 0;
    END;
END;
/

CREATE OR REPLACE TYPE BODY ETF_t AS
    OVERRIDING MEMBER FUNCTION yearlyFee(amount NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN amount * SELF.expenseRatio;
    END;
END;
/

CREATE OR REPLACE TYPE BODY Order_t AS
    MEMBER FUNCTION priceAcceptable(price NUMBER) RETURN VARCHAR2 IS
    BEGIN
        IF limitPrice IS NULL THEN
        RETURN 'TRUE';
        ELSIF SELF.side = 'BUY' AND price <= limitPrice THEN
        RETURN 'TRUE';
        ELSIF SELF.side = 'SELL' AND price >= limitPrice THEN
        RETURN 'TRUE';
        ELSE
        RETURN 'FALSE';
        END IF;
    END;

    MEMBER FUNCTION filledQuantity RETURN NUMBER IS
        total NUMBER;
    BEGIN
        SELECT NVL(SUM(f.quantity), 0) INTO total
        FROM   Fill_obj_tab f
        WHERE  f.orderRef.orderNo = SELF.orderNo;
        RETURN total;
    END;

    MAP MEMBER FUNCTION remainingQuantity RETURN NUMBER IS
    BEGIN
        RETURN SELF.quantity - SELF.filledQuantity();
    END;
END;
/

CREATE OR REPLACE TYPE BODY Holding_t AS
    MEMBER FUNCTION marketValue(latestClose NUMBER) RETURN NUMBER IS
    BEGIN
        RETURN quantity * latestClose;
    END;

    MEMBER FUNCTION hasSufficientShares(reqQuantity INTEGER) RETURN VARCHAR2 IS
    BEGIN
        IF quantity >= reqQuantity THEN
        RETURN 'TRUE';
        ELSE
        RETURN 'FALSE';
        END IF;
    END;
END;
/


CREATE OR REPLACE TYPE BODY PriceRecord_t AS
    MAP MEMBER FUNCTION percentChange RETURN NUMBER IS
    BEGIN
        RETURN (SELF.closePrice - SELF.openPrice) / SELF.openPrice * 100;
    END;
END;
/

commit;

SPOOL OFF;