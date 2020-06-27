xquery version "3.1";

(:~
 : Get each payment to each state.
 :)

import module namespace sparql = "http://exist-db.org/xquery/sparql";

let $query1 := '
	 PREFIX ds:  <https://data.cdc.gov/resource/kh8y-3es6/>
	 PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

      SELECT ?state ?payment_amount
      WHERE {
      	?provider ds:state ?state ;
      			ds:payment ?payment
      	BIND (xsd:integer(replace(?payment, "[^0-9]", "")) as ?payment_amount)
      }
      ORDER BY ?state
'

return
	sparql:query($query1)
