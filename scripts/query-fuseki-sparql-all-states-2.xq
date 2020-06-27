xquery version "3.1";

import module namespace fuseki = "http://evolvedbinary.com/muk20/fuseki"
	at "file:///Users/aretter/tmp-code/MarkukUK2020/scripts/fuseki.xqm";


let $query1 := "
	 PREFIX ds: <https://data.cdc.gov/resource/kh8y-3es6/>
      SELECT ?state
      WHERE { ?provider ds:state ?state }
      ORDER BY ?state
"
return
	fuseki:query("hhs", $query1)