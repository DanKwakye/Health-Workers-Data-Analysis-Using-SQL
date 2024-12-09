USE nursing_data;

SELECT 
    COUNT(*)
FROM
    daily_nurse_staffing;

--  basic statistics for MDScensus across the entire dataset.
SELECT 
	MIN(MDScensus) AS min_MDScensus,
    MAX(MDScensus) AS max_MDScensus,
    AVG(MDScensus) AS avg_MDScensus,
    STDDEV(MDScensus) AS stddev_MDScensus,
    COUNT(*) AS total_days
FROM daily_nurse_staffing;

 -- the average and total patient census for each day
SELECT 
    WorkDate,
    SUM(MDScensus) AS total_MDScensus,
    AVG(MDScensus) AS avg_MDScensus
FROM
    daily_nurse_staffing
GROUP BY WorkDate
ORDER BY WorkDate , total_MDScensus DESC;

--  the daily census for each provider
SELECT 
    PROVNAME WorkDate, MDScensus
FROM
    daily_nurse_staffing
ORDER BY MDScensus DESC
LIMIT 100 ;

-----


SELECT 
    STATE, AVG(MDScensus) AS avg_MDScensus
FROM
    daily_nurs e_staffing
GROUP BY STATE
ORDER BY avg_MDScensus DESC;

-- lets dig deeper to find the states where the PROVIDERS have zero patience

SELECT DISTINCT
    PROVNAME, STATE
FROM
    daily_nurse_staffing
WHERE
    MDScensus = 0;




-- identifying the providers with the highest average patient census.
SELECT 
    PROVNAME, STATE, AVG(MDScensus) AS avg_MDScensus
FROM
    daily_nurse_staffing
GROUP BY PROVNAME , STATE
ORDER BY avg_MDScensus DESC
LIMIT 5;

-- analyzing the correlation between patient census (MDScensus) and direct care RN hours (Hrs_RNDON).
SELECT 
    MDScensus, AVG(Hrs_RNDON)
FROM
    daily_nurse_staffing
GROUP BY MDScensus
ORDER BY MDScensus DESC;
-- turnsout average 0.00 hours are spents at one of the highest residence place by RN Director of Nursing
-- looking at other Nursing to find out the average number of hours spent
SELECT 
    MDScensus,
    AVG(Hrs_RNDON),
    AVG(Hrs_RN),
    AVG(Hrs_LPN),
    AVG(Hrs_CNA),
    AVG(Hrs_NAtrn),
    AVG(Hrs_MedAide)
FROM
    daily_nurse_staffing
GROUP BY MDScensus
ORDER BY MDScensus DESC;
-- upon further querying, we realized that Nurse Aide in Training and Med Aide/Technician are almost redundant and should be let go,
-- however, attention should be given to Registered Nursing, Certified Nursing AND Licensed Practical Nursing and and if possible, recruit more, especially CNA.


 -- identifies days with very low or very high census compared to the overall average .
WITH CensusStats AS (
	SELECT
		AVG(MDScensus) AS avg_MDScensus,
        STDDEV(MDScensus) AS stddev_MDScensus
FROM daily_nurse_staffing
)
SELECT 
	WorkDate,
    PROVNAME,
    MDScensus
FROM daily_nurse_staffing, CensusStats
WHERE MDScensus > avg_MDScensus + 2 * stddev_MDScensus
	OR MDScensus < avg_MDScensus - 2 * stddev_MDScensus
ORDER BY WorkDate, MDScensus DESC;

WITH CensusStats AS (
    SELECT
        AVG(MDScensus) AS avg_MDScensus,
        STDDEV(MDScensus) AS stddev_MDScensus
    FROM daily_nurse_staffing
),
MonthlyCensus AS (
    SELECT 
       DATE_FORMAT(WorkDate, '%Y-%m-01') AS Month, 
        AVG(MDScensus) AS avg_monthly_MDScensus,
        SUM(MDScensus) AS total_monthly_MDScensus,
        COUNT(WorkDate) AS total_days_in_month,
        MAX(MDScensus) AS max_daily_MDScensus,
        MIN(MDScensus) AS min_daily_MDScensus
    FROM daily_nurse_staffing
    GROUP BY DATE_FORMAT(WorkDate, '%Y-%m-01')
)
SELECT 
    Month,
    avg_monthly_MDScensus,
    total_monthly_MDScensus,
    total_days_in_month,
    max_daily_MDScensus,
    min_daily_MDScensus
FROM MonthlyCensus
ORDER BY avg_monthly_MDScensus DESC;


SELECT 
    YEAR(WorkDate) AS year,
    MONTH(WorkDate) AS month,
    SUM(MDScensus) AS total_census,
    SUM(Hrs_RNDON) AS total_RNDON_hours,
    SUM(Hrs_RN) AS total_RN_hours,
    SUM(Hrs_LPN) AS total_LPN_hours,
    SUM(Hrs_CNA) AS total_CNA_hours,
    AVG(Hrs_RNDON) AS avg_RNDON_hours_per_day,
    AVG(Hrs_RN) AS avg_RN_hours_per_day,
    AVG(Hrs_LPN) AS avg_LPN_hours_per_day,
    AVG(Hrs_CNA) AS avg_CNA_hours_per_day
FROM
    daily_nurse_staffing
GROUP BY YEAR(WorkDate) , MONTH(WorkDate)
ORDER BY year DESC , month DESC;
SELECT 
    YEAR(WorkDate) AS year,
    MONTH(WorkDate) AS month,
    SUM(MDScensus) AS total_census,
    SUM(Hrs_RNDON) AS total_RNDON_hours,
    SUM(Hrs_RN) AS total_RN_hours,
    SUM(Hrs_LPN) AS total_LPN_hours,
    SUM(Hrs_CNA) AS total_CNA_hours,
    AVG(Hrs_RNDON) AS avg_RNDON_hours_per_day,
    AVG(Hrs_RN) AS avg_RN_hours_per_day,
    AVG(Hrs_LPN) AS avg_LPN_hours_per_day,
    AVG(Hrs_CNA) AS avg_CNA_hours_per_day
FROM
    daily_nurse_staffing
GROUP BY YEAR(WorkDate) , MONTH(WorkDate)
ORDER BY year DESC , month DESC;
    
    
-- comparison between employee and contract nurse hours
SELECT 
    'Employee' AS Nurse_Type,
    AVG(Hrs_RNDON_emp + Hrs_RNadmin_emp + Hrs_RN_emp + Hrs_LPNadmin_emp + Hrs_LPN_emp + Hrs_CNA_emp) AS Avg_Employee_Hours
FROM
    daily_nurse_staffing 
UNION ALL SELECT 
    'Contract' AS Nurse_Type,
    AVG(Hrs_RNDON_ctr + Hrs_RNadmin_ctr + Hrs_RN_ctr + Hrs_LPNadmin_ctr + Hrs_LPN_ctr + Hrs_CNA_ctr) AS Avg_Contract_Hours
FROM
    daily_nurse_staffing;



CREATE TEMPORARY TABLE temp_staffing_trends AS
SELECT PROVNAME, STATE, MDScensus, Hrs_RNDON, Hrs_RNDON_emp, Hrs_RNDON_ctr, Hrs_RNadmin, Hrs_RNadmin_emp Hrs_RNadmin_ctr
FROM daily_nurse_staffing;

-- Querying the temporary table to identify trends
-- Average staffing levels per state of Registered_Nurse
SELECT 
    STATE,
    COUNT(DISTINCT PROVNAME) AS num_providers,
    AVG(Hrs_RNDON) AS state_avg_Hrs_RNDON,
    AVG(Hrs_RNadmin) AS state_avg_Hrs_RNadmin
FROM
    temp_staffing_trends
GROUP BY STATE
ORDER BY state_avg_Hrs_RNadmin , num_providers DESC;


 -- Top 5 providers with the highest average RN hours (direct care)
SELECT 
    PROVNAME, STATE, AVG(Hrs_RNDON) AS avg_Hrs_RNDON
FROM
    temp_staffing_trends
GROUP BY PROVNAME , STATE
ORDER BY avg_Hrs_RNDON DESC
LIMIT 5;

SELECT 
    PROVNAME,
    STATE,
    AVG(MDScensus),
    AVG(Hrs_RNDON) AS avg_Hrs_RNDON,
    AVG(Hrs_RN_emp),
    AVG(Hrs_RN_ctr),
    AVG(Hrs_LPN),
    AVG(Hrs_LPN_emp),
    AVG(Hrs_LPN_ctr),
    AVG(Hrs_CNA),
    AVG(Hrs_CNA_emp),
    AVG(Hrs_CNA_ctr),
    AVG(Hrs_NAtrn),
    AVG(Hrs_MedAide)
FROM
    daily_nurse_staffing
GROUP BY PROVNAME , STATE
ORDER BY avg_Hrs_RNDON DESC
LIMIT 5;


 -- Providers with highest dependency on contracted staff
SELECT 
    PROVNAME,
    STATE,
    AVG(Hrs_RNDON_ctr / NULLIF(Hrs_RNDON_emp, 0)) AS contract_to_emp_ratio
FROM
    temp_staffing_trends
GROUP BY PROVNAME , STATE
ORDER BY contract_to_emp_ratio DESC
LIMIT 5;


-- Calculate the standard deviation of staffing levels for RNs and LPNs
WITH RN_StdDev AS (
  SELECT 
    STDDEV(Hrs_RN) AS RN_StdDev
  FROM daily_nurse_staffing
),
LPN_StdDev AS (
  SELECT 
    STDDEV(Hrs_LPN) AS LPN_StdDev
  FROM daily_nurse_staffing
)
SELECT 
  RN_StdDev, LPN_StdDev
FROM 
  RN_StdDev, LPN_StdDev;
  
  -- Calculate the daily standard deviation of total staff hours
WITH DailyStaffing AS (
  SELECT WorkDate,
         SUM(Hrs_RNDON + Hrs_RNDON_emp + Hrs_RNDON_ctr + Hrs_RNadmin + Hrs_RNadmin_emp + Hrs_RNadmin_ctr + Hrs_RN + Hrs_RN_emp + Hrs_RN_ctr + Hrs_LPNadmin + Hrs_LPNadmin_emp + Hrs_LPNadmin_ctr + Hrs_LPN + Hrs_LPN_emp + Hrs_LPN_ctr + Hrs_CNA + Hrs_CNA_emp + Hrs_CNA_ctr + Hrs_NAtrn + Hrs_NAtrn_emp + Hrs_NAtrn_ctr + Hrs_MedAide + Hrs_MedAide_emp + Hrs_MedAide_ctr) AS TotalHours
  FROM daily_nurse_staffing
  GROUP BY WorkDate
)
SELECT 
  STDDEV(TotalHours) AS StdDev_TotalHours
FROM DailyStaffing;

-- Calculate the standard deviation of staffing levels for each staff category
SELECT 
    AVG(Hrs_RN) AS Avg_RN_Hours,
    STDDEV(Hrs_RN) AS StdDev_RN_Hours,
    AVG(Hrs_LPN) AS Avg_LPN_Hours,
    STDDEV(Hrs_LPN) AS StdDev_LPN_Hours,
    AVG(Hrs_CNA) AS Avg_CNA_Hours,
    STDDEV(Hrs_CNA) AS StdDev_CNA_Hours,
    AVG(Hrs_NAtrn) AS Avg_NAtrn_Hours,
    STDDEV(Hrs_NAtrn) AS StdDev_NAtrn_Hours,
    AVG(Hrs_MedAide) AS Avg_MedAide_Hours,
    STDDEV(Hrs_MedAide) AS StdDev_MedAide_Hours
FROM
    daily_nurse_staffing;


-- Calculate staffing ratios for each shift and date
WITH ShiftRatios AS (
  SELECT
    WorkDate,
    MDScensus AS TotalPatients,
    SUM(Hrs_RN) / SUM(MDScensus) AS RN_to_Patient_Ratio,
    SUM(Hrs_LPN) / SUM(MDScensus) AS LPN_to_Patient_Ratio
  FROM
    daily_nurse_staffing
  GROUP BY
    WorkDate, MDScensus
)
SELECT
  WorkDate,
  RN_to_Patient_Ratio,
  LPN_to_Patient_Ratio
FROM
  ShiftRatios
ORDER BY
  WorkDate;
    

-- calcualte the number and Percentage of PROVNAMES with less than 10 MDScensus
SELECT 
    COUNT(*) AS TotalProvNames,
    COUNT(DISTINCT CASE
            WHEN MDScensus < 10 THEN PROVNAME
        END) AS ProvNamesWithLessThan10MDScensus,
    (COUNT(DISTINCT CASE
            WHEN MDScensus < 10 THEN PROVNAME
        END) / COUNT(*)) * 100 AS Percentage
FROM
    daily_nurse_staffing;
  
SELECT 
    COUNT(*) AS TotalProvNames,
    COUNT(DISTINCT CASE
            WHEN MDScensus > 50 THEN PROVNAME
        END) AS ProvNamesWithMoreThan10MDScensus,
    (COUNT(DISTINCT CASE
            WHEN MDScensus > 50 THEN PROVNAME
        END) / COUNT(*)) * 100 AS Percentage
FROM
    daily_nurse_staffing;
    
-- total hours by various nurses to identify dependency
SELECT
    SUM(Hrs_RNDON) AS Total_Hours_RNDON,
    SUM(Hrs_RNadmin) AS Total_Hours_RNadmin,
    SUM(Hrs_RN) AS Total_Hours_RN,
    SUM(Hrs_LPNadmin) AS Total_Hours_LPNadmin,
    SUM(Hrs_LPN) AS Total_Hours_LPN,
    SUM(Hrs_CNA) AS Total_Hours_CNA,
    SUM(Hrs_NAtrn) AS Total_Hours_NAtrn,
    SUM(Hrs_MedAide) AS Total_Hours_MedAide
FROM 
    daily_nurse_staffing;
