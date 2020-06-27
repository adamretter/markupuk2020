xquery version "3.1";

(:~
 : CDC.
 :
 : Download and parse CSV, and then upload to SQL database.
 :)

import module namespace http = "http://expath.org/ns/http-client";
import module namespace sql = "http://exist-db.org/xquery/sql";

declare variable $local:cdc-views-uri := "https://data.cdc.gov/api/views/";

declare variable $local:sql-jdbc-driver := "org.mariadb.jdbc.Driver";
declare variable $local:sql-jdbc-uri := "jdbc:mariadb://localhost";
declare variable $local:sql-jdbc-user := "root";
declare variable $local:sql-db-name := "covid";
declare variable $local:sql-tbl-name := "dsas";


declare function local:download-csv($dataset-id) as xs:string {
	let $uri := $local:cdc-views-uri || $dataset-id || "/rows.csv?accessType=DOWNLOAD"
	return
		let $result := http:send-request(<http:request method="get" href="{$uri}"/>)
	        return
	            if ($result[1]/@status ne "200")
	            then
	                fn:error(xs:QName("local:bad-request-1"), $result[1])
	            else
	                $result[2]
};

declare function local:parse-csv-row($csv-row as xs:string) as array(xs:string+) {
	array {
		analyze-string($csv-row || ',', '(("[^"]*")+|[^,]*),')//fn:group[@nr eq "1"] ! replace(., "^""|""$|("")""", "$1")		
	}
};

declare function local:parse-csv($csv-data as xs:string) as array(xs:string+)* {
	let $csv-lines := tokenize($csv-data, "\n")
	for $csv-row in $csv-lines
	return
		local:parse-csv-row($csv-row)
};

declare function local:sql-safe-column-name($name) {
	replace(replace(lower-case($name), "\s|-", "_"), ",", "")
};

declare function local:sql-column-data-type($column-name as xs:string) as xs:string {
	if ($column-name = ("data_as_of", "start_week", "end_week"))
	then
		"DATE"
	else if ($column-name = ("covid_19_deaths", "total_deaths", "pneumonia_deaths", "pneumonia_and_covid_19_deaths", "influenza_deaths", "pneumonia_influenza_or_covid_19_deaths"))
	then
		"INTEGER"
	else
		"TEXT"
};

declare function local:csv-header-to-create-table-sql($csv-header as array(xs:string+)) {
	let $column-ddl := array:for-each($csv-header, function($column-name) { let $sn := local:sql-safe-column-name($column-name) return $sn || " " || local:sql-column-data-type($sn) })
	let $columns-ddl := array:fold-left($column-ddl, (), function($a, $b){ string-join(($a, $b), ",&#10;") })
	return
		"create or replace table " || $local:sql-tbl-name || " (&#10;" || $columns-ddl || ")"
};

declare function local:format-as-sql-type($s as xs:string) as xs:string {
	if (matches($s, "[0-9]{2}/[0-9]{2}/[0-9]{4}"))
	then
		(: convert commons US Date format to SQL date format :)
		'"' || replace($s, "([0-9]{2})/([0-9]{2})/([0-9]{4})", "$3-$1-$2") || '"'
	else if (matches($s, "^[0-9]+$"))
	then
		$s
	else if (string-length($s) eq 0)
	then
		"NULL"
	else
		'"' || $s || '"'
};

declare function local:csv-row-to-insert-sql($csv-row as array(xs:string+)) {
	let $column-ddl := array:for-each($csv-row, function($cell) { local:format-as-sql-type($cell) })
	let $columns-ddl := array:fold-left($column-ddl, (), function($a, $b){ string-join(($a, $b), ",&#10;") })
	return
		"insert into " || $local:sql-tbl-name || " values (&#10;" || $columns-ddl || ")"
};

declare function local:store-as-sql-table($csv) {
	(: create db :)
	let $conn := sql:get-connection($local:sql-jdbc-driver, $local:sql-jdbc-uri, $local:sql-jdbc-user, "")
	let $result := sql:execute($conn, "create or replace database " || $local:sql-db-name, true())
	return

		(: create table in db :)
		if ($result/@updateCount eq "0")
		then
			fn:error(xs:QName("local:create-database"), $result)
		else
			let $create-table-sql := local:csv-header-to-create-table-sql($csv[1])
			let $conn := sql:get-connection($local:sql-jdbc-driver, $local:sql-jdbc-uri || "/" || $local:sql-db-name, $local:sql-jdbc-user, "")
			return
				let $result := sql:execute($conn, $create-table-sql, true())
				return
					if (empty($result))
					then
						fn:error(xs:QName("local:create-database"), $result)
					else
						for $i in (2 to count($csv) - 1)
						let $csv-row := $csv[$i]
						let $insert-row-sql := local:csv-row-to-insert-sql($csv-row)
						return
							sql:execute($conn, $insert-row-sql, true())
};

let $csv-data := local:download-csv("9bhg-hcku")
let $csv := local:parse-csv($csv-data)
return
	local:store-as-sql-table($csv)
		
	
