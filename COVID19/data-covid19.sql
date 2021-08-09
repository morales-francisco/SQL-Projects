/*
Covid 19 Dataset
Skills used: Views, CTE's, Joins, Temp Tables, Subqueries, Aggregate Functions, Converting Data Types
*/

---The objective is to pull some data to make visualizations 
USE [Covid-Dataset]
GO

---Creating Views to to make the information more manageable 

CREATE VIEW InfoCovidView AS
SELECT[iso_code],[continent],[location],[date],[stringency_index],[population],[population_density],[median_age],
[aged_65_older],[aged_70_older],[gdp_per_capita],[extreme_poverty],[cardiovasc_death_rate],[diabetes_prevalence],
[female_smokers],[male_smokers],[handwashing_facilities],[hospital_beds_per_thousand],[life_expectancy],[human_development_index],
[excess_mortality]
FROM [Covid-Dataset].[dbo].[covid]
GO

CREATE VIEW CasesCovidView AS
SELECT [iso_code],[continent],[location],[date],[total_cases],[new_cases],[new_cases_smoothed],[total_cases_per_million],
[new_cases_per_million],[new_cases_smoothed_per_million],[reproduction_rate],[icu_patients],[icu_patients_per_million],
[hosp_patients],[hosp_patients_per_million],[weekly_icu_admissions],[weekly_icu_admissions_per_million],[weekly_hosp_admissions],
[weekly_hosp_admissions_per_million]
FROM [Covid-Dataset].[dbo].[covid]
GO

CREATE VIEW DeathsCovidView AS
SELECT[iso_code],[continent],[location],[date],[total_deaths],[new_deaths],[new_deaths_smoothed],[total_deaths_per_million],
[new_deaths_per_million],[new_deaths_smoothed_per_million], [population]
FROM [Covid-Dataset].[dbo].[covid]
GO

CREATE VIEW TestsCovidView AS
SELECT [iso_code],[continent],[location],[date],[new_tests],[total_tests],[total_tests_per_thousand],[new_tests_per_thousand],
[new_tests_smoothed],[new_tests_smoothed_per_thousand],[positive_rate],[tests_per_case],[tests_units]
FROM [Covid-Dataset].[dbo].[covid]
GO

CREATE VIEW	VaccinationCovidView AS
SELECT [iso_code],[continent],[location],[date],[total_vaccinations],[people_vaccinated],[people_fully_vaccinated],
[new_vaccinations],[new_vaccinations_smoothed],[total_vaccinations_per_hundred],[people_vaccinated_per_hundred],
[people_fully_vaccinated_per_hundred],[new_vaccinations_smoothed_per_million]
FROM [Covid-Dataset].[dbo].[covid]
GO

--- Confirmed cases evolution by country 
DROP TABLE IF EXISTS #CasesTemp
GO

SELECT c.continent,
c.location,
CAST(c.date AS DATE) AS Date,
new_cases,
SUM(new_cases) OVER(PARTITION BY c.location ORDER BY c.location, c.date) AS AcumulativeCases,
ROUND((SUM(new_cases) OVER(PARTITION BY c.location ORDER BY c.location, c.date) / population)*100,4) AS PercentageOfPopulation
INTO #CasesTemp
FROM CasesCovidView AS c
JOIN InfoCovidView AS i
ON c.continent = i.continent and c.location = i.location and c.date = i.date
WHERE c.continent IS NOT NULL
ORDER BY c.continent, c.location, c.date

SELECT *
FROM #CasesTemp

--- Countries who have passed the million confirmed cases---
SELECT location, MAX(AcumulativeCases) AS TotalCases
FROM #CasesTemp
GROUP BY location
HAVING MAX(AcumulativeCases) > 1000000
ORDER BY TotalCases DESC 
GO


--- Total cases by month 
WITH CasesMonthCTE AS(
SELECT TOP 200 YEAR(date) AS Year,
MONTH(date) AS MonthNumber,
DATENAME(MONTH,date) as MonthName,
SUM(new_cases) AS TotalCasesByMonth
FROM #CasesTemp
GROUP BY YEAR(date),MONTH(date), DATENAME(MONTH,date)
ORDER BY YEAR(date),MONTH(date) ASC
)
SELECT Year,
MonthName,
TotalCasesByMonth
FROM CasesMonthCTE
GO


---Total tests and positivity rate 
SELECT t.continent,
t.location,
CAST(t.date AS DATE) AS Date,
new_tests,
new_cases,
ROUND((new_cases/new_tests)*100,2) AS PositivityRate,
SUM(new_tests) OVER(PARTITION BY t.location ORDER BY t.location, t.date) AS	TotalTests
FROM TestsCovidView AS t
JOIN CasesCovidView AS c
ON c.continent = t.continent and c.location = t.location and c.date = t.date
WHERE t.continent IS NOT NULL
ORDER BY t.location, t.date


--- Deaths evolution by country 
WITH DeathsCTE AS( 
SELECT continent,
location,
CAST(date AS DATE) AS Date,
new_deaths,
SUM(new_deaths) OVER(PARTITION BY location ORDER BY location, date) AS TotalDeaths,
population
FROM DeathsCovidView
WHERE continent IS NOT NULL
)
SELECT continent,
location,
date,
new_deaths,
TotalDeaths,
ROUND(TotalDeaths/population*1000000,4) AS DeathsPerMillion
FROM DeathsCTE
GO


--- Total deaths by month 
SELECT Year,
MonthName,
TotalDeathsByMonth
FROM ( 
SELECT TOP 200 YEAR(date) AS Year,
MONTH(date) AS MonthNumber,
DATENAME(MONTH,date) as MonthName,
SUM(new_deaths) AS TotalDeathsByMonth
FROM DeathsCovidView
WHERE continent IS NOT NULL
GROUP BY YEAR(date),MONTH(date), DATENAME(MONTH,date)
ORDER BY YEAR(date),MONTH(date) ASC
) AS DeathsMonths
GO

--- Top 20 countries with most deaths per million habitants 
SELECT TOP 20 location,
population,
MAX(total_deaths) AS TotalDeaths,
ROUND((MAX(total_deaths)/population)*1000000,2) AS DeathsPerMillion
FROM DeathsCovidView
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathsPerMillion DESC



---Number of people who received at least one vaccine dose 
SELECT v.continent,
v.location,
CAST(v.date AS date) AS Date,
people_fully_vaccinated,
ROUND((people_fully_vaccinated / population)*100,2) AS PercentageOfPopulation
FROM VaccinationCovidView AS v
JOIN InfoCovidView AS i
ON v.continent = i.continent AND v.location = i.location AND v.date = i.date
WHERE v.continent IS NOT NULL
ORDER BY v.location, v.date
