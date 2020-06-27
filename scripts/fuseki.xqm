xquery version "3.1";

(:~
 : Module for working with Fuseki Server.
 :
 : Uses SPARQL 1.1 Protocol for communication.
 :)

module namespace fuseki = "http://evolvedbinary.com/muk20/fuseki";


import module namespace http = "http://expath.org/ns/http-client";

declare variable $fuseki:api-uri := "http://localhost:3030";


declare function fuseki:query($dataset-id as xs:string, $sparql-query as xs:string) {
	let $query-uri := $fuseki:api-uri || "/" || $dataset-id || "/query"
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