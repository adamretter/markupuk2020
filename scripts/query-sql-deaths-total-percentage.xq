xquery version "3.1";

import module namespace sql = "http://exist-db.org/xquery/sql";

let $deaths-sql := '
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
	    replace(state, "New York City", "New York")
	order by
	    covid_percentage desc
'
return
	let $conn := sql:get-connection("org.mariadb.jdbc.Driver", "jdbc:mariadb://localhost/covid?user=root")
	return
		let $sql-results := sql:execute($conn, $deaths-sql, true())
		return
			<deaths>
			{
				for $sql-result in $sql-results//sql:row
				return
					<death>
						<state>{$sql-result/sql:state_name/text()}</state>
						<total>{$sql-result/sql:t_total_deaths/text()}</total>
						<covid19>{$sql-result/sql:t_covid_19_deaths/text()}</covid19>
						<covid-percentage>{$sql-result/sql:covid_percentage/text()}</covid-percentage>
					</death>
			}
			</deaths>
