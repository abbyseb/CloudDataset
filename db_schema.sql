-- DuckDB schema aligned with report.tex §5 (Stage 5): simplified two-table storage model.
-- Paths use Data/; Assignment 2 CLI rewrites to assignment2Data/ when applied programmatically elsewhere.
--
-- 1) denormalised — wide integrated facility-year table from final_denormalized.csv
-- 2) corporate_total — NGER corporate roll-up from CorporateTotal.csv
-- Logical join (not enforced): corporate_total can be joined to denormalised on
--   (reporting_entity, reporting_year) for analysis.

CREATE TABLE IF NOT EXISTS denormalised AS
SELECT * FROM read_csv_auto('Data/final_denormalized.csv', HEADER=TRUE);

CREATE TABLE IF NOT EXISTS corporate_total AS
SELECT * FROM read_csv_auto('Data/CorporateTotal.csv', HEADER=TRUE);
