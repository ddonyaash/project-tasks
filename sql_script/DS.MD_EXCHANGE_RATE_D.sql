--BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

INSERT INTO DS.MD_EXCHANGE_RATE_D (
    data_actual_date,
    data_actual_end_date,
    currency_rk,
    reduced_cource,
    code_iso_num
) 
SELECT
    TO_TIMESTAMP(data_actual_date, 'YYYY-MM-DD') AS data_actual_date,
    TO_TIMESTAMP(data_actual_end_date, 'YYYY-MM-DD') AS data_actual_end_date,
    currency_rk::DOUBLE PRECISION,
    reduced_cource::DOUBLE PRECISION,
    code_iso_num::VARCHAR(3)
FROM (SELECT
	*,
    ROW_NUMBER() OVER (PARTITION BY DATA_ACTUAL_DATE, CURRENCY_RK ORDER BY id DESC) AS ROW_NUMBER
	FROM SOURCE.MD_EXCHANGE_RATE_D
    WHERE data_actual_date IS NOT NULL
        AND currency_rk IS NOT NULL) t
WHERE ROW_NUMBER = 1
ON CONFLICT (DATA_ACTUAL_DATE, CURRENCY_RK) DO UPDATE
SET
    data_actual_end_date = EXCLUDED.data_actual_end_date,
    reduced_cource = EXCLUDED.reduced_cource,
    code_iso_num = EXCLUDED.code_iso_num;

--COMMIT;

