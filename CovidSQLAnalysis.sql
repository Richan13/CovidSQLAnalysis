--SELECT *
--FROM Portfolio_Project.dbo.CovidVaccinations
--ORDER BY 3, 4

-- CovidDeaths Table had duplicate entries

--SELECT DISTINCT *
--INTO duplicate_table
--FROM Portfolio_Project..CovidDeaths

--DELETE Portfolio_Project..CovidDeaths


--INSERT Portfolio_Project..CovidDeaths
--SELECT *
--FROM duplicate_table

--DROP TABLE duplicate_table

SELECT DISTINCT *
INTO Portfolio_Project.dbo.CovidDeath

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project.dbo.CovidDeaths
WHERE continent is not NULL
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths
-- The likelihood of dying if you contract covid
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/CONVERT(float, total_cases))*100 AS DeathPercentage
FROM Portfolio_Project.dbo.CovidDeaths
WHERE location like '%states%' and continent is not NULL
ORDER BY 1, 2

-- Looking at the Total Cases vs Population
-- Shows what percentage of the population is affected

SELECT location, date, total_cases, population, CONVERT(float, total_cases)/population*100 AS CasePercentage
FROM Portfolio_Project.dbo.CovidDeaths
WHERE location like '%states' and continent is not NULL
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((CONVERT(float, total_cases)/population)*100) as PercentPopulationInfected
FROM Portfolio_Project.dbo.CovidDeaths
WHERE continent is not NULL
Group by Location, Population
ORDER BY 4 desc

-- Showing the countries with the highest death count
SELECT location, population, MAX(total_deaths) as HighestDeathCount, MAX((CONVERT(float, total_deaths)/population)*100) as PercentPopulationDeaths
FROM Portfolio_Project.dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY Location, Population
ORDER BY 3 desc

-- total deaths by continent
SELECT continent, SUM(CAST(total_deaths as BIGINT)) as TotaltDeathCount
FROM Portfolio_Project.dbo.CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY 2 desc


-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as TotalNewCases, SUM(cast(new_deaths as int)) as TotalNewDeaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
FROM Portfolio_Project.dbo.CovidDeaths
WHERE continent is not NULL 
GROUP BY date
HAVING SUM(new_cases) != 0


-- Total Population vs Total Vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
COUNT(*)
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
where dea.continent is not NULL
GROUP BY dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
HAVING COUNT(*) > 1

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
where dea.continent is not NULL
ORDER BY 2, 3


-- USING CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
where dea.continent is not NULL
-- ORDER BY 2, 3
)
SELECT location, population, MAX(RollingPeopleVaccinated) AS TotalPeopleVaccinated, 
MAX(RollingPeopleVaccinated)/population*100
FROM PopvsVac
GROUP BY location, population

-- TEMP Table

IF OBJECT_ID('TempDB..#PercentPopulationVaccinated','U') IS NOT NULL
DROP TABLE #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
where dea.continent is not NULL
-- ORDER BY 2, 3

SELECT location, population, MAX(RollingPeopleVaccinated) AS TotalPeopleVaccinated, 
MAX(RollingPeopleVaccinated)/population*100
FROM #PercentPopulationVaccinated
GROUP BY location, population

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
where dea.continent is not NULL
-- ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated