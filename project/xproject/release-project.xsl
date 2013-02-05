<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:proj="http://expath.org/ns/project"
                xmlns:zip="http://expath.org/ns/zip"
                exclude-result-prefixes="#all"
                version="2.0">

   <xsl:import href="http://expath.org/ns/project/release.xsl"/>

   <!-- The overload point. -->
   <xsl:template match="zip:file" mode="proj:modify-release">
      <xsl:apply-templates select="." mode="add-bin"/>
   </xsl:template>

   <!-- Copy everything... -->
   <xsl:template match="node()" mode="add-bin">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="node()" mode="add-bin"/>
      </xsl:copy>
   </xsl:template>

   <!-- ...and add the bin dir. -->
   <xsl:template match="zip:file/zip:dir" mode="add-bin">
      <xsl:copy>
         <!-- copy the existing -->
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates select="node()" mode="add-bin"/>
         <!-- the 'bin' dir, absolute, resolved from the project's dir -->
         <xsl:variable name="dir" select="resolve-uri('bin/', $proj:project)"/>
         <!-- recurse in 'specs' and create the appropriate zip:file elements -->
         <xsl:sequence select="proj:zip-directory($dir)"/>
      </xsl:copy>
   </xsl:template>

</xsl:stylesheet>
