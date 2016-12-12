xquery version "3.0";
(:~
 : Module Name: springs.xqm
 :
 : @author Clifford Wulfman
 :
 : @version 1.1.0
 : 
 : This module provides the resource functions supporting the Blue Mountain Springs
 : API. They conform with the RESTXQ 1.0 specification for writing RESTful services in XQuery.
 :
 : The Blue Mountain Springs API is implemented as a suite of
 : XQuery Resource Functions as defined by the RESTXQ specification.
 : That specification uses XQuery 3.0 annotations to associate
 : xquery functions with HTTP interactions.
 :
 : When enabled in eXist-db, RESTXQ establishes a registry of 
 : resource functions in the database and routes HTTP requests to
 : the matching functions. RESTXQ enables content negotiation by
 : supporting annotations that specify what content type a function
 : produces. Different functions can be written to handle different
 : content specifications.
 :
 : @see http://www.exquery.org/
 : @see http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html
 :)
module namespace springs = "http://bluemountain.princeton.edu/apps/springs";

import module namespace config="http://bluemountain.princeton.edu/apps/springs/config" at "config.xqm";
import module namespace app="http://bluemountain.princeton.edu/apps/springs/app" at "app.xql";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace response = "http://exist-db.org/xquery/response";
import module namespace rest = "http://exquery.org/ns/restxq" ;

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http = "http://expath.org/ns/http-client"; 
declare namespace tei="http://www.tei-c.org/ns/1.0";

(:~
 : /springs
 :
 : The top level of the service; it returns an XML
 : document detailing the API.
 :
 :)
 
declare
 %rest:GET
 %output:method("html5")
 %rest:path("/springs")
function springs:redirect-to-spec() {
    (
    <rest:response>
        <http:response status="200"/>
    </rest:response>,
    <html>
        <head><title>Blue Mountain Springs</title></head>
    <body>
        <h1>Blue Mountain Springs API</h1>
        <p>See <a href="https://github.com/Princeton-CDH/bluemountainsprings/blob/master/doc/api-doc.org">Specification</a>
        for more information.</p>
    </body>
    </html>
    )
};


(:~
 : The magazines/ service.
 :
 : Specification Section 3.1.1
 :
 : Blue Mountain contains magazines. The magazines/
 : service returns representations of those magazines.
 :
 : If no resource is specified, the service returns a
 : representation of all the magazines in Blue Mountain.
 :
 : If a resource is specified (as a bmtnid), the service
 : returns a representation of the corresponding magazine.
 :
 : Blue Mountain Springs supports cross-origin resource sharing
 : (CORS) by specifying Access-Control-Allow-Origin: * in the
 : response header.
 :
 : The HTTP response header is only basic in Springs 1.0.
 :)

(:~
 : magazines/ as JSON
 :
 : Specification section 3.1.1.2
 :
 : Queries the database for magazines and generates
 : a magazine-struct for each. It uses eXist's built-in
 : JSON serializer to convert the magazine-struct XML
 : into JSON.
 : 
 : @return a result sequence (rest:response, magazines)
 :)
declare
 %rest:GET
 %rest:path("/springs/magazines")
 %output:method("json")
 %rest:produces("application/json")
function springs:magazines-as-json() 
as item()+ 
{
    let $response :=
      <magazines> {
        for $mag in app:magazines()
        return app:magazine-struct($mag, false())
    } </magazines>
    return 
         (<rest:response>
            <http:response>
              <http:response status="{ if (empty($response)) then 204 else 200 }"/>
              <http:header name="Content-Type" value="application/json"/>
              <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
          </rest:response>,
         $response)
};


(:~
 : magazines/ as text/CSV
 :
 : Specification Section 3.1.1.1
 :
 : Queries the database for magazines and generates
 : a magazine-struct for each. It assembles a return
 : value by converting each magazine-struct into a
 : comma-separated string.
 :
 : @return a result sequence (<rest:response/>, text)
 :)
declare
 %rest:GET
 %rest:path("/springs/magazines")
 %output:method("text")
 %rest:produces("text/csv")
function springs:magazines-as-csv()
as item()+
{
    let $response :=
      for $mag in app:magazines()
      let $struct := app:magazine-struct($mag, false())
      return concat(string-join(($struct/bmtnid,
                                 $struct/primaryTitle,
                                 $struct/primaryLanguage,
                                 $struct/startDate,
                                 $struct/endDate,
                                 $struct/uri), ','), $app:lf)
    return
        (<rest:response>
           <http:response status="{ if (empty($response)) then 204 else 200 }">
             <http:header name="Content-Type" value="text/csv"/>
             <http:header name="Access-Control-Allow-Origin" value="*"/>
           </http:response>
         </rest:response>,
         $response)
};




(:~
 : magazines/$bmtnid
 :
 : Specification Section 3.1.2
 :
 : When the Blue Mountain ID of a magzine is supplied
 : as a resource to the magazines/ service, it returns a
 : representation of that magazine.
 :
 : In Blue Mountain Springs 1.0, the only representation
 : available is a JSON expression of the magazine-struct.
 :
 : @param $bmtnid a Blue Mountain ID of a magazine
 : @return a sequence (rest:response, json)
 :)
declare
  %rest:GET
  %rest:path("/springs/magazines/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:magazine-as-json($bmtnid as xs:string) 
as item()+
{
    if (app:bmtnidp($bmtnid)) then
        let $response := app:magazine-struct(app:bmtn-object($bmtnid), true())
        let $status := if (empty($response)) then 204 else 200
        return 
         (<rest:response>   
            <http:response status="{$status}">
              <http:header name="Content-Type" value="application/json"/>
              <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
          </rest:response>,
         $response)
     else
        <rest:response>
            <http:response status="400"/>
        </rest:response>
};  
  


(:~
 : The issues/ service.
 :
 : Specification Section 3.2
 :
 : The issues/ service returns representations of magazine issues.
 : The service behaves differently depending on the kind of
 : resource that is requested:
 : <ol>
 : <li>if the resource is an issue, the service returns a representation
 :     of the issue.</li>
 :<li>if the resource is a magazine, the service returns representations
 :    of all the issues of that magazine.</li>
 :</ol>
 :)

(:~
 : issues/$bmtnid as TEI
 :
 : Specification 3.2.1.2, 3.2.2.2
 :
 : If the requested resource is an issue,
 : return the tei:TEI document in the database.
 :
 : If the requested resource is a magazine,
 : return a teiCorpus object containing
 : the TEI documents for all the magazine's
 : issues.
 :
 : For large magazine runs, this service will 
 : return a very large data set in Blue Mountain 1.0.
 : A future version will use status 413 to indicate
 : an excessively large response and compress the response
 : before transmission or implement status 207 to coordinate
 : partial file tranfers.
 :
 : @param $bmtnid an id of a magazine or an issue
 : @return a sequence (rest:response, xml)
 :)
declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %rest:produces("application/tei+xml")
function springs:issue-as-tei($bmtnid as xs:string)
as item()+
{
   if (app:bmtnidp($bmtnid)) then
    let $response :=
       if (app:issuep($bmtnid)) then
            app:bmtn-object($bmtnid)
        else
       <teiCorpus xmlns="http://www.tei-c.org/ns/1.0">
         <teiHeader>
             <fileDesc>
                 <titleStmt>
                     <title>{ app:object-title(app:bmtn-object($bmtnid)) }</title>
                </titleStmt>
	           <publicationStmt>
	               <p>Publication Information</p>
	            </publicationStmt>
	           <sourceDesc>
	               <p>Information about the source</p>
	            </sourceDesc>
           </fileDesc>
         </teiHeader>
          { app:issues-of-magazine($bmtnid) }
       </teiCorpus>
     return
         (<rest:response>
            <http:response>
              <http:header name="Content-Type" value="application/tei+xml"/>
              <http:header name="Access-Control-Allow-Origin" value="*"/>
            </http:response>
          </rest:response>,
         $response)
    else
        <rest:response>
            <http:response status="400"/>
        </rest:response>
};


(:~
 : issues/$bmtnid as plain text
 :
 : Specification Section 3.2.1.3, 3.2.2.3
 :
 : If the requested resource is an issue,
 : the service retrieves the issue tei:TEI 
 : document from the database and converts it
 : to plain text using a simple xslt transformation.
 :
 : If the requested resource is a magazine,
 : the service iterates over all the issues in the
 : magazine and returns a single bag of words representing
 : the text of the entire run.
 :
 : For large magazine runs, this service will 
 : return a very large data set in Blue Mountain 1.0.
 : A future version will use status 413 to indicate
 : an excessively large response and compress the response
 : before transmission or implement status 207 to coordinate
 : partial file tranfers.
 :
 : @param $bmtnid an id of a magazine or issue
 : @return a sequence (rest:response, text)
 :)
declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %output:method("text")
  %rest:produces("text/plain")
function springs:issue-as-plaintext($bmtnid as xs:string) 
as item()+
{
   if (app:bmtnidp($bmtnid)) then
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    let $responseBody :=
        if (app:issuep($bmtnid)) then
            transform:transform( app:bmtn-object($bmtnid), $xsl, () )
        else
            for $issue in app:issues-of-magazine($bmtnid)
            return transform:transform($issue, $xsl, ())
    return
        (<rest:response>
          <http:response>
            <http:header name="Content-Type" value="text/plain"/>
            <http:header name="Access-Control-Allow-Origin" value="*"/>
          </http:response>
         </rest:response>,
         $responseBody)
   else
        <rest:response>
         <http:response status="400"/>
        </rest:response> 
};



(:~
 : issues/$bmtnid as JSON
 :
 : Specification Sections 3.2.1.1, 3.2.2.1
 :
 : If the requested resource is an issue,
 : the service retrieves the issue tei:TEI 
 : document from the database and converts it
 : to JSON using an xslt transformation.
 :
 : If the requested resource is a magazine,
 : the service iterates over all the issues in the
 : magazine and returns a single structure representing
 : the text of the entire run.
 :
 : For large magazine runs, this service will 
 : return a very large data set in Blue Mountain 1.0.
 : A future version will use status 413 to indicate
 : an excessively large response and compress the response
 : before transmission or implement status 207 to coordinate
 : partial file tranfers.
 :
 : @param $bmtnid an id of a magazine or issue
 : @return a sequence (rest:response, text)
 :)
declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:issue-as-json($bmtnid as xs:string) 
as item()+
{
  if (app:bmtnidp($bmtnid)) then
    let $xsl := doc($config:app-root || "/resources/xsl/tei2data.xsl")
    let $xslt-parameters := 
      <parameters>
          <param name="springs-root" value="{$config:springs-root}"/>
      </parameters>
    let $responseBody :=
        if (app:issuep($bmtnid)) then
            transform:transform( app:bmtn-object($bmtnid), $xsl, $xslt-parameters )
        else
            app:magazine-struct(app:bmtn-object($bmtnid), true())
            
    return 
             (<rest:response>
               <http:response>
                <http:header name="Content-Type" value="application/json"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
               </http:response>
              </rest:response>,
              $responseBody)
   else
        <rest:response>
         <http:response status="400"/>
        </rest:response> 
};


(:~
 : issues/$bmtnid as RDF
 :
 : Specification Section 3.2.1.4
 :
 : In Blue Mountain version 1.0, this
 : service is aimed primarily at the
 : MODNETS aggregator, and it provides
 : an RDF representation that complies
 : with its requirements: COLLEX-flavored
 : RDF.
 :
 : @see http://www.modnets.org/
 : @see http://wiki.collex.org/index.php/Submitting_RDF
 :
 : If the requested resource is an issue,
 : the service retrieves the issue tei:TEI 
 : document from the database and converts it
 : to RDF using an xslt transformation.
 :
 : If the requested resource is a magazine,
 : the service iterates over all the issues in the
 : magazine and returns a single structure representing
 : the text of the entire run.
 :
 : @param $bmtnid an id of a magazine or issue
 : @return a sequence (rest:response, RDF+XML)
 :)
declare
  %rest:GET
  %rest:path("/springs/issues/{$bmtnid}")
  %rest:produces("application/rdf+xml")
function springs:issue-as-rdf($bmtnid as xs:string)
as item()+
{
  if (app:bmtnidp($bmtnid)) then
    let $issue := app:bmtn-object($bmtnid)
    let $xsl := doc($config:app-root || "/resources/xsl/bmtn2rdf.xsl")
    let $responseBody := transform:transform($issue, $xsl, ())
    return 
             (<rest:response>
               <http:response>
                <http:header name="Content-Type" value="application/rdf+xml"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
               </http:response>
              </rest:response>,
              $responseBody)
   else
        <rest:response>
         <http:response status="400"/>
        </rest:response> 
};



(:~
 :  constituents/ service
 :
 : Specification 3.3
 :
 : The addressable portions of the magazine issues --
 : articles, illustrations, advertisements -- are the
 : issue's constituents. They are represented in two ways:
 :<ol>
 :<li>descriptive metadata about the constituent is encoded
 :    in the teiHeader as a relatedItem with an xml id attribute; 
 :</li>
 :<li>the full text of the constituent (if it is a textual
 :    constituent) is encoded in a div element linked to
 :    the metadata element with a corresp attribute.
 :</li>
 :</ol>
 :
 : The constituents service returns representations of the metadata
 : or the full text, depending on the content type requested.
 :)


(:~
 : constituents/$bmtnid as JSON
 :
 : Specification 3.3.1, 3.3.2
 :
 : If the specified resource is an issue,
 : the service retrieves the metadata for the
 : issue's constituents and extracts data fields.
 : If the specified resource is a magazine, 
 : extract constituents from all issues of the run.
 :
 : @param $bmtnid a magazine or issue id
 : @return a sequence (rest:response, XML)
 :)
declare
  %rest:GET
  %rest:path("/springs/constituents/{$bmtnid}")
  %output:method("json")
  %rest:produces("application/json")
function springs:constituents-as-json($bmtnid as xs:string)
as item()+
{
  if (app:bmtnidp($bmtnid)) then
    let $responseBody :=
      if (app:issuep($bmtnid))
        then app:issue-struct(app:bmtn-object($bmtnid), true())
       else
         <issues>
            { for $issue in app:issues-of-magazine($bmtnid)
              return app:issue-struct($issue, false())
            }
         </issues>
    return
       (<rest:response>
          <http:response>
           <http:header name="Content-Type" value="application/rdf+xml"/>
           <http:header name="Access-Control-Allow-Origin" value="*"/>
          </http:response>
         </rest:response>,
         $responseBody)
   else
        <rest:response>
         <http:response status="400"/>
        </rest:response> 
};


(:~
 : constituent/$issueid/$constid as plain text
 :
 : Specification 3.4
 :
 : Return a plain-text representation of a constituent of
 : an issue by retrieving it from the database and transforming
 : it into plain text with an XSL stylesheet.
 :
 : @param $issueid the bmtnid of an issue
 : @param $constid the id of a constituent
 : @returns a sequence (rest:response, text)
 :)
declare
  %rest:GET
  %rest:path("/springs/constituent/{$issueid}/{$constid}")
  %rest:produces("text/plain")
function springs:constituent-plaintext($issueid as xs:string, $constid as xs:string)
as item()+
{
  if (app:bmtnidp($issueid)) then
    let $constituent := app:constituent($issueid, $constid)
    let $xsl := doc($config:app-root || "/resources/xsl/tei2txt.xsl")
    let $responseBody := transform:transform($constituent, $xsl, ())
    return 
    (<rest:response>
       <http:response status="{ if (empty($responseBody)) then 204 else 200 }">
          <http:header name="Content-Type" value="text/plain"/>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
       </http:response>
      </rest:response>,
      $responseBody)
   else
        <rest:response>
         <http:response status="400"/>
        </rest:response> 
};


(:~
 : constituent/$issueid/$constid as TEI
 :
 : Specification 3.4
 :
 : Return the TEI-encoded representation of a constituent of
 : an issue by retrieving it from the database. Returns a div
 : element not an entire document.
 :
 : @param $issueid the bmtnid of an issue
 : @param $constid the id of a constituent
 : @returns a sequence (rest:response, text)
 :)
declare
  %rest:GET
  %rest:path("/springs/constituent/{$issueid}/{$constid}")
  %rest:produces("application/tei+xml")
function springs:constituent-tei($issueid as xs:string, $constid as xs:string)
as item()+
{
  if (app:bmtnidp($issueid)) then 
    let $response := app:constituent($issueid, $constid)
    return
    (<rest:response>
       <http:response status="{if (empty($response)) then 204 else 200 }">
          <http:header name="Content-Type" value="application/tei+xml"/>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
       </http:response>
      </rest:response>,
     $response)
   else
        <rest:response>
         <http:response status="400"/>
        </rest:response>
};



(:~ Contributors/ service
 :
 : Specification 3.5
 :
 :)

(:~
 : contributors/$bmtnid as CSV
 :
 : Specification 3.5.1.1
 :
 : Returns a representation of all the contributors to a
 : Blue Mountain object. If the object is an issue, it
 : returns all the contributors to the issue; if a magazine,
 : all the contributors to the entire magazine.
 :
 : @param $bmtnid the id of a Blue Mountain object
 : @returns a CSV file with the following fields
 : bmtnid,label,contributorid,byline,constituentid,title
 : embedded in a sequence (response, text)
 :)
declare
 %rest: GET
 %rest:path("/springs/contributors/{$bmtnid}")
 %output:method("text")
 %rest:produces("text/csv")
function springs:contributors-csv($bmtnid as xs:string)
as item()+
{
  if (app:bmtnidp($bmtnid)) then
    (<rest:response>
       <http:response>
          <http:header name="Content-Type" value="text/csv"/>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
       </http:response>
      </rest:response>,
      app:contributors-to($bmtnid))
   else
        <rest:response>
         <http:response status="400"/>
        </rest:response>
};


(:~
 : contributors/$bmtnid as JSON
 :
 : Specification 3.5.1.2
 :
 :)
declare 
 %rest: GET
 %rest:path("/springs/contributors/{$issueid}")
 %output:method("json")
 %rest:produces("application/json")
function springs:contributors-from-issue($issueid as xs:string)
as item()+
{
  if (app:bmtnidp($issueid)) then
    let $issue := app:bmtn-object($issueid)
    let $bylines := $issue//tei:relatedItem[@type='constituent']//tei:respStmt[tei:resp = 'cre']/tei:persName
    let $issue-label := app:object-title($issue)
    let $responseBody := 
        <contributors> {
          for $byline in $bylines
          let $contributorid := 
            if ($byline/@ref)
                then xs:string($byline/@ref)
            else ()
          let $constituent := $byline/ancestor::tei:relatedItem[@type='constituent'][1]
          let $constituentid := xs:string($constituent/@xml:id)
          let $title := if ($constituent) then app:constituent-title($constituent) else "Untitled"
          return
            <contributor>
                <bmtnid>{ $issueid }</bmtnid>
                <label>{ $issue-label }</label>
                <contributorid>{ $contributorid }</contributorid>
                <byline>{ xs:string($byline) }</byline>
                <contributionid>{ $constituentid }</contributionid>
                <title> { $title }</title>
            </contributor>
        }</contributors>
  
    return
    (<rest:response>
       <http:response>
          <http:header name="Content-Type" value="application/json"/>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
       </http:response>
      </rest:response>,
      $responseBody)
   else
        <rest:response>
         <http:response status="400"/>
        </rest:response>    
};



(:~
 : contributions?byline=$byline as JSON
 :
 : Specification 3.6.1.1
 :
 : Returns metadata about all constituents in the corpus
 : with byline $byline.
 :
 :)
declare
 %rest:GET
 %rest:path("/springs/contributions")
 %rest:query-param("byline", "{$byline}", "")
 %output:method("json")
 %rest:produces("application/json")
function springs:constituents-with-byline-json($byline as xs:string*)
as item()*
{
    let $responseBody :=
    if ($byline) then
    <contributions> {
    for $constituent in collection($config:transcriptions)//tei:relatedItem[ft:query(.//tei:persName, $byline)]
    let $title := app:constituent-title($constituent)
    let $bylines := $constituent/tei:biblStruct/tei:analytic/tei:respStmt/tei:persName
    let $languages := $constituent/tei:biblStruct/tei:analytic/tei:textLang
    let $issueid := app:bmtnid-of($constituent/ancestor::tei:TEI)
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
     else ()
     
     return
    (<rest:response>
       <http:response status="{if (empty($responseBody)) then 204 else 200 }">
          <http:header name="Content-Type" value="application/json"/>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
       </http:response>
      </rest:response>,
      $responseBody)
};

(:~
 : contributions?byline=$byline as TEI
 :
 : Specification 3.6.1.2
 :
 : Returns xml-encoded text of all constituents in the corpus
 : with byline $byline.
 :
 :)
declare
 %rest:GET
 %rest:path("/springs/contributions")
 %rest:query-param("byline", "{$byline}", "stranger")
 %rest:produces("application/tei+xml")
function springs:constituents-with-byline($byline)
as element()*
{
    let $constituents := 
        if ($byline) then
            collection($config:transcriptions)//tei:relatedItem[ft:query(.//tei:persName, $byline)]
        else ()
    
    let $responseBody :=
    if ($constituents) then
    <teiCorpus xmlns="http://www.tei-c.org/ns/1.0">
     <teiHeader>
         <fileDesc>
             <titleStmt>
                 <title>Blue Mountain Contributions</title>
                 <author>{ $byline }</author>
             </titleStmt>
	        <publicationStmt>
	           <p>Blue Mountain Project</p>
	        </publicationStmt>
	        <sourceDesc>
	           <biblStruct>
	           {
	               for $constituent in $constituents
	               return
	                   <relatedItem type='constituent'>
	                   { $constituent/tei:biblStruct }
	                   </relatedItem>
	           }
	           </biblStruct>
	        </sourceDesc>
         </fileDesc>
     </teiHeader> {
    for $constituent in $constituents
    let $biblStruct := $constituent/tei:biblStruct
    let $issueid := $constituent/ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid']
    let $constid := xs:string($constituent/@xml:id)
    return
     <TEI xml:id="{$issueid ||'_'||$constid}">
        <teiHeader>
            <fileDesc>
            <titleStmt>
                <title>{ $biblStruct }</title>
            </titleStmt>
            <publicationStmt>
                <p>
                <ref target="{ $config:springs-root || '/constituent/' || $issueid || '/' || $constid }"/>
                </p>
            </publicationStmt>
            <seriesStmt>
                <p>Blue Mountain Project</p>
            </seriesStmt>
            <sourceDesc>{ $biblStruct }</sourceDesc>
            </fileDesc>
        </teiHeader>
        <text>
          <body>
          { $constituent/ancestor::tei:TEI//tei:div[@corresp=$constid] }
          </body>
        </text>
     </TEI>
     } </teiCorpus>
     else ()
     return
    (<rest:response>
       <http:response status="{if (empty($responseBody)) then 204 else 200 }">
          <http:header name="Content-Type" value="application/tei+xml"/>
          <http:header name="Access-Control-Allow-Origin" value="*"/>
       </http:response>
      </rest:response>,
      $responseBody)     
};
