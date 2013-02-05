<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:proj="http://expath.org/ns/project"
                xmlns:file="http://expath.org/ns/file"
                xmlns:zip="http://expath.org/ns/zip"
                exclude-result-prefixes="#all"
                version="2.0">

   <xsl:import href="http://expath.org/ns/file.xsl"/>

   <pkg:import-uri>##none</pkg:import-uri>

   <!--
       See proj:zip-directory($dir).
       
       TODO: Add some other systems as well (Mercurial, Git, etc.)
   -->
   <xsl:param name="proj:directories-to-ignore" as="xs:string+" select="'.~', '.git', '.svn', 'CVS'"/>
   <!--
       The Subversion revision number (or any other source control system).
   -->
   <xsl:param name="proj:revision" as="xs:string?"/>

   <xsl:variable name="proj:project" as="xs:anyURI" select="resolve-uri('..', base-uri(.))"/>
   <xsl:variable name="proj:version" as="xs:string" select="/proj:project/@version"/>

   <xsl:variable name="src"        as="xs:anyURI"  select="resolve-uri('src/', $proj:project)"/>
   <xsl:variable name="xproject"   as="xs:anyURI"  select="resolve-uri('xproject/', $proj:project)"/>
   <xsl:variable name="dist"       as="xs:anyURI"  select="resolve-uri('dist/', $proj:project)"/>
   <xsl:variable name="sample"     as="xs:anyURI"  select="resolve-uri('sample/', $proj:project)"/>
   <xsl:variable name="abbrev"     as="xs:string"  select="/proj:project/@abbrev"/>
   <xsl:variable name="prj-name"   as="xs:string"  select="concat($abbrev, '-', $proj:version)"/>
   <xsl:variable name="is-web"     as="xs:boolean" select="
       exists(file:old-list($xproject)/file:file[@name eq 'expath-web.xml'])"/>
   <xsl:variable name="xar-name" as="xs:string"    select="
       concat($prj-name, if ( $is-web ) then '.xaw' else '.xar')"/>
   <xsl:variable name="xar"        as="xs:anyURI"  select="resolve-uri($xar-name, $dist)"/>
   <xsl:variable name="release"    as="xs:anyURI"  select="
       resolve-uri(concat($prj-name, '.zip'), $dist)"/>
   <xsl:variable name="pkg-ns"     as="xs:string"  select="'http://expath.org/ns/pkg'"/>

   <xsl:function name="proj:display-filename">
      <xsl:param name="file" as="xs:string"/>
      <xsl:sequence select="substring-after($file, $proj:project)"/>
   </xsl:function>

   <xsl:template match="file:dir" mode="zip-dir">
      <xsl:if test="not(@name = $proj:directories-to-ignore)">
         <zip:dir name="{ @name }">
            <xsl:apply-templates select="*" mode="zip-dir"/>
         </zip:dir>
      </xsl:if>
   </xsl:template>

   <xsl:template match="file:file" mode="zip-dir">
      <zip:entry name="{ @name }" src="{ @href }"/>
   </xsl:template>

   <!--
       Ignore directories with their name in proj:directories-to-ignore.
       Typically this parameter is a sequence of name like .svn, CVS, etc.
   -->
   <xsl:function name="proj:zip-directory" as="element(zip:dir)?">
      <xsl:param name="dir" as="xs:anyURI"/>
      <xsl:apply-templates select="file:old-list($dir)" mode="zip-dir"/>
   </xsl:function>

   <!--
       Same as proj:zip-directory(), except it does not copy $dir itself,
       only its content (its children files and dirs).
   -->
   <xsl:function name="proj:zip-directory-content" as="element()*">
      <xsl:param name="dir" as="xs:anyURI"/>
      <xsl:apply-templates select="file:old-list($dir)/*" mode="zip-dir"/>
   </xsl:function>

</xsl:stylesheet>
