USE GooglePlayStoreDB
GO

---First look at the table 
SELECT * FROM PlayStoreV1
GO
--- Looking for duplicate records 
SELECT Rating, App, Category, Reviews, Size, Installs, Type, Price, [Content Rating], Genres, [Last Updated], [Current Ver], [Android Ver], COUNT(App)
FROM PlayStoreV1
GROUP BY Rating, App, Category, Reviews, Size, Installs, Type, Price, [Content Rating], Genres, [Last Updated], [Current Ver], [Android Ver]
HAVING COUNT(App) > 1
ORDER BY COUNT(App) DESC
GO

---Create a temp table to storage the unique records
DROP TABLE IF EXISTS #UniqueRecords
GO
SELECT DISTINCT * 
INTO #UniqueRecords
FROM PlayStoreV1
GO

--- Verifying unique records in the temp table 
SELECT Rating, App, Category, Reviews, Size, Installs, Type, Price, [Content Rating], Genres, [Last Updated], [Current Ver], [Android Ver], COUNT(App)
FROM #UniqueRecords
GROUP BY Rating, App, Category, Reviews, Size, Installs, Type, Price, [Content Rating], Genres, [Last Updated], [Current Ver], [Android Ver]
HAVING COUNT(App) > 1
ORDER BY COUNT(App) DESC 
GO

--- Removing records with 'Varies with device
DELETE FROM #UniqueRecords
WHERE Size = 'Varies with device'

DELETE FROM #UniqueRecords
WHERE [Current Ver] = 'Varies with device'

DELETE FROM #UniqueRecords
WHERE [Android Ver] = 'Varies with device'
GO

SELECT  * FROM #UniqueRecords
GO

SELECT *
INTO PlayStoreV2
FROM #UniqueRecords


--- Cleaning the Category column
SELECT REPLACE(Category, '_',' ')
FROM PlayStoreV2

UPDATE PlayStoreV2
SET Category=REPLACE(Category, '_',' ')
GO


SELECT UPPER(LEFT(Category,1))+LOWER(SUBSTRING(Category,2,LEN(Category)))
FROM PlayStoreV2

UPDATE PlayStoreV2
SET Category= UPPER(LEFT(Category,1))+LOWER(SUBSTRING(Category,2,LEN(Category)))
GO

--- Normalize al the records from the column "Size" in MB
SELECT Size, CASE
WHEN RIGHT(Size,1) = 'k' THEN 1
WHEN RIGHT(Size,1) = 'M' THEN 1024 END
FROM PlayStoreV2

ALTER TABLE PlayStoreV2
ADD SizeInMB FLOAT
GO

UPDATE PlayStoreV2
SET SizeInMB = CASE
WHEN right(Size,1) = 'k' THEN 1
WHEN right(Size,1) = 'M' THEN 1024 END
GO

UPDATE PlayStoreV2
SET Size = replace(Size, 'M','')
GO
update PlayStoreV2
SET Size = replace(Size, 'k','')
GO


SELECT DISTINCT SizeInMB FROM PlayStoreV2

ALTER TABLE PlayStoreV2
ALTER COLUMN size FLOAT

SELECT Size, Size * SizeInMB FROM PlayStoreV2

UPDATE PlayStoreV2
SET SizeInMB = Size * SizeInMB
GO

SELECT ROUND(SizeInMB/1024,2) FROM PlayStoreV2

UPDATE PlayStoreV2
SET SizeInMB= ROUND(SizeInMB/1024,2)
GO

SELECT * FROM PlayStoreV2

--- Cleaning the 'Installs' column 
SELECT DISTINCT Installs
FROM PlayStoreV2
GO

SELECT DISTINCT(REPLACE(Installs,',','')) FROM PlayStoreV2
UPDATE PlayStoreV2
SET Installs = REPLACE(Installs,',','')
GO


SELECT DISTINCT(REPLACE(Installs,'+','')) FROM PlayStoreV2
UPDATE PlayStoreV2
SET Installs = REPLACE(Installs,'+','')
GO

ALTER TABLE PlayStoreV2
GO

---The "Genres" column
SELECT DISTINCT(Genres) FROM PlayStoreV2

---Add a semicolon to clean and separate each genre "combination"
SELECT CONCAT(Genres, ';') FROM PlayStoreV2

UPDATE PlayStoreV2
SET Genres = CONCAT(Genres, ';')
GO

SELECT SUBSTRING(Genres, 1,CHARINDEX(';', Genres)-1) AS Genre1,
REPLACE(SUBSTRING(Genres, CHARINDEX(';', Genres) + 1, LEN(Genres)),';','') AS Genre2
FROM PlayStoreV2

ALTER TABLE PlayStoreV2
ADD Genre1 NVARCHAR(255)

ALTER TABLE PlayStoreV2
ADD Genre2 NVARCHAR(255)
GO

UPDATE PlayStoreV2
SET Genre1 = SUBSTRING(Genres, 1,CHARINDEX(';', Genres)-1)
GO

UPDATE PlayStoreV2
SET Genre2 = REPLACE(SUBSTRING(Genres, CHARINDEX(';', Genres) + 1, LEN(Genres)),';','')
GO
---  "Last Updated" Column
SELECT REPLACE(LOWER([Last Updated]), '.','') FROM PlayStoreV2
UPDATE PlayStoreV2
SET [Last Updated] = REPLACE(LOWER([Last Updated]), '.','')
GO

--- Day, month and year
ALTER TABLE PlayStoreV2
ADD DayNumber NVARCHAR (10)
GO
SELECT SUBSTRING([Last Updated],1,2) FROM PlayStoreV2
UPDATE PlayStoreV2
SET DayNumber = SUBSTRING([Last Updated],1,2)
GO

ALTER TABLE PlayStoreV2
ADD MonthNumber NVARCHAR (10)
GO
SELECT CASE
WHEN SUBSTRING([Last Updated],4,3) = 'jan' THEN '01'
WHEN SUBSTRING([Last Updated],4,3) = 'feb' THEN '02'
WHEN SUBSTRING([Last Updated],4,3) = 'mar' THEN '03'
WHEN SUBSTRING([Last Updated],4,3) = 'apr' THEN '04'
WHEN SUBSTRING([Last Updated],4,3) = 'may' THEN '05'
WHEN SUBSTRING([Last Updated],4,3) = 'jun' THEN '06'
WHEN SUBSTRING([Last Updated],4,3) = 'jul' THEN '07'
WHEN SUBSTRING([Last Updated],4,3) = 'aug' THEN '08'
WHEN SUBSTRING([Last Updated],4,3) = 'sep' THEN '09'
WHEN SUBSTRING([Last Updated],4,3) = 'oct' THEN '10'
WHEN SUBSTRING([Last Updated],4,3) = 'nov' THEN '11'
WHEN SUBSTRING([Last Updated],4,3) = 'dec' THEN '12'
END, [Last Updated]
FROM PlayStoreV2

UPDATE PlayStoreV2
SET MonthNumber = CASE
WHEN SUBSTRING([Last Updated],4,3) = 'jan' THEN '01'
WHEN SUBSTRING([Last Updated],4,3) = 'feb' THEN '02'
WHEN SUBSTRING([Last Updated],4,3) = 'mar' THEN '03'
WHEN SUBSTRING([Last Updated],4,3) = 'apr' THEN '04'
WHEN SUBSTRING([Last Updated],4,3) = 'may' THEN '05'
WHEN SUBSTRING([Last Updated],4,3) = 'jun' THEN '06'
WHEN SUBSTRING([Last Updated],4,3) = 'jul' THEN '07'
WHEN SUBSTRING([Last Updated],4,3) = 'aug' THEN '08'
WHEN SUBSTRING([Last Updated],4,3) = 'sep' THEN '09'
WHEN SUBSTRING([Last Updated],4,3) = 'oct' THEN '10'
WHEN SUBSTRING([Last Updated],4,3) = 'nov' THEN '11'
WHEN SUBSTRING([Last Updated],4,3) = 'dec' THEN '12'
END
GO

ALTER TABLE PlayStoreV2
ADD YearNumber NVARCHAR (10)
GO
SELECT CONCAT('20',SUBSTRING([Last Updated],LEN([Last Updated])-1,2)) FROM PlayStoreV2
UPDATE PlayStoreV2
SET YearNumber = CONCAT('20',SUBSTRING([Last Updated],LEN([Last Updated])-1,2))
GO

--- Create the date column
ALTER TABLE PlayStoreV2
ADD DateLastUpdated DATE
GO
SELECT CONVERT(DATE, CONCAT(YearNumber, MonthNumber, DayNumber)) FROM PlayStoreV2
UPDATE PlayStoreV2
SET DateLastUpdated = CONVERT(DATE, CONCAT(YearNumber, MonthNumber, DayNumber))

--- Remove the 'and up' from the 'Android Ver' column.
SELECT DISTINCT([Android Ver]) FROM PlayStoreV2

SELECT REPLACE([Android Ver],' and up','') FROM PlayStoreV2
UPDATE PlayStoreV2
SET [Android Ver] = REPLACE([Android Ver],' and up','')
GO
SELECT DISTINCT([Android Ver]) FROM PlayStoreV2

UPDATE PlayStoreV2
SET [Android Ver] = REPLACE([Android Ver],' - 7.1.1','')
UPDATE PlayStoreV2
SET [Android Ver] = REPLACE([Android Ver],' - 6.0','')
UPDATE PlayStoreV2
SET [Android Ver] = REPLACE([Android Ver],' - 8.0','')
UPDATE PlayStoreV2
SET [Android Ver] = REPLACE([Android Ver],'W','')
GO


SELECT DISTINCT([Android Ver]) FROM PlayStoreV2


--- Drop the columns that were cleaned
ALTER TABLE PlayStoreV2
DROP COLUMN Size
GO
ALTER TABLE PlayStoreV2
DROP COLUMN Genres
GO
ALTER TABLE PlayStoreV2
DROP COLUMN [Last Updated]
GO
ALTER TABLE PlayStoreV2
DROP COLUMN DayNumber
GO
ALTER TABLE PlayStoreV2
DROP COLUMN YearNumber
GO
ALTER TABLE PlayStoreV2
DROP COLUMN MonthNumber


--- Select to export the information

SELECT * FROM PlayStoreV2 




