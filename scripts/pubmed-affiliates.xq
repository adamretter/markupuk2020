(:
	doc("/db/pubmed-data/32569797.xml")
:)

distinct-values(
	collection("/db/pubmed-data")//Affiliation[contains(., 'USA') or contains(., 'United States')]
)