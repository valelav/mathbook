<?xml version='1.0'?> <!-- As XML file -->
<!-- Identify as a stylesheet -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xml="http://www.w3.org/XML/1998/namespace"
    xmlns:exsl="http://exslt.org/common"
    xmlns:date="http://exslt.org/dates-and-times"
    extension-element-prefixes="exsl date"
>

<xsl:import href="./mathbook-common.xsl" />
<xsl:import href="./mathbook-html.xsl" />

<!-- Intend output for Python docstring -->
<xsl:output method="text" />

<!-- Whitespace control in text output mode-->
<!-- Forcing newlines with &#xa; : http://stackoverflow.com/questions/723226/producing-a-new-line-in-xslt -->
<!-- Avoiding extra whitespace: http://stackoverflow.com/questions/1468984/xslt-remove-whitespace-from-template -->

<xsl:template match="/mathbook">
    <xsl:apply-templates mode="structural-to-files" />
</xsl:template>

<xsl:template match="*" mode="structural-to-files">
    <xsl:variable name="structural">
        <xsl:apply-templates select="." mode="is-structural" />
    </xsl:variable>
    <!-- If not structural, we can't expect a coherent selection of Sage cells -->
    <xsl:if test="$structural='true'">
        <!-- Investigate characteristics relative to chunking and webpage construction -->
        <xsl:variable name="webpage">
            <xsl:apply-templates select="." mode="is-webpage" />
        </xsl:variable>
        <xsl:variable name="summary">
            <xsl:apply-templates select="." mode="is-summary" />
        </xsl:variable>
        <xsl:if test="$webpage='true' or $summary='true'">
            <!-- Construct the tests, if any -->
            <xsl:variable name="tests">
                <!-- Webpage nodes are big Sage sessions, delve as deep as necessary -->
                <xsl:if test="$webpage='true'">
                    <xsl:apply-templates select=".//sage" />
                </xsl:if>
                <!-- Examine non-structural parts of summary pages for Sage-->
                <xsl:if test="$summary='true'">
                    <xsl:apply-templates select="introduction/sage" mode="structural-to-files" />
                </xsl:if>
            </xsl:variable>
            <!-- Write a file, if there is something to write -->
            <xsl:if test="$tests!=''">
                <xsl:variable name="filename">
                    <xsl:apply-templates select="." mode="internal-id" />
                    <xsl:text>.py</xsl:text>
                </xsl:variable>
                <exsl:document href="{$filename}" method="text">
                    <xsl:call-template name="doctest-file-header" />
                    <xsl:text>## </xsl:text>
                    <xsl:apply-templates select="." mode="type-name" />
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="." mode="number" />
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="title" />
                    <xsl:text>&#xa;</xsl:text>
                    <xsl:text>##&#xa;</xsl:text>
                    <xsl:text>r"""&#xa;</xsl:text>
                    <xsl:value-of select="$tests" />
                    <xsl:text>"""&#xa;</xsl:text>
                </exsl:document>
            </xsl:if>
            <!-- Recurse into summary node subdivisions -->
            <!-- Non-structural quickly get found out and no file is written -->
            <xsl:if test="$summary='true'">
                <xsl:apply-templates mode="structural-to-files" />
            </xsl:if>
        </xsl:if>
    </xsl:if>
</xsl:template>

<!-- Just handle "copy" Sage blocks the same way as others -->
<xsl:template match="sage[@copy]">
    <xsl:apply-templates select="id(@copy)" />
</xsl:template>

<!-- Totally kill a display block, cannot depend on it, etc -->
<xsl:template match="sage[@type='display']" />

<!-- Totally kill a practice block, it is uninteresting -->
<xsl:template match="sage[@type='practice']" />

<!-- "Normal" Sage blocks, including invisible -->
<!-- Form doctring/ReST verbatim block         -->
<!-- for one input/output pair                 -->
<xsl:template match="sage">
    <xsl:text>~~~~~~~~~~~~~~~~~~~~~~ ::&#xA;&#xA;</xsl:text>
    <xsl:apply-templates select="input" />
    <xsl:apply-templates select="output" />
    <xsl:text>&#xA;</xsl:text>
</xsl:template>

<!-- Options to doctesting -->
<!-- A property of the Sage element,         -->
<!-- but employed in processing input        -->
<!-- Returns: necessary string, no adornment -->
<xsl:template match="sage" mode="doctest-marker">
    <xsl:if test="@doctest">
        <xsl:choose>
            <xsl:when test="@doctest='random'">
                <xsl:text>random</xsl:text>
            </xsl:when>
            <xsl:when test="@doctest='long time'">
                <xsl:text>long time</xsl:text>
            </xsl:when>
            <xsl:when test="@doctest='not implemented'">
                <xsl:text>not implemented</xsl:text>
            </xsl:when>
            <xsl:when test="@doctest='not tested'">
                <xsl:text>not tested</xsl:text>
            </xsl:when>
            <xsl:when test="@doctest='known bug'">
                <xsl:text>known bug</xsl:text>
            </xsl:when>
            <!-- absolute and relative floating point need literal tolerance -->
            <xsl:when test="@doctest='absolute' or @doctest='relative'">
                <xsl:choose>
                    <xsl:when test="@doctest='absolute'">
                        <xsl:text>absolute</xsl:text>
                    </xsl:when>
                    <xsl:when test="@doctest='relative'">
                        <xsl:text>relative</xsl:text>
                    </xsl:when>
                </xsl:choose>
                <xsl:text> tolerance </xsl:text>
                <xsl:choose>
                    <xsl:when test="@tolerance">
                        <xsl:value-of select="@tolerance" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>MBX:WARNING: '<xsl:value-of select="@doctest" /> tolerance' Sage doctest needs 'tolerance=' attribute</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- 'optional' indicates an optional package is needed for the test -->
            <xsl:when test="@doctest='optional'">
                <xsl:text>optional</xsl:text>
                <xsl:choose>
                    <xsl:when test="@package">
                        <xsl:text>: </xsl:text>
                        <xsl:value-of select="@package" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>MBX:WARNING: 'optional' Sage doctest missing package, supply a 'package=' attribute</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:if>
</xsl:template>

<!-- Sanitize input block       -->
<!-- Add in 4-space indentation -->
<!-- and Sage prompts, then     -->
<!-- add Sage doctest markers   -->
<xsl:template match="input">
    <xsl:variable name="input-block">
        <xsl:call-template name="prepend-prompt">
            <xsl:with-param name="text">
                <xsl:call-template name="sanitize-sage" >
                    <xsl:with-param name="raw-sage-code" select="." />
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:variable>
    <!-- Construct an option marker, perhaps empty -->
    <xsl:variable name="doctest-marker">
        <xsl:apply-templates select=".." mode="doctest-marker" />
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$doctest-marker!=''">
            <!-- Locate pieces relative to: end of first line of last input command -->
            <xsl:variable name="before-last-sage">
                <xsl:call-template name="substring-before-last">
                    <xsl:with-param name="input"  select="$input-block" />
                    <xsl:with-param name="substr" select="'sage:'" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="after-last-sage">
                <xsl:call-template name="substring-after-last">
                    <xsl:with-param name="input"  select="$input-block" />
                    <xsl:with-param name="substr" select="'sage:'" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="before-eol" select="substring-before($after-last-sage, '&#xa;')" />
            <xsl:variable name="after-eol"  select="substring-after($after-last-sage, '&#xa;')" />
            <!-- Back in its box, with markers and doctest marker -->
            <xsl:value-of select="$before-last-sage" />
            <xsl:text>sage:</xsl:text>
            <xsl:value-of select="$before-eol" />
            <xsl:text>   # </xsl:text>
            <xsl:value-of select="$doctest-marker" />
            <xsl:text>&#xa;</xsl:text>
            <xsl:value-of select="$after-eol" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$input-block" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- Sanitize output block      -->
<!-- Add in 4-space indentation -->
<xsl:template match="output">
    <xsl:call-template name="add-indentation">
        <xsl:with-param name="text">
            <xsl:call-template name="sanitize-sage" >
                <xsl:with-param name="raw-sage-code" select="." />
            </xsl:call-template>
        </xsl:with-param>
        <xsl:with-param name="indent" select="'    '" />
    </xsl:call-template>
</xsl:template>

<!-- Doctest specific template, others are in common XSL file -->
<xsl:template name="prepend-prompt">
    <xsl:param name="text" />
    <!-- Just quit when string becomes empty -->
    <xsl:if test="string-length($text)">
        <xsl:variable name="first-line" select="substring-before($text, '&#xA;')" />
        <xsl:choose>
            <!-- blank lines are treated as continuation -->
            <!-- could be important content of triply-quoted strings? -->
            <!-- no harm if really just spacing at totally out-dented level? -->
            <xsl:when test="not(string-length($first-line))">
                <xsl:text>    ....: </xsl:text>
            </xsl:when>
            <!-- leading blank indicates continuation -->
            <xsl:when test="substring($first-line,1,1)=' '">
                <xsl:text>    ....: </xsl:text>
            </xsl:when>
            <!-- otherwise, totally outdented, needs sage prompt -->
            <xsl:otherwise>
                <xsl:text>    sage: </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$first-line"/>
        <xsl:text>&#xA;</xsl:text>
        <!-- recursive call on remainder of string -->
        <xsl:call-template name="prepend-prompt">
            <xsl:with-param name="text" select="substring-after($text, '&#xA;')"/>
        </xsl:call-template>
    </xsl:if>
</xsl:template>

<xsl:template name="doctest-file-header">
    <xsl:text>##          Sage Doctest File         ##&#xa;</xsl:text>
    <xsl:call-template name="converter-blurb" />
    <xsl:text>##&#xa;</xsl:text>
    <xsl:text>## To execute doctests in these files, run&#xa;</xsl:text>
    <xsl:text>##   $ $SAGE_ROOT/sage -t &lt;directory-of-these-files&gt;&#xa;</xsl:text>
    <xsl:text>## or&#xa;</xsl:text>
    <xsl:text>##   $ $SAGE_ROOT/sage -t &lt;a-single-file&gt;&#xa;</xsl:text>
    <xsl:text>##&#xa;</xsl:text>
    <xsl:text>## Replace -t by "-tp n" for parallel testing,&#xa;</xsl:text>
    <xsl:text>##   "-tp 0" will use a sensible number of threads&#xa;</xsl:text>
    <xsl:text>##&#xa;</xsl:text>
    <xsl:text>## See: http://www.sagemath.org/doc/developer/doctesting.html&#xa;</xsl:text>
    <xsl:text>##   or run  $ $SAGE_ROOT/sage --advanced  for brief help&#xa;</xsl:text>
    <xsl:text>##&#xa;</xsl:text>
</xsl:template>

<xsl:template name="converter-blurb">
    <xsl:text>##                                    ##&#xa;</xsl:text>
    <xsl:text>## Generated from MathBook XML source ##&#xa;</xsl:text>
    <xsl:text>##    on </xsl:text>
    <xsl:value-of select="date:date-time()" />
    <xsl:text>    ##&#xa;</xsl:text>
    <xsl:text>##                                    ##&#xa;</xsl:text>
    <xsl:text>##   http://mathbook.pugetsound.edu   ##&#xa;</xsl:text>
    <xsl:text>##                                    ##&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>