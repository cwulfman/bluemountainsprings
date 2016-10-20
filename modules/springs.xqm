xquery version "3.0";

module namespace springs = "http://bluemountain.princeton.edu/apps/springs";
import module namespace config="http://bluemountain.princeton.edu/apps/springs/config" at "config.xqm";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";

import module namespace rest = "http://exquery.org/ns/restxq" ;

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client"; 

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace tei="http://www.tei-c.org/ns/1.0";


(: Utility functions :)

declare function springs:_typeof($bmtnid)
as xs:string
{
    let $object := collection($config:transcriptions)//tei:TEI[./tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid'] = $bmtnid]
    return xs:string($object//tei:teiHeader//tei:profileDesc/tei:textClass/tei:classCode)
};

declare function springs:_issuep($bmtnid)
as xs:boolean
{
    let $classCode := springs:_typeof($bmtnid)
    return if ($classCode = "300312349") then true() else false() 
};

declare function springs:_magazine-monogr($magazine as element())
as element()
{
    $magazine/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr
};

declare function springs:_magazine-title($magazine as element())
as xs:string?
{
    let $title := springs:_magazine-monogr($magazine)/tei:title[@level='j']
    let $nonSort := $title/tei:seg[@type='nonSort']
    let $main := $title/tei:seg[@type='main']
    let $sub  := $title/tei:seg[@type='sub']
    let $titleString := string-join(($nonSort,$main), ' ')
    return if ($sub) then $titleString || ': ' || $sub else $titleString
};

declare function springs:_magazine-date-start($magazine as element())
as xs:string
{
    let $date := springs:_magazine-monogr($magazine)/tei:imprint/tei:date
    return if ($date/@from) then $date/@from else $date/@when
};

declare function springs:_magazine-date-end($magazine as element())
as xs:string
{
    let $date := springs:_magazine-monogr($magazine)/tei:imprint/tei:date
    return if ($date/@to) then $date/@to else $date/@when
};

declare function springs:_issue($issueid as xs:string)
as element()
{
    collection($config:transcriptions)//tei:TEI[./tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid'] = $issueid]
};

declare function springs:_issue-mods($bmtnid as xs:string)
as element()
{
    let $issue := collection($config:metadata)//mods:mods[mods:identifier[@type='bmtn'] = 'urn:PUL:bluemountain:' || $bmtnid]
    return $issue    
};

declare function springs:_magazine($bmtnid as xs:string)
{
    collection($config:transcriptions)//tei:TEI[./tei:teiHeader//tei:publicationStmt/tei:idno[@type='bmtnid'] = $bmtnid]
};

declare function springs:_magazine-mods($bmtnid as xs:string)
{
    let $identifier := concat('urn:PUL:bluemountain:', $bmtnid)
    let $titlerec := collection($config:metadata)//mods:identifier[@type='bmtn' and . = $identifier]/ancestor::mods:mods
    return $titlerec
};

declare function springs:_magazines-tei() {
    collection($config:transcriptions)//tei:TEI[./tei:teiHeader/tei:profileDesc/tei:textClass/tei:classCode = 300215389 ]
};


declare function springs:_issue-label($issue as element())
{
    xs:string($issue/mods:titleInfo[1]/mods:title[1])
};

declare function springs:_bylines-from-issue($issueid as xs:string)
as element()+
{
    let $issue := springs:_issue-mods($issueid)
    let $creators := $issue//mods:roleTerm[. = 'cre']
    return $creators/ancestor::mods:name/mods:displayForm
};

declare function springs:_bylines-from-issue-tei($issue as element())
as element()+
{
    let $respStmts := $issue//tei:respStmt[tei:resp = 'cre']
    return $respStmts/tei:persName
};


(:::::::::::::::::::  MAGAZINES ::::::::::::::::)
declare
 %rest:GET
 %rest:path("/springs/magazines")
 %output:method("text")
 %rest:produces("text/csv")
function springs:magazines-as-csv() {
  let $mags := springs:_magazines-tei()
  for $mag in $mags
    let $bmtnid := $mag/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid']
    let $primaryTitle := springs:_magazine-title($mag)
    let $primaryLanguage := $mag/tei:teiHeader/tei:profileDesc/tei:langUsage/tei:language[1]/@ident
    let $startDate := springs:_magazine-date-start($mag)
    let $endDate := springs:_magazine-date-end($mag)
    let $uri := $config:springs-root || '/magazines/' || $bmtnid
    
    return concat(string-join(($bmtnid,$primaryTitle,$primaryLanguage,$startDate,$endDate,$uri), ','), codepoints-to-string(10))
};


declare
 %rest:GET
 %rest:path("/springs/magazines")
 %output:method("json")
 %rest:produces("application/json")
function springs:magazines-as-json() {
    <magazines> {
  let $mags := springs:_magazines-tei()
  for $mag in $mags
    let $bmtnid := $mag/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid']
    let $primaryTitle := springs:_magazine-title($mag)
    let $primaryLanguage := $mag/tei:teiHeader/tei:profileDesc/tei:langUsage/tei:language[1]/@ident
    let $startDate := springs:_magazine-date-start($mag)
    let $endDate := springs:_magazine-date-end($mag)
    let $uri := $config:springs-root || '/magazines/' || $bmtnid
    return 
        <magazine>
            <bmtnid>{ $bmtnid }</bmtnid>
            <primaryTitle>{ $primaryTitle }</primaryTitle>
            <primaryLanguage>{ $primaryLanguage }</primaryLanguage>
            <startDate>{ $startDate }</startDate>
            <endDate>{ $endDate }</endDate>
            <uri>{ $uri }</uri>
        </magazine>
    } </magazines>
};

declare
  %rest:GET
  %rest:path("/springs/magazines/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:magazine($bmtnid) {
    let $titlerec := springs:_magazine($bmtnid)
    let $title := xs:string($titlerec/mods:titleInfo[1]/mods:title[1])
    let $issues   := collection($config:metadata)//mods:mods[mods:relatedItem[@type='host']/@xlink:href = 'urn:PUL:bluemountain:' || $bmtnid]
    let $sorted-issues :=
        for $i in $issues
        order by $i/mods:originInfo/mods:dateIssued[@keyDate='yes']
        return $i
    let $startDate := xs:string($sorted-issues[1]/mods:originInfo/mods:dateIssued[@keyDate='yes'])
    let $endDate   := xs:string($sorted-issues[last()]/mods:originInfo/mods:dateIssued[@keyDate='yes'])
    return
   <magazine>
    <bmtnid>{ $bmtnid }</bmtnid>
    <primaryTitle>{ $title }</primaryTitle>
    <startDate>{ $startDate }</startDate>
    <endDate>{ $endDate }</endDate>
    {
        for $language in $titlerec/mods:language
        return
            <language>{ xs:string($language/mods:languageTerm) }</language>
    },
    


                {
                    for $issue in $issues
                    let $id   := $issue//mods:identifier[@type='bmtn']/text() 
                    let $date := $issue/mods:originInfo/mods:dateIssued[@keyDate='yes']/text()
                    return
                        <issues>
                            <id>{ $id }</id>
                            <date>{ $date }</date>
                            <url>
                              { $config:springs-root || '/issues/' || substring-after($id, 'urn:PUL:bluemountain:') }
                            </url>
                        </issues>
                }

              </magazine>
};


(:::::::::::::::::::: ISSUES ::::::::::::::::::::)

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %rest:produces("application/tei+xml")
function springs:issue-as-tei($bmtnid) {
    springs:_issue($bmtnid)
};

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %output:method("text")
  %rest:produces("text/plain")
function springs:issue-as-plaintext($bmtnid) {
    let $issue := springs:_issue($bmtnid)
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    return 
    (
        <rest:response>
            <http:response>
                <http:header name="Content-Type" value="text/plain"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>,

    transform:transform($issue, $xsl, ())
    )
};

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:issue-as-json($bmtnid) {
    let $issue := springs:_issue($bmtnid)
    let $xsl := doc($config:app-root || "/resources/xsl/tei2data.xsl")
    let $xslt-parameters := 
      <parameters>
          <param name="springs-root" value="{$config:springs-root}"/>
      </parameters>    
    return 
    (
        <rest:response>
            <http:response>
                <http:header name="Content-Type" value="application/json"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>,

    transform:transform($issue, $xsl, $xslt-parameters)
    )
};

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %rest:produces("application/rdf+xml")
function springs:issue-as-rdf($bmtnid) {
    let $issue := springs:_issue-mods($bmtnid)
    let $xsl := doc($config:app-root || "/resources/xsl/mods2crm.xsl")

    return transform:transform($issue, $xsl, ())
};

(:::::::::::::::::::: CONSTITUENTS ::::::::::::::::::::)
declare
  %rest:GET
  %rest:path("/springs/constituents/{$bmtnid}")
function springs:constituents($bmtnid) {
    let $issue := collection($config:metadata)//mods:mods[mods:identifier[@type='bmtn'] = 'urn:PUL:bluemountain:' || $bmtnid]
    let $constituents := $issue/mods:relatedItem[@type = 'constituent']
    return
        <issue>
            {
                for $constituent in $constituents
                let $title :=  $constituent/mods:titleInfo[1]/mods:title[1]/text()
                let $bylines := $constituent/mods:name/mods:displayForm
                let $id := xs:string($constituent/@ID)
                return
                    <constituent>
                        <id>{ string-join(($bmtnid,$id), '#') }</id>
                        <title>{ $title }</title>
                        {
                            for $byline in $bylines
                            return
                                <byline>{ $byline/text() }</byline>
                        }
                    </constituent>
            }
        </issue>
};


declare function springs:constituents-with-byline($byline as xs:string)
as element()*
{
    collection($config:transcriptions)//tei:relatedItem[ft:query(.//tei:persName, $byline)]
};

 
declare
  %rest:GET
  %rest:path("/springs/constituent/{$issueid}/{$constid}")
    %rest:produces("text/plain")
function springs:constituent-plaintext($issueid, $constid) {
    let $issue := springs:_issue($issueid)
    let $constituent := $issue//tei:div[@corresp = $constid]
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    return 
    (
        <rest:response>
            <http:response>
                <http:header name="Content-Type" value="text/plain"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>,

    transform:transform($constituent, $xsl, ())
    )
};

declare
  %rest:GET
  %rest:path("/springs/constituent/{$issueid}/{$constid}")
  %rest:produces("application/tei+xml")
function springs:constituent-tei($issueid, $constid) {
    let $issue := springs:_issue($issueid)
    let $constituent := $issue//tei:div[@corresp = $constid]
    return $constituent
};


(::::::::::::::::::: TEXT ::::::::::::::::::::)
declare
    %rest:GET
    %rest:path("/springs/text/{$issueid}/{$constid}")
    %output:method("text")
function springs:constituent-text($issueid as xs:string, $constid as xs:string)
{
    let $issue := springs:_issue($issueid)
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    let $constituent := $issue//tei:div[@corresp = $constid]
    return transform:transform($constituent, $xsl, ())
};


declare
 %rest:GET
 %rest:path("/springs/text/{$issueid}")
function springs:text($issueid) {
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    let $issue := springs:_issue($issueid)
    return transform:transform($issue, $xsl, ())
};


(::::::::::::::::::: CONTRIBUTORS ::::::::::::::::::::)
declare function springs:_contributor-data-tei($issue)
{
    let $issueid := xs:string($issue//tei:idno[@type='bmtnid'])
    let $issuelabel := $issue//tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title/tei:seg[@type='main']
    let $contributions := $issue//tei:relatedItem[@type='constituent']
    for $contribution in $contributions
        let $constituentid := xs:string($contribution/@xml:id)
        let $title := xs:string($contribution/tei:biblStruct/tei:analytic/tei:title[@level = 'a']/tei:seg[@type='main'][1])
        let $respStmts := $contribution//tei:respStmt
        for $stmt in $respStmts
            let $byline := $stmt/tei:persName/text()
            let $contributorid := if ($stmt/tei:persName/@ref) then xs:string($stmt/tei:persName/@ref) else " "
            return
             concat(string-join(($issueid, $issuelabel,$contributorid,$byline,$constituentid,$title), ','), codepoints-to-string(10))
};

declare function springs:_issue-by-id($bmtnid) {
    collection($config:transcriptions)//tei:idno[@type='bmtnid' and . = $bmtnid]/ancestor::tei:TEI
};

declare function springs:contributors-from-issue-csv($bmtnid) {
    let $issue := springs:_issue-by-id($bmtnid)
    let $rows := springs:_contributor-data-tei($issue)
    return
            (concat(string-join(('bmtnid', 'label', 'contributorid', 'byline', 'constituentid', 'title'),','), codepoints-to-string(10)),
        $rows)
};

declare function springs:contributors-from-title-csv($bmtnid) {
    let $issues := collection($config:transcriptions)//tei:relatedItem[@type='host' and @target = $bmtnid]/ancestor::tei:TEI
    let $rows := 
        for $issue in $issues
         return springs:_contributor-data-tei($issue)
    return 
        (concat(string-join(('bmtnid', 'label', 'contributorid', 'byline', 'constituentid', 'title'),','), codepoints-to-string(10)),
        $rows)
};


declare
 %rest: GET
 %rest:path("/springs/contributors/{$bmtnid}")
 %output:method("text")
 %rest:produces("text/csv")
function springs:contributors-csv($bmtnid) {
    if (springs:_issuep($bmtnid))
        then springs:contributors-from-issue-csv($bmtnid)
    else springs:contributors-from-title-csv($bmtnid)
};


declare 
 %rest: GET
 %rest:path("/springs/contributors/{$issueid}")
 %output:method("json")
 %rest:produces("application/json")
function springs:contributors-from-issue($issueid) {
    let $issue := springs:_issue-mods($issueid)
    let $bylines := springs:_bylines-from-issue($issueid)
    let $issue-label := springs:_issue-label($issue)
  
    return
        <contributors> {
          for $byline in $bylines
          let $contributorid := 
            if ($byline/ancestor::mods:name/@authority = 'viaf')
                then xs:string($byline/ancestor::mods:name/@valueURI)
            else ()
          let $constituentid := xs:string($byline/ancestor::mods:relatedItem[@type='constituent'][1]/@ID)
          let $title := xs:string($byline/ancestor::mods:relatedItem[@type='constituent'][1]/mods:titleInfo[1])
          return
            <contributor>
                <bmtnid>{ $issueid }</bmtnid>
                <label>{ $issue-label }</label>
                <contributorid>{ $contributorid }</contributorid>
                <byline>{ xs:string($byline) }</byline>
                <contributionid>{ $constituentid }</contributionid>
                <title> { $title }</title>
            </contributor>
        } </contributors>
    
};