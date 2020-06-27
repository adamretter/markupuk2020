import module namespace sql = "http://exist-db.org/xquery/sql";

(: create the database :)
let $conn := sql:get-connection("org.mariadb.jdbc.Driver", "jdbc:mariadb://localhost", "root", "")
let $result := sql:execute($conn, "create or replace database covid", true())
return
		if ($result/@updateCount eq "0")
		then
			fn:error(xs:QName("local:create-database"), $result)
		else
			
			let $conn := sql:get-connection("org.mariadb.jdbc.Driver", "jdbc:mariadb://localhost/covid", "root", "")
			return
				let $result := sql:execute($conn, "create or replace table death_sas()", true())
				return $result
