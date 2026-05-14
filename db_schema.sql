-- DuckDB Database Schema for AU Energy Transition Project
-- Architecture: Denormalized-as-Staging (final integrated CSV + corporate totals CSV)
-- Source of truth: Section 5 of submission-all-steps.ipynb (cells that CREATE staging/dims/facts)

--------------------------------------------------------------------------------
-- 1. STAGING LAYER (Final Cleaned Datasets)
--------------------------------------------------------------------------------

-- Central denormalized dataset containing NGER, CER, and ABS attributes
CREATE TABLE IF NOT EXISTS staging_final_denormalized AS
SELECT * FROM read_csv_auto('Data/final_denormalized.csv', HEADER=TRUE);

-- NGER corporate totals (as provided in CorporateTotal.csv)
CREATE TABLE IF NOT EXISTS staging_nger_corporate_totals AS
SELECT * FROM read_csv_auto('Data/CorporateTotal.csv', HEADER=TRUE);

--------------------------------------------------------------------------------
-- 2. DIMENSION TABLES (Derived from Staging)
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS dim_reporting_year AS
SELECT DISTINCT CAST(year AS INTEGER) AS year
FROM staging_final_denormalized
WHERE year IS NOT NULL
ORDER BY year;

CREATE TABLE IF NOT EXISTS dim_australian_state AS
SELECT
  state AS state_code,
  max(label) AS state_name
FROM staging_final_denormalized
GROUP BY state
ORDER BY state;

CREATE TABLE IF NOT EXISTS dim_energy_site AS
SELECT
  source_system,
  facility_name_clean AS site_name_clean,
  max(facility_name) AS site_name,
  state,
  max(latitude) AS latitude,
  max(longitude) AS longitude,
  max(geocode_status) AS geocode_status,
  max(geocode_query) AS geocode_query,
  max(display_name) AS display_name
FROM staging_final_denormalized
GROUP BY source_system, facility_name_clean, state;

CREATE TABLE IF NOT EXISTS dim_reporting_entity AS
SELECT DISTINCT reporting_entity
FROM staging_final_denormalized
WHERE reporting_entity IS NOT NULL
ORDER BY reporting_entity;

--------------------------------------------------------------------------------
-- 3. FACT TABLES (Granular metrics)
--------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS fact_energy_facility_year AS
SELECT
  source_system,
  state,
  CAST(year AS INTEGER) AS year,
  facility_name,
  facility_name_clean,
  fuel_group,
  primary_fuel,
  reporting_year,
  reporting_entity,
  facility_type,
  electricity_production_gj,
  electricity_production_mwh,
  scope1_emissions_tco2e,
  scope2_emissions_tco2e,
  total_emissions_tco2e,
  emission_intensity_tco2e_per_mwh,
  grid_connected,
  grid,
  scope1_imputed,
  scope2_imputed,
  total_imputed,
  intensity_imputed,
  project_status,
  mw_capacity,
  accreditation_code,
  postcode,
  accreditation_start_date,
  approval_date,
  committed_date,
  reference_date,
  reference_year,
  latitude,
  longitude,
  geocode_status,
  geocode_query,
  display_name,
  abs_joined
FROM staging_final_denormalized;

-- ABS demographic context at state-year level (one row per state-year in current build)
CREATE TABLE IF NOT EXISTS fact_abs_state_year_context AS
SELECT DISTINCT state, CAST(year AS INTEGER) AS year, label
FROM staging_final_denormalized
WHERE year IS NOT NULL;

CREATE TABLE IF NOT EXISTS fact_nger_corporate_year_totals AS
SELECT *
FROM staging_nger_corporate_totals;

--------------------------------------------------------------------------------
-- 4. OPTIONAL CONSTRAINTS / VALIDATION (NOT automatically applied by the notebook DDL above)
--------------------------------------------------------------------------------
-- The notebook optionally applies PRIMARY KEY constraints on some dimensions:
--   pk_dim_reporting_year(year)
--   pk_dim_australian_state(state_code)
--   pk_dim_energy_site(source_system, site_name_clean, state)
--
-- DuckDB foreign-key support via ALTER TABLE may be limited depending on version/settings;
-- the notebook validates referential integrity using LEFT JOIN counts instead of FK constraints.
