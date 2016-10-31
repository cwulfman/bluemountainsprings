<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://erlangen-crm.org/efrbroo/" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:ns0="http://www.w3.org/2004/02/skos/" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:bmtn="http://blaueberg.info/" xmlns:local="http://library.princeton.edu" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:efrbroo="http://erlangen-crm.org/efrbroo/" xmlns:dc="http://purl.org/dc/terms/" xmlns:xlink="http://www.w3.org/1999/xlink" version="2.0">
    <xsl:output indent="yes"/>
    <xsl:variable name="bmtnid">
        <xsl:value-of select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type = 'bmtnid']"/>
    </xsl:variable>
    <xsl:variable name="biblInfo" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct"/>
    <xsl:template match="/">
        <rdf:RDF>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template><!-- a typical bibliographic record for a publication (not a
         manuscript) reflects the notion of F3 Manifestation Product
         Type -->
    <xsl:template match="tei:TEI">
        <xsl:variable name="bmtnid">
            <xsl:value-of select="tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type = 'bmtnid']"/>
        </xsl:variable>
        <xsl:variable name="hostid">
            <xsl:value-of select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:relatedItem[@type='host']/@target"/>
        </xsl:variable>
        <F3_Manifestation_Product_Type rdf:about="http://blaueberg.info/F3/{$bmtnid}">
            <dc:title>
                <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:monogr/tei:title"/>
                <xsl:if test="$biblInfo/tei:monogr/tei:imprint/tei:biblScope[@unit='issue']">
                    <xsl:variable name="partString">
                        <xsl:apply-templates select="$biblInfo/tei:monogr/tei:imprint/tei:biblScope[@unit='issue']"/>
                    </xsl:variable>
                    <xsl:value-of select="concat(' ', $partString)"/>
                </xsl:if>
            </dc:title>
            <dc:date>
                <xsl:value-of select="$biblInfo/tei:monogr/tei:impring/tei:date/@when"/>
            </dc:date>
            <CLR6_should_carry>
                <F24_Publication_Expression rdf:about="http://blaueberg.info/F24/{$bmtnid}">
                    <R14_incorporates>
                        <F22_Self_Contained_Expression rdf:about="http://blaueberg.info/F22/{$bmtnid}/0"/>
                    </R14_incorporates>
                    <R3i_realises>
                        <F19_Publication_Work rdf:about="http://blaueberg.info/F19/{$bmtnid}/0">
                            <R5i_is_component_of>
                                <F24_Publication_Expression rdf:about="http://blaueberg.info/F24/{$hostid}">
                                    <R3i_realises>
                                        <F18_Serial_Work rdf:about="http://blaueberg.info/F18/{$hostid}"/>
                                    </R3i_realises>
                                </F24_Publication_Expression>
                            </R5i_is_component_of>
                        </F19_Publication_Work>
                    </R3i_realises>
                </F24_Publication_Expression>
            </CLR6_should_carry>
        </F3_Manifestation_Product_Type>
        <xsl:apply-templates select="tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:biblStruct/tei:relatedItem[@type='constituent']"/>
    </xsl:template>
    <xsl:template match="tei:relatedItem[@type='constituent']">
        <xsl:variable name="constituentID" select="@xml:id"/>
        <F22_Self_Contained_Expression rdf:about="http://blaueberg.info/F22/{$bmtnid}/{$constituentID}">
            <R14i_is_incorporated_in>
                <F22_Self_Contained_Expression rdf:about="http://blaueberg.info/F22/{$bmtnid}/0"/>
            </R14i_is_incorporated_in>
            <P102_has_title>
                <xsl:apply-templates select="tei:biblStruct/tei:analytic/tei:title[@level='a'][1]"/>
            </P102_has_title>
            <xsl:for-each select="tei:biblStruct/tei:analytic/tei:respStmt">
                <xsl:variable name="i" select="position()"/>
                <R17i_was_created_by>
                    <F28_Expression_Creation rdf:about="http://blaueberg.info/F28/{$bmtnid}/{$constituentID}/{$i}">
                        <E14_carried_out_by>
                            <E21_Person>
                                <xsl:if test="./@valueURI">
                                    <xsl:attribute name="rdf:about" select="./@valueURI"/>
                                </xsl:if>
                                <P1131_is_identified_by>
                                    <xsl:apply-templates select="tei:persName"/>
                                </P1131_is_identified_by>
                            </E21_Person><!--	    <P14.1_in_the_role_of>
	      <xsl:value-of select="mods:role/mods:roleTerm/text()"/>
	    </P14.1_in_the_role_of> -->
                        </E14_carried_out_by>
                    </F28_Expression_Creation>
                </R17i_was_created_by>
            </xsl:for-each>
        </F22_Self_Contained_Expression>
    </xsl:template>
</xsl:stylesheet>