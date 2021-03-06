<?xml version="1.0" encoding="UTF-8"?>
<?xml-model href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"?>
<?xml-model href="http://www.tei-c.org/release/xml/tei/custom/schema/relaxng/tei_all.rng" type="application/xml"
	schematypens="http://purl.oclc.org/dsdl/schematron"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
    xmlns:saxon="http://saxon.sf.net/" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:functx="http://www.functx.com">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Jul 2, 2013</xd:p>
            <xd:p><xd:b>Author:</xd:b> Nathan Gibson</xd:p>
            <xd:p>This stylesheet contains templates for processing birth, death, floruit, event and other date-related elements 
            for person records in TEI format.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Cycles through types of events to create only a single <gi>birth</gi> or <gi>death</gi> event.</xd:p>
        </xd:desc>
        <xd:param name="bib-ids">The $bib-ids param is used for adding @source attributes. (See the source template.)</xd:param>
        <xd:param name="event-columns">The various columns which have dates for events.</xd:param>
    </xd:doc>
    <xsl:template name="personal-events">
        <xsl:param name="bib-ids"/>
        <xsl:param name="event-columns"/>
        
        <!-- Create a birth element if the data exists for one -->
        <xsl:if test="$event-columns[contains(name(),'DOB') and string-length(normalize-space(node()))]">
            <xsl:variable name="birth-columns" select="$event-columns[contains(name(),'DOB') and string-length(normalize-space(node()))]"/>
            <xsl:for-each select="$birth-columns[1]"> <!-- wrapping it in for-each is an awful hack to make the context work in the called template -->
            <xsl:call-template name="event-element">
                <xsl:with-param name="bib-ids" select="$bib-ids"/>
                <xsl:with-param name="column-name" select="name(.)"/>
            </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
        
        <!-- Create a death element if the data exists for one -->
        <xsl:if test="$event-columns[contains(name(),'DOD') and string-length(normalize-space(node()))]">
            <xsl:variable name="death-columns" select="$event-columns[contains(name(),'DOD') and string-length(normalize-space(node()))]"/>
            <xsl:for-each select="$death-columns[1]"> <!-- wrapping it in for-each is an awful hack to make the context work in the called template -->
                <xsl:call-template name="event-element">
                    <xsl:with-param name="bib-ids" select="$bib-ids"/>
                    <xsl:with-param name="column-name" select="name(.)"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
        
        <!-- Create a floruit element if the data exists for one -->
        <xsl:if test="$event-columns[contains(name(),'Floruit') and string-length(normalize-space(node()))]">
            <xsl:variable name="floruit-columns" select="$event-columns[contains(name(),'Floruit') and string-length(normalize-space(node()))]"/>
            <xsl:for-each select="$floruit-columns[1]"> <!-- wrapping it in for-each is an awful hack to make the context work in the called template -->
                <xsl:call-template name="event-element">
                    <xsl:with-param name="bib-ids" select="$bib-ids"/>
                    <xsl:with-param name="column-name" select="name(.)"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:if>
        
        <!-- Create a floruit element if our only date information for this record is Barsoum_en-Century -->
        <xsl:if test="$event-columns[compare(name(),'Barsoum_en-Century') = 0 and string-length(normalize-space(node()))]">
            <xsl:if test="not($event-columns[not(contains(name(),'Century')) and string-length(normalize-space(node()))])">
                <xsl:for-each select="$event-columns[compare(name(),'Barsoum_en-Century') = 0 and string-length(normalize-space(node()))]">
                <xsl:call-template name="event-element">
                    <xsl:with-param name="bib-ids" select="$bib-ids"/>
                    <xsl:with-param name="column-name" select="name(.)"/>
                </xsl:call-template>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>
        
        <!-- <xsl:for-each 
            select="$event-columns[ends-with(name(),'Floruit') or ends-with(name(),'DOB') or ends-with(name(),'DOD')]">
            <xsl:call-template name="event-element">
                <xsl:with-param name="bib-ids" select="$bib-ids"/>
                <xsl:with-param name="column-name" select="name(.)"/>
            </xsl:call-template>
        </xsl:for-each> -->
        <!-- Tests whether there are any columns with content that will be put into event elements (e.g., "Event"). 
                                        If so, creates a listEvent parent element to contain them. 
                                        Add to the if test and to the for-each the descriptors of any columns that should be put into event elements. -->
        <xsl:if test="exists(*[contains(name(), 'Event') and string-length(normalize-space(node()))])">
            <listEvent>
                <xsl:for-each 
                    select="$event-columns[ends-with(name(),'Event')]">
                    <xsl:call-template name="event-element">
                        <xsl:with-param name="bib-ids" select="$bib-ids"/>
                        <xsl:with-param name="column-name" select="name(.)"/>
                    </xsl:call-template>
                </xsl:for-each>
            </listEvent>
        </xsl:if>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Creates a birth, death, floruit, event, etc. element using the current column/context node as human-readable content and 
            using machine-readable dates from other columns whose names include the current column's name. (E.g., the GEDSH_DOB 
            column contains human-readable content, whereas GEDSH_DOB_Standard, GEDSH_DOB_Not_Before, and GEDSH_DOB_Not_After are 
            machine-readable columns. If this template is called on GEDSH_DOB, the content of the created element will be the content of
            GEDSH_DOB, while GEDSH_DOB_Standard, GEDSH_DOB_Not_Before, and GEDSH_DOB_Not_After will be automatically detected and 
            their contents added as machine-readable attributes.)</xd:p>
        </xd:desc>
        <xd:param name="bib-ids">The $bib-ids param is used for adding @source attributes. (See the source template.)</xd:param>
        <xd:param name="column-name">The name of the column being processed (must be specified when template is called).</xd:param>
        <xd:param name="element-name">The name of the TEI element to be created, determined from the $column-name.</xd:param>
    </xd:doc>
    <xsl:template name="event-element" xmlns="http://www.tei-c.org/ns/1.0">
        <xsl:param name="bib-ids"/>
        <xsl:param name="column-name" select="name()"/>
        <xsl:param name="element-name">
            <!-- Names of date-related elements to be created go here. -->
            <xsl:choose>
                <xsl:when test="contains($column-name, 'Floruit') or contains($column-name, 'Century')">floruit</xsl:when>
                <xsl:when test="contains($column-name, 'DOB')">birth</xsl:when>
                <xsl:when test="contains($column-name, 'DOD')">death</xsl:when>
                <xsl:when test="contains($column-name, 'Event')">event</xsl:when>
            </xsl:choose>
        </xsl:param>
        
        <!-- If the current column has content or a related column has content, adds the element with the name specified by $element-name. -->
        <xsl:if test="string-length(normalize-space(.)) or exists(following-sibling::*[contains(name(), $column-name) and string-length(normalize-space(node()))]) or exists(preceding-sibling::*[contains(name(), $column-name) and string-length(normalize-space(node()))])">
            <xsl:element name="{$element-name}">
                <!-- Adds machine-readable attributes to date. -->
                <xsl:choose>
                    <xsl:when test="contains($column-name,'Century')">
                        <xsl:variable name="century" select="number(.)"/>
                        <xsl:attribute name="notBefore"><xsl:if test="$century &lt; 11">0</xsl:if><xsl:value-of select="$century - 1"/>00</xsl:attribute>
                        <xsl:attribute name="notAfter"><xsl:if test="$century &lt; 10">0</xsl:if><xsl:value-of select="$century"/>00</xsl:attribute>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="date-attributes">
                            <xsl:with-param name="date-type" select="replace(replace(name(), '_Begin', ''), '_End', '')"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
        
                <!-- Adds source attributes. -->
                <xsl:call-template name="source">
                    <xsl:with-param name="bib-ids" select="$bib-ids"/>
                    <xsl:with-param name="column-name" select="name(.)"/>
                </xsl:call-template>
                
                <!-- Adds custom type: Any additional custom types should go here.-->
                <xsl:choose>
                    <xsl:when test="contains(name(), 'Event')">
                        <xsl:attribute name="type" select="'event'"/>
                    </xsl:when>
                </xsl:choose>
                
                <!-- Adds human readable content to element, usually just the date -->
                <xsl:choose>
                    <xsl:when test="contains($column-name,'Century')"><xsl:value-of select="."/><xsl:choose>
                        <xsl:when test="number(.) = 2">nd</xsl:when>
                        <xsl:when test="number(.) = 3">rd</xsl:when>
                        <xsl:otherwise>th</xsl:otherwise>
                    </xsl:choose> century</xsl:when>
                    <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
                </xsl:choose>
            </xsl:element>
        </xsl:if>
    </xsl:template>
    
    <xd:doc xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl">
        <xd:desc>
            <xd:p>This template adds machine-readable date attributes to an element, based on 
                text strings contained in the source XML element's name.
                <xd:ul>
                    <xd:li>_Begin_Standard --> @from</xd:li>
                    <xd:li>_End_Standard --> @to</xd:li>
                    <xd:li>_Standard --> @when</xd:li>
                    <xd:li>_Not_Before --> @notBefore</xd:li>
                    <xd:li>_Not_After --> @notAfter</xd:li>
                </xd:ul>
            </xd:p>
            <xd:p>Modified to make it not recursive, just checking for the existence of such columns.  -- TAC 7/30/2013</xd:p>
        </xd:desc>
        <xd:param name="date-type">Uses the name of the human-readable field, except in fields that have "_Begin" and "_End",
            which it replaces so that @from and @to attributes can be added to the same element. Fields should be named in such a way that machine-readable fields contain the name of the field that has human-readable date data.</xd:param>
    </xd:doc>
    <xsl:template name="date-attributes" xmlns="http://www.tei-c.org/ns/1.0">
        <xsl:param name="date-type"/>
        <!-- Tests whether the beginning of the field name matches the name of the human-readable field. 
        For this to work, machine-readable date fields need to start with the field name of the corresponding human-readable field.
        For example, GEDSH_en-DOB and GEDSH_en-DOB_Standard -->
        <!-- What should be done if a _Begin field or an _End field have notBefore/notAfter attributes? -->
        <xsl:if test="../*[contains(name(),$date-type) and ends-with(name(),'_Begin_Standard') and string-length(normalize-space(node()))]">
            <xsl:attribute name="from" select="../*[contains(name(),$date-type) and ends-with(name(),'_Begin_Standard') and string-length(normalize-space(node()))][1]"/>
        </xsl:if>
        <xsl:if test="../*[contains(name(),$date-type) and ends-with(name(),'_End_Standard') and string-length(normalize-space(node()))]">
            <xsl:attribute name="to" select="../*[contains(name(),$date-type) and ends-with(name(),'_End_Standard') and string-length(normalize-space(node()))][1]"/>
        </xsl:if>
        <xsl:if test="../*[contains(name(),$date-type) and ends-with(name(),'_Standard') and string-length(normalize-space(node()))]">
            <xsl:attribute name="when" select="../*[contains(name(),$date-type) and ends-with(name(),'_Standard') and string-length(normalize-space(node()))][1]"/>
        </xsl:if>
        <xsl:if test="../*[contains(name(),$date-type) and ends-with(name(),'_Not_Before') and string-length(normalize-space(node()))]">
            <xsl:attribute name="notBefore" select="../*[contains(name(),$date-type) and ends-with(name(),'_Not_Before') and string-length(normalize-space(node()))]"/>
        </xsl:if>
        <xsl:if test="../*[contains(name(),$date-type) and ends-with(name(),'_Not_After') and string-length(normalize-space(node()))]">
            <xsl:attribute name="notAfter" select="../*[contains(name(),$date-type) and ends-with(name(),'_Not_After') and string-length(normalize-space(node()))]"/>
        </xsl:if>
        
        <!-- <xsl:if test="contains($next-element-name, $date-type)">
            <xsl:if test="string-length(normalize-space($next-element))">
                <xsl:choose>
                    <xsl:when test="contains($next-element-name, '_Begin_Standard')">
                        <xsl:attribute name="from" select="$next-element"/>
                    </xsl:when>
                    <xsl:when test="contains($next-element-name, '_End_Standard')">
                        <xsl:attribute name="to" select="$next-element"/>
                    </xsl:when>
                    <xsl:when test="contains($next-element-name, '_Standard')">
                        <xsl:attribute name="when" select="$next-element"/>
                    </xsl:when>
                    <xsl:when test="contains($next-element-name, '_Not_Before')">
                        <xsl:attribute name="notBefore" select="$next-element"/>
                    </xsl:when>
                    <xsl:when test="contains($next-element-name, '_Not_After')">
                        <xsl:attribute name="notAfter" select="$next-element"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            <xsl:call-template name="date-attributes">
                <xsl:with-param name="date-type" select="$date-type"/>
                <xsl:with-param name="next-element-name" select="name(following-sibling::*[$count + 1])"/>
                <xsl:with-param name="next-element" select="following-sibling::*[$count + 1]"/>
                <xsl:with-param name="count" select="$count + 1"/>
            </xsl:call-template>
        </xsl:if> -->
    </xsl:template>
    
</xsl:stylesheet>