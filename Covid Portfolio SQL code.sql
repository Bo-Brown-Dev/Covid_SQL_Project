/*
# Covid-19 Data Exploration using SQL



## Setup



In this notebook I will be exploring data related to covid deaths and covid vaccinations using SQL. 



We will observe two tables named Deaths and Vaccinations. I imported from Excel files retrieved from a publically available dataset developed by ourworldindata.org. I import these tables using SQL Server Management Studio, and below I write a query to make sure the import was successful:
*/

--Let's Check the Vaccinations Table
SELECT *
FROM CovidProject..Vaccinations
ORDER BY 3,4;

--Let's check the Deaths table
SELECT *
FROM CovidProject..Deaths
ORDER BY 3,4;

/*
Looks good!



## Exploration



First I want to examine Total Cases by Total Deaths in the United States. We will define this calculation as the Mortality Rate.
*/

--Take Total Deaths by Total Cases as a percentage
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as MortalityRate
FROM Deaths
WHERE location like '%states%'
ORDER BY 1, 2;

/*
We can see from the data that the mortality rate, as we actually have data for it, starts very high and then slowly reduces before increasing and then reducing again. I wonder why the mortality rate would start so high. I'll come back to this question.



Now let's explore infectiousness. I want to compare Total Cases by population as a percentage and call this InfectionRate
*/

--take total cases by population as a percentage
SELECT location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
FROM Deaths
WHERE location LIKE '%states%'
order by 1, 2;

/*
I wonder if Covid has been more infectious in certain countries?



I'll try to understand infectivity across countries below:
*/

--Countries by infectivity at highest infection count
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 as InfectionRate
FROM Deaths
WHERE continent IS NOT null
GROUP BY location, population
order by InfectionRate desc;



/*
We can clearly see the percentage of the population that has been infected by country.



  



Now let's see the mortality rate by country:
*/

SELECT location, population, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount, MAX(total_deaths/population)*100 as MortalityRate
FROM Deaths
WHERE continent IS NOT null
GROUP BY location, population
order by MortalityRate desc;


/*
Let's break this down by continent as well
*/

SELECT continent, SUM(population) as TotalPop, MAX(CAST(total_deaths AS INT)) AS HighestDeathCount, ((SUM(CAST(total_deaths AS INT)))/(SUM(total_cases)))*100 as MortalityRate
FROM Deaths
WHERE continent IS NOT null
GROUP BY continent
order by MortalityRate desc;

/*
This table is pretty clear. We see that we include the EU which is not a continent, and International, which is not a continent, but we can leave this for now. 



Let's take a look at global statistics. I want to see mortality rate to date and mortality rate per day:
*/

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/(SUM(new_cases))*100 AS MortalityRate
FROM Deaths
WHERE continent IS NOT null
order by 1, 2;

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/(SUM(new_cases))*100 AS MortalityRate
FROM Deaths
WHERE continent IS NOT null
GROUP BY date
order by 1, 2;

/*
Now let's make use of our other table, Vaccinations.



Let's see a rolling count of vaccinations in each country by day:
*/

SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, vaccinations.new_vaccinations, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY Deaths.Location ORDER BY deaths.location, deaths.date) as RollingVaxCount
FROM Deaths
JOIN Vaccinations
    ON Deaths.location = Vaccinations.location
    AND Deaths.date = Vaccinations.date
WHERE deaths.continent IS NOT null
ORDER BY 1, 2, 3;

/*
Now let's make some sense of this new table:
*/

WITH PopByVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaxCount)
AS
(SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, vaccinations.new_vaccinations, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY Deaths.Location ORDER BY deaths.location, deaths.date) as Rolling_Vax_count
FROM Deaths
JOIN Vaccinations
    ON Deaths.location = Vaccinations.location
    AND Deaths.date = Vaccinations.date
WHERE deaths.continent IS NOT null)
SELECT *,  (RollingVaxCount/population)*100 AS PercentVaccinated
FROM PopByVac;

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaxCount numeric,
)
INSERT INTO #PercentPopulationVaccinated
SELECT 
    Deaths.continent, 
    Deaths.location, 
    Deaths.date, 
    Deaths.population, 
    vaccinations.new_vaccinations, 
    SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY Deaths.Location ORDER BY Deaths.location, Deaths.date) as RollingVaxCount
FROM Deaths
JOIN Vaccinations
    ON Deaths.location = Vaccinations.location
    AND Deaths.date = Vaccinations.date
SELECT *
FROM #PercentPopulationVaccinated


CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    Deaths.continent, 
    Deaths.location, 
    Deaths.date, 
    Deaths.population, 
    vaccinations.new_vaccinations, 
    SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY Deaths.Location ORDER BY Deaths.location, Deaths.date) as RollingVaxCount
FROM Deaths
JOIN Vaccinations
    ON Deaths.location = Vaccinations.location
    AND Deaths.date = Vaccinations.date