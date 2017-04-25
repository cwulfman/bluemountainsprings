<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mods="http://www.loc.gov/mods/v3" xmlns:mets="http://www.loc.gov/METS/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:mix="http://www.loc.gov/mix/" xmlns:local="http://bluemountain/" xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="#all" version="2.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Mar 14, 2016</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> cwulfman</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:include href="mods.xsl"/>
    <xsl:output encoding="UTF-8" indent="yes" method="xml"/>
    <xsl:key name="imageKey" match="mets:fileGrp[@ID = 'IMGGRP']/mets:file" use="@ID"/>
    <xsl:key name="image-by-group" match="mets:fileGrp[@ID = 'IMGGRP']/mets:file" use="@GROUPID"/>
    <xsl:key name="div-by-dmdid" match="mets:div" use="@DMDID"/>
    <xsl:key name="alto-file" match="mets:fileGrp[@ID='ALTOGRP']/mets:file" use="@ID"/>
    <xsl:key name="techMD" match="mets:techMD" use="@ID"/>
    <xsl:param name="baseURI">http://bluemountain.princeton.edu/iiif</xsl:param><!-- default value; real value is passed in -->
    <xsl:variable name="iiif-context">http://iiif.io/api/image/2/context.json</xsl:variable>
    
    <xsl:variable name="pdf-root">http://bluemountain.princeton.edu/pdfs</xsl:variable>
    
    <xsl:variable name="bmtnid">
        <xsl:value-of select="substring-after(/mets:mets/mets:dmdSec/mets:mdWrap[@MDTYPE = 'MODS']/mets:xmlData/mods:mods/mods:identifier[@type = 'bmtn'],'urn:PUL:bluemountain:')"/>
    </xsl:variable>
    <xsl:function name="local:file-path">
        <xsl:param name="fileURI"/>
        <xsl:variable name="protocol">http://</xsl:variable>
        <xsl:variable name="host">libimages.princeton.edu</xsl:variable>
        <xsl:variable name="service">loris2</xsl:variable>
        <xsl:variable name="base">bluemountain/astore%2Fperiodicals</xsl:variable>
        <xsl:variable name="path" select="substring-after($fileURI, 'file:///usr/share/BlueMountain/astore/periodicals/')"/>
        <xsl:value-of select="concat($protocol, $host, '/', $service, '/', $base, '/', $path)"/>
    </xsl:function>
    
    <xsl:function name="local:pdf-path">
        <xsl:param name="mets"/>
        <xsl:variable name="titleid">
            <xsl:value-of select="substring-after($mets//mods:relatedItem[@type='host']/@xlink:href, 'urn:PUL:bluemountain:')"/>
        </xsl:variable>
        <xsl:variable name="bmtnid">
            <xsl:value-of select="$mets//mods:identifier[@type='bmtn']"/>
        </xsl:variable>
        <xsl:variable name="issueid">
            <xsl:value-of select="substring-after($bmtnid, 'urn:PUL:bluemountain:')"/>
        </xsl:variable>
        <xsl:variable name="datepath">
            <xsl:value-of select="replace(substring-after($bmtnid, '_'),'-', '/')"/>
        </xsl:variable>

        <xsl:value-of select="concat($pdf-root, '/periodicals/', $titleid, '/issues/', $datepath,'/', $issueid, '.pdf')"/>
    </xsl:function>
    
    <xsl:template match="mods:mods" mode="metadata">
        <map>
            <string key="label">title</string>
            <string key="value">
                <xsl:value-of select="mods:use-title(., 'full')"/>
            </string>
        </map>
        <map>
            <string key="label">display-date</string>
            <string key="value">
                <xsl:value-of select="mods:display-date(.)"/>
            </string>
        </map><!--<map>
            <string key="label">detail</string>
            <string key="value">
                <xsl:apply-templates select="mods:part/mods:detail"/>
            </string>
        </map>-->
        <map>
            <string key="label">part</string>
            <string key="value">
                <xsl:apply-templates select="mods:part"/>
            </string>
        </map>
    </xsl:template>
    <xsl:template match="mods:mods" mode="ranges">
        <map>
            <string key="label">Table of Contents</string>
            <string key="@type">sc:Range</string>
            <string key="@id">
                <xsl:value-of select="string-join(($baseURI, $bmtnid, 'range', 'toc'), '/')"/>
            </string>
            <array key="canvases">
                <xsl:for-each select="ancestor::mets:mets/mets:fileSec/mets:fileGrp[@USE='Images']/mets:file/@GROUPID">
                    <string>
                        <xsl:value-of select="string-join(($baseURI, $bmtnid, 'canvas', current()), '/')"/>
                    </string>
                </xsl:for-each>
            </array>
        </map>
        <xsl:apply-templates select="mods:relatedItem[@type='constituent']" mode="#current"/>
    </xsl:template>
    <xsl:template match="mods:relatedItem[@type='constituent']" mode="ranges">
        <map>
            <string key="@type">sc:Range</string>
            <string key="@id">
                <xsl:value-of select="string-join(($baseURI, $bmtnid, 'range', @ID), '/')"/>
            </string>
            <string key="label">
                <xsl:value-of select="mods:use-title(., 'full')"/>
            </string>
            <string key="within">
                <xsl:value-of select="string-join(($baseURI, $bmtnid, 'range', 'toc'), '/')"/>
            </string>
            <array key="canvases">
                <xsl:for-each select="key('div-by-dmdid', @ID)//mets:area/@FILEID">
                    <xsl:variable name="groupid" select="key('alto-file', .)/@GROUPID"/>
                    <string>
                        <xsl:value-of select="string-join(($baseURI, $bmtnid, 'canvas', $groupid), '/')"/>
                    </string>
                </xsl:for-each>
            </array>
            <array key="members">
                <xsl:for-each select="key('div-by-dmdid', @ID)//mets:area/@FILEID">
                    <xsl:variable name="groupid" select="key('alto-file', .)/@GROUPID"/>
                    <string>
                        <xsl:value-of select="string-join(($baseURI, $bmtnid, 'canvas', $groupid), '/')"/>
                    </string>
                </xsl:for-each>
            </array>
        </map>
    </xsl:template>
    <xsl:template name="metadata">
        <xsl:param name="metsrec" as="node()"/>
        <array key="metadata">
            <xsl:apply-templates select="$metsrec//mods:mods" mode="metadata"/>
        </array>
    </xsl:template>
    <xsl:template name="description">
        <xsl:param name="metsrec" as="node()"/>
        <string key="description">a magazine issue in the Blue Mountain collection</string>
    </xsl:template>
    <xsl:template name="license">
        <xsl:param name="metsrec" as="node()"/>
        <string key="license">a license</string>
    </xsl:template>
    <xsl:template name="attribution">
        <xsl:param name="metsrec" as="node()"/>
        <string key="attribution">Provided by the Blue Mountain Project at Princeton University</string>
    </xsl:template>
    <xsl:template name="service-manifest">
        <xsl:param name="metsrec" as="node()"/>
        <map key="service"/>
    </xsl:template>
    <xsl:template name="seeAlso">
        <xsl:param name="metsrec" as="node()"/>
        <map key="seeAlso"/>
    </xsl:template>
    <xsl:template name="rendering">
        <xsl:param name="metsrec" as="node()"/>
        <map key="rendering">
            <string key="@id">
                <xsl:value-of select="local:pdf-path($metsrec)"/>
            </string>
            <string key="label">Download as PDF</string>
            <string key="format">application/pdf</string>
        </map>
    </xsl:template>
    <xsl:template name="within">
        <xsl:param name="metsrec" as="node()"/>
        <string key="within">within URI</string>
    </xsl:template>
    <xsl:template name="sequences">
        <xsl:param name="metsrec" as="node()"/>
        <array key="sequences">
            <xsl:call-template name="sequence-normal">
                <xsl:with-param name="metsrec" select="$metsrec"/>
            </xsl:call-template>
        </array>
    </xsl:template>
    <xsl:template name="sequence-normal">
        <xsl:param name="metsrec" as="node()"/>
        <map>
            <string key="@id">
                <xsl:value-of select="string-join(($baseURI, $bmtnid, 'sequence', 'normal'), '/')"/>
            </string>
            <string key="@type">sc:Sequence</string>
            <string key="label">Normal Page Order</string>
            <map key="rendering">
                <string key="@id">
                    <xsl:value-of select="local:pdf-path($metsrec)"/>
                </string>
                <string key="label">Download as PDF</string>
                <string key="format">application/pdf</string>
            </map>
            <string key="viewingDirection">left-to-right</string>
            <string key="viewingHint">paged</string>
            <xsl:call-template name="canvases">
                <xsl:with-param name="metsrec" select="$metsrec"/>
            </xsl:call-template>
        </map>
    </xsl:template>
    <xsl:template name="structures">
        <xsl:param name="metsrec" as="node()"/>
        <array key="structures">
            <xsl:apply-templates select="$metsrec//mods:mods" mode="ranges"/>
        </array>
    </xsl:template>
    <xsl:template name="canvases">
        <xsl:param name="metsrec" as="node()"/>
        <array key="canvases">
            <xsl:apply-templates select="mets:structMap[@TYPE = 'PHYSICAL']"/>
        </array>
    </xsl:template>
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="mets:structMap[@TYPE = 'PHYSICAL']">
        <xsl:apply-templates select="mets:div[@TYPE = 'Magazine']/mets:div"/>
    </xsl:template>
    <xsl:template match="mets:div">
        <xsl:variable name="image-fileid" select="mets:fptr//mets:area[not(@BEGIN)]/@FILEID"/>
        <xsl:variable name="image-file" select="key('imageKey', $image-fileid)"/>
        <xsl:variable name="canvasid">
            <xsl:value-of select="string-join(($baseURI, $bmtnid, 'canvas', $image-file/@GROUPID), '/')"/>
        </xsl:variable>
        <map>
            <string key="@type">sc:Canvas</string>
            <string key="@id">
                <xsl:value-of select="$canvasid"/>
            </string>
            <string key="label">
                <xsl:choose>
                    <xsl:when test="@LABEL">
                        <xsl:value-of select="@LABEL"/>
                    </xsl:when>
                    <xsl:when test="@TYPE">
                        <xsl:value-of select="@TYPE"/>
                    </xsl:when>
                    <xsl:otherwise>Unlabeled</xsl:otherwise>
                </xsl:choose>
            </string>
            <number key="height">
                <xsl:value-of select="key('techMD', xs:string($image-file/@ADMID))//mix:ImageLength"/>
            </number>
            <number key="width">
                <xsl:value-of select="key('techMD', xs:string($image-file/@ADMID))//mix:ImageWidth"/>
            </number>
            <array key="images">
                <xsl:apply-templates select="key('imageKey', $image-fileid)">
                    <xsl:with-param name="canvasid" select="$canvasid"/>
                </xsl:apply-templates>
            </array>
        </map>
    </xsl:template>
    <xsl:template match="mets:file">
        <xsl:param name="canvasid"/>
        <map>
            <string key="@type">oa:Annotation</string>
            <string key="motivation">sc:painting</string>
            <map key="resource">
                <string key="@id">
                    <xsl:value-of select="concat(local:file-path(mets:FLocat/@xlink:href), '/full/!200,200/0/default.jpg')"/>
                </string>
                <string key="@type">dctypes:Image</string>
                <string key="format">
                    <xsl:value-of select="@MIMETYPE"/>
                </string>
                <map key="service">
                    <string key="@context">
                        <xsl:value-of select="$iiif-context"/>
                    </string>
                    <string key="@id">
                        <xsl:value-of select="local:file-path(mets:FLocat/@xlink:href)"/>
                    </string>
                    <string key="profile">http://iiif.io/api/image/2/level1.json</string>
                </map>
                <number key="height">
                    <xsl:value-of select="key('techMD', xs:string(@ADMID))//mix:ImageLength"/>
                </number>
                <number key="width">
                    <xsl:value-of select="key('techMD', xs:string(@ADMID))//mix:ImageWidth"/>
                </number>
            </map>
            <string key="on">
                <xsl:value-of select="$canvasid"/>
            </string>
        </map>
    </xsl:template>
    <xsl:template match="mets:mets">
        <map>
            <string key="@context">
                <xsl:value-of select="$iiif-context"/>
            </string>
            <string key="@type">sc:Manifest</string>
            <string key="@id">
                <xsl:value-of select="string-join(($baseURI, $bmtnid, 'manifest'), '/')"/>
            </string>
            <string key="label">
                <xsl:apply-templates select="mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods/mods:titleInfo[1]"/>
                <xsl:text>, </xsl:text>
                <xsl:apply-templates select="mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods/mods:part"/>
            </string>
            <xsl:call-template name="metadata">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="description">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="license">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="attribution">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="service-manifest">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="seeAlso">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="rendering">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="within">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="sequences">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
            <xsl:call-template name="structures">
                <xsl:with-param name="metsrec" select="current()"/>
            </xsl:call-template>
        </map>
    </xsl:template>
</xsl:stylesheet>