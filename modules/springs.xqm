xquery version "3.0";

module namespace springs = "http://bluemountain.princeton.edu/apps/springs";
import module namespace config="http://bluemountain.princeton.edu/apps/springs/config" at "config.xqm";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";

import module namespace rest = "http://exquery.org/ns/restxq" ;

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client"; 

declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:::::::::::::::::::  SPRINGS (TOP) ::::::::::::::::)
declare
 %rest:GET
 %rest:path("/springs")
 %output:method("json")
 %rest:produces("application/json")
function springs:existing-resources() {
<resources>
    <resource>
        <path>/springs/magazines</path>
    </resource>
    <resource>
        <path>/springs/magazines/bmtnid</path>
    </resource>
    <resource>
        <path>/springs/issues/bmtnid</path>
    </resource>
    <resource>
        <path>/springs/constituents/bmtnid</path>
    </resource>
        <resource>
        <path>/springs/constituent/bmtnid/constituentid</path>
    </resource>
    <resource>
        <path>/springs/text/bmtnid</path>
    </resource>
        <resource>
        <path>/springs/constituent/bmtnid/constituentid</path>
    </resource>
        <resource>
        <path>/springs/contributors/bmtnid</path>
    </resource>
</resources>
};


(:::::::::::::::::::  MAGAZINES ::::::::::::::::)
declare
 %rest:GET
 %rest:path("/springs/magazines")
 %output:method("json")
 %rest:produces("application/json")
function springs:magazines-as-json() {
    let $returnVal :=
    <magazines> {
  let $mags := springs:_magazines-tei()
  for $mag in $mags
    let $bmtnid := springs:_title-id($mag)
    let $primaryTitle := springs:_magazine-title($mag)
    let $primaryLanguage := xs:string($mag/tei:teiHeader/tei:profileDesc/tei:langUsage/tei:language[1]/@ident)
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
    return springs:_return-response($returnVal)
};

declare
 %rest:GET
 %rest:path("/springs/magazines")
 %output:method("text")
 %rest:produces("text/csv")
function springs:magazines-as-csv() {
  let $mags := springs:_magazines-tei()
  for $mag in $mags
    let $bmtnid := springs:_title-id($mag)
    let $primaryTitle := springs:_magazine-title($mag)
    let $primaryLanguage := $mag/tei:teiHeader/tei:profileDesc/tei:langUsage/tei:language[1]/@ident
    let $startDate := springs:_magazine-date-start($mag)
    let $endDate := springs:_magazine-date-end($mag)
    let $uri := $config:springs-root || '/magazines/' || $bmtnid
    let $returnVal := concat(string-join(($bmtnid,$primaryTitle,$primaryLanguage,$startDate,$endDate,$uri), ','), codepoints-to-string(10))
    return springs:_return-response($returnVal)
};

(: TODO support output as TEI, RDF :)

declare
  %rest:GET
  %rest:path("/springs/magazines/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:magazine($bmtnid) {
    let $titlerec := springs:_magazine($bmtnid)
    let $title := springs:_magazine-title($titlerec)
    let $issues := springs:_magazine-issues($bmtnid)
    let $sorted := 
        for $i in $issues
        let $pubdate := springs:_issue-date($i)
        order by $pubdate
        return $pubdate
    let $startDate := xs:string($sorted[1])
    let $endDate   := xs:string($sorted[last()])
    let $returnVal :=
        <magazine>
            <bmtnid>{ $bmtnid }</bmtnid>
            <primaryTitle>{ $title }</primaryTitle>
            <startDate>{ $startDate }</startDate>
            <endDate>{ $endDate }</endDate>
            <issues>
            {
                for $issue in $issues
                let $issueid := springs:_issue-id($issue)
                let $date := springs:_issue-date($issue)
                return
                    <issue>
                        <id>{$issueid}</id>
                        <date>{$date}</date>
                        <url>{$config:springs-root || '/issues/' || $issueid}</url>
                    </issue>
            }
            </issues>
        </magazine>
    return springs:_return-response($returnVal)      
};


(:::::::::::::::::::: ISSUES ::::::::::::::::::::)

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %rest:produces("application/tei+xml")
function springs:issue-as-tei($bmtnid) {
    springs:_return-response($springs:_issue($bmtnid))
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
    springs:_return-response(transform:transform($issue, $xsl, ()))
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
        springs:_return-response(transform:transform($issue, $xsl, $xslt-parameters))
};

(:
declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %rest:produces("application/rdf+xml")
function springs:issue-as-rdf($bmtnid) {
    let $issue := springs:_issue-mods($bmtnid)
    let $xsl := doc($config:app-root || "/resources/xsl/mods2crm.xsl")

    return springs:_return-response(transform:transform($issue, $xsl, ()))
};
:)
(:::::::::::::::::::: CONSTITUENTS ::::::::::::::::::::)
declare function springs:constituents($bmtnid) {
    let $constituents :=
        if (springs:_issuep($bmtnid))
            then springs:_issue($bmtnid)//tei:relatedItem[@type='constituent']
        else
            for $issue in springs:_magazine-issues($bmtnid)
            return $issue//tei:relatedItem[@type='constituent']
    return
        $constituents
};

declare
 %rest:GET
 %rest:path("/springs/constituents/{$bmtnid}")
 %output:method("text")
 %rest:produces("text/csv")
function springs:constituents-as-csv($bmtnid) {
    let $header := "issueid,issueTitle,constituentID,constituentTitle"
    let $rows :=
        for $constituent in springs:constituents($bmtnid)
            let $issue := $constituent/ancestor::tei:TEI
            let $issueid := xs:string($issue//tei:idno[@type='bmtnid'])
            let $issueTitle := xs:string($issue//tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title/tei:seg[@type='main'])
            let $constituentid := xs:string($constituent/@xml:id)
            let $constituentTitle := springs:_clean-string(xs:string($constituent/tei:biblStruct/tei:analytic/tei:title[@level = 'a']/tei:seg[@type='main'][1]))
        return
            string-join(($issueid,$issueTitle,$constituentid,$constituentTitle), ',')
    return
        string-join(($header,$rows), codepoints-to-string(10))
};

declare
 %rest:GET
 %rest:path("/springs/constituents/{$bmtnid}")
 %output:method("json")
 %rest:produces("application/json")
function springs:constituents-as-json($bmtnid) {
    <constituents> {
        for $constituent in springs:constituents($bmtnid)
            let $issue := $constituent/ancestor::tei:TEI
            let $issueid := xs:string($issue//tei:idno[@type='bmtnid'])
            let $issueTitle := xs:string($issue//tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title/tei:seg[@type='main'])
            let $constituentid := xs:string($constituent/@xml:id)
            let $constituentTitle := springs:_clean-string(xs:string($constituent/tei:biblStruct/tei:analytic/tei:title[@level = 'a']/tei:seg[@type='main'][1]))
        return
            <constituent>
                <issueid>{$issueid}</issueid>
                <issueTitle>{$issueTitle}</issueTitle>
                <constituentID>{$constituentid}</constituentID>
                <constituentTitle>{$constituentTitle}</constituentTitle>
            </constituent>
    }
    </constituents>
};
   

declare
 %rest:GET
 %rest:path("springs/constituents")
 %rest:query-param("byline", "{$byline}","")
 %rest:query-param("viafid", "{$viafid}","")
 %rest:produces("application/tei+xml")
function springs:constituents-by-byline-tei($byline, $viafid) {
    let $constituents := 
        if ($byline) then 
            springs:constituents-with-byline($byline)
        else if ($viafid) then
        collection($config:transcriptions)//tei:relatedItem[@type='constituent' and contains(.//tei:persName/@ref, $viafid)]
        else ()
    
    let $xsl := doc($config:app-root || "/resources/xsl/constituent-to-tei.xsl")
    let $constituents-old := collection($config:transcriptions)//tei:relatedItem[@type='constituent' and ft:query(.//tei:persName, $byline)]
    return
        <teiCorpus xmlns="http://www.tei-c.org/ns/1.0">
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                        <title>Blue Mountain Selections</title>
                        <author>{ $byline }</author>
                    </titleStmt>
                    <publicationStmt>
                        <p>
                            Generated { count($constituents) } hits from { $config:transcriptions }
                        </p>
                    </publicationStmt>
                    <sourceDesc><p>Blue Mountain Project</p></sourceDesc>
                </fileDesc>
            </teiHeader>
            {
                for $hit in $constituents
                let $cid := $hit/@xml:id
                let $div := $hit/ancestor::tei:TEI//tei:div[@corresp = $cid]
                return 
                    <TEI>
                        <teiHeader>
                            <fileDesc>
                                <titleStmt>
                                    <title>
                                        { $hit/tei:biblStruct }
                                    </title>
                                </titleStmt>
                    <publicationStmt>
                        <p>
                            Later
                        </p>
                    </publicationStmt>
                    <sourceDesc><p>Later</p></sourceDesc>
                            </fileDesc>
       
                        </teiHeader>
                        <text>
                            <body>
                                { $div }
                            </body>
                        </text>                
                    </TEI>
            }
        
        </teiCorpus>
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

declare function springs:constituents-with-byline($byline as xs:string)
as element()*
{
    collection($config:transcriptions)//tei:relatedItem[ft:query(.//tei:persName, $byline)]
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
 %rest:path("/springs/contributors/{$bmtnid}")
 %output:method("json")
 %rest:produces("application/json")
function springs:contributors-json($bmtnid) {
    if (springs:_issuep($bmtnid))
        then springs:contributors-from-issue-json($bmtnid)
    else springs:contributors-from-title-json($bmtnid)
};

(: ::::::::: Utility functions :::::::::: :)

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

declare function springs:_magazine($bmtnid as xs:string)
{
    collection($config:transcriptions)//tei:TEI[./tei:teiHeader//tei:publicationStmt/tei:idno[@type='bmtnid'] = $bmtnid]
};

declare function springs:_magazine-issues($bmtnid as xs:string)
{
    collection($config:transcriptions)//tei:TEI[.//tei:relatedItem[@type='host']/@target = $bmtnid]
};

declare function springs:_magazines-tei() {
    collection($config:transcriptions)//tei:TEI[./tei:teiHeader/tei:profileDesc/tei:textClass/tei:classCode = 300215389 ]
};

declare function springs:_issue-id($issue as element())
{
    xs:string($issue/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid'])
};

declare function springs:_issue-date($issue as element())
{
    xs:string(springs:_magazine-monogr($issue)/tei:imprint/tei:date/@when)
};

declare function springs:_title-id($title as element())
{
    xs:string($title/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid'])
};

declare function springs:_bylines-from-issue-tei($issue)
as element()+
{
    $issue//tei:respStmt[./tei:resp = 'cre']/tei:persName
};

declare function springs:_clean-string($string)
{
    let $cleaned := normalize-space($string)
    let $cleaned := replace($cleaned, ',', '|')
    
    return $cleaned
};

declare function springs:_contributor-data-tei($issue)
{
    let $issueid := xs:string($issue//tei:idno[@type='bmtnid'])
    let $issuelabel := $issue//tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title/tei:seg[@type='main']
    let $contributions := $issue//tei:relatedItem[@type='constituent']
    for $contribution in $contributions
        let $constituentid := xs:string($contribution/@xml:id)
        let $title := springs:_clean-string(xs:string($contribution/tei:biblStruct/tei:analytic/tei:title[@level = 'a']/tei:seg[@type='main'][1]))
        let $respStmts := $contribution//tei:respStmt
        for $stmt in $respStmts
            let $byline := springs:_clean-string($stmt/tei:persName/text())
            let $contributorid := if ($stmt/tei:persName/@ref) then xs:string($stmt/tei:persName/@ref) else " "
            return
             concat(string-join(($issueid, $issuelabel,$contributorid,$byline,$constituentid,$title), ','), codepoints-to-string(10))
};


declare function springs:_contributor-data-tei-as-xml($issue)
{
    let $issueid := xs:string($issue//tei:idno[@type='bmtnid'])
    let $issuelabel := $issue//tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title/tei:seg[@type='main']
    let $contributions := $issue//tei:relatedItem[@type='constituent']
    for $contribution in $contributions
        let $constituentid := xs:string($contribution/@xml:id)
        let $title := springs:_clean-string(xs:string($contribution/tei:biblStruct/tei:analytic/tei:title[@level = 'a']/tei:seg[@type='main'][1]))
        let $respStmts := $contribution//tei:respStmt
        for $stmt in $respStmts
            let $byline := springs:_clean-string($stmt/tei:persName/text())
            let $contributorid := if ($stmt/tei:persName/@ref) then xs:string($stmt/tei:persName/@ref) else " "
            return
                <contributor>
                    <issueid>{$issueid}</issueid>
                    <issuelabel>{$issuelabel}</issuelabel>
                    <contributorid>{$contributorid}</contributorid>
                    <byline>{$byline}</byline>
                    <constituentid>{$constituentid}</constituentid>
                    <title>{$title}</title>
                </contributor>
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

declare function springs:contributors-from-issue-json($bmtnid) {
    let $issue := springs:_issue-by-id($bmtnid)
    let $contributors := springs:_contributor-data-tei-as-xml($issue)
    return <contributors>{$contributors}</contributors>
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

declare function springs:contributors-from-title-json($bmtnid) {
    let $issues := collection($config:transcriptions)//tei:relatedItem[@type='host' and @target = $bmtnid]/ancestor::tei:TEI
    return
        <contributors>
            {
                for $issue in $issues return springs:_contributor-data-tei-as-xml($issue)
            }
        </contributors>
};

declare function springs:_return-response($returnVal) {
    (
        <rest:response>
            <http:response>
                <http:header name="Content-Type" value="text/plain"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>,
    $returnVal
    )   
};
 