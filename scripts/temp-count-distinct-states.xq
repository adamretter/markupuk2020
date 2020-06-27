count(
    for $state in distinct-values(doc("/db/hhs-provider/hhs-provider.rdf")//*:state/string(.))
    return
        <state>{$state}</state>
)