xquery version "3.1";

(:~
 : National Library of Medicine - E-Utilities.
 :
 : Keyword Search and Fetch for Pubmed DB.
 :)

import module namespace file = "http://exist-db.org/xquery/file";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";


declare variable $local:eutils-uri := "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/";

declare variable $local:eutils-search-uri := $local:eutils-uri || "/esearch.fcgi?db=pubmed";
declare variable $local:esearch-retmax := 100000;

declare variable $local:eutils-fetch-uri := $local:eutils-uri || "/efetch.fcgi?db=pubmed";
declare variable $local:efetch-retmax := 10000;

declare variable $local:pubmed-data-collection-uri := "/db/pubmed-data";



declare function local:search-articles($keyword) as document-node(element(eSearchResult)) {
	let $uri := $local:eutils-search-uri || "&amp;usehistory=y&amp;retmax=" || $local:esearch-retmax || "&amp;rettype=uilist&amp;term=" || fn:encode-for-uri($keyword)
	return
        let $result := http:send-request(<http:request method="get" href="{$uri}"/>)
        return
            if ($result[1]/@status ne "200")
            then
                fn:error(xs:QName("local:bad-request-2"), $result[1])
            else
            	$result[2]
            (:
                $result[2]/eSearchResult/IdList/Id/string(.)
                :)
};

(: zero-indexed based pages! :)
declare function local:calculate-page-starts($total, $page-size) {
	(
		for $ i in 1 to xs:integer($total div $page-size)
		let $end := $i * $page-size
		let $start := $end - $page-size
		return
			$start
		,
		let $m := $total mod $page-size
		return
			if ($m gt 0) then
				$total - $m
			else()
	)
};

declare function local:fetch-articles($web-env, $query-key, $count) as element(PubmedArticle)* {
	let $page-starts := local:calculate-page-starts($count, $local:efetch-retmax)
	for $page-start in $page-starts
	let $uri := $local:eutils-fetch-uri || "&amp;retstart=" || ($page-start + 1) || "&amp;retmax=" || $local:efetch-retmax || "&amp;retmode=xml&amp;WebEnv=" || $web-env || "&amp;query_key=" || $query-key
	return
		let $result := http:send-request(<http:request method="get" href="{$uri}"/>)
        	return
            if ($result[1]/@status ne "200")
            then
                fn:error(xs:QName("local:bad-request-3"), $result[1])
            else
                $result[2]/PubmedArticleSet/PubmedArticle
};

declare function local:setup-collection($collection-uri) {
	if (not(xmldb:collection-available($collection-uri)))
	then
		xmldb:create-collection(local:base-name($collection-uri), local:name($collection-uri))
	else
		$collection-uri
};


let $_ := local:setup-collection($local:pubmed-data-collection-uri)
return

	let $search-results := local:search-articles("covid")
	let $articles := local:fetch-articles($search-results/eSearchResult/WebEnv, $search-results/eSearchResult/QueryKey, $search-results/eSearchResult/Count)
	for $article in $articles
	return
		let $pmid := $article/MedlineCitation/PMID/string(.)
		let $doc-name := $pmid || ".xml"
		return
			
	
	        xmldb:store($local:pubmed-data-collection-uri, $doc-name, $article)
	        
	        (:
	        file:serialize($article, "/Users/aretter/tmp-code/MarkukUK2020/pubmed-data/" || $doc-name, ())
	        :)
