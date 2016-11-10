<?xml version="1.0" encoding="UTF-8"?>
<!-- 
A set of XSL templates for transforming the METS records produced by
the Blue Mountain Project into RDF suitable for ingestion into 
ModNets.

REFERENCES: http://wiki.collex.org/index.php/Submitting_RDF
--><!-- This stylesheet uses the "pull" method of XSL processing,
because the purpose is to create a conformant Collex document, not to
account for all elements in the bmtn MODS record. -->
<xsl:stylesheet xmlns:collex="http://www.collex.org/schema#" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:role="http://www.loc.gov/loc.terms/relators/" xmlns:mets="http://www.loc.gov/METS/" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:bmtn="http://bluemountain.princeton.edu" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0" exclude-result-prefixes="xs mods">
    <xsl:output indent="yes"/><!-- GLOBAL DECLARATIONS -->
    <xsl:variable name="springs-server" as="xs:string">http://bluemountain.princeton.edu/exist/restxq/springs</xsl:variable><!-- Collex REQUIRES "a shorthand reference to the contributing project or journal."  -->
    <xsl:variable name="bmtn-server" as="xs:anyURI">http://bluemountain.princeton.edu/exist/apps/bluemountain</xsl:variable>
    <xsl:variable name="project-id" as="xs:string">bmtn</xsl:variable><!-- Collex REQUIRES one or more federation ids. An authorized string for ModNets would be nice
       but this will do for now. -->
    <xsl:variable name="federation-id" as="xs:string">ModNets</xsl:variable><!-- Collex REQUIRES one or more disciplines.  These are not terribly well defined; for
       now, Literature seems to be the only one universally applicable to Blue Mountain materials. -->
    <xsl:variable name="disciplines">
        <disciplines>
            <discipline>Literature</discipline>
        </disciplines>
    </xsl:variable>
    <xsl:variable name="objid" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid']" as="xs:string"/>
    <xsl:variable name="magid" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:relatedItem[@type='host']/@target"/>
    <xsl:variable name="pubDate" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr/tei:imprint/tei:date/@when"/><!--  TEMPLATES -->
    <xsl:template match="/"><!-- The top-level RDF element is REQUIRED. -->
        <rdf:RDF>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template><!--  Periodical Issues   -->
    <xsl:template match="tei:TEI">
        <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc"/>
    </xsl:template>
    <xsl:template match="tei:sourceDesc">
        <bmtn:Description rdf:about="{$springs-server}/issues/{$objid}">
            <collex:federation>
                <xsl:value-of select="$federation-id"/>
            </collex:federation>
            <collex:archive>
                <xsl:value-of select="string-join(($project-id, $magid), '_')"/>
            </collex:archive>
            <dc:title>
                <xsl:apply-templates select="tei:biblStruct/tei:monogr/tei:title"/>
            </dc:title>
            <dc:type>Collection</dc:type>
            <dc:type>Periodical</dc:type>
            <xsl:for-each select="tei:biblStruct/tei:monogr/tei:respStmt[tei:resp='edt']">
                <role:EDT>
                    <xsl:value-of select="tei:persName"/>
                </role:EDT>
            </xsl:for-each>
            <collex:discipline>Literature</collex:discipline>
            <collex:genre>Collection</collex:genre>
            <dc:date>
                <xsl:value-of select="$pubDate"/>
            </dc:date>
            <rdfs:seeAlso rdf:resource="{$bmtn-server}/issue.html?issueid={$objid}"/>
            <collex:text rdf:resource="{$springs-server}/text/{$objid}"/><!-- Need uri to the tei -->
            <xsl:for-each select="tei:biblStruct/tei:relatedItem[@type='constituent']">
                <dcterms:hasPart rdf:resource="{$springs-server}/constituent/{$objid}/{@xml:id}"/>
            </xsl:for-each>
        </bmtn:Description>
        <xsl:apply-templates select="tei:biblStruct/tei:relatedItem[@type='constituent']"/>
    </xsl:template>
    <xsl:template match="tei:relatedItem[@type='constituent']">
        <bmtn:Description rdf:about="{$springs-server}/constituent/{$objid}/{@xml:id}">
            <dcterms:isPartOf rdf:resource="{$springs-server}/issues/{$objid}"/>
            <collex:federation>
                <xsl:value-of select="$federation-id"/>
            </collex:federation>
            <collex:archive>
                <xsl:value-of select="string-join(($project-id, $magid), '_')"/>
            </collex:archive>
            <dc:title>
                <xsl:apply-templates select="tei:biblStruct/tei:analytic/tei:title[@level='a']"/>
            </dc:title>
            <dc:type>Periodical</dc:type>
            <xsl:choose>
                <xsl:when test="tei:biblStruct/tei:analytic/tei:respStmt[tei:resp='cre']">
                    <xsl:for-each select="tei:biblStruct/tei:analytic/tei:respStmt[tei:resp='cre']">
                        <role:CRE>
                            <xsl:apply-templates select="current()/tei:persName"/>
                        </role:CRE>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <role:AUT>Unknown</role:AUT>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="tei:biblStruct/tei:monogr/tei:imprint/tei:classCode" mode="genre"/>
            <xsl:for-each select="$disciplines/disciplines/discipline">
                <collex:discipline>
                    <xsl:value-of select="current()"/>
                </collex:discipline>
            </xsl:for-each>
            <xsl:apply-templates select="tei:biblStruct/tei:monogr/tei:imprint/tei:classCode"/>
            <dc:date>
                <xsl:value-of select="$pubDate"/>
            </dc:date>
            <rdfs:seeAlso rdf:resource="{$bmtn-server}/issue.html?issueid={$objid}"/>
            <collex:text rdf:resource="{$springs-server}/constituent/{$objid}/{@xml:id}"/>
        </bmtn:Description>
    </xsl:template>
    <xsl:template match="tei:title">
        <xsl:apply-templates select="tei:seg[@type='main']"/>
    </xsl:template>
    <xsl:template match="tei:classCode" mode="genre">
        <collex:genre>
            <xsl:choose>
                <xsl:when test="./text() = 'Periodicals-Issue'">
                    <xsl:text>Collection</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'SponsoredAdvertisement'">
                    <xsl:text>Ephemera</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'Music'">
                    <xsl:text>Musical Score</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'Illustration'">
                    <xsl:text>Visual Art</xsl:text>
                </xsl:when><!-- docWorks categorizes all text as TextContent, so
		       we have no finer-grained genre for texts. As
		       ARC Collex has no generic text category, we must
		       declare all texts to be Unspecified. -->
                <xsl:when test="./text() = 'TextContent'">
                    <xsl:text>Unspecified</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Unspecified</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </collex:genre>
    </xsl:template>
    <xsl:template match="tei:classCode[@scheme='CCS']">
        <collex:genre>
            <xsl:choose>
                <xsl:when test="./text() = 'Periodicals-Issue'">
                    <xsl:text>Collection</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'SponsoredAdvertisement'">
                    <xsl:text>Ephemera</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'Music'">
                    <xsl:text>Musical Score</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'Illustration'">
                    <xsl:text>Visual Art</xsl:text>
                </xsl:when><!-- docWorks categorizes all text as TextContent, so
		       we have no finer-grained genre for texts. As
		       ARC Collex has no generic text category, we must
		       declare all texts to be Unspecified. -->
                <xsl:when test="./text() = 'TextContent'">
                    <xsl:text>Unspecified</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Unspecified</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </collex:genre>
    </xsl:template>
    <xsl:template match="mets:mets[@TYPE='Magazine']"><!-- An element with an rdf:about element is REQUIRED.  
         The spec says it should be an arbitrary element in the
         project's namespace.  -->
        <xsl:variable name="objid" select="@OBJID"/>
        <bmtn:Description rdf:about="{bmtn:clean-id($objid)}">
            <xsl:apply-templates select="//mods:mods">
                <xsl:with-param name="objid" select="bmtn:clean-id($objid)"/>
            </xsl:apply-templates>
        </bmtn:Description><!-- Generate an RDF object for each issue constituent.	-->
        <xsl:for-each select="//mods:mods/mods:relatedItem[@type='constituent']">
            <bmtn:Description rdf:about="{bmtn:clean-id($objid)}#{@ID}">
                <dcterms:isPartOf rdf:resource="{bmtn:clean-id($objid)}"/>
                <xsl:apply-templates select=".">
                    <xsl:with-param name="objid" select="$objid"/>
                </xsl:apply-templates>
            </bmtn:Description>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="mods:mods">
        <xsl:param name="objid"/>
        <xsl:variable name="issueid">
            <xsl:value-of select="substring-after(bmtn:clean-id($objid), 'http://bluemountain.princeton.edu/')"/>
        </xsl:variable><!-- One or more <collex:federation> elements are REQUIRED. -->
        <collex:federation>
            <xsl:value-of select="$federation-id"/>
        </collex:federation><!-- A SINGLE <collex:archive> element is REQUIRED. -->
        <collex:archive><!-- <xsl:value-of select="$project-id"/> -->
            <xsl:value-of select="bmtn:archive-name(./mods:relatedItem[@type='host']/@xlink:href)"/><!-- <xsl:value-of select="xs:string(./mods:relatedItem[@type='host']/@xlink:href)"/> -->
        </collex:archive><!-- A SINGLE <dc:title> element is REQUIRED. --><!--Some issues may have more than one title element; use the
	first one. -->
        <dc:title>
            <xsl:apply-templates select="mods:titleInfo[1]"/>
        </dc:title><!-- ONE OR MORE <dc:type> elements are REQUIRED. We determine
         the dc:type from the mods:genre; NB that the mods:genre
         element is also used to determine the collex:genre. -->
        <dc:type>Collection</dc:type>
        <dc:type>
            <xsl:apply-templates select="mods:genre[1]"/>
        </dc:type><!-- ONE OR MORE <role:*> elements are REQUIRED. -->
        <xsl:choose>
            <xsl:when test="mods:name">
                <xsl:apply-templates select="mods:name"/>
            </xsl:when>
            <xsl:otherwise>
                <role:AUT>Unknown</role:AUT>
            </xsl:otherwise>
        </xsl:choose><!-- One or more <collex:discipline> elements are REQUIRED. -->
        <xsl:for-each select="$disciplines/disciplines/discipline">
            <collex:discipline>
                <xsl:value-of select="current()"/>
            </collex:discipline>
        </xsl:for-each><!-- ONE OR MORE <collex:genre> elements are REQUIRED. -->
        <xsl:apply-templates select="mods:genre" mode="collex-genre"/><!-- ONE OR MORE <dc:date> elements are REQUIRED. -->
        <dc:date>
            <xsl:value-of select="mods:originInfo/mods:dateIssued[@keyDate='yes']"/>
        </dc:date><!-- ONE <rdfs:seeAlso> element with the URL of the resource is REQUIRED. 
	 We write a function, bmtn:object-URL(), that returns this URL. -->
        <rdfs:seeAlso>
            <xsl:attribute name="rdf:resource" select="bmtn:object-URL(mods:identifier[@type='bmtn'])"/>
        </rdfs:seeAlso><!-- END OF REQUIRED ELEMENTS --><!-- Generate a <collex:source_xml> element that points to the TEI
              file associated with this object. Blue Mountain will (soon)
              have a uri for this; meanwhile, bmtn:tei-URL(modsid) is a
              stub function.
	 -->
        <collex:source_xml rdf:resource="{bmtn:tei-URL($issueid)}"/><!-- MODS constituents are represented as explicit resources (objects).
              In the parent (issue) object, their relationship with the parent object
              is represented with <dcterms:hasPart> elements. -->
        <xsl:for-each select="mods:relatedItem[@type='constituent']">
            <dcterms:hasPart rdf:resource="{bmtn:clean-id($objid)}#{@ID}"/>
        </xsl:for-each>
    </xsl:template><!-- This template converts a mods:titleInfo element into a formatted string.
	    The complete format is the following: NonSort Title: Subtitle (Part) -->
    <xsl:template match="mods:titleInfo">
        <xsl:variable name="nonSort">
            <xsl:choose>
                <xsl:when test="mods:nonSort">
                    <xsl:value-of select="concat(mods:nonSort/text(), ' ')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="title">
            <xsl:value-of select="mods:title[1]/text()"/>
        </xsl:variable>
        <xsl:variable name="subTitle">
            <xsl:choose>
                <xsl:when test="mods:subTitle">
                    <xsl:value-of select="concat(': ', mods:subTitle[1]/text())"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="part">
            <xsl:choose>
                <xsl:when test="mods:partNumber">
                    <xsl:value-of select="concat(' (',mods:partNumber[1]/text(),')')"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="concat($nonSort,$title,$subTitle,$part)"/>
    </xsl:template>
    <xsl:template match="mods:genre[@authority='aat' or @authority='marcgt']"><!-- <dc:type> is poorly implemented in Collex.
              For purposes of ingestion into Collex, we identify
              magazine issues as Collections and the contents of
	      issues as Periodical. -->
        <xsl:choose>
            <xsl:when test="./text() = 'periodicals'">
                <xsl:text>Collection</xsl:text>
            </xsl:when>
            <xsl:otherwise>Periodical</xsl:otherwise>
        </xsl:choose>
    </xsl:template><!-- We need a default for the genre of *all* constituent content;
		 the only reasonable value is Periodical. -->
    <xsl:template match="mods:genre">
        <xsl:choose>
            <xsl:when test="./text() = 'advertisement'">
                <xsl:text>Periodical</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Periodical</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mods:genre" mode="collex-genre">
        <collex:genre>
            <xsl:choose>
                <xsl:when test="./text() = 'Periodicals-Issue'">
                    <xsl:text>Collection</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'SponsoredAdvertisement'">
                    <xsl:text>Ephemera</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'Music'">
                    <xsl:text>Musical Score</xsl:text>
                </xsl:when>
                <xsl:when test="./text() = 'Illustration'">
                    <xsl:text>Visual Art</xsl:text>
                </xsl:when><!-- docWorks categorizes all text as TextContent, so
		       we have no finer-grained genre for texts. As
		       ARC Collex has no generic text category, we must
		       declare all texts to be Unspecified. -->
                <xsl:when test="./text() = 'TextContent'">
                    <xsl:text>Unspecified</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Unspecified</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </collex:genre>
    </xsl:template>
    <xsl:template match="mods:name"><!-- ARC has a fixed set of elements to denote roles. --><!-- Blue Mountain captures all bylines as mods:displayForm, so
		   we use that here as the value for name. -->
        <xsl:variable name="name" select="mods:displayForm/text()"/>
        <xsl:if test="$name">
            <xsl:variable name="roleTerm" select="mods:role/mods:roleTerm/text()"/>
            <xsl:choose>
                <xsl:when test="$roleTerm = 'edt'">
                    <role:EDT>
                        <xsl:value-of select="$name"/>
                    </role:EDT>
                </xsl:when>
                <xsl:when test="$roleTerm = 'cre'">
                    <role:CRE>
                        <xsl:value-of select="$name"/>
                    </role:CRE>
                </xsl:when>
                <xsl:when test="$roleTerm = 'trl'">
                    <role:TRL>
                        <xsl:value-of select="$name"/>
                    </role:TRL>
                </xsl:when>
                <xsl:otherwise><!-- Default to "contributor" update (7/23/15): Collex doesn't support CTB, so reverting to CRE -->
                    <role:CRE>
                        <xsl:value-of select="$name"/>
                    </role:CRE>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    <xsl:function name="bmtn:object-URL">
        <xsl:param name="objid" as="xs:string"/>
        <xsl:value-of select="concat('http://bluemountain.princeton.edu/issue.html?issueURN=',$objid)"/>
    </xsl:function>
    <xsl:function name="bmtn:tei-URL">
        <xsl:param name="modsid" as="xs:string"/>
        <xsl:value-of select="concat('http://bluemountain.princeton.edu/issues/', $modsid, '.tei')"/><!-- later -->
    </xsl:function>
    <xsl:function name="bmtn:archive-name">
        <xsl:param name="objid" as="xs:string"/>
        <xsl:value-of select="concat($project-id,'_',tokenize($objid, ':')[last()])"/>
    </xsl:function>
    <xsl:function name="bmtn:clean-id">
        <xsl:param name="objid" as="xs:string"/>
        <xsl:value-of select="replace($objid, 'urn:PUL:(periodicals:)?bluemountain:', 'http://bluemountain.princeton.edu/')"/>
    </xsl:function>
    <xsl:function name="bmtn:simple-id">
        <xsl:param name="objid" as="xs:string"/>
        <xsl:value-of select="tokenize($objid, ':')[last()]"/>
    </xsl:function><!-- Template for processing issue constituents.  There's a good
		 deal of overlap with the mods:mods template, so some code
		 refactoring needs to be done. -->
    <xsl:template match="mods:relatedItem[@type='constituent']">
        <xsl:param name="objid"/><!-- One or more <collex:federation> elements are REQUIRED. -->
        <collex:federation>
            <xsl:value-of select="$federation-id"/>
        </collex:federation><!-- A SINGLE <collex:archive> element is REQUIRED. -->
        <collex:archive>
            <xsl:value-of select="bmtn:archive-name(ancestor::mods:mods/mods:relatedItem[@type='host']/@xlink:href)"/>
        </collex:archive><!-- A SINGLE <dc:title> element is REQUIRED. -->
        <dc:title>
            <xsl:choose>
                <xsl:when test="mods:titleInfo[1]">
                    <xsl:apply-templates select="mods:titleInfo[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>[untitled]</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </dc:title><!-- One or more <dc:type> elements are REQUIRED. -->
        <xsl:for-each select="mods:genre">
            <dc:type>
                <xsl:apply-templates select="current()"/>
            </dc:type>
        </xsl:for-each>
        <xsl:choose>
            <xsl:when test="mods:name and not(empty(mods:name/text()))">
                <xsl:apply-templates select="mods:name"/>
            </xsl:when>
            <xsl:otherwise>
                <role:AUT>Unknown</role:AUT>
            </xsl:otherwise>
        </xsl:choose><!-- One or more <collex:discipline> elements are REQUIRED. -->
        <xsl:for-each select="$disciplines/disciplines/discipline">
            <collex:discipline>
                <xsl:value-of select="current()"/>
            </collex:discipline>
        </xsl:for-each><!-- One or more <collex:genre> elements are REQUIRED. -->
        <xsl:apply-templates select="mods:genre" mode="collex-genre"/><!-- One or more <dc:date> elements are REQUIRED. -->
        <dc:date>
            <xsl:value-of select="ancestor::mods:mods/mods:originInfo/mods:dateIssued[@keyDate='yes']"/>
        </dc:date><!-- ONE <rdfs:seeAlso> element with the URL of the resource is REQUIRED. -->
        <rdfs:seeAlso>
            <xsl:attribute name="rdf:resource" select="bmtn:object-URL(ancestor::mods:mods/mods:identifier[@type='bmtn'])"/>
        </rdfs:seeAlso><!-- A collex:text element with the URL of the plain-text expression of the constituent -->
        <collex:text>
            <xsl:attribute name="rdf:resource" select="string-join(($springs-server, 'constituent', bmtn:simple-id($objid), @ID),'/')"/>
        </collex:text>
    </xsl:template>
</xsl:stylesheet>