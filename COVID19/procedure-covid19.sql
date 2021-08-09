/*
Covid 19 Dataset 
Skills used: Procedure, CTE's, Joins, Variables, Aggregate Functions, Converting Data Types, If statements, Over
*/


USE [Covid-Dataset]
GO

--- Create a procedure to obtain global information for a country and perior of time 
DROP PROCEDURE IF EXISTS CountryInformation
GO
CREATE PROCEDURE CountryInformation(@Country NVARCHAR(50), @DateFrom DATE = '20200101', @DateTo DATE = '20210730')
AS
BEGIN
	IF @DateFrom NOT IN (SELECT DISTINCT(date) FROM covid WHERE continent IS NULL)
		BEGIN
			PRINT('The DateFrom variable is not valid')
		END

	IF @DateTo NOT IN (SELECT DISTINCT(date) FROM covid WHERE continent IS NULL)
		BEGIN
			PRINT('The DateTo variable is not valid')
		END

	IF @Country IN (SELECT DISTINCT(Location) FROM covid WHERE continent IS NULL)
		BEGIN
			PRINT('This is a continent')
		END

	IF @Country NOT IN (SELECT DISTINCT(Location) FROM covid WHERE continent IS NOT NULL)
		BEGIN
			PRINT('The country does not exists')
		END

	IF (@Country IN (SELECT DISTINCT(Location) FROM covid WHERE continent IS NOT NULL)	AND @DateFrom IN (SELECT DISTINCT(date) FROM covid WHERE continent IS NOT NULL) AND @DateTo IN (SELECT DISTINCT(date) FROM covid WHERE continent IS NOT NULL))
		BEGIN
			WITH Cases AS(
			SELECT TOP 200 ROW_NUMBER() OVER(ORDER BY SUM(new_cases) DESC) AS RankCases,
			location AS Location,
			SUM(new_cases) AS ConfirmedCases,
			ROUND((SUM(new_cases) / MAX(population))*100,2) AS PercentageOfPopulation
			FROM covid
			WHERE continent IS NOT NULL AND date BETWEEN @DateFrom AND @DateTo
			GROUP BY location
			ORDER BY SUM(new_cases) DESC),

			Deaths AS(
			SELECT TOP 200 ROW_NUMBER() OVER(ORDER BY SUM(new_deaths) DESC) AS RankDeaths,
			location AS Location,
			SUM(new_deaths) as ConfirmedDeaths,
			ROUND((SUM(new_deaths) / SUM(new_cases) )*100,2) AS CaseFatalityRate
			FROM covid
			WHERE continent IS NOT NULL AND date BETWEEN @DateFrom AND @DateTo
			GROUP BY location
			ORDER BY sum(new_deaths) DESC),

			Tests AS(
			SELECT TOP 200 ROW_NUMBER() OVER(ORDER BY SUM(new_tests) DESC) AS RankTests,
			location AS Location,
			SUM(new_tests) as Tests,
			CAST((SUM(new_tests) / MAX(population))*1000000 AS INT) AS TestPerMillionHabitants ,
			ROUND((SUM(new_cases) / SUM(new_tests) )*100,2) AS PositivityRate
			FROM covid
			WHERE continent IS NOT NULL AND date BETWEEN @DateFrom AND @DateTo
			GROUP BY location
			ORDER BY Tests  DESC),

			Vaccination AS(
			SELECT TOP 200 ROW_NUMBER() OVER(ORDER BY SUM(new_vaccinations) DESC) AS RankVacc,
			location AS Location,
			SUM(new_vaccinations) as TotalVaccineDoses,
			MAX(people_vaccinated) as AtLeastOneDose,
			MAX(people_fully_vaccinated) as FullyVaccinated,
			ROUND((MAX(people_vaccinated) /MAX(population))*100,2) AS PercentageWithAtLeastOneDose,
			ROUND((MAX(people_fully_vaccinated) /MAX(population))*100,2) AS PercentageFullyVaccinated
			FROM covid
			WHERE continent IS NOT NULL AND date BETWEEN @DateFrom AND @DateTo
			GROUP BY location
			ORDER BY TotalVaccineDoses DESC)

			SELECT c.Location as Country,
			RankCases,
			ConfirmedCases,
			PercentageOfPopulation,
			RankDeaths,
			ConfirmedDeaths,
			CaseFatalityRate,
			RankTests,
			Tests,
			TestPerMillionHabitants,
			PositivityRate,
			RankVacc,
			TotalVaccineDoses,
			AtLeastOneDose,
			FullyVaccinated,
			PercentageWithAtLeastOneDose,
			PercentageFullyVaccinated
			FROM Cases AS c
			LEFT JOIN Deaths AS d
			ON c.Location = d.Location
			LEFT JOIN Tests AS t
			ON t.Location = c.Location
			LEFT JOIN Vaccination AS v
			ON v.Location = c.Location
			WHERE c.Location = @Country
		END
END
GO

EXEC CountryInformation 'Argentina'
GO
EXEC CountryInformation 'United States'
GO
EXEC CountryInformation 'Croatia','20190505', '20210505'
GO
EXEC CountryInformation 'India', @DateFrom = '20200122', @DateTo = '20221231'
GO
EXEC CountryInformation 'Test', @DateFrom ='20200305', @DateTo= '20210405'
GO