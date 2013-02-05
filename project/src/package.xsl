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

   <pkg:import-uri>http://expath.org/ns/project/package.xsl</pkg:import-uri>

   <xsl:output method="text"/>

   <xsl:template match="/">
      <xsl:message>
         <xsl:text>Building project </xsl:text>
         <xsl:value-of select="$proj:project"/>
      </xsl:message>
      <xsl:variable name="zip" as="element(zip:file)">
         <zip:file href="{ $xar }">
            <!-- the package descriptor -->
            <zip:entry name="expath-pkg.xml" method="xml" indent="yes">
               <xsl:apply-templates select="*" mode="proj:pkg"/>
            </zip:entry>
            <!-- the webapp descriptor if any -->
            <xsl:if test="file:old-list($xproject)/file:file[@name eq 'expath-web.xml']">
               <zip:entry src="{ resolve-uri('expath-web.xml', $xproject) }"/>
            </xsl:if>
            <!-- the CXAN descriptor if any -->
            <!-- TODO: Generate it from xproject/project.xml. -->
            <xsl:if test="file:old-list($xproject)/file:file[@name eq 'cxan.xml']">
               <zip:entry src="{ resolve-uri('cxan.xml', $xproject) }"/>
            </xsl:if>
            <!-- the Saxon descriptor if any -->
            <xsl:if test="file:old-list($xproject)/file:file[@name eq 'saxon.xml']">
               <zip:entry src="{ resolve-uri('saxon.xml', $xproject) }"/>
            </xsl:if>
            <!-- the content of src/ is the package content -->
            <zip:dir name="content">
               <xsl:sequence select="proj:zip-directory-content($src)"/>
            </zip:dir>
         </zip:file>
      </xsl:variable>
      <xsl:variable name="final-zip" as="element(zip:file)">
         <xsl:apply-templates select="$zip" mode="proj:modify-package"/>
      </xsl:variable>
      <xsl:sequence select="zip:zip-file($final-zip)"/>
      <xsl:message>
         <xsl:text>Generated </xsl:text>
         <xsl:sequence select="if ( $is-web ) then 'XAW' else 'XAR'"/>
         <xsl:text> file </xsl:text>
         <xsl:value-of select="proj:display-filename($xar)"/>
      </xsl:message>
   </xsl:template>

   <!--
       The default implem just returns itself; to be overriden in a
       specific project, if needed.
   -->
   <xsl:template match="zip:file" mode="proj:modify-package">
      <xsl:sequence select="."/>
   </xsl:template>

   <xsl:template match="proj:*" mode="proj:pkg">
      <xsl:element name="{ local-name(.) }" namespace="{ $pkg-ns }">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="proj:pkg"/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="proj:project" mode="proj:pkg">
      <xsl:element name="package" namespace="{ $pkg-ns }">
         <xsl:attribute name="spec" select="'1.0'"/>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="proj:pkg"/>
         <xsl:apply-templates select="file:old-list($src)/*" mode="proj:pkg"/>
      </xsl:element>
   </xsl:template>

   <xsl:template match="file:dir" mode="proj:pkg">
      <xsl:apply-templates select="*" mode="proj:pkg"/>
   </xsl:template>

   <xsl:template match="file:file" mode="proj:pkg">
      <xsl:choose>
         <!-- FIXME: TODO: ... !!! -->
         <!--xsl:when test="@name = ('servlets.xsl', 'webpage.xsl', 'xqts-suite.xsl')">
            <xsl:apply-templates select="." mode="proj:handle-xslt"/>
         </xsl:when-->
         <xsl:when test="ends-with(@name, '.xsl')">
            <xsl:apply-templates select="." mode="proj:handle-xslt"/>
         </xsl:when>
         <xsl:when test="ends-with(@name, '.xq')">
            <xsl:apply-templates select="." mode="proj:handle-main-query"/>
         </xsl:when>
         <xsl:when test="ends-with(@name, '.xql') or ends-with(@name, '.xqm')">
            <xsl:apply-templates select="." mode="proj:handle-query-lib"/>
         </xsl:when>
         <xsl:when test="ends-with(@name, '.xpl') or ends-with(@name, '.xproc')">
            <xsl:apply-templates select="." mode="proj:handle-xproc"/>
         </xsl:when>
      </xsl:choose>
   </xsl:template>

   <!--
       By construction, we know the file exists (we got the name from
       file:old-list()).  If it is "not available", that means there was
       some kind of parsing error.  We prevent this this error to
       occur and we emit a warning instead.
   -->
   <xsl:template match="file:file[not(doc-available(@href))]" priority="10"
                 mode="proj:handle-xslt proj:handle-xproc">
      <xsl:message>
         <xsl:text>Warning: Parsing error in an XML component</xsl:text>
         <xsl:text>&#10;  at </xsl:text>
         <xsl:value-of select="proj:display-filename(@href)"/>
      </xsl:message>
   </xsl:template>

   <!--
       Same reasoning than the above template rule.  Except that I am
       not sure what would mean such an error here (because there is
       no parsing involve, just accessing the file as text).  Anyway,
       we prevent any error to occur and emit a warning instead.
   -->
   <xsl:template match="file:file[not(unparsed-text-available(@href))]" priority="10"
                 mode="proj:handle-main-query proj:handle-query-lib">
      <xsl:message>
         <xsl:text>Warning: Error accessing a textual component</xsl:text>
         <xsl:text>&#10;  at </xsl:text>
         <xsl:value-of select="proj:display-filename(@href)"/>
      </xsl:message>
   </xsl:template>

   <xsl:template match="file:file" mode="proj:handle-xslt">
      <xsl:variable name="uri" as="xs:string?" select="doc(@href)/*/pkg:import-uri/string(.)"/>
      <xsl:choose>
         <!-- TODO: Should probably use a specific attribute on the pkg:import-uri
              element in the stylesheet, for that purpose...?  Maybe tagging the
              file as 'private' to not include it in the package descriptor and
              not emit a warning neither... -->
         <xsl:when test="$uri eq '#none'">
            <!-- ignore -->
         </xsl:when>
         <xsl:when test="exists($uri)">
            <xsl:element name="xslt" namespace="{ $pkg-ns }">
               <xsl:element name="import-uri" namespace="{ $pkg-ns }">
                  <xsl:value-of select="$uri"/>
               </xsl:element>
               <xsl:element name="file" namespace="{ $pkg-ns }">
                  <xsl:value-of select="proj:resolve-from-src(@href)"/>
               </xsl:element>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message>
               <xsl:text>Warning: XSLT stylesheet has no public import URI</xsl:text>
               <xsl:text>&#10;  at </xsl:text>
               <xsl:value-of select="proj:display-filename(@href)"/>
            </xsl:message>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="file:file" mode="proj:handle-main-query">
      <xsl:variable name="uri" as="xs:string?" select="
          proj:match-first-line(@href, '\(:\s+import\s+uri:\s+(.+)\s+:\)')"/>
      <xsl:choose>
         <xsl:when test="$uri eq '#none'">
            <!-- ignore -->
         </xsl:when>
         <xsl:when test="exists($uri)">
            <xsl:element name="xquery" namespace="{ $pkg-ns }">
               <xsl:element name="import-uri" namespace="{ $pkg-ns }">
                  <xsl:value-of select="$uri"/>
               </xsl:element>
               <xsl:element name="file" namespace="{ $pkg-ns }">
                  <xsl:value-of select="proj:resolve-from-src(@href)"/>
               </xsl:element>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message>
               <xsl:text>Warning: XQuery main module has no public import URI</xsl:text>
               <xsl:text>&#10;  at </xsl:text>
               <xsl:value-of select="proj:display-filename(@href)"/>
            </xsl:message>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="file:file" mode="proj:handle-query-lib">
      <xsl:variable name="uri-re" select="
          '\s*module\s+namespace\s+[-_a-zA-Z0-9]+\s*=\s*&quot;([^&quot;]+)&quot;.+'"/>
      <!--xsl:variable name="uri" as="xs:string?" select="
          proj:match-first-line(@href, '\(:\s+target\s+namespace:\s+(.+)\s+:\)')"/-->
      <xsl:variable name="uri" as="xs:string?" select="proj:match-first-line(@href, $uri-re)"/>
      <xsl:choose>
         <xsl:when test="$uri eq '#none'">
            <!-- ignore -->
         </xsl:when>
         <xsl:when test="$uri">
            <xsl:element name="xquery" namespace="{ $pkg-ns }">
               <xsl:element name="namespace" namespace="{ $pkg-ns }">
                  <xsl:value-of select="$uri"/>
               </xsl:element>
               <xsl:element name="file" namespace="{ $pkg-ns }">
                  <xsl:value-of select="proj:resolve-from-src(@href)"/>
               </xsl:element>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message>
               <xsl:text>Warning: XQuery library module has no target namespace URI</xsl:text>
               <xsl:text>&#10;  at </xsl:text>
               <xsl:value-of select="proj:display-filename(@href)"/>
            </xsl:message>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="file:file" mode="proj:handle-xproc">
      <xsl:variable name="uri" as="xs:string?" select="doc(@href)/*/@pkg:import-uri/string(.)"/>
      <xsl:choose>
         <!-- TODO: Should probably use a specific attribute on the pkg:import-uri
              element in the stylesheet, for that purpose...? -->
         <xsl:when test="$uri eq '#none'">
            <!-- ignore -->
         </xsl:when>
         <xsl:when test="exists($uri)">
            <xsl:element name="xproc" namespace="{ $pkg-ns }">
               <xsl:element name="import-uri" namespace="{ $pkg-ns }">
                  <xsl:value-of select="$uri"/>
               </xsl:element>
               <xsl:element name="file" namespace="{ $pkg-ns }">
                  <xsl:value-of select="proj:resolve-from-src(@href)"/>
               </xsl:element>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:message>
               <xsl:text>Warning: XProc pipeline has no public import URI</xsl:text>
               <xsl:text>&#10;  at </xsl:text>
               <xsl:value-of select="proj:display-filename(@href)"/>
            </xsl:message>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:function name="proj:resolve-from-src" as="xs:string">
      <xsl:param name="href" as="xs:string"/>
      <xsl:sequence select="substring($href, string-length($src) + 1)"/>
   </xsl:function>

   <xsl:function name="proj:match-first-line" as="xs:string?">
      <xsl:param name="href"  as="xs:string"/>
      <xsl:param name="regex" as="xs:string"/>
      <xsl:variable name="first-line" select="
          substring-before(unparsed-text($href), '&#10;')"/>
      <xsl:sequence select="
          if ( matches($first-line, $regex) ) then
            replace($first-line, $regex, '$1')
          else
            ()"/>
   </xsl:function>

</xsl:stylesheet>
