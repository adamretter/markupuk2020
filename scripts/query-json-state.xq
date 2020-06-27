xquery version "3.1";

let $state-abbr-name-map := json-doc("/db/states/abbr-name.json")
return
	for $abbrev in ("DE", "NY", "CO")
	return
		<state>
			<abbrev>{$abbrev}</abbrev>
			<name>{$state-abbr-name-map($abbrev)}</name>
		</state>
,

let $state-name-abbr-map := json-doc("/db/states/name-abbr.json")
return
	for $name in ("Idaho", "Nevada", "California")
	return
		<state>
			<abbrev>{$state-name-abbr-map($name)}</abbrev>
			<name>{$name}</name>
		</state>