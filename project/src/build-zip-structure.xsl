<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                version="2.0">

   <!--
       Context node for the transform: a document node with "c:directory" as the
       root element.  This is defined in p:directory-list, plus recursion in
       sub-directories, for the record something like:
       
           <c:directory name="src">
              <c:file name="page.xsl"/>
              <c:file name="driver.xproc"/>
              <c:directory name="pages">
                 <c:file name="uno.xml"/>
                 <c:file name="dos.xml"/>
                 <c:file name="tres.xml"/>
              </c:directory>
           </c:directory>
       
       The default collection contains, in first position the context node of
       course, and in second position (optional) a document node with "manifest"
       as the root element.  This corresponds to what is recieved on the port
       "manifest" in the pipeline "proj:build", for the record something like:
       
           <manifest>
              <entry name="extra-engine.xml"       href="../xproject/extra-engine.xml"/>
              <entry name="content/extra-file.xml" href="/some/place/file.xml"/>
              <entry name="content/override.xsl"   href="override.xsl"/>
              <entry name="content/generated.xml"  href="http://example.org/some-name.xml"/>
           </manifest>
       
       The output is a ZIP manifest, as accepted by pxp:zip, for the record
       something like:
       
           <c:zip-manifest>
              <c:entry name="..." href="..."/>
              <c:entry name="..." href="..."/>
           </c:zip-manifest>
       
       No entry for the directories.  The entries derived from the context
       document are prefixed with "content/" (because the top-level c:directory
       corresponds to src/).  The entries derived from the secondary input (from
       the port "manifest") are not prefixed.  If there is an entry in the port
       "manifest" with the same name as from the primary input, the former
       overrides the latter.
   -->

   <xsl:variable name="manifest" select="collection()[2]/*" as="element(manifest)?"/>

   <xsl:variable name="overrides" select="$manifest/entry/@name" as="xs:string*"/>

   <xsl:template match="/*" priority="-1">
      <xsl:sequence select="error((), concat('Unexpected root element: ', name(.)))"/>
   </xsl:template>

   <xsl:template match="*" priority="-2">
      <xsl:sequence select="error((), concat('Unexpected element: ', name(.)))"/>
   </xsl:template>

   <xsl:template match="/c:directory">
      <c:zip-manifest>
         <xsl:apply-templates select="$manifest/entry">
            <xsl:with-param name="base" select="@xml:base"/>
         </xsl:apply-templates>
         <xsl:apply-templates select="*">
            <xsl:with-param name="path" select="'content/'"/>
            <xsl:with-param name="href" select="@xml:base"/>
         </xsl:apply-templates>
      </c:zip-manifest>
   </xsl:template>

   <xsl:template match="entry">
      <xsl:param name="base" as="xs:anyURI"/>
      <xsl:variable name="href" select="resolve-uri(@href, $base)"/>
      <c:entry name="{ @name }" href="{ $href }"/>
   </xsl:template>

   <xsl:template match="c:directory">
      <xsl:param name="path" as="xs:string"/>
      <xsl:param name="href" as="xs:anyURI"/>
      <xsl:variable name="p" select="concat($path, @name, '/')"/>
      <xsl:variable name="h" select="resolve-uri(concat(@name, '/'), $href)"/>
      <xsl:apply-templates select="*">
         <xsl:with-param name="path" select="$p"/>
         <xsl:with-param name="href" select="$h"/>
      </xsl:apply-templates>
   </xsl:template>

   <xsl:template match="c:file">
      <xsl:param name="path" as="xs:string"/>
      <xsl:param name="href" as="xs:anyURI"/>
      <xsl:variable name="p" select="concat($path, @name)"/>
      <xsl:variable name="h" select="resolve-uri(@name, $href)"/>
      <xsl:if test="not($p = $overrides)">
         <c:entry name="{ $p }" href="{ $h }"/>
      </xsl:if>
   </xsl:template>

</xsl:stylesheet>
