# Clinical Heart Disease — SQL + Power BI

**Goal**  
Practice end-to-end analytics on a clinical dataset and communicate insights clearly. I leverage my biotechnology/microbiology background to keep the clinical context accurate.

**Stack**  
SQLite (DBeaver) for data cleaning & SQL queries · Power BI for the dashboard

---

## Data
- Source: Kaggle — Heart Disease Dataset  
  https://www.kaggle.com/datasets/johnsmith88/heart-disease-dataset  
- Origin: UCI Heart Disease (Cleveland, Hungary, Switzerland, Long Beach V; 1988).  
- Note: The Kaggle CSV includes many exact duplicates. I cleaned in SQLite and analyzed **302 unique patients** (deduplicated).

---

## What I built
1. **SQL cleaning:** imported the raw CSV to `heart_raw`, created a typed & deduplicated table `heart` (`SELECT DISTINCT`), normalized `? → NULL`, and set correct types (e.g., `oldpeak` as REAL).  
2. **KPIs:** prevalence overall, by gender and age group; cholesterol trends; a high-risk slice (Resting BP ≥140, Cholesterol ≥240, exercise-induced angina = Yes).  
3. **Dashboard:** one page with slicers for Age Group, Gender, and Exercise-induced Angina.

---

## Results (from the report)
- Patients: **302**  
- Prevalence of heart disease: **54.3%**  
- Average age: **54** years  
- Average cholesterol: **247 mg/dl**  
- High-risk disease % (BP ≥140, Chol ≥240, Angina=Yes): **13.0%**

---

## Screenshot
Go to powerbi folder

---

## Reproduce
- **SQL:** open `sql/queries_sqlite_heart_disease.sql` in DBeaver (SQLite).  
- **Power BI:** connect to your local `heart.db` via ODBC (or rebuild from the SQL steps).

**Note**  
Exploratory analytics for learning. Not diagnostic or medical advice.
