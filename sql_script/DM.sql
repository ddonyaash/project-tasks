DROP SCHEMA IF EXISTS DM CASCADE;
CREATE SCHEMA DM;

--------- Таблица оборотов
DROP TABLE IF EXISTS DM.DM_ACCOUNT_TURNOVER_F;
CREATE TABLE DM.DM_ACCOUNT_TURNOVER_F  (
    on_date TIMESTAMP,
    account_rk DOUBLE PRECISION,
    credit_amount_rub DOUBLE PRECISION,
    credit_amount_rub_ths DOUBLE PRECISION,
    debet_amount_rub DOUBLE PRECISION,
    debet_amount_rub_ths DOUBLE PRECISION
);


DROP FUNCTION IF EXISTS DM.ACCOUNT_TURNOVER_F (date_from date, to_date date);
CREATE FUNCTION DM.ACCOUNT_TURNOVER_F (date_from date, to_date date) 
RETURNS TABLE (
    on_date TIMESTAMP,
    account_rk DOUBLE PRECISION,
    credit_amount_rub_ths DOUBLE PRECISION,
    credit_amount_rub DOUBLE PRECISION,
    debet_amount_rub_ths DOUBLE PRECISION,
    debet_amount_rub DOUBLE PRECISION
) AS 
$$
WITH wt_turn AS (
    SELECT 
        p.oper_date AS on_date,
        p.credit_account_rk AS account_rk,
        p.credit_amount * COALESCE(er.reduced_cource, 1)/1000 AS credit_amount,
        p.credit_amount * COALESCE(er.reduced_cource, 1) AS credit_amount_rub,
        NULL::DOUBLE PRECISION AS debet_amount,
        NULL::DOUBLE PRECISION  AS debet_amount_rub
    FROM 
        ds.ft_posting_f p
        JOIN ds.md_account_d a ON a.account_rk = p.credit_account_rk AND p.oper_date BETWEEN a.data_actual_date AND a.data_actual_end_date
        LEFT JOIN ds.md_exchange_rate_d er ON er.currency_rk = a.currency_rk AND p.oper_date BETWEEN er.data_actual_date AND er.data_actual_end_date
    WHERE 
        p.oper_date BETWEEN date_from AND to_date

    UNION ALL

    SELECT
        p.oper_date AS on_date,
        p.debet_account_rk AS account_rk,
        NULL::DOUBLE PRECISION  AS credit_amount,
        NULL::DOUBLE PRECISION  AS credit_amount_rub,
        p.debet_amount * COALESCE(er.reduced_cource, 1)/1000 AS debet_amount,
        p.debet_amount * COALESCE(er.reduced_cource, 1) AS debet_amount_rub
    FROM
        ds.ft_posting_f p
        JOIN ds.md_account_d a ON a.account_rk = p.debet_account_rk AND p.oper_date BETWEEN a.data_actual_date AND a.data_actual_end_date
        LEFT JOIN ds.md_exchange_rate_d er ON er.currency_rk = a.currency_rk AND p.oper_date BETWEEN er.data_actual_date AND er.data_actual_end_date
    WHERE
        p.oper_date BETWEEN date_from AND to_date
)
SELECT 
    on_date,
    account_rk,
    COALESCE(SUM(credit_amount), 0) AS credit_amount_rub_ths,
    COALESCE(SUM(credit_amount_rub), 0) AS credit_amount_rub,
    COALESCE(SUM(debet_amount), 0) AS debet_amount_rub_ths,
    COALESCE(SUM(debet_amount_rub), 0) AS debet_amount_rub
FROM 
    wt_turn 
GROUP BY 
    on_date, account_rk
ORDER BY 
    on_date, account_rk
$$
LANGUAGE SQL;

INSERT INTO DM.DM_ACCOUNT_TURNOVER_F (on_date,
    account_rk,
    credit_amount_rub_ths,
    credit_amount_rub,
    debet_amount_rub_ths,
    debet_amount_rub)
SELECT * FROM DM.ACCOUNT_TURNOVER_F('2018-01-01', '2018-01-31');

SELECT * FROM DM.DM_ACCOUNT_TURNOVER_F;

--------- 101 отчетная форма
DROP TABLE IF EXISTS DM.DM_F101_ROUND_F ;
CREATE TABLE DM.DM_F101_ROUND_F (
    REGN numeric(4),
    PLAN varchar(1),
    NUM_SC varchar(5),
    A_P varchar(1),
    VR numeric(16),
    VV numeric(16),
    VITG numeric(33,4),
    ORA numeric(16),
    OVA numeric(16),
    OITGA numeric(33,4),
    ORP numeric(16),
    OVP numeric(16),
    OITGP numeric(33,4),
    IR numeric(16),
    IV numeric(16),
    IITG numeric(33,4),
    DT date,
    PRIZ numeric(1)
);

CREATE OR REPLACE PROCEDURE dm.fill_f101_round_f(IN i_ondate date)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO dm.dm_f101_round_f
           (REGN,
            DT,
            PRIZ,
            PLAN,
            NUM_SC,
            A_P,
            VR,
            VV,
            VITG,
            ORA,
            OVA,
            OITGA,
            ORP,
            OVP,
            OITGP,
            IR,
            IV,
            IITG
           )
    WITH cte AS (
        SELECT 
		    -- Регистрационный номер кредитной организации
            1481 AS REGN,
		    -- Отчетная дата, на которую составлена оборотная ведомость кредитной организации
            i_ondate AS DT,
		    -- Признак категории раскрытия информации: 1 – оборотная ведомость в полном объеме;
            1 AS PRIZ,
		    -- Глава Плана счетов бухгалтерского учета вкредитных организациях: А – балансовые счета;
            s.chapter AS PLAN,
		    -- Номер счета второго порядка по Плану счетов бухгалтерского учета в кредитных организациях
            substr(acc_d.account_number::varchar, 1, 5) AS NUM_SC,
		    -- Признак счета: 1 – счет активный; 2 – счет пассивный
            CASE 
                WHEN acc_d.char_type IN ('A') THEN '1'::varchar 
                ELSE '2'::varchar
            END AS A_P,
            -- Входящие остатки «в рублях», тыс. руб.
            ROUND(SUM(
                CASE 
                    WHEN cur.currency_code IN ('643', '810') THEN b.balance_out
                    ELSE 0
                END
            ) / 1000) AS VR,
            -- Входящие остатки «ин. вал.», тыс. руб.
            ROUND(SUM(
                CASE 
                    WHEN cur.currency_code NOT IN ('643', '810') THEN b.balance_out * exch_r.reduced_cource
                    ELSE 0
                END
            ) / 1000) AS VV,
            -- Входящие остатки «итого», тыс. руб.
            ROUND((SUM(
                CASE 
                    WHEN cur.currency_code IN ('643', '810') THEN b.balance_out
                    ELSE b.balance_out * exch_r.reduced_cource
                END
            ) / 1000)::numeric, 4) AS VITG,
            -- Обороты за отчетный период по дебету(активу) «в рублях», тыс. руб.
            ROUND(COALESCE(SUM(
                CASE 
                    WHEN cur.currency_code IN ('643', '810') THEN at.debet_amount_rub
                    ELSE 0
                END
            ), 0) / 1000) AS ORA,
            -- Обороты за отчетный период по дебету(активу) «ин. вал.», тыс. руб.
            ROUND(COALESCE(SUM(
                CASE 
                    WHEN cur.currency_code NOT IN ('643', '810') THEN at.debet_amount_rub
                    ELSE 0
                END
            ), 0) / 1000) AS OVA,
            -- Обороты за отчетный период по дебету(активу) «итого», тыс. руб.
            ROUND((COALESCE(SUM(at.debet_amount_rub), 0) / 1000)::numeric, 4) AS OITGA,
            -- Обороты за отчетный период по кредиту (пассиву) «в рублях», тыс. руб.
            ROUND(COALESCE(SUM(
                CASE 
                    WHEN cur.currency_code IN ('643', '810') THEN at.credit_amount_rub
                    ELSE 0
                END
            ), 0) / 1000) AS ORP,
            -- Обороты за отчетный период по кредиту(пассиву) «ин. вал.», тыс.руб.
            ROUND(COALESCE(SUM(
                CASE 
                    WHEN cur.currency_code NOT IN ('643', '810') THEN at.credit_amount_rub
                    ELSE 0
                END
            ), 0) / 1000) AS OVP,
            -- Обороты за отчетный период по кредиту(пассиву) «итого», тыс. руб.
            ROUND((COALESCE(SUM(at.credit_amount_rub), 0) / 1000)::numeric, 4) AS OITGP,
            -- Исходящие остатки «в рублях», тыс. руб. 
            ROUND(COALESCE(SUM(
                CASE
                    WHEN acc_d.char_type = 'A' AND cur.currency_code IN ('643', '810') THEN b.balance_out - at.credit_amount_rub + at.debet_amount_rub
                    WHEN acc_d.char_type = 'P' AND cur.currency_code IN ('643', '810') THEN b.balance_out + at.credit_amount_rub - at.debet_amount_rub
                END
            ), 0) / 1000) AS IR,
            -- Исходящие остатки «ин. вал.», тыс. руб.
            ROUND(COALESCE(SUM(
                CASE
                    WHEN acc_d.char_type = 'A' AND cur.currency_code NOT IN ('643', '810') THEN (b.balance_out * exch_r.reduced_cource) - at.credit_amount_rub + at.debet_amount_rub
                    WHEN acc_d.char_type = 'P' AND cur.currency_code NOT IN ('643', '810') THEN (b.balance_out * exch_r.reduced_cource) + at.credit_amount_rub - at.debet_amount_rub
                END
            ), 0) / 1000) AS IV
        FROM 
            ds.md_ledger_account_s s
            JOIN ds.md_account_d acc_d ON substr(acc_d.account_number::varchar, 1, 5) = s.ledger_account::varchar
            JOIN ds.md_currency_d cur ON cur.currency_rk = acc_d.currency_rk
            LEFT JOIN ds.ft_balance_f b 
		    	ON b.account_rk = acc_d.account_rk 
				AND b.on_date = (date_trunc('month', i_ondate) - INTERVAL '1 day')
            LEFT JOIN ds.md_exchange_rate_d exch_r 
		    	ON exch_r.currency_rk = acc_d.currency_rk AND i_ondate BETWEEN exch_r.data_actual_date 
		        AND exch_r.data_actual_end_date
            LEFT JOIN dm.dm_account_turnover_f at 
				ON at.account_rk = acc_d.account_rk 
				AND at.on_date BETWEEN date_trunc('month', i_ondate) 
				AND (date_trunc('MONTH', i_ondate) + INTERVAL '1 MONTH - 1 day')
        WHERE 
            i_ondate BETWEEN s.start_date AND s.end_date
            AND i_ondate BETWEEN acc_d.data_actual_date AND acc_d.data_actual_end_date
            AND i_ondate BETWEEN cur.data_actual_date AND cur.data_actual_end_date
        GROUP BY 
            s.chapter,
            substr(acc_d.account_number::varchar, 1, 5),
            acc_d.char_type
    )
    SELECT 
        *,
        -- Исходящие остатки «итого», тыс. руб.
        ROUND((IV + IR)::numeric, 4) AS IITG
    FROM 
        cte;
END;
$$;

CALL dm.fill_f101_round_f('2018-01-31');

SELECT * FROM dm.dm_f101_round_f;
