xquery version "3.1";


(:~
 : World Polulation Review - State Names and Abbreviations.
 :
 : Download JSON, and then store into the database.
 :)

import module namespace http = "http://expath.org/ns/http-client";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare variable $local:wpr-api-uri := "https://worldpopulationreview.com/static/states/";

declare variable $local:data-collection-uri := "/db/states";

declare function local:download-file($dataset-id) {
	let $uri := $local:wpr-api-uri || $dataset-id || ".json"
	return
		let $result := http:send-request(<http:request method="get" href="{$uri}"/>)
		return
		  if ($result[1]/@status ne "200")
		  then
		      fn:error(xs:QName("local:bad-request-1"), $result[1])
		  else
		      $result[2]
};

declare function local:base-name($uri) {
	replace($uri, "(.*)/.*", "$1")
};

declare function local:name($uri) {
	replace($uri, ".*/([^/]*)", "$1")
};

declare function local:setup-collection($collection-uri) {
	if (not(xmldb:collection-available($collection-uri)))
	then
		xmldb:create-collection(local:base-name($collection-uri), local:name($collection-uri))
	else
		$collection-uri
};


let $_ := local:setup-collection($local:data-collection-uri)

for $dataset-id in ("abbr-name", "name-abbr")
return
	let $bin := local:download-file($dataset-id)
	return
		xmldb:store($local:data-collection-uri, $dataset-id || ".json", $bin, "application/json")