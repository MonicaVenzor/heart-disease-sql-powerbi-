/* ======================================================================
   Heart Disease (SQLite) — Import, Clean, KPIs
   Author: Monica
   Dataset: Kaggle — https://www.kaggle.com/datasets/johnsmith88/heart-disease-dataset
   Origin: UCI Heart Disease (Cleveland, Hungary, Switzerland, Long Beach V; 1988)
   Purpose: Create clean analytical table `heart` (302 unique patients) and run KPIs
   Notes:
     - Raw CSV may include duplicates; we deduplicate with SELECT DISTINCT.
     - Missing markers like '?' in `ca` and `thal` are normalized to NULL.
     - `oldpeak` is REAL (decimal) to preserve precision.
   ====================================================================== */

/* 0) RAW IMPORT (assumed):
      In DBeaver, import the CSV as table `heart_raw` (headers on).
      Columns expected (raw names): 
      age, sex, cp, trestbps, chol, fbs, restecg, thalach, exang, oldpeak, slope, ca, thal, target
*/

/* 1) Build clean, typed, de-duplicated analytical table */
DROP TABLE IF EXISTS heart;

CREATE TABLE heart (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  age       INTEGER,
  sex       INTEGER,      -- 0=female, 1=male
  cp        INTEGER,      -- chest pain type (0–3)
  trestbps  INTEGER,      -- resting blood pressure (mm Hg)
  chol      INTEGER,      -- serum cholesterol (mg/dl)
  fbs       INTEGER,      -- fasting blood sugar >120 mg/dl (1/0)
  restecg   INTEGER,      -- resting ECG (0–2)
  thalach   INTEGER,      -- max heart rate achieved
  exang     INTEGER,      -- exercise-induced angina (1/0)
  oldpeak   REAL,         -- ST depression (decimal)
  slope     INTEGER,      -- slope of ST segment (0–2)
  ca        INTEGER,      -- number of major vessels (0–3) colored by fluoroscopy
  thal      INTEGER,      -- thalassemia code
  target    INTEGER       -- 1=disease, 0=no disease
);

INSERT INTO heart (
  age,sex,cp,trestbps,chol,fbs,restecg,thalach,exang,oldpeak,slope,ca,thal,target
)
SELECT DISTINCT
  CAST(age AS INTEGER),
  CAST(sex AS INTEGER),
  CAST(cp AS INTEGER),
  CAST(trestbps AS INTEGER),
  CAST(chol AS INTEGER),
  CAST(fbs AS INTEGER),
  CAST(restecg AS INTEGER),
  CAST(thalach AS INTEGER),
  CAST(exang AS INTEGER),
  CAST(oldpeak AS REAL),
  CAST(slope AS INTEGER),
  CAST(NULLIF(TRIM(ca),'?') AS INTEGER),
  CAST(NULLIF(TRIM(thal),'?') AS INTEGER),
  CAST(target AS INTEGER)
FROM heart_raw;

/* 2) Helpful indexes */
CREATE INDEX IF NOT EXISTS idx_heart_target ON heart(target);
CREATE INDEX IF NOT EXISTS idx_heart_sex    ON heart(sex);
CREATE INDEX IF NOT EXISTS idx_heart_age    ON heart(age);

/* 3) Sanity checks (quick profiling) */
SELECT COUNT(*) AS total_patients FROM heart;

SELECT target AS heart_disease, COUNT(*) AS n
FROM heart
GROUP BY target;

SELECT MIN(age) AS min_age, ROUND(AVG(age),1) AS avg_age, MAX(age) AS max_age
FROM heart;

SELECT ROUND(AVG(chol),1) AS avg_chol, SUM(chol IS NULL) AS missing_chol
FROM heart;

/* 4) View with Age Bands (to reuse same bucketing as in Power BI) */
DROP VIEW IF EXISTS v_heart_ageband;

CREATE VIEW v_heart_ageband AS
SELECT
  h.*,
  CASE
    WHEN age < 40 THEN '<40'
    WHEN age BETWEEN 40 AND 49 THEN '40-49'
    WHEN age BETWEEN 50 AND 59 THEN '50-59'
    WHEN age BETWEEN 60 AND 69 THEN '60-69'
    ELSE '70+'
  END AS age_band
FROM heart h;

/* 5) Core KPIs & Analysis */

/* 5.1 Overall prevalence */
SELECT ROUND(100.0 * AVG(target), 1) AS pct_with_disease
FROM heart;

/* 5.2 By sex (Female/Male) */
SELECT
  CASE sex WHEN 0 THEN 'Female' WHEN 1 THEN 'Male' END AS sex,
  COUNT(*) AS n,
  ROUND(100.0 * AVG(target), 1) AS pct_with_disease
FROM heart
GROUP BY sex
ORDER BY pct_with_disease DESC;

/* 5.3 By age band (using the view) */
SELECT
  age_band,
  COUNT(*) AS n,
  ROUND(100.0 * AVG(target), 1) AS pct_with_disease
FROM v_heart_ageband
GROUP BY age_band
ORDER BY
  CASE age_band
    WHEN '<40' THEN 1
    WHEN '40-49' THEN 2
    WHEN '50-59' THEN 3
    WHEN '60-69' THEN 4
    ELSE 5
  END;

/* 5.4 Cholesterol by age (for line chart; keep only ages with n>=3) */
SELECT
  age,
  ROUND(AVG(chol),1) AS avg_chol,
  COUNT(*) AS n
FROM heart
GROUP BY age
HAVING COUNT(*) >= 3
ORDER BY age;

/* 5.5 Risk slice (Resting BP >= 140, Chol >= 240, Exercise angina = 1) */
SELECT
  COUNT(*) AS risk_patients,
  ROUND(100.0 * AVG(target), 1) AS risk_prevalence_pct
FROM heart
WHERE trestbps >= 140
  AND chol >= 240
  AND exang = 1;

/* 5.6 Interaction: sex × chest pain type (cp) */
SELECT
  CASE sex WHEN 0 THEN 'Female' WHEN 1 THEN 'Male' END AS sex,
  cp AS chest_pain_type,
  COUNT(*) AS n,
  ROUND(100.0 * AVG(target), 1) AS pct_with_disease
FROM heart
GROUP BY sex, cp
HAVING COUNT(*) >= 5
ORDER BY pct_with_disease DESC;

/* 6) One-row validation summary (aligns with your dashboard cards) */
WITH
overall AS (
  SELECT
    COUNT(*) AS total_patients,
    ROUND(100.0 * AVG(target), 1) AS pct_with_disease,
    ROUND(AVG(age), 0) AS avg_age,
    ROUND(AVG(chol), 0) AS avg_chol
  FROM heart
),
risk AS (
  SELECT
    COUNT(*) AS risk_patients,
    ROUND(100.0 * AVG(target), 1) AS risk_pct
  FROM heart
  WHERE trestbps >= 140 AND chol >= 240 AND exang = 1
)
SELECT
  o.total_patients,
  o.pct_with_disease,
  o.avg_age,
  o.avg_chol,
  r.risk_patients,
  r.risk_pct
FROM overall o
CROSS JOIN risk r;

/* =============================== END =============================== */
