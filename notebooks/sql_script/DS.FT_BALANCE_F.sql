--BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

INSERT INTO DS.FT_BALANCE_F (on_date, account_rk, currency_rk, balance_out)
SELECT
    TO_TIMESTAMP(on_date, 'DD.MM.YYYY') AS on_date,
    account_rk::DOUBLE PRECISION AS account_rk,
    currency_rk::DOUBLE PRECISION AS currency_rk,
    balance_out::DOUBLE PRECISION AS balance_out
FROM (SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY ON_DATE, ACCOUNT_RK ORDER BY id DESC)
    FROM SOURCE.FT_BALANCE_F
    WHERE id IS NOT NULL 
        AND on_date IS NOT NULL 
        AND account_rk IS NOT NULL) t
WHERE row_number = 1
ON CONFLICT (ON_DATE, ACCOUNT_RK)
DO UPDATE SET
    currency_rk = EXCLUDED.currency_rk,
    balance_out = EXCLUDED.balance_out;

--COMMIT;
