-- DATA CLEANING PROJECT --

CREATE DATABASE world_layoffs;
USE world_layoffs;

-- Upload dataset inside layoffs --

SELECT *
FROM layoffs;

-- STEPS INVOLVED IN DATA CLEANING --
/*   1. REMOVING DUPLICATES
     2. STANDARDIZING DATA
     3. ADDRESSING NULL AND BLANK VALUES
     4. REMOVE UNNECESSARY ROWS/COLUMNS      */

-- STEP 1. REMOVING DUPLICATES --

-- Creating staging table (layoffs_staging) to perform queries so that if we make any mistake, the raw data remains as it is 

CREATE TABLE layoffs_staging            
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;

-- since there is no unique identifier in the table, we'll add row number

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;

-- making cte to look for duplicates 

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry,
total_laid_off, percentage_laid_off,
`date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging
)
SELECT *                            -- duplicates found
FROM duplicate_cte
WHERE row_num > 1;          

SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- since we cannot delete duplicates through cte, we'll create a new table (layoffs_staging2) with an extra column (row_num)

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
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry,
total_laid_off, percentage_laid_off,
`date`, stage, country, funds_raised_millions) as row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- now we can delete duplicates from layoffs_staging2

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;

-- STEP 2. STANDARDIZING DATA --

SELECT *
FROM layoffs_staging2;

-- Going through company column 

SELECT company, TRIM(company)       -- issue found regarding white spaces
FROM layoffs_staging2;

-- removing white spaces

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Going through industry column

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;                      -- issue found WHERE industry LIKE 'Crypto%'

SELECT DISTINCT industry
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- updating industry crypto

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Going through location column

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY location;                      -- no issue found

-- Going through country column

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;                      -- issue found WHERE country LIKE 'United States%'


SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%';

-- updating country United States

UPDATE layoffs_staging2                          -- method 1
SET country = 'United States'
WHERE country LIKE 'United States%';

-- or --

UPDATE layoffs_staging2                          -- method 2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- formatting dates

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')                  -- '%m/%d/%Y' is the original format in the table
FROM layoffs_staging2;

-- updating date format 

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- updating data type of date column

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- updating data type of total_laid_off column

ALTER TABLE layoffs_staging2
MODIFY COLUMN total_laid_off DOUBLE;

-- updating data type of percentage_laid_off column

ALTER TABLE layoffs_staging2
MODIFY COLUMN percentage_laid_off DOUBLE;

-- STEP 3. ADDRESSING NULL AND BLANK VALUES --

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- updating all the blank values as null in industry column 

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *                                         -- 4 rows found
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *                                         -- one row has 'Travel' in industry column
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- populating industry column (null or blank values) with data from another row of the same company

SELECT t1.industry, t2.industry 
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company                        -- we can join on company and location both as well
WHERE (t1.industry IS NULL)
AND (t2.industry IS NOT NULL OR t2.industry = '');

UPDATE layoffs_staging2 t1                            -- 3 rows updated
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *                                              -- 'Bally's Interactive' is still null 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

SELECT *                                              -- There's only one row with company 'Bally's Interactive' 
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- STEP 4. REMOVE UNNECESSARY ROWS/COLUMNS

SELECT *                                              -- We can get rid of these rows coz they are of no use
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- deleting rows with no layoff data

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *                                              -- We don't need column row_num anymore
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;