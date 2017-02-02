<?xml version="1.0" encoding="UTF-8"?>
<!-- 
A set of XSL templates for transforming the TEI documents produced by
the Blue Mountain Project into RDF suitable for ingestion into 
ModNets.

REFERENCES: http://wiki.collex.org/index.php/Submitting_RDF
-->
<xsl:stylesheet xmlns:collex="http://www.collex.org/schema#" xmlns:role="http://www.loc.gov/loc.terms/relators/" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:bmtn="http://bluemountain.princeton.edu" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0" exclude-result-prefixes="xs">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/><!-- GLOBAL DECLARATIONS -->
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
    <xsl:variable name="newline" select="'&#xD;&#xA;'"/>
    <xsl:variable name="objid" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type='bmtnid']" as="xs:string"/>
    <xsl:variable name="magid" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:relatedItem[@type='host']/@target"/>
    <xsl:variable name="pubDate" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr/tei:imprint/tei:date/@when"/>
    <xsl:key name="divKey" match="tei:div" use="@corresp"/><!--  TEMPLATES -->
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
            <xsl:choose>
                <xsl:when test="tei:biblStruct/tei:monogr/tei:respStmt[tei:resp='edt']">
                    <xsl:for-each select="tei:biblStruct/tei:monogr/tei:respStmt[tei:resp='edt']">
                        <role:EDT>
                            <xsl:value-of select="tei:persName"/>
                        </role:EDT>
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <role:EDT>Unknown</role:EDT>
                </xsl:otherwise>
            </xsl:choose>
            <collex:discipline>Literature</collex:discipline>
            <collex:genre>Collection</collex:genre>
            <dc:date>
                <xsl:value-of select="$pubDate"/>
            </dc:date>
            <rdfs:seeAlso rdf:resource="{$bmtn-server}/issue.html?issueURN={$objid}"/>
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
            <xsl:apply-templates select="tei:biblStruct/tei:monogr/tei:imprint/tei:classCode"/>
            <xsl:for-each select="$disciplines/disciplines/discipline">
                <collex:discipline>
                    <xsl:value-of select="current()"/>
                </collex:discipline>
            </xsl:for-each>
            <dc:date>
                <xsl:value-of select="$pubDate"/>
            </dc:date>
            <rdfs:seeAlso rdf:resource="{$bmtn-server}/issue.html?issueURN={$objid}"/>
            <collex:fulltext>true</collex:fulltext>
            <collex:text>
                <xsl:apply-templates select="key('divKey', @xml:id)"/>
            </collex:text>
        </bmtn:Description>
    </xsl:template>
    <xsl:template match="tei:title">
        <xsl:apply-templates select="tei:seg[@type='main']"/>
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
    <xsl:template match="tei:lb">
        <xsl:value-of select="$newline"/>
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
</xsl:stylesheet>