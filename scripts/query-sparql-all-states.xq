import module namespace sparql = "http://exist-db.org/xquery/sparql";

let $query1 := "
	 PREFIX ds: <https://data.cdc.gov/resource/kh8y-3es6/>
      SELECT ?state
      WHERE { ?provider ds:state ?state }
      ORDER BY ?state
"

return
	sparql:query($query1)