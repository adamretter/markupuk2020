<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    
    <xsl:template match="reports">
        <html>
            <head>
                <title>Covid 19 Deaths vs HHS Payments</title>
            </head>
            <h1>Covid 19 Deaths vs HHS Funding</h1>
            <table border="1">
                <thead>
                    <tr>
                        <th scope="col" colspan="2">Highest % Deaths</th>
                        <th style="padding-left: 2em"></th>
                        <th scope="col" colspan="2">Highest % HHS Payments</th>
                    </tr>
                    <tr>
                        <th>State</th>
                        <th>Covid 19 Deaths</th>
                        <th></th>
                        <th>State</th>
                        <th>HHS Payment</th>
                    </tr>
                </thead>
                <tbody>
                    <xsl:variable name="report1" select="report[@id eq '1']"/>
                    <xsl:variable name="report2" select="report[@id eq '2']"/>
                    <xsl:for-each select="(1 to count($report1/states/state))">
                        <xsl:variable name="idx" select="."/>
                        <tr>
                            <td><xsl:value-of select="$report1/states/state[$idx]/name"/></td>
                            <td><xsl:value-of select="$report1/states/state[$idx]/covid19-deaths/@percentage-of-usa"/>% (<xsl:value-of select="$report1/states/state[$idx]/covid19-deaths"/>)</td>
                            
                            <td></td>
                            
                            <td><xsl:value-of select="$report2/states/state[$idx]/name"/></td>
                            <td><xsl:value-of select="$report2/states/state[$idx]/hhs-payments/@percentage-of-usa"/>% ($ <xsl:value-of select="$report1/states/state[$idx]/hhs-payments"/>)</td>
                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
        </html>
    </xsl:template>
    
    <xsl:template match="report[@id eq '1']">
        
    </xsl:template>
    
    <xsl:template match="report[@id eq '2']">
    </xsl:template>
    
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>