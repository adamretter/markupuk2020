xquery version "3.1";

(:~
 :
 : Answering the question: 
 : 		"Is there a proportionate relationsip between Covid-19 mortalities and Covid-19 relief funding?"
 :
 : Combines Graph (RDF using SPARQL) and Relational data (using SQL)
 : into XML, and then generates two reports in HTML format.
 :)

import module namespace fuseki = "http://evolvedbinary.com/muk20/fuseki"
	at "file:///Users/aretter/tmp-code/MarkukUK2020/scripts/fuseki.xqm";
import module namespace functx = "http://www.functx.com";
import module namespace sql = "http://exist-db.org/xquery/sql";
import module namespace transform = "http://exist-db.org/xquery/transform";



declare function local:total-deaths-by-state() as element(deaths) {
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
							<covid19-percentage>{$sql-result/sql:covid_percentage/text()}</covid19-percentage>
						</death>
				}
				</deaths>
};

declare function local:total-hhs-funding-by-state() as element(payments) {
	let $funding-sparql := '
		PREFIX ds:  <https://data.cdc.gov/resource/kh8y-3es6/>
		PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

		SELECT ?state (sum(?payment_amount) as ?total_payment)
 		WHERE {
      		?provider ds:state ?state ;
					ds:payment ?payment
      		BIND (xsd:integer(replace(?payment, "[^0-9]", "")) as ?payment_amount)
      	}
      	GROUP BY ?state
      	ORDER BY ?state
	'
	return
		let $sparql-results := fuseki:query("hhs", $funding-sparql)
		return
			<payments>
			{
				for $sparql-result in $sparql-results//*:result
				return
					<payment>
						<state>{$sparql-result/*:binding[@name eq "state"]/functx:trim(.)}</state>
						<total currency="usd">{$sparql-result/*:binding[@name eq "total_payment"]/functx:trim(.)}</total>
					</payment>
			}
			</payments>
			
};

declare function local:deaths-calculate-percentage-of-all($deaths as element(deaths)) {
	<deaths>
	{
		let $total := sum($deaths//total/xs:integer(.))
		let $covid19-total := sum($deaths//covid19[child::node()]/xs:integer(.))
		return
		(
			<total>{$total}</total>,
			<covid19>{$covid19-total}</covid19>,
			for $death in $deaths/death
			let $total-percentage-of-all := ($death/total/xs:integer(.) div $total) * 100.0
			let $covid19-percentage-of-all := if($death/covid19/child::node()) then ($death/covid19/xs:integer(.) div $covid19-total) * 100.0 else 0
			return
				<death>
				{ 
					$death/child::node(),
					<total-percentage-of-all>{format-number($total-percentage-of-all, "##0.00")}</total-percentage-of-all>,
					<covid19-percentage-of-all>{format-number($covid19-percentage-of-all, "##0.00")}</covid19-percentage-of-all>
				}
				</death>
		)
	}
	</deaths>
};

declare function local:hhs-expand-state-abbrev-to-name($payments as element(payments), $abbr-map as map(xs:string, xs:string)) {
	<payments>
	{
		for $payment in $payments/payment
		let $state := $payment/state/string(.)
		let $state := ($abbr-map($state), $state)[1]
		return
			<payment>
			{
				<state>{$state}</state>,
				$payment/child::node()[local-name(.) ne "state"]
			}
			</payment>
	}
	</payments>
		
};


declare function local:hhs-calculate-percentage-of-all($payments as element(payments)) {
	<payments>
	{
		let $total := sum($payments//total/xs:integer(.))
		return
		(
			<total currency="usd">{$total}</total>,
			for $payment in $payments/payment
			let $percentage-of-all := ($payment/total/xs:integer(.) div $total) * 100.0
			return
				<payment>
				{ 
					$payment/child::node(),
					<percentage-of-all>{format-number($percentage-of-all, "##0.00")}</percentage-of-all>
				}
				</payment>
		)
	}
	</payments>
};

(: get deaths :)
let $deaths := local:total-deaths-by-state()
let $deaths-with-percentage := local:deaths-calculate-percentage-of-all($deaths)
return
	
	
(: get HHS funding :)
let $hhs-funding := local:total-hhs-funding-by-state()
let $state-abbr-name-map := json-doc("/db/states/abbr-name.json")
return
	let $hhs-funding-state-named := local:hhs-expand-state-abbrev-to-name($hhs-funding, $state-abbr-name-map)
	return
		let $hhs-funding-with-percentage := local:hhs-calculate-percentage-of-all($hhs-funding-state-named)

return


		(: 1. join the two datasets on state name and sumarize :)
		let $data := 
			<states>
			{
				for $death in $deaths-with-percentage/death
				let $state := $death/state/string(.)
				let $payment := $hhs-funding-with-percentage/payment[state eq $state]
				where not(empty($payment))
				return
					<state>
						<name>{$state}</name>
						<covid19-deaths percentage-of-usa="{$death/covid19-percentage-of-all}">{$death/covid19/text()}</covid19-deaths>
						<hhs-payments percentage-of-usa="{$payment/percentage-of-all cast as xs:decimal}" currency="usd">{format-number($payment/total/text(), "###,###,###,###")}</hhs-payments>
					</state>
			}
			</states>
		return

			let $reports :=
				<reports>
			
					<report id="1" description="Covid 19 deaths by state as a percentage of all USA Covid 19 deaths">
						<states>
						{
							for $state in $data/state
							order by $state/covid19-deaths/xs:decimal(@percentage-of-usa) descending
							return
								$state
						}
						</states>
					</report>
	
	
					<report id="2" description="HHS Payments by state as a percentage of all HHS payments">
						<states>
						{
							for $state in $data/state
							order by $state/hhs-payments/xs:decimal(@percentage-of-usa) descending
							return
								$state
						}
						</states>
					</report>
				</reports>

			return
				
				(: For compatibility with eXist-db we use transform module... should really be fn:transform ! :)
				let $xslt := doc("file:///Users/aretter/tmp-code/MarkukUK2020/scripts/answer1-to-html.xslt")
				return
					transform:transform(document { $reports }, $xslt, ())
			