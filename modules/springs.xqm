xquery version "3.0";
(:~
: This module provides the functions supporting the Blue Mountain Springs
: API.
@author Clifford Wulfman
@version 1.0.0
:)
module namespace springs = "http://bluemountain.princeton.edu/apps/springs";
import module namespace config="http://bluemountain.princeton.edu/apps/springs/config" at "config.xqm";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";

import module namespace rest = "http://exquery.org/ns/restxq" ;

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client"; 

declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace tei="http://www.tei-c.org/ns/1.0";


(: Utility functions :)

(:~
: Blue Mountain objects -- magazines and issues -- are
: distinguished by a unique identifier: a bmtnid. The composition
: of a bmtnid is discussed in detail elsewhere.
:
: To retrieve a Blue Mountain object from the database, therefore,
: one queries for an object with a matching bmtnid.
:
: @param $bmtnid the id of the object to be retrieved
: @return the TEI document for the object
:)
declare function springs:_bmtn-object($bmtnid)
as element()
{
    collection($config:transcriptions)//tei:idno[@type='bmtnid' and . = $bmtnid]/ancestor::tei:TEI
};


declare function springs:_typeof($bmtnid)
as xs:string
{
    let $object := springs:_bmtn-object($bmtnid)
    return xs:string($object//tei:teiHeader//tei:profileDesc/tei:textClass/tei:classCode)
};

declare function springs:_bmtnid-of($bmtnobject)
as xs:string
{
    $bmtnobject//tei:TEI//tei:teiHeader//tei:publicationStmt/tei:idno[@type='bmtnid']
};


declare function springs:_issuep($bmtnid)
as xs:boolean
{
    let $classCode := springs:_typeof($bmtnid)
    return if ($classCode = "300312349") then true() else false() 
};


declare function springs:_magazine($bmtnid as xs:string)
{
    springs:_bmtn-object($bmtnid)
};


declare function springs:_magazine-monogr($magazine as element())
as element()
{
    $magazine/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr
};

declare function springs:_magazine-title($magazine as element())
as xs:string?
{
    springs:_object-title($magazine)
};


declare function springs:_issue-label($issue as element())
{
    springs:_object-title($issue)
};

declare function springs:_object-title($object as element())
{
    let $title := springs:_magazine-monogr($object)/tei:title[@level='j']
    let $nonSort := $title/tei:seg[@type='nonSort']
    let $main := $title/tei:seg[@type='main']
    let $sub  := $title/tei:seg[@type='sub']
    let $titleString := string-join(($nonSort,$main), ' ')
    return if ($sub) then $titleString || ': ' || $sub else $titleString
};

declare function springs:_constituent($objid, $constid)
{
    springs:_bmtn-object($objid)//tei:div[@corresp = $constid]
};

declare function springs:_constituent-id($constituent as element())
{
    xs:string($constituent/@xml:id)
};

declare function springs:_constituent-title($constituent as element())
{
    let $title := $constituent/tei:biblStruct/tei:analytic/tei:title[@level = 'a']
    let $nonSort := $title/tei:seg[@type='nonSort']
    let $main := $title/tei:seg[@type='main']
    let $sub  := $title/tei:seg[@type='sub']
    let $titleString := string-join(($nonSort,$main), ' ')
    return if ($sub) then $titleString || ': ' || $sub else $titleString    
};

declare function springs:_constituent-bylines($constituent as element())
{
    for $stmt in $constituent//tei:respStmt
    return normalize-space($stmt/tei:persName/text())
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

(: TODO refactor :)
declare function springs:_issue($issueid as xs:string)
as element()
{
    springs:_bmtn-object($issueid)
};

declare function springs:_issues-of-magazine($magid as xs:string)
as element()*
{
    collection($config:transcriptions)//tei:relatedItem[@type='host' and @target = $magid]/ancestor::tei:TEI
};

declare function springs:_issue-date($issueobj)
{
    let $date := springs:_magazine-monogr($issueobj)/tei:imprint/tei:date
    return if ($date/@from) then $date/@from else $date/@when    
};

declare function springs:_magazines() {
    collection($config:transcriptions)//tei:TEI[./tei:teiHeader/tei:profileDesc/tei:textClass/tei:classCode = 300215389 ]
};

declare function springs:_bylines-from-issue-tei($issue as element())
as element()+
{
    $issue//tei:relatedItem[@type='constituent']//tei:respStmt[tei:resp = 'cre']/tei:persName
};

declare function springs:_magazine-struct($bmtnobj as element(), $include-issues as xs:boolean)
{
    let $bmtnid := springs:_bmtnid-of($bmtnobj)
    let $primaryTitle := springs:_magazine-title($bmtnobj)
    let $primaryLanguage := $bmtnobj/tei:teiHeader/tei:profileDesc/tei:langUsage/tei:language[1]/@ident
    let $startDate := springs:_magazine-date-start($bmtnobj)
    let $endDate := springs:_magazine-date-end($bmtnobj)
    let $uri := $config:springs-root || '/magazines/' || $bmtnid
    let $issues :=
        if ($include-issues) then
              for $issue in springs:_issues-of-magazine($bmtnid)
              return
                   <issues>
                       <id>  { springs:_bmtnid-of($issue) }</id>
                       <date>{ springs:_issue-date($issue) }</date>
                       <url> { $config:springs-root || '/issues/' || springs:_bmtnid-of($issue) }</url>
                   </issues>
        else ()
    return
        <magazine>
            <bmtnid>{ $bmtnid }</bmtnid>
            <primaryTitle>{ $primaryTitle }</primaryTitle>
            <primaryLanguage>{ $primaryLanguage }</primaryLanguage>
            <startDate>{ $startDate }</startDate>
            <endDate>{ $endDate }</endDate>
            <uri>{ $uri }</uri>
            { for $issue in $issues return $issue }
        </magazine>
};

(:::: Utilities for Contributors ::::)
declare function springs:_contributor-data-tei($issue)
{
    let $issueid := xs:string($issue//tei:idno[@type='bmtnid'])
    let $issuelabel := $issue//tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title/tei:seg[@type='main']
    let $contributions := $issue//tei:relatedItem[@type='constituent']
    for $contribution in $contributions
        let $constituentid := xs:string($contribution/@xml:id)
        let $title := normalize-space(xs:string($contribution/tei:biblStruct/tei:analytic/tei:title[@level = 'a']/tei:seg[@type='main'][1]))
        let $qtitle := concat("&quot;", $title,"&quot;")
        let $respStmts := $contribution//tei:respStmt
        for $stmt in $respStmts
            let $byline := normalize-space($stmt/tei:persName/text())
            let $byline := concat("&quot;", $byline,"&quot;")
            let $contributorid := if ($stmt/tei:persName/@ref) then xs:string($stmt/tei:persName/@ref) else " "
            return
             concat(string-join(($issueid, $issuelabel,$contributorid,$byline,$constituentid,$qtitle), ','), codepoints-to-string(10))
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



(:::::::::::::::::::  MAGAZINES ::::::::::::::::)


declare
 %rest:GET
 %rest:path("/springs/magazines")
 %output:method("json")
 %rest:produces("application/json")
function springs:magazines-as-json() {
    <magazines> {
  for $mag in springs:_magazines()
    return springs:_magazine-struct($mag, false())
    } </magazines>
};

declare
 %rest:GET
 %rest:path("/springs/magazines")
 %output:method("text")
 %rest:produces("text/csv")
function springs:magazines-as-csv() {
  for $mag in springs:_magazines()
    let $struct := springs:_magazine-struct($mag, false())
    return concat(string-join(($struct/bmtnid,$struct/primaryTitle,$struct/primaryLanguage,$struct/startDate,$struct/endDate,$struct/uri), ','), codepoints-to-string(10))
};

declare
  %rest:GET
  %rest:path("/springs/magazines/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:magazine-tei($bmtnid) {
    springs:_magazine-struct(springs:_magazine($bmtnid), true())
};  
  

(:::::::::::::::::::: ISSUES ::::::::::::::::::::)

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %rest:produces("application/tei+xml")
function springs:issue-as-tei($bmtnid) {
    if (springs:_issuep($bmtnid)) then
        springs:_bmtn-object($bmtnid)
    else
    <teiCorpus xmlns="http://www.tei-c.org/ns/1.0">
     <teiHeader>
         <fileDesc>
             <titleStmt>
                 <title>{ springs:_magazine-title(springs:_magazine($bmtnid)) }</title>
             </titleStmt>
	        <publicationStmt>
	           <p>Publication Information</p>
	        </publicationStmt>
	        <sourceDesc>
	           <p>Information about the source</p>
	        </sourceDesc>
         </fileDesc>
     </teiHeader>
     { springs:_issues-of-magazine($bmtnid) }
     </teiCorpus>
};

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %output:method("text")
  %rest:produces("text/plain")
function springs:issue-as-plaintext($bmtnid) {
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    let $responseBody :=
        if (springs:_issuep($bmtnid)) then
            transform:transform( springs:_bmtn-object($bmtnid), $xsl, () )
        else
            for $issue in springs:_issues-of-magazine($bmtnid)
            return transform:transform($issue, $xsl, ())
    return 
    (
        <rest:response>
            <http:response>
                <http:header name="Content-Type" value="text/plain"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>,
        $responseBody 
    )
};

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:issue-as-json($bmtnid) {
    let $xsl := doc($config:app-root || "/resources/xsl/tei2data.xsl")
    let $xslt-parameters := 
      <parameters>
          <param name="springs-root" value="{$config:springs-root}"/>
      </parameters>
    let $responseBody :=
        if (springs:_issuep($bmtnid)) then
            transform:transform( springs:_bmtn-object($bmtnid), $xsl, $xslt-parameters )
        else
            springs:_magazine-struct(springs:_magazine($bmtnid), true())
    return 
    (
        <rest:response>
            <http:response>
                <http:header name="Content-Type" value="application/json"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
        </rest:response>,
        $responseBody
    )
};

declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %rest:produces("application/rdf+xml")
function springs:issue-as-rdf($bmtnid) {
    let $issue := springs:_issue($bmtnid)
    let $xsl := doc($config:app-root || "/resources/xsl/bmtn2rdf.xsl")

    return transform:transform($issue, $xsl, ())
};

(:::::::::::::::::::: CONSTITUENTS ::::::::::::::::::::)

declare
  %rest:GET
  %rest:path("/springs/constituents/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:constituents-as-json($bmtnid) {
    let $constituents := springs:_bmtn-object($bmtnid)//tei:relatedItem[@type='constituent']
    return
     <issue>
       {
        for $constituent in $constituents
        return
        <constituent>
        <id>{ string-join(($bmtnid,springs:_constituent-id($constituent)), '#') }</id>
        <uri>{ $config:springs-root || '/constituent/' || $bmtnid || '/' || springs:_constituent-id($constituent) }</uri>
        <title>{ springs:_constituent-title($constituent) }</title>
        {
            for $byline in springs:_constituent-bylines($constituent)
            return <byline>{ $byline }</byline>
        }
        </constituent>
       }
     </issue>
};

(:::::::::::::::::::: CONSTITUENT ::::::::::::::::::::) 
declare
  %rest:GET
  %rest:path("/springs/constituent/{$issueid}/{$constid}")
    %rest:produces("text/plain")
function springs:constituent-plaintext($issueid, $constid) {
    let $constituent := springs:_constituent($issueid, $constid)
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
    springs:_constituent($issueid, $constid)
};


(::::::::::::::::::: TEXT ::::::::::::::::::::)
(:: I think this service is redundant ::)

declare
    %rest:GET
    %rest:path("/springs/text/{$issueid}/{$constid}")
    %output:method("text")
function springs:constituent-text($issueid as xs:string, $constid as xs:string)
{
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    let $constituent := springs:_constituent($issueid, $constid)
    return transform:transform($constituent, $xsl, ())
};


declare
 %rest:GET
 %rest:path("/springs/text/{$issueid}")
function springs:text($issueid) {
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    return transform:transform(springs:_bmtn-object($issueid), $xsl, ())
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
 %rest:path("/springs/contributors/{$issueid}")
 %output:method("json")
 %rest:produces("application/json")
function springs:contributors-from-issue($issueid) {
    let $issue := springs:_bmtn-object($issueid)
    let $bylines := springs:_bylines-from-issue-tei($issue)
    let $issue-label := springs:_object-title($issue)
  
    return
        <contributors> {
          for $byline in $bylines
          let $contributorid := 
            if ($byline/@ref)
                then xs:string($byline/@ref)
            else ()
          let $constituent := $byline/ancestor::tei:relatedItem[@type='constituent'][1]
          let $constituentid := xs:string($constituent/@xml:id)
          let $title := if ($constituent) then springs:_constituent-title($constituent) else "Untitled"
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

declare
 %rest:GET
 %rest:path("/springs/contributions")
 %rest:query-param("byline", "{$byline}", "stranger")
 %output:method("json")
 %rest:produces("application/json")
function springs:constituents-with-byline-json($byline)
as element()*
{
    <contributions> {
    for $constituent in collection($config:transcriptions)//tei:relatedItem[ft:query(.//tei:persName, $byline)]
    let $title := xs:string($constituent/tei:biblStruct/tei:analytic/tei:title)
    let $bylines := $constituent/tei:biblStruct/tei:analytic/tei:respStmt/tei:persName
    let $languages := $constituent/tei:biblStruct/tei:analytic/tei:textLang
    let $issueid := $constituent/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid']
    let $constid := xs:string($constituent/@xml:id)
    return
     <contribution>
        <title>{ $title }</title>
        { for $b in $bylines return <byline>{ xs:string($b)} </byline> }
        { for $l in $languages return <language>{ xs:string($l/@mainLang)}</language> }        
        <issue>{ xs:string($issueid) }</issue>
        <constituentid>{ $constid }</constituentid>
        <uri>{ $config:springs-root || '/constituent/' || $issueid || '/' || $constid }</uri>
     </contribution>
     } </contributions>
};

declare
 %rest:GET
 %rest:path("/springs/contributions")
 %rest:query-param("byline", "{$byline}", "stranger")
 %rest:produces("application/tei+xml")
function springs:constituents-with-byline-tei($byline)
as element()*
{
    <teiCorpus xmlns="http://www.tei-c.org/ns/1.0">
     <teiHeader>
         <fileDesc>
             <titleStmt>
                 <title>title of corpus</title>
                 <author>author</author>
             </titleStmt>
	        <publicationStmt>
	           <p>Publication Information</p>
	        </publicationStmt>
	        <sourceDesc>
	           <p>Information about the source</p>
	        </sourceDesc>
         </fileDesc>
     </teiHeader> {
    for $constituent in collection($config:transcriptions)//tei:relatedItem[ft:query(.//tei:persName, $byline)]
    let $title := xs:string($constituent/tei:biblStruct/tei:analytic/tei:title)
    let $bylines := $constituent/tei:biblStruct/tei:analytic/tei:respStmt/tei:persName
    let $languages := $constituent/tei:biblStruct/tei:analytic/tei:textLang
    let $issueid := $constituent/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid']
    let $constid := xs:string($constituent/@xml:id)
    return
     <TEI xml:id="{$issueid ||'_'||$constid}">
        <teiHeader>
            <fileDesc>
            <titleStmt>
                <title>{ $title }</title>
            </titleStmt>
            <publicationStmt>
                <p>
                <ref target="{ $config:springs-root || '/constituent/' || $issueid || '/' || $constid }"/>
                </p>
            </publicationStmt>
            <seriesStmt>
                <p>Blue Mountain Project</p>
            </seriesStmt>
            <sourceDesc>{ $constituent/tei:biblStruct }</sourceDesc>
            </fileDesc>
        </teiHeader>
        <text>
          <body>
          { $constituent/ancestor::tei:TEI//tei:div[@corresp=$constid] }
          </body>
        </text>
     </TEI>
     } </teiCorpus>
};
