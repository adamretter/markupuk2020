xquery version "3.1";

import module namespace http = "http://expath.org/ns/http-client";

declare variable $local:fuseki-api-uri := "http://localhost:3030";

declare function local:query($dataset-id as xs:string, $sparql-query as xs:string) {
	let $query-uri := $local:fuseki-api-uri || "/" || $dataset-id || "/query"
	let $request :=
		<http:request method="post">
			<http:header name="Content-Type" value="application/sparql-query"/>
			<http:header name="Accept" value="application/rdf+xml"/>
			<http:body media-type="text/plain"/>
		</http:request>
	return
		let $result := http:send-request($request, $query-uri, $sparql-query)
	        return
	            if ($result[1]/@status ne "200")
	            then
	                fn:error(xs:QName("local:bad-request-1"), $result[1])
	            else
	                $result[2]
};

let $query1 := "
	 PREFIX ds: <https://data.cdc.gov/resource/kh8y-3es6/>
      SELECT ?state
      WHERE { ?provider ds:state ?state }
      ORDER BY ?state
"
return
	local:query("hhs", $query1)