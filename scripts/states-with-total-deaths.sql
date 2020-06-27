// Note, data includes:
//      District of Columbia
//      New York City
//      Puerto Rico

// distinct states with totals and percentage
SELECT
    replace(state, " Total", "") as state_name,
    sum(covid_19_deaths) as t_covid_19_deaths,
    sum(total_deaths) as t_total_deaths,
    round((sum(covid_19_deaths) / sum(total_deaths)) * 100, 2) as covid_percentage
from
    dsas
where
    state like "% Total"
    and state != "United States Total"
group by
    replace(state, "New York City", "New York")  // NYC is in NY!
order by
    covid_percentage desc

GO