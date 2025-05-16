-- Data Cleaning, to fix and clean raw data to make it usable to visualize or analyze
USE world_layoffs;

SELECT * 
FROM layoffs
ORDER BY company;

-- 1) Remove duplicates if there are any 
-- 2) Standardize the Data, fix spelling and stuff so it is all the same
-- 3) Null values or Blank Values, populate if needed
-- 4) remove Columns or Rows that are not needed


-- Make a temp table to work with, good practice, happens in real life work place
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

-- Remove duplicates

-- Checks if everyhting is unique
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS 
(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE 
FROM duplicate_cte
WHERE row_num>1;

-- New table to work with

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2
ORDER BY company;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num>1;

-- Deleted all duplicates
DELETE
FROM layoffs_staging2
WHERE row_num>1;

SELECT *
FROM layoffs_staging2;


-- 2) Standardizing Data, 

-- Removing extra spaces to standardize
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Making all similar names the same 
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;


SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Making Crypto, CryptoCurrecny, and Crypto Currecy all Crypto
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

--  Remove extra periods from countries, specifically United States
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
WHERE country LIKE 'United States%';

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'UNITED STATES%';


-- Change date from string to actual date and time
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y') -- converts string to date where it is month, day, 4 number year 
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET date = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Changed the date column from text to date variable type
ALTER TABLE layoffs_staging2 -- NEVER DO THIS IN RAW TABLE
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;

-- 3) Fix NULL and Blank Values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry is NULL 
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Check which rows have empty info that we can fill
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry ='')
AND t2.industry IS NOT NULL;

-- Change all empty to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Change all NULL to connected known industry (only using stuff we know from the table)
UPDATE layoffs_staging2 t1
Join layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- Remove columns and rows that are not needed

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND Percentage_laid_off IS NULL;

-- Deleted rows that have no important data (total_laid_off and percentage_laid_off)
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND Percentage_laid_off IS NULL;


-- Remove row_num since we are done using it
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;
