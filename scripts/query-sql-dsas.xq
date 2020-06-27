let $conn := sql:get-connection("org.mariadb.jdbc.Driver", "jdbc:mariadb://localhost/covid?user=root")
return
	sql:execute($conn, "select * from dsas", true())