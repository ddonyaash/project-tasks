--BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

INSERT INTO DS.MD_ACCOUNT_D (
    data_actual_date,
    data_actual_end_date,
    account_rk,
    account_number,
    char_type,
    currency_rk,
    currency_code
) 
SELECT
    TO_TIMESTAMP(data_actual_date, 'YYYY-MM-DD') AS data_actual_date,
    TO_TIMESTAMP(data_actual_end_date, 'YYYY-MM-DD') AS data_actual_end_date,
    account_rk::DOUBLE PRECISION,
    account_number::NUMERIC(20),
    char_type::VARCHAR(1),
    currency_rk::DOUBLE PRECISION,
    currency_code::VARCHAR(3)
FROM  (SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY DATA_ACTUAL_DATE, ACCOUNT_RK ORDER BY id DESC)
    FROM SOURCE.MD_ACCOUNT_D
    WHERE data_actual_date IS NOT NULL 
        AND data_actual_end_date IS NOT NULL
        AND account_rk IS NOT NULL 
        AND char_type IS NOT NULL 
        AND currency_rk IS NOT NULL 
        AND currency_code IS NOT NULL) t
WHERE row_number = 1
ON CONFLICT (DATA_ACTUAL_DATE, ACCOUNT_RK) DO UPDATE
SET
    data_actual_end_date = EXCLUDED.data_actual_end_date,
    account_number = EXCLUDED.account_number,
    char_type = EXCLUDED.char_type,
    currency_rk = EXCLUDED.currency_rk,
    currency_code = EXCLUDED.currency_code;

--COMMIT;
