--Deaths IN the U.S 


SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) *100 as deathpercentage
From Project..Coviddeaths
WHERE location LIKE '%states%'
AND continent is not null 
Order by 1,2 ;


--Total Cases vs Population
--Percent of Population infected 


SELECT location, date, total_cases, population, (total_cases/population) *100 as populationinfectedpercent
From Project..Coviddeaths
WHERE location LIKE '%states%'
AND continent is not null 
Order by 1,2 ;


--Total Deaths by Country


SELECT location, MAX (cast (total_deaths as int)) as totaldeathcount 
From Project..Coviddeaths
WHERE continent is not null 
GROUP BY location
Order by totaldeathcount desc;


-- Total Deaths by Continent 


SELECT location, MAX (cast (total_deaths as int)) as totaldeathcount 
From Project..Coviddeaths
WHERE continent is null 
AND location NOT LIKE '%income%' 
GROUP BY location
Order by totaldeathcount desc;



-- Countries with Highest Infection Rate compared to population 

SELECT location, population, MAX (total_cases) as highestinfectioncount,MAX ((total_cases/population)) *100.00 as populationinfectedpercent
From Project..Coviddeaths
WHERE continent is not null
GROUP BY location, population
Order by populationinfectedpercent desc;



--Continents with the Highest Deatcount 


SELECT location,MAX (cast(total_deaths as int)) as totaldeaths
From Project..Coviddeaths
WHERE continent is null 
AND location NOT LIKE '%income%'
AND location NOT LIKE '%World%'
AND location NOT LIKE '%Union%'
AND location NOT LIKE '%international%'
GROUP BY location
Order by totaldeaths desc;


--Continents with the Highest Deathrate 


SELECT location, MAX (population)as peakpopulation, MAX (cast(total_deaths as int)) as totaldeaths, MAX ((total_deaths/population)) *100.00 as populationdeathspercent
From Project..Coviddeaths
WHERE continent is null 
AND location NOT LIKE '%income%'
AND location NOT LIKE '%World%'
AND location NOT LIKE '%Union%'
AND location NOT LIKE '%international%'
GROUP BY location
Order by populationdeathspercent desc;


--Global Numbers 


Select SUM (new_cases) as globalcases, SUM (cast(new_deaths as int)) as globaldeaths, 
SUM (cast(new_deaths as int))/ SUM (new_cases) * 100 as globaldeathrate
From Project..Coviddeaths
Where continent is not null 
Order by 1,2 ;


--Global Numbers Time progression 


Select date, SUM (new_cases) as globalcases, SUM (cast(new_deaths as int)) as globaldeaths, 
SUM (cast(new_deaths as int))/ SUM (new_cases) * 100 as globaldeathrate
From Project..Coviddeaths
Where continent is not null 
Group by date
Order by 1,2 ;


--JOIN. Total Population Vs Vaccinations 

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
 SUM (convert(bigint, cv.new_vaccinations)) OVER (partition by cd.location Order by cd.location, cd.date) as rollingpeoplevaccinated
 --,(rollingpeoplevaccinated/cd.population) *100 as percentvaccinated
From Project..Coviddeaths as cd
JOIN Project..Covidvacs as cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent is not null 
order by 2,3

--Expanding Total Population Vs Vaccinations using CTE

WITH popvsvac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
 SUM (convert(bigint, cv.new_vaccinations)) OVER (partition by cd.location Order by cd.location, cd.date) as rollingpeoplevaccinated
 --,(rollingpeoplevaccinated/cd.population) *100 as percentvaccinated
From Project..Coviddeaths as cd
JOIN Project..Covidvacs as cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent is not null 
--order by 2,3
) 

Select *, (rollingpeoplevaccinated/population) *100 as percentvaccinated
FROM popvsvac
order by location, date


--Temp Table to Find number of 0Vaccinations administered per capita over time

Drop table if exists #percentvaccinated 
Create table #percentvaccinated 
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric,
)

Insert into #percentvaccinated 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
 SUM (convert(bigint, cv.new_vaccinations)) OVER (partition by cd.location Order by cd.location, cd.date) as rollingpeoplevaccinated
 --,(rollingpeoplevaccinated/cd.population) *100 as percentvaccinated
From Project..Coviddeaths as cd
JOIN Project..Covidvacs as cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent is not null 
--order by 2,3
 

Select *, (rollingpeoplevaccinated/population) as vaccinationsperperson
FROM #percentvaccinated
ORDER BY location, date


--Percent of people with at least 1 vaccine by country

Drop table if exists #percentvaccinated 
Create table #percentvaccinated 
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
population numeric,
new_people_vaccinated_smoothed numeric,
rollingpeoplevaccinated numeric,
)

Insert into #percentvaccinated 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_people_vaccinated_smoothed ,
 SUM (convert(bigint, cv.new_people_vaccinated_smoothed)) OVER (partition by cd.location Order by cd.location, cd.date) as rollingpeoplevaccinated
 --,(rollingpeoplevaccinated/cd.population) *100 as percentvaccinated
From Project..Coviddeaths as cd
JOIN Project..Covidvacs as cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent is not null 
--order by 2,3
 

Select *, (rollingpeoplevaccinated/population) as PercentPopAtLeast1Vax
FROM #percentvaccinated
ORDER BY location, date