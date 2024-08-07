#Tableau information i want to display
#copy query result into new excel doc

#total cases and death percentage
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
From coviddeaths
#Where location like '%states%'
where continent is not null 
#Group By date
order by 1,2

#death percentage by date from highest to lowest point
Select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
FROM coviddeaths
#Where location like '%states%'
#where location is 'World'
Group By date
order by DeathPercentage desc;

#total deathcount by country including continents
Select location, SUM(new_deaths) as TotalDeathCount
From coviddeaths
#Where location like '%states%'
Where continent is not null 
and location not in ('World', 'European Union', 'International', 'High income', 'Low income')
Group by location
order by TotalDeathCount desc

#Percentage infected by country
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From coviddeaths
#Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

https://public.tableau.com/app/profile/daniel.burke7699/viz/CovidDashboard_16707348494740/Dashboard1