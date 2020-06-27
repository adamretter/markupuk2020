xquery version "3.1";

import module namespace fuseki = "http://evolvedbinary.com/muk20/fuseki"
	at "file:///Users/aretter/tmp-code/MarkukUK2020/scripts/fuseki.xqm";


let $query1 := '
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
	fuseki:query("hhs", $query1)
