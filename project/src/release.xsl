<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:proj="http://expath.org/ns/project"
                xmlns:file="http://expath.org/ns/file"
                xmlns:zip="http://expath.org/ns/zip"
                exclude-result-prefixes="#all"
                version="2.0">

   <xsl:import href="library.xsl"/>

   <xsl:import href="http://expath.org/ns/zip.xsl"/>

   <pkg:import-uri>http://expath.org/ns/project/release.xsl</pkg:import-uri>

   <xsl:output method="text"/>

   <xsl:template match="/">
      <xsl:message>
         <xsl:text>Releasing project </xsl:text>
         <xsl:value-of select="$proj:project"/>
      </xsl:message>
      <xsl:variable name="zip" as="element(zip:file)">
         <zip:file href="{ $release }">
            <zip:dir name="{ $prj-name }">
               <!-- the package -->
               <zip:entry src="{ $xar }"/>
               <!-- the version file -->
               <zip:entry name="VERSION" method="text">
                  <xsl:text>Version: </xsl:text>
                  <xsl:value-of select="$proj:version"/>
                  <xsl:if test="$proj:revision">
                     <xsl:text>&#10;Revision: </xsl:text>
                     <xsl:value-of select="$proj:revision"/>
                  </xsl:if>
                  <xsl:text>&#10;</xsl:text>
               </zip:entry>
               <!-- the README file if any -->
               <xsl:if test="file:old-list($xproject)/file:file[@name eq 'README']">
                  <zip:entry src="{ resolve-uri('README', $xproject) }"/>
               </xsl:if>
               <!-- a copy of src/ -->
               <xsl:sequence select="proj:zip-directory($src)"/>
               <!-- a copy of sample/ -->
               <xsl:sequence select="proj:zip-directory($sample)"/>
            </zip:dir>
         </zip:file>
      </xsl:variable>
      <xsl:variable name="final-zip" as="element(zip:file)">
         <xsl:apply-templates select="$zip" mode="proj:modify-release"/>
      </xsl:variable>
      <xsl:sequence select="zip:zip-file($final-zip)"/>
      <xsl:message>
         <xsl:text>Generated ZIP release file </xsl:text>
         <xsl:value-of select="proj:display-filename($release)"/>
      </xsl:message>
   </xsl:template>

   <!--
       The default implem just returns itself; to be overriden in a
       specific project, if needed.
   -->
   <xsl:template match="zip:file" mode="proj:modify-release">
      <xsl:sequence select="."/>
   </xsl:template>

</xsl:stylesheet>
