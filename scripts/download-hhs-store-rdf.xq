xquery version "3.1";

(:~
 : CDC.
 :
 : Download RDF, and then store with RDF/TDB Jena Index.
 :)

import module namespace http = "http://expath.org/ns/http-client";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";

declare variable $local:cdc-api-uri := "https://data.cdc.gov/resource/";

declare variable $local:data-collection-uri := "/db/hhs-provider";
declare variable $local:data-collection-config := document {
	<collection xmlns="http://exist-db.org/collection-config/1.0">
  		<index xmlns:xs="http://www.w3.org/2001/XMLSchema">
    			<rdf />
  		</index>
	</collection>
};


declare function local:download-rdf($dataset-id) {
	let $uri := $local:cdc-api-uri || "/" || $dataset-id || ".rdf?$limit=1000000"   (: TODO(AR) we happen to know this dataset only contains ~210,000 rows :)
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

declare function local:setup-collection($collection-uri, $collection-config as document-node()?) {
	if ($collection-config)
	then
		let $config-collection-uri := "/db/system/config" || $collection-uri
		let $config-collection-doc-uri := $config-collection-uri || "/collection.xconf"
		return
		(
			if (not(xmldb:collection-available($config-collection-uri)))
			then
				xmldb:create-collection(local:base-name($config-collection-uri), local:name($config-collection-uri))
			else
				$config-collection-uri
			,
	
			
			if (not(doc-available($config-collection-doc-uri)))
			then
				xmldb:store(local:base-name($config-collection-doc-uri), local:name($config-collection-doc-uri), $collection-config)
			else
				$config-collection-doc-uri
		)
	else(),
	

	if (not(xmldb:collection-available($collection-uri)))
	then
		xmldb:create-collection(local:base-name($collection-uri), local:name($collection-uri))
	else
		$collection-uri
};


let $_ := local:setup-collection($local:data-collection-uri, $local:data-collection-config)

let $rdf-data := local:download-rdf("kh8y-3es6")
return
	xmldb:store($local:data-collection-uri, "hhs-provider.rdf", $rdf-data)
