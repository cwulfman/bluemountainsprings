<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:mets="http://www.loc.gov/METS/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs xd mods mets" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Mar 14, 2016</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> cwulfman</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:param name="baseURI">http://bluemountain.princeton.edu/exist/restxq/iiif</xsl:param>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="collection[@level='top']">
        <map>
            <string key="@context">http://iiif.io/api/presentation/2/context.json</string>
            <string key="@type">sc:Collection</string>
            <string key="@id">
                <xsl:value-of select="concat($baseURI, '/collection/top')"/>
            </string>
            <string key="label">Top Level Collection for Blue Mountain</string>
            <string key="viewingHint">top</string>
            <string key="description">A collection of magazines of music, the arts, and letters from the 20th century European and American avant-gardes</string>
            <string key="attribution">Provided by the Blue Mountain Project at Princeton University</string>
            <array key="collections">
                <xsl:apply-templates select="titles"/>
            </array>
            <array key="members">
                <xsl:apply-templates select="titles"/>
            </array>
        </map>
    </xsl:template>
    <xsl:template match="mods:mods">
        <map>
            <string key="@id">
                <xsl:value-of select="concat($baseURI, '/collection/', substring-after(mods:identifier[@type='bmtn'], 'urn:PUL:bluemountain:'))"/>
            </string>
            <string key="@type">sc:Collection</string>
            <string key="label">
                <xsl:value-of select="mods:titleInfo[1]/mods:title"/>
            </string>
        </map>
    </xsl:template>
    <xsl:template match="mods:mods" mode="manifest">
        <xsl:variable name="bmtnid">
            <xsl:value-of select="substring-after(mods:identifier[@type='bmtn'], 'urn:PUL:bluemountain:')"/>
        </xsl:variable>
        <map>
            <string key="@id">
                <xsl:value-of select="concat($baseURI, '/', $bmtnid, '/manifest')"/>
            </string>
            <string key="@type">sc:Manifest</string>
            <string key="label">
                <xsl:apply-templates select="mods:originInfo/mods:dateIssued[not(@keyDate)]"/>
            </string>
        </map>
    </xsl:template>
    <xsl:template match="collection">
        <map>
            <string key="@context">http://iiif.io/api/presentation/2/context.json</string>
            <string key="@type">sc:Collection</string>
            <string key="viewingHint">individuals</string>
            <string key="label">
                <xsl:value-of select="title/mods:mods/mods:titleInfo[1]/mods:title"/>
            </string>
            <array key="manifests">
                <xsl:apply-templates select="issues/mods:mods" mode="manifest"/>
            </array>
            <array key="members">
                <xsl:apply-templates select="issues/mods:mods" mode="manifest"/>
            </array>
        </map>
    </xsl:template>
</xsl:stylesheet>