xquery version "3.0";
(:~
 : This module provides the utility functions supporting the
 : primary resource functions in springs.xqm.
 :
 : @author Clifford Wulfman
 : @version 1.1.0
 :)
module namespace app="http://bluemountain.princeton.edu/apps/springs/app";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://bluemountain.princeton.edu/apps/springs/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";


(: Global Declarations :)

(:~
 : The class identifiers for Blue Mountain Objects.
 :
 : Blue Mountain Objects are classified in the TEI header according to
 : the Getty Art and Architecture Thesaurus.
 : 
 : In the current implementation, there are two kinds of objects:
 : <ul>
 : <li>http://vocab.getty.edu/aat/300215389: magazines (periodicals)</li>
 : <li>http://vocab.getty.edu/aat/300312349: issues (object groupings)</li>
 : </ul>
 :
 : @see http://vocab.getty.edu/aat/
 :)
declare variable $app:issueClass    as xs:string := "300312349";
declare variable $app:magazineClass as xs:string := "300215389";

(:~
 : Emitting csv requires terminating each line with a linefeed character.
 :)
declare variable $app:lf as xs:string := codepoints-to-string(10);

(:~
 : Is a given string a valid Blue Mountain ID?
 : @param $string
 : @return boolean
 :)
 declare function app:bmtnidp($inputstring as xs:string)
 as xs:boolean
 {
    if (collection($config:transcriptions)//tei:idno[@type='bmtnid' and .= $inputstring])
        then true()
        else false()
 };


(:~
 : The Blue Mountain Object identified by an ID.
 :
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
declare function app:bmtn-object($bmtnid as xs:string)
as element()?
{
    collection($config:transcriptions)//tei:idno[@type='bmtnid' and . = $bmtnid]/ancestor::tei:TEI
};



(:~
 : The type of a given Blue Mountain Object.
 :
 : Blue Mountain Objects are classified in the TEI header according to
 : the Getty Art and Architecture Thesaurus.
 : 
 : In the current implementation, there are two kinds of objects:
 : <ul>
 : <li>http://vocab.getty.edu/aat/300215389: magazines (periodicals)</li>
 : <li>http://vocab.getty.edu/aat/300312349: issues (object groupings)</li>
 : </ul>
 :
 : The implementation does not specify what kinds of objects may be in
 : Blue Mountain.
 :
 : @see http://vocab.getty.edu/aat/
 : @param $bmtnid the id of the Object whose type is being determined
 : @return a string identifying the Object's type.
 :)
declare function app:typeof($bmtnid as xs:string)
as xs:string
{
    xs:string(app:bmtn-object($bmtnid)//tei:teiHeader//tei:profileDesc/tei:textClass/tei:classCode)
};


(:~
 : The ID of a given Blue Mountain Object.
 :
 : Every Blue Mountain Object has a unique identifier. This identifier
 : is encoded in a tei:idno element whose type is 'bmtnid'.
 :
 : @param $bmtnobject a TEI element
 : @return a string representing the supplied parameter's id.
 :)
declare function app:bmtnid-of($bmtnobject as element())
as xs:string
{
    $bmtnobject//tei:TEI//tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid']
};


(:~
 : Is an Object with a given ID an issue?
 :
 : Some module logic depends on the type of Object being evaluated:
 : a Magazine object or an Issue object. This predicate hides the 
 : procedure for determining that an object is an issue.
 :
 : @param $bmtnid a string representing a Blue Mountain Object's id
 : @return boolean true if the associated object is an issue; false otherwise
 :)
declare function app:issuep($bmtnid as xs:string)
as xs:boolean
{
    if (app:typeof($bmtnid) = $app:issueClass) then true() else false() 
};


(:~
 : The primary descriptive metadata element of a Blue Mountain Object.
 :
 : This function serves as a macro for the xpath to the tei:monogr element
 : of a object.
 : 
 : @see http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-monogr.html
 : @param $magazine a TEI element
 : @return a tei:monogr element
 :)
declare function app:magazine-monogr($magazine as element())
as element()
{
    $magazine/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr
};


(:~
 : The display-formatted version of a title.
 :
 : A tei:title may contain a number of sub-elements. This function
 : parses them into a string that can be used to display the title
 : of the object.
 :
 : @see http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-title.html
 : @param $title a tei:title element
 : @return a string
 :)
declare function app:formatted-title($title as element()?)
as xs:string
{
    if ($title) then  
    let $nonSort := $title/tei:seg[@type='nonSort']
    let $main := $title/tei:seg[@type='main']
    let $sub  := $title/tei:seg[@type='sub']
    let $titleString := string-join(($nonSort,$main), ' ')
    return if ($sub) then $titleString || ': ' || $sub else $titleString
    else "[Untitled]"
};

(:~
 : The display title of a Blue Mountain Object.
 :
 : A wrapper around a call to app:formatted-title($title) with
 : the 'j' level title as an argument.
 :
 : @see http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-title.html
 :)
declare function app:object-title($object as element())
as xs:string
{
    app:formatted-title(app:magazine-monogr($object)/tei:title[@level='j'])
};


(:~
 : The constituent with a particular constituent id.
 :
 : The text body of an Issue Object contains tei:divs corresponding
 : to the relatedItems in the teiHeader's source description. This function
 : retrieves an Issue Object and extracts the tei:div corresponding to the
 : given id.
 :
 : @param $objid a bmtnid
 : @param $constid the id of a constituent of the given object.
 : @return a tei:div element
 :)
declare function app:constituent($objid as xs:string, $constid as xs:string)
as element()?
{
    app:bmtn-object($objid)//tei:div[@corresp = $constid]
};


(:~
 : The id of an issue constituent (tei:relatedItem type='constituent']).
 :
 : The descriptive bibliographic information for the articles, advertisements,
 : and other content of a magazine issue are encoded in the teiHeader as a series
 : of tei:relatedItems. Each of these relatedItems has an xml:id; this id is used
 : to link the bibliographic information about a constituent with its representation
 : in the body of the document.
 :
 : @see http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-sourceDesc.html
 : @see http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-biblStruct.html
 : @param $constituent a tei:relatedItem element
 : @return the xml:id of that element
 :)
declare function app:constituent-id($constituent as element())
as xs:string
{
    xs:string($constituent/@xml:id)
};


(:~
 : The display title of an issue constituent.
 :
 : A wrapper around a call to app:formatted-title($title) with
 : the first 'a' level title as an argument.
 :
 : @see http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-title.html
 :)    
declare function app:constituent-title($constituent as element())
as xs:string
{
    app:formatted-title($constituent/tei:biblStruct[1]/tei:analytic[1]/tei:title[@level = 'a'][1])   
};


(:~
 : The publication date of a Blue Mountain Object.
 :
 : The publication date is encoded as a tei:date in the
 : tei:imprint of the object in its teiHeader. 
 :
 : @see http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-imprint.html
 : @param $bmtnobj a tei:TEI element
 : @return a tei:date element
 :)
declare function app:object-date($bmtnobj as element())
as element()
{
    app:magazine-monogr($bmtnobj)/tei:imprint/tei:date
};


(:~
 : The issuance date of an issue.
 :
 : Sometimes an issue has a specific issuance date; in the
 : case of an issue whose issuance date is a range (of weeks, months)
 : Blue Mountain defines its issuance date as the first date in the range.
 :
 : @param $issueobj a TEI element
 : @return a w3cdtf-formatted date string.
 :)
declare function app:issue-date($issueobj as element())
as xs:date
{
    let $date := app:object-date($issueobj)
    return if ($date/@from) then app:w3cdtf-to-xsdate($date/@from) else app:w3cdtf-to-xsdate($date/@when)    
};


(:~
 : The start date of a magazine run.
 :
 : Magazine objects encode their run dates as
 : date @from="yyyy-mm-dd" @to="yyyy-mm-dd";
 : if there was only one issue, the run is
 : encoded as date @when="yyyy-mm-dd", in which case
 : the @when date is used for both the beginning and
 : the end of the run.
 :
 : @param $magazine a TEI element
 : @return a w3cdtf-formatted date string.
 :)
declare function app:magazine-date-start($magazine as element())
as xs:date
{
    let $date := app:object-date($magazine)
    return if ($date/@from) then app:w3cdtf-to-xsdate($date/@from) else app:w3cdtf-to-xsdate($date/@when)
};


(:~
 : The end date of a magazine run.
 :
 : @see documentation for app:magazine-date-start()
 : @param $magazine a TEI element
 : @return a w3cdtf-formatted date string.
 :)
declare function app:magazine-date-end($magazine as element())
as xs:date
{
    let $date := app:object-date($magazine)
    return if ($date/@to) then app:w3cdtf-to-xsdate($date/@to) else app:w3cdtf-to-xsdate($date/@when)
};


(:~
 : The issues of a Magazine
 :
 : The issues of a magazine M are defined as all tei:TEI elements
 : having M as the host.
 :
 : @param $magid a bmtnid
 : @return a sequence of 0 or more TEI elements
 :)
declare function app:issues-of-magazine($magid as xs:string)
as element()*
{
    collection($config:transcriptions)//tei:relatedItem[@type='host' and @target = $magid]/ancestor::tei:TEI
};


(:~
 : All the Magazine objects in Blue Mountain.
 :
 : Magazine objects are TEI elements whose tei:classCode is $app:magazineClass.
 : @return sequence of tei:TEI elements.
 :)
declare function app:magazines()
as element()+
{
    collection($config:transcriptions)//tei:TEI[./tei:teiHeader/tei:profileDesc/tei:textClass/tei:classCode = $app:magazineClass ]
};

(:~
 : A common representation of a magazine that can be serialized different ways.
 :
 : The common data model for a magazine used by Blue Mountain Springs. It is serialized
 : in different formats by the RESTXQ functions.
 :
 : @param $bmtnobj a tei:TEI element representing a Magazine Object
 : @param $include-issues as boolean flag; if true include a representation of all issues
 : @return a magazine element
 :)
declare function app:magazine-struct($bmtnobj as element()?, $include-issues as xs:boolean)
as element()?
{   if (empty($bmtnobj)) then () else
    let $bmtnid := app:bmtnid-of($bmtnobj)
    let $primaryTitle := app:object-title($bmtnobj)
    let $primaryLanguage := $bmtnobj/tei:teiHeader/tei:profileDesc/tei:langUsage/tei:language[1]/@ident
    let $startDate := app:magazine-date-start($bmtnobj)
    let $endDate := app:magazine-date-end($bmtnobj)
    let $uri := $config:springs-root || '/magazines/' || $bmtnid
    let $issues :=
        if ($include-issues) then
              for $issue in app:issues-of-magazine($bmtnid)
              return
                app:issue-struct($issue, false())
        else
        ()
    return
        <magazine>
            <bmtnid>{ $bmtnid }</bmtnid>
            <primaryTitle>{ $primaryTitle }</primaryTitle>
            <primaryLanguage>{ $primaryLanguage }</primaryLanguage>
            <startDate>{ $startDate }</startDate>
            <endDate>{ $endDate }</endDate>
            <uri>{ $uri }</uri>
            <issues>{  if ($issues) then $issues else $config:springs-root || '/issues/' || $bmtnid}</issues>
        </magazine>
};


(:~
 : A common representation of an issue that can be serialized different ways.
 :
 : The common data model for an issue used by Blue Mountain Springs. It is serialized
 : in different formats by the RESTXQ functions.
 :
 : @param $bmtnobj a tei:TEI element representing a Magazine Object
 : @param $include-constituents a boolean if true, include all constituents
 : @return an issue element
 :)
declare function app:issue-struct($bmtnobj as element(), $include-constituents as xs:boolean)
as element()
{
    let $bmtnid := app:bmtnid-of($bmtnobj)
    return
     <issue>
        <id>  { $bmtnid }</id>
        <date>{ app:issue-date($bmtnobj) }</date>
        <url> { $config:springs-root || '/issues/' || $bmtnid }</url>
        <constituents>
        {
            if ($include-constituents) then
                for $constituent in $bmtnobj//tei:relatedItem[@type='constituent']
                return
                <constituent>{ app:constituent-struct($constituent, $bmtnid) }</constituent>
            else
            <uri>{ $config:springs-root || '/constituents/' || $bmtnid }</uri>
        }
        </constituents>
       
     </issue>
};


declare function app:issue-struct-old($bmtnobj as element(), $include-constituents as xs:boolean)
as element()
{
    let $bmtnid := app:bmtnid-of($bmtnobj)
    return
     <issue>
        <id>  { $bmtnid }</id>
        <date>{ app:issue-date($bmtnobj) }</date>
        <url> { $config:springs-root || '/issues/' || $bmtnid }</url>
       {
         for $constituent in $bmtnobj//tei:relatedItem[@type='constituent']
         return
         if ($include-constituents) 
         then
            app:constituent-struct($constituent, $bmtnid)
         else
            let $constituentid := xs:string($constituent/@xml:id)
            let $uri := $config:springs-root || '/constituent/' || $bmtnid || '/' || $constituentid
            return
            <constituent>
                <uri>{ $uri }</uri>
            </constituent>

       }
     </issue>
};



(:~
 : A common representation of a constituent that can be serialized different ways.
 :
 : The common data model for a constituent used by Blue Mountain Springs. It is serialized
 : in different formats by the RESTXQ functions.
 :
 : @param $bmtnobj a tei:relatedItem element representing a constituent's metadata
 : @param $include-constituents a boolean if true, include all constituents
 : @return an issue element
 :)
declare function app:constituent-struct($constituent as element(), $issueid as xs:string)
as element()
{
    let $issueObject := app:bmtn-object($issueid)
    let $issuelabel := app:formatted-title($issueObject)
    let $constituentid := xs:string($constituent/@xml:id)
    let $title := app:constituent-title($constituent)
    let $qtitle := concat("&quot;", $title,"&quot;")
    let $uri := $config:springs-root || '/constituent/' || $issueid || '/' || $constituentid
    let $contributors := 
        for $stmt in $constituent//tei:respStmt
        let $byline := normalize-space($stmt/tei:persName/text())
        let $byline := concat("&quot;", $byline,"&quot;")
        let $contributorid := if ($stmt/tei:persName/@ref) then xs:string($stmt/tei:persName/@ref) else " "
        return
            <contributor>
                <byline>{ $byline }</byline>
                <contributorid>{ $contributorid }</contributorid>
            </contributor>
    return
        <constituent>
            <issueid>{ $issueid }</issueid>
            <constituentid>{ $constituentid }</constituentid>
            <uri>{ $uri }</uri>
            <title>{ $qtitle }</title>
            { for $c in $contributors return $c }
        </constituent>
};


(:::: Utilities for Contributors ::::)

declare function app:magazine-of($issue as element())
as xs:string
{
    xs:string($issue//tei:relatedItem[@type='host']/@target)
};

declare function app:contributor-data($issue as element())
as xs:string*
{
    let $issueid := app:bmtnid-of($issue)
    let $issuelabel := app:object-title($issue)
    let $issueDate := app:issue-date($issue)
    let $magazine  := app:magazine-of($issue)
    let $contributions := $issue//tei:relatedItem[@type='constituent']
    for $contribution in $contributions
        let $constituentid := xs:string($contribution/@xml:id)
        let $title := app:constituent-title($contribution)
        let $title := replace($title, '"', '""') 
        let $qtitle := concat("&quot;", $title,"&quot;")
        let $respStmts := $contribution//tei:respStmt
        for $stmt in $respStmts
            let $byline := normalize-space($stmt/tei:persName/text())
            let $byline := concat("&quot;", $byline,"&quot;")
            let $contributorid := if ($stmt/tei:persName/@ref) then xs:string($stmt/tei:persName/@ref) else " "
            return
             concat(string-join(($issueid,$issuelabel,$issueDate,$magazine,$contributorid,$byline,$constituentid,$qtitle), ','), $app:lf)
};


declare function app:contributors-to($bmtnid as xs:string)
as xs:string*
{
    let $header := concat(string-join(('bmtnid', 'label', 'issueDate', 'magazine', 'contributorid', 'byline', 'constituentid', 'title'),','), $app:lf)
    let $records :=
        if (app:issuep($bmtnid))
            then app:contributor-data(app:bmtn-object($bmtnid))
        else 
            for $issue in app:issues-of-magazine($bmtnid)
            return app:contributor-data($issue)
    return
         ($header,$records)
};


(:~
 : Returns a valid xs:date from a w3cdtf-formatted string.
 : The input string may simply be a year (e.g., '2015'), in which
 : case the function appends January 1 to it (e.g., 2015-01-01);
 : if it is a YearMonth, then the function returns default first of 
 : the month.
 :
 : The function works by seeing if it can cast the input string as
 : an xs:date type.
 : @param $d a string in w3cdtf format
 :)
declare function app:w3cdtf-to-xsdate($d as xs:string) as xs:date
{
  let $dstring :=
  if ($d castable as xs:gYear) then $d || "-01-01"
  else if ($d castable as xs:gYearMonth) then $d || "-01"
  else if ($d castable as xs:date) then $d
  else error($d, "not valid w3cdtf")
  return xs:date($dstring)
};
