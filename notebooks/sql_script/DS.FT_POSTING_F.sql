--BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

INSERT INTO DS.FT_POSTING_F (oper_date, credit_account_rk, debet_account_rk, credit_amount, debet_amount)
SELECT
    TO_TIMESTAMP(oper_date, 'YYYY-MM-DD') AS oper_date,
    credit_account_rk::DOUBLE PRECISION,
    debet_account_rk::DOUBLE PRECISION,
    credit_amount::DOUBLE PRECISION,
    debet_amount::DOUBLE PRECISION
FROM (
    SELECT 
     *,
    ROW_NUMBER() OVER (PARTITION BY OPER_DATE, CREDIT_ACCOUNT_RK, DEBET_ACCOUNT_RK ORDER BY id DESC) AS row_number
    FROM source.FT_POSTING_F
    WHERE id IS NOT NULL 
        AND oper_date IS NOT NULL 
        AND credit_account_rk IS NOT NULL
        AND debet_account_rk IS NOT NULL
        AND credit_amount IS NOT NULL 
        AND debet_amount IS NOT NULL
) t
WHERE row_number = 1
ON CONFLICT (OPER_DATE, CREDIT_ACCOUNT_RK, DEBET_ACCOUNT_RK)
DO UPDATE SET
    credit_amount = EXCLUDED.credit_amount,
    debet_amount = EXCLUDED.debet_amount;

--COMMIT;