<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs xd tei" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Jun 27, 2016</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> cwulfman</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:output indent="yes"/>
    <xsl:param name="springs-root"/>
    <xsl:template match="/">
        <xsl:variable name="bmtnid">
            <xsl:value-of select="tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type = 'bmtnid']"/>
        </xsl:variable>
        <issue>
            <bmtnid>
                <xsl:value-of select="$bmtnid"/>
            </bmtnid>
            <xsl:apply-templates select="tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr">
                <xsl:with-param name="bmtnid" select="$bmtnid"/>
            </xsl:apply-templates>
        </issue>
    </xsl:template>
    <xsl:template match="tei:monogr">
        <xsl:param name="bmtnid"/>
        <title>
            <xsl:value-of select="normalize-space(tei:title)"/>
        </title>
        <xsl:apply-templates select="tei:imprint"/>
        <editors>
            <xsl:for-each select="tei:respStmt[./tei:resp = 'edt']">
                <editor viafid="{tei:persName/@ref}">
                    <xsl:value-of select="normalize-space(tei:persName)"/>
                </editor>
            </xsl:for-each>
        </editors>
        <contributors>
            <xsl:for-each select="ancestor::tei:biblStruct/tei:relatedItem[@type='constituent']//tei:respStmt[tei:resp='cre']/tei:persName">
                <contributor>
                    <viafid>
                        <xsl:value-of select="@ref"/>
                    </viafid>
                    <byline>
                        <xsl:value-of select="current()"/>
                    </byline>
                </contributor>
            </xsl:for-each>
        </contributors>
        <xsl:for-each-group select="ancestor::tei:biblStruct/tei:relatedItem[@type='constituent']" group-by="tei:biblStruct//tei:classCode[@scheme = 'CCS']">
            <xsl:variable name="groupName">
                <xsl:choose>
                    <xsl:when test="current-grouping-key()">
                        <xsl:value-of select="current-grouping-key()"/>
                    </xsl:when>
                    <xsl:otherwise>Unspecified</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:element name="{ $groupName }">
                <xsl:for-each select="current-group()">
                    <contribution>
                        <id>
                            <xsl:value-of select="xs:string(@xml:id)"/>
                        </id>
                        <uri>
                            <xsl:value-of select="string-join(($springs-root,'constituent',$bmtnid,xs:string(@xml:id)), '/')"/>
                        </uri>
                        <title>
                            <xsl:value-of select="normalize-space(tei:biblStruct/tei:analytic/tei:title)"/>
                        </title>
                    </contribution>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each-group>
    </xsl:template>
    <xsl:template match="tei:imprint">
        <volume>
            <xsl:value-of select="normalize-space(tei:biblScope[@unit='vol'])"/>
        </volume>
        <number>
            <xsl:value-of select="normalize-space(tei:biblScope[@unit='issue'])"/>
        </number>
        <pubDate>
            <xsl:value-of select="xs:string(tei:date/@when)"/>
        </pubDate>
        <pubPlace>
            <xsl:value-of select="normalize-space(tei:pubPlace)"/>
        </pubPlace>
    </xsl:template>
</xsl:stylesheet>