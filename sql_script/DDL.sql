--------------------------------------------------------
CREATE SCHEMA SOURCE;

DROP TABLE IF EXISTS SOURCE.FT_BALANCE_F;
DROP TABLE IF EXISTS SOURCE.FT_POSTING_F;
DROP TABLE IF EXISTS SOURCE.MD_ACCOUNT_D;
DROP TABLE IF EXISTS SOURCE.MD_CURRENCY_D;
DROP TABLE IF EXISTS SOURCE.MD_EXCHANGE_RATE_D;
DROP TABLE IF EXISTS SOURCE.MD_LEDGER_ACCOUNT_S;

CREATE TABLE SOURCE.FT_BALANCE_F
(
id VARCHAR,
on_date VARCHAR,
account_rk VARCHAR,
currency_rk VARCHAR,
balance_out VARCHAR
);

CREATE TABLE SOURCE.FT_POSTING_F
(
id VARCHAR,
oper_date VARCHAR,
credit_account_rk VARCHAR,
debet_account_rk VARCHAR,
credit_amount VARCHAR,
debet_amount VARCHAR
);



CREATE TABLE SOURCE.MD_ACCOUNT_D
(
id VARCHAR,
data_actual_date VARCHAR,
data_actual_end_date VARCHAR,
account_rk VARCHAR,
account_number VARCHAR,
char_type VARCHAR,
currency_rk VARCHAR,
currency_code VARCHAR
);


CREATE TABLE SOURCE.MD_CURRENCY_D
(
id VARCHAR,
currency_rk VARCHAR,
data_actual_date VARCHAR,
data_actual_end_date VARCHAR,
currency_code VARCHAR,
code_iso_char VARCHAR
);

CREATE TABLE SOURCE.MD_EXCHANGE_RATE_D
(
id VARCHAR,
data_actual_date VARCHAR,
data_actual_end_date VARCHAR,
currency_rk VARCHAR,
reduced_cource VARCHAR,
code_iso_num VARCHAR
);

CREATE TABLE SOURCE.MD_LEDGER_ACCOUNT_S
(
id VARCHAR,
chapter VARCHAR,
chapter_name VARCHAR,
section_number VARCHAR,
section_name VARCHAR,
subsection_name VARCHAR,
ledger1_account VARCHAR,
ledger1_account_name VARCHAR,
ledger_account VARCHAR,
ledger_account_name VARCHAR,
characteristic VARCHAR,
is_resident VARCHAR,
is_reserve VARCHAR,
is_reserved VARCHAR,
is_loan VARCHAR,
is_reserved_assets VARCHAR,
is_overdue VARCHAR,
is_interest VARCHAR,
pair_account VARCHAR,
start_date VARCHAR,
end_date VARCHAR,
is_rub_only VARCHAR,
min_term VARCHAR,
min_term_measure VARCHAR,
max_term VARCHAR,
max_term_measure VARCHAR,
ledger_acc_full_name_translit VARCHAR,
is_revaluation VARCHAR,
is_correct VARCHAR
);

CREATE SCHEMA DS;    -------------------------------------------------------------------

DROP TABLE IF EXISTS DS.FT_BALANCE_F;
DROP TABLE IF EXISTS DS.FT_POSTING_F;
DROP TABLE IF EXISTS DS.MD_ACCOUNT_D;
DROP TABLE IF EXISTS DS.MD_LEDGER_ACCOUNT_S;
DROP TABLE IF EXISTS DS.MD_EXCHANGE_RATE_D;
DROP TABLE IF EXISTS DS.MD_CURRENCY_D;


CREATE TABLE DS.MD_CURRENCY_D
(
    currency_rk DOUBLE PRECISION NOT NULL  
    ,data_actual_date TIMESTAMP NOT NULL
    ,data_actual_end_date TIMESTAMP
    ,currency_code VARCHAR(3)
    ,code_iso_char VARCHAR(3)

    ,PRIMARY KEY(currency_rk, data_actual_date)
);



CREATE TABLE DS.MD_EXCHANGE_RATE_D
(
    data_actual_date TIMESTAMP NOT NULL
    ,data_actual_end_date TIMESTAMP
    ,currency_rk DOUBLE PRECISION NOT NULL
    ,reduced_cource DOUBLE PRECISION
    ,code_iso_num VARCHAR(3)

    ,PRIMARY KEY(DATA_ACTUAL_DATE, CURRENCY_RK)
);



CREATE TABLE DS.MD_LEDGER_ACCOUNT_S
(
    chapter CHAR(1)
    ,chapter_name VARCHAR(16)
    ,section_number INTEGER
    ,section_name VARCHAR(22)
    ,subsection_name VARCHAR(21)
    ,ledger1_account INTEGER
    ,ledger1_account_name VARCHAR(47)
    ,ledger_account INTEGER NOT NULL
    ,ledger_account_name VARCHAR(153)
    ,characteristic CHAR(1)
    ,is_resident INTEGER
    ,is_reserve INTEGER
    ,is_reserved INTEGER
    ,is_loan INTEGER
    ,is_reserved_assets INTEGER
    ,is_overdue INTEGER
    ,is_interest INTEGER
    ,pair_account VARCHAR(5)
    ,start_date TIMESTAMP NOT NULL
    ,end_date TIMESTAMP
    ,is_rub_only INTEGER
    ,min_term VARCHAR(1)
    ,min_term_measure VARCHAR(1)
    ,max_term VARCHAR(1)
    ,max_term_measure VARCHAR(1)
    ,ledger_acc_full_name_translit VARCHAR(1)
    ,is_revaluation VARCHAR(1)
    ,is_correct VARCHAR(1)

    ,PRIMARY KEY(LEDGER_ACCOUNT, START_DATE)
);


CREATE TABLE DS.MD_ACCOUNT_D
(
	data_actual_date TIMESTAMP NOT NULL
	,data_actual_end_date TIMESTAMP NOT NULL
    ,account_rk DOUBLE PRECISION NOT NULL
	,account_number NUMERIC(20)
	,char_type VARCHAR(1) NOT NULL
	,currency_rk DOUBLE PRECISION  NOT NULL
	,currency_code VARCHAR(3) NOT NULL

    ,PRIMARY KEY(DATA_ACTUAL_DATE, ACCOUNT_RK)
);



CREATE TABLE DS.FT_POSTING_F
(   
	oper_date TIMESTAMP
	,credit_account_rk DOUBLE PRECISION NOT NULL
	,debet_account_rk DOUBLE PRECISION NOT NULL
	,credit_amount DOUBLE PRECISION 
	,debet_amount DOUBLE PRECISION

    ,PRIMARY KEY(OPER_DATE, CREDIT_ACCOUNT_RK, DEBET_ACCOUNT_RK) 
);



CREATE TABLE DS.FT_BALANCE_F
(
    on_date TIMESTAMP NOT NULL
    ,account_rk DOUBLE PRECISION NOT NULL
    ,currency_rk DOUBLE PRECISION
    ,balance_out DOUBLE PRECISION

    ,PRIMARY KEY(ON_DATE, ACCOUNT_RK)
);

--------------------------------------------------------
CREATE SCHEMA LOGS;   

DROP TABLE IF EXISTS LOGS.LOGS;

CREATE TABLE LOGS.LOGS (
id SERIAL,
table_name VARCHAR,
start_time TIMESTAMP,
end_time TIMESTAMP,
status VARCHAR,
file_path VARCHAR,
rows_inserted INT,
error_message TEXT
);

--------------------------------------------------------
CREATE ROLE DS;
GRANT USAGE ON SCHEMA DS TO DS;
GRANT SELECT ON ALL TABLES IN SCHEMA DS TO DS;

CREATE USER user_1
PASSWORD 'password';

GRANT DS TO user_1;
