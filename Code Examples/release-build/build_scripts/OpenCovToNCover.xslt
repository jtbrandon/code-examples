<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" indent="yes" standalone="yes"/>
  <xsl:template match="/CoverageSession/Modules">
    <coverage>
      <xsl:for-each select="Module[not(@skippedDueTo)]">
        <module name="{ModuleName}">
          <xsl:for-each select="Classes/Class">
            <xsl:if test="count(Methods/Method) &gt; 0">
              <class name="{FullName}">
                <xsl:variable name="className" select="FullName" />
                <xsl:for-each select="Methods/Method">
                  <method class="{$className}">
                    <xsl:for-each select="SequencePoints/SequencePoint">
                      <seqpnt visitcount="{@vc}" />
                    </xsl:for-each>
                  </method>
                </xsl:for-each>
              </class>
            </xsl:if>
          </xsl:for-each>
        </module>
      </xsl:for-each>
    </coverage>
  </xsl:template>
</xsl:stylesheet>
