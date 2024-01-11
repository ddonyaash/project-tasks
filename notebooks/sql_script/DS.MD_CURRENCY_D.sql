--BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

INSERT INTO DS.MD_CURRENCY_D (
    currency_rk,
    data_actual_date,
    data_actual_end_date,
    currency_code,
    code_iso_char
) 
SELECT
    currency_rk::DOUBLE PRECISION,
    TO_TIMESTAMP(data_actual_date, 'YYYY-MM-DD') AS data_actual_date,
    TO_TIMESTAMP(data_actual_end_date, 'YYYY-MM-DD') AS data_actual_end_date,
    currency_code::VARCHAR(3),
    code_iso_char::VARCHAR(3)
FROM (SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY currency_rk, data_actual_date ORDER BY id DESC) 
    FROM SOURCE.MD_CURRENCY_D
    WHERE currency_rk IS NOT NULL 
        AND data_actual_date IS NOT NULL) t
WHERE row_number = 1
ON CONFLICT (CURRENCY_RK, DATA_ACTUAL_DATE) DO UPDATE
SET
    data_actual_end_date = EXCLUDED.data_actual_end_date,
    currency_code = EXCLUDED.currency_code,
    code_iso_char = EXCLUDED.code_iso_char;


--COMMIT;
