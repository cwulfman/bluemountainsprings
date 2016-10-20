xquery version "3.0";

module namespace iiif = "http://bluemountain.princeton.edu/apps/springs/iiif";
import module namespace config="http://bluemountain.princeton.edu/apps/springs/config" at "config.xqm";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";

import module namespace rest = "http://exquery.org/ns/restxq" ;
(:  declare namespace rest="http://exquery.org/ns/restxq"; :)
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client"; 

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace mets="http://www.loc.gov/METS/";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function iiif:_collection-xml($bmtnid)
{
    let $fullid := concat('urn:PUL:bluemountain:', $bmtnid)
    let $titlerec := collection($config:metadata)//mods:identifier[@type='bmtn'][. = $fullid]/ancestor::mods:mods
    let $issuerecs :=
        collection($config:metadata)//mods:mods[mods:relatedItem[@type='host'][@xlink:href= $fullid]]
    let $xsl := doc($config:app-root || "/resources/xsl/bmtn-collection-top.xsl") 
 

    return
        transform:transform(<collection>
            <title>{ $titlerec }</title>
            <issues>{ $issuerecs }</issues>
        </collection>, $xsl, 
            <parameters>
                <param name="baseURI" value="{ $config:iiif-root }"/>
            </parameters>)
};


declare function iiif:collection-top-xml()
{
    let $recs := collection($config:metadata)//mods:genre[@authority='bmtn' and .='Periodicals-Title']/ancestor::mods:mods
    let $xsl := doc($config:app-root || "/resources/xsl/bmtn-collection-top.xsl") 
    
    return 
    (
        <rest:response>
            <http:response>
                <http:header name="access-control-allow-origin" value="*"/>
            </http:response>
        </rest:response>,
    
    transform:transform(
        <collection level="top">
            <titles>{ $recs }</titles>
        </collection>,
    $xsl, ())
    )
};

declare
 %rest:GET
 %rest:path("/iiif/collection/{$bmtnid}")
 %output:method("text")
 %rest:produces("application/json")
function iiif:collection-json($bmtnid)
{
    let $source := 
        if ($bmtnid = 'top') then
            iiif:collection-top-xml()
        else iiif:_collection-xml($bmtnid)
    let $xsl    := doc($config:app-root || "/resources/xsl/xml2json.xsl")
    return
    (
        <rest:response>
            <http:response>
                <http:header name="Content-Type" value="application/json"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>,
        transform:transform($source, $xsl, ())
    )
};



(:~ Manifests :)

declare
 %rest:GET

function iiif:_mets-to-manifest-xml($issueid) {
    let $issue := collection($config:metadata)//mods:mods[mods:identifier[@type='bmtn'] = 'urn:PUL:bluemountain:' || $issueid]
    let $xsl := doc($config:app-root || "/resources/xsl/bmtn-manifest.xsl")
    return transform:transform($issue/ancestor::mets:mets, $xsl, 
    <parameters>
     <param name="baseURI" value="{ $config:iiif-root }"/>
    </parameters>)
};

declare
 %rest:GET
 %rest:path("/iiif/{$issueid}/manifest")
 %output:method("text")
 %rest:produces("application/json")
 function iiif:mets-to-manifest-json($issueid) {
    let $manifest-xml := iiif:_mets-to-manifest-xml($issueid)
    
    let $xsl := doc($config:app-root || "/resources/xsl/xml2json.xsl")
    return 
    (
        <rest:response>
            <http:response>
                <http:header name="Content-Type" value="application/json"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>,
    
      transform:transform($manifest-xml, $xsl, ())
    )
 };
