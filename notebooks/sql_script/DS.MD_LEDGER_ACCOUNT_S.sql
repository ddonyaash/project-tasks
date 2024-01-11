--BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
 
 INSERT INTO DS.MD_LEDGER_ACCOUNT_S (
    chapter,
    chapter_name,
    section_number,
    section_name,
    subsection_name,
    ledger1_account,
    ledger1_account_name,
    ledger_account,
    ledger_account_name,
    characteristic,
    is_resident,
    is_reserve,
    is_reserved,
    is_loan,
    is_reserved_assets,
    is_overdue,
    is_interest,
    pair_account,
    start_date,
    end_date,
    is_rub_only,
    min_term,
    min_term_measure,
    max_term,
    max_term_measure,
    ledger_acc_full_name_translit,
    is_revaluation,
    is_correct
)
SELECT
    chapter::CHAR(1),
    chapter_name::VARCHAR(16),
    section_number::INTEGER,
    section_name::VARCHAR(22),
    subsection_name::VARCHAR(21),
    ledger1_account::INTEGER,
    ledger1_account_name::VARCHAR(47),
    ledger_account::INTEGER,
    ledger_account_name::VARCHAR(153),
    characteristic::CHAR(1),
    is_resident::INTEGER,
    is_reserve::INTEGER,
    is_reserved::INTEGER,
    is_loan::INTEGER,
    is_reserved_assets::INTEGER,
    is_overdue::INTEGER,
    is_interest::INTEGER,
    pair_account::VARCHAR(5),
    TO_TIMESTAMP(start_date, 'YYYY-MM-DD') AS start_date,
    TO_TIMESTAMP(end_date, 'YYYY-MM-DD') AS end_date,
    is_rub_only::INTEGER,
    min_term::VARCHAR(1),
    min_term_measure::VARCHAR(1),
    max_term::VARCHAR(1),
    max_term_measure::VARCHAR(1),
    ledger_acc_full_name_translit::VARCHAR(1),
    is_revaluation::VARCHAR(1),
    is_correct::VARCHAR(1)
FROM  (SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY LEDGER_ACCOUNT, START_DATE ORDER BY id DESC) as row_number
    FROM SOURCE.MD_LEDGER_ACCOUNT_S
    WHERE start_date IS NOT NULL
        AND ledger_account IS NOT NULL) t
WHERE row_number = 1
ON CONFLICT (LEDGER_ACCOUNT, START_DATE) DO UPDATE
SET
    chapter = EXCLUDED.chapter,
    chapter_name = EXCLUDED.chapter_name,
    section_number = EXCLUDED.section_number,
    section_name = EXCLUDED.section_name,
    subsection_name = EXCLUDED.subsection_name,
    ledger1_account = EXCLUDED.ledger1_account,
    ledger1_account_name = EXCLUDED.ledger1_account_name,
    characteristic = EXCLUDED.characteristic,
    is_resident = EXCLUDED.is_resident,
    is_reserve = EXCLUDED.is_reserve,
    is_reserved = EXCLUDED.is_reserved,
    is_loan = EXCLUDED.is_loan,
    is_reserved_assets = EXCLUDED.is_reserved_assets,
    is_overdue = EXCLUDED.is_overdue,
    is_interest = EXCLUDED.is_interest,
    pair_account = EXCLUDED.pair_account,
    end_date = EXCLUDED.end_date,
    is_rub_only = EXCLUDED.is_rub_only,
    min_term = EXCLUDED.min_term,
    min_term_measure = EXCLUDED.min_term_measure,
    max_term = EXCLUDED.max_term,
    max_term_measure = EXCLUDED.max_term_measure,
    ledger_acc_full_name_translit = EXCLUDED.ledger_acc_full_name_translit,
    is_revaluation = EXCLUDED.is_revaluation,
    is_correct = EXCLUDED.is_correct;

 
 --COMMIT;