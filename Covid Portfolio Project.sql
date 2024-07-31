CREATE DATABASE PortfolioProjectcoviddeaths
-- SELECT* 
-- FROM portfolioproject.coviddeaths
-- ORDER BY 3,4

-- SELECT* 
-- FROM portfolioproject.covidvaccinations
-- ORDER BY 3,4

-- Select the data that we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population_density
FROM portfolioproject.coviddeaths
ORDER BY total_cases, new_cases;

-- Looking at the total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/ total_cases)*100 as Deathpercentage
FROM portfolioproject.coviddeaths
WHERE location like '%states%'
ORDER BY 1,2;


-- looking at the total cases vs population
-- Shows what percentage of population got covid

SELECT Location, date,population_density, total_cases,  (total_cases/ population_density)*100 as PercentPopulationInfected
FROM portfolioproject.coviddeaths
WHERE location like '%states%'
ORDER BY 1,2;


-- Looking at countries with highest infection rate compared to population

SELECT Location,population_density, max(total_cases) as Highestinfectioncount,  max((total_cases/ population_density))*100 as PercentPopulationInfected
FROM portfolioproject.coviddeaths
-- WHERE location like '%states%'
group by location, population_density
ORDER BY PercentPopulationInfected desc

--Showing the countries with the highest death count per population

SELECT Location, max(total_deaths) as totaldeathcount
FROM portfolioproject.coviddeaths
-- WHERE location like '%states%'
WHERE continent is not null
group by location 
ORDER BY totaldeathcount desc

-- LETS BREAK THINGS DOWN BY CONTINENT
-- Showing the continents with the highest death counts

SELECT location, max(total_deaths) as totaldeathcount
FROM portfolioproject.coviddeaths
-- WHERE location like '%states%'
WHERE continent is not null
group by location 
ORDER BY totaldeathcount desc


-- Global numbers

SELECT date, SUM(new_cases), SUM(cast(new_deaths as int)), SUM(cast(new_deaths as int))/ SUM(new_cases)*100 as Deathpercentage
FROM portfolioproject.coviddeaths
-- WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;


SELECT 
    date, 
    SUM(new_cases) AS total_new_cases, 
    SUM(CAST(new_deaths AS UNSIGNED)) AS total_new_deaths, 
    (SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM 
    portfolioproject.coviddeaths
WHERE 
    continent IS NOT NULL
GROUP BY 
    date
ORDER BY 
    date, total_new_cases;
    
 -- Looking at total population vs vs vaccinations
 
SELECT dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations,
sum(convert (int, vac.new_vaccinations)) OVER(partition by dea.location ORDER BY dea.location, dea.date ) as Rollingpeoplevaccinated,
-- (Rollingpeoplevaccinated/ population)*100
FROM portfolioproject.coviddeaths dea
JOIN portfolioproject.covidvaccinations vac
ON dea.location= vac.location
AND dea.date= vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3;


-- USE CTE

WITH popvsvac (Continent, Location, Date, Population,New_vaccinations, Rollingpeoplevaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations,
sum(convert (int, vac.new_vaccinations)) OVER(partition by dea.location ORDER BY dea.location, dea.date ) as Rollingpeoplevaccinated,
-- (Rollingpeoplevaccinated/ population)*100
FROM portfolioproject.coviddeaths dea
JOIN portfolioproject.covidvaccinations vac
ON dea.location= vac.location
AND dea.date= vac.date
WHERE dea.continent is NOT NULL
-- ORDER BY 2,3
)
SELECT*, (Rollingpeoplevaccinated/ population)*100
FROM popvsvac


-- Temp table

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations,
sum(convert (int, vac.new_vaccinations)) OVER(partition by dea.location ORDER BY dea.location, dea.date ) as Rollingpeoplevaccinated,
-- (Rollingpeoplevaccinated/ population)*100
FROM portfolioproject.coviddeaths dea
JOIN portfolioproject.covidvaccinations vac
ON dea.location= vac.location
AND dea.date= vac.date
WHERE dea.continent is NOT NULL
-- ORDER BY 2,3
SELECT*, (Rollingpeoplevaccinated/ population)*100
FROM #PercentPopulationVaccinated



-- Drop the temporary table if it already exists
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

-- Create the temporary table
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population_density AS Population, 
    vac.New_vaccinations,
    SUM(CAST(vac.New_vaccinations AS UNSIGNED)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    portfolioproject.coviddeaths dea
JOIN 
    portfolioproject.covidvaccinations vac
ON 
    dea.location = vac.location
AND 
    dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

-- Select from the temporary table and calculate the vaccination percentage
SELECT 
    Continent, 
    Location, 
    Date, 
    Population, 
    New_vaccinations, 
    RollingPeopleVaccinated, 
    (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM 
    PercentPopulationVaccinated;

-- Optionally, drop the temporary table if you no longer need it
-- DROP TEMPORARY TABLE PercentPopulationVaccinated;




-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations,
sum(convert (int, vac.new_vaccinations)) OVER(partition by dea.location ORDER BY dea.location, dea.date ) as Rollingpeoplevaccinated,
-- (Rollingpeoplevaccinated/ population)*100
FROM portfolioproject.coviddeaths dea
JOIN portfolioproject.covidvaccinations vac
ON dea.location= vac.location
AND dea.date= vac.date
WHERE dea.continent is NOT NULL
-- ORDER BY 2,3