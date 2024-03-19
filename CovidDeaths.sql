-- Fields to work on
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
Where continent is not null
ORDER BY 1,2

-- TOTAL CASES VS TOTAL DEATHS
-- Calculating the percentage of total deaths
-- Shows likelihood of contracting Covid

SELECT location, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths$
-- WHERE location like 'africa%' -- wild card at the end will ensure that only location that with the word 'africa' only are returned
WHERE location = 'South Africa'
ORDER BY 4 desc

-- TOTAL CASES VS POPULATION
-- Show the percentage of the populatin that has covid

SELECT location, date, population, total_cases, (total_cases/population)*100 as InfectionsPercentage
FROM PortfolioProject..CovidDeaths$
-- GROUP BY location - group by doesn't work here because there isn't an aggregate function
ORDER BY InfectionsPercentage desc

-- COUNTRIES WITH HIGHEST INFECTION COMPARED TO POPULATION

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionsPercentage
FROM PortfolioProject..CovidDeaths$
Group by location, population
Order by InfectionsPercentage DESC

 -- COUNTRIES WITH HIGHEST DEATH COUNT PER POPULATION

Select location, population, max(cast(total_deaths as int)) as HighestDeathCount, max((total_deaths/population))*100 as PopulationDeathsPercentage
From PortfolioProject..CovidDeaths$
Where continent is not null
Group by location, population
Order by HighestDeathCount desc

-- BREAKING THE NUMBERS DOWN BY  CONTINENT

Select continent, Max(cast(total_deaths as int)) as HighestDeathCount
From PortfolioProject..CovidDeaths$
Where continent is not null
Group by continent
order by HighestDeathCount desc

-- GLOBAL NUMBERS

Select date, Sum(new_cases) as total_cases, Sum(cast(new_deaths as int)) as total_deaths, Sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is not null
Group by date
Order by 1, 2

-- GLOBAL NUMBER - looking at only the total cases without the date or location
Select Sum(new_cases) as total_cases, Sum(cast(new_deaths as int)) as total_deaths, Sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths$
where continent is not null
-- Group by date
Order by 1, 2

-- JOINING THE TWO TABLES - joining the two tables on location and on date (since the tables don't seem to have PKs, joining them on the common columns like location and date makes sense)

SELECT *
From PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date

-- Total Population vs Vaccinaction
-- BASED ON THE JOINED TABLES: Total Population vs Vaccinaction - How many people in the world have been vaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null --Note: we are adding this because are inaccurate when it shows locations where the continent is null
Order By 2,3 -- So this is ordered by location and date

-- DOING A ROLLING COUNT - The numbers in the new vaccinations should add up!?
-- Need to use the PARTITION BY

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(int,vac.new_vaccinations)) Over (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order By 2,3 

-- TOTAL NUMBER OF PEOPLE VACCINATED BASED ON THE RollingPeopleVaccinated
-- Use a CTE
-- Note: If the number of columns in the CTE is different than the number of columns in the Select statement, then you will get an error. The column number should be the same

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(int,vac.new_vaccinations)) Over (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--Order By 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 As PercentagePopulationVaccinated
From PopvsVac


-- TEMP TABLE
-- This will have the same effect/result as the CTE
-- Remember: For a temp table you have to specify the data type because it's like creating a table where you would specify the data type

Drop Table if exists #PercentPopulationVaccinated -- This will ensure that this runs and the table is created again just in case you made changes or simply need to run the table again, otherwise you'll get an error
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(int,vac.new_vaccinations)) Over (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 As PercentagePopulationVaccinated
From #PercentPopulationVaccinated


-- Creating a View to store data for later visualizations
-- VIEW

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(int,vac.new_vaccinations)) Over (Partition By dea.location Order By dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null


