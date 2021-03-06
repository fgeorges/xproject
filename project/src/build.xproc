<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:proj="http://expath.org/ns/project"
                xmlns:pxp="http://exproc.org/proposed/steps"
                xmlns:h="http://www.w3.org/1999/xhtml"
                pkg:import-uri="http://expath.org/ns/project/build.xproc"
                name="pipeline"
                exclude-inline-prefixes="p cx xsl pkg pxp"
                version="1.0"
                type="proj:build">

   <p:documentation>
      <p>Run on the project descriptor, create a package in dist/.</p>
   </p:documentation>

   <p:input port="source" primary="true">
      <p:documentation>
         <p>The xproject/project.xml descriptor.</p>
      </p:documentation>
   </p:input>

   <p:input port="files" sequence="true">
      <p:documentation>
         <p>Additional or overloading files in the XAR.</p>
      </p:documentation>
   </p:input>

   <p:input port="manifest" sequence="true">
      <p:documentation>
         <p>An optional document of the form:</p>
         <pre><![CDATA[<manifest>
   <entry name="extra-engine.xml"       href="../xproject/extra-engine.xml"/>
   <entry name="content/extra-file.xml" href="/some/place/file.xml"/>
   <entry name="content/override.xsl"   href="override.xsl"/>
   <entry name="content/generated.xml"  href="http://example.org/some-name.xml"/>
</manifest>]]></pre>
         <p>@name is the entry name in the final XAR file.  For instance, the
            first entry above places an extra descriptor at the root, and the
            other entries add files within the content dir.</p>
         <p>@href is the base URI of a document in the port "files".  If it is
            relative, it is resolved against the project src/ directory.  For
            instance, the first entry above refers to a file in the xproject/
            dircetory (resolved from within src/, so needs '../').  The second
            and third entries also resolve against src/ (either from the file
            system root, or within the same dir).  The last entry refers to an
            absolute HTTP URI, which is just a name, and a document with the
            same base URI must be in the port "files" (useful if the file has
            been generated, so the base URI is set explicitly).</p>
         <p>If an entry has the same name as one entry automatically generated
            from src/, it then overrides it.  In this case, the entry is not
            necessary (just add the overriding document to the port "files",
            with the correct base URI, is enough).</p>
      </p:documentation>
   </p:input>

   <p:input port="parameters" primary="true" kind="parameter">
      <p:documentation>
         <p>The parameters.</p>
      </p:documentation>
   </p:input>

   <p:option name="ignore-dirs" required="false" select="'.~,.git,.svn,CVS'">
      <p:documentation>
         <p>Directories to ignore, comma-separated list of dir names.</p>
      </p:documentation>
   </p:option>

   <p:option name="ignore-components" required="false" select="''">
      <p:documentation>
         <p>Components to ignore, comma-separated list of anchored regexes.</p>
      </p:documentation>
   </p:option>

   <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
   <p:import href="library.xpl"/>

   <p:declare-step type="proj:zip-structure" name="this">
      <p:documentation>
         <p>From the recursive content of src/, build the corresponding ZIP structure.</p>
         <p>The ZIP structure (as expected by pxp:zip) does not include the top-level
            descriptors (like expath-pkg.xml, cxan.xml, etc.)  Only the content from the
            src/ sub-directory.</p>
      </p:documentation>
      <!-- the recursive src/ structure -->
      <p:input  port="source" primary="true"/>
      <!-- the extra entries, from the port "manifest" on "pipeline", optional -->
      <p:input  port="manifest" sequence="true"/>
      <!-- the corresponding zip structure (to pass to pxp:zip) -->
      <p:output port="result" primary="true"/>
      <p:xslt>
         <p:input port="source">
            <p:pipe step="this" port="source"/>
            <p:pipe step="this" port="manifest"/>
         </p:input>
         <p:input port="stylesheet">
            <p:document href="build-zip-structure.xsl"/>
         </p:input>
         <p:input port="parameters">
            <p:empty/>
         </p:input>
      </p:xslt>
   </p:declare-step>

   <p:declare-step type="proj:add-extension-entry" name="this">
      <p:documentation>
         <p>Add one of the descriptors in xproject/ to the ZIP structure.</p>
         <p>The descriptor is added at the root of the ZIP file, and at the beginning.
            This step does not generate the package descriptor, just adds a fixed file
            stored in the xproject/ private directory.</p>
      </p:documentation>
      <!-- the zip structure -->
      <p:input  port="source" primary="true"/>
      <!-- the augmented zip structure -->
      <p:output port="result" primary="true"/>
      <!-- the extension descriptor file name -->
      <p:option name="desc-name" required="true"/>
      <!-- the xproject/ dir -->
      <p:option name="private-dir" required="true"/>
      <p:directory-list>
         <p:with-option name="path" select="$private-dir"/>
      </p:directory-list>
      <p:choose>
         <p:when test="/*/c:file[@name eq $desc-name]">
            <p:add-attribute match="/*" attribute-name="name">
               <p:with-option name="attribute-value" select="$desc-name"/>
               <p:input port="source">
                  <p:inline><c:entry/></p:inline>
               </p:input>
            </p:add-attribute>
            <p:add-attribute match="/*" attribute-name="href" name="entry">
               <p:with-option name="attribute-value" select="resolve-uri($desc-name, $private-dir)"/>
            </p:add-attribute>
            <p:insert position="first-child">
               <p:input port="source">
                  <p:pipe step="this" port="source"/>
               </p:input>
               <p:input port="insertion">
                  <p:pipe step="entry" port="result"/>
               </p:input>
            </p:insert>
         </p:when>
         <p:otherwise>
            <p:identity>
               <p:input port="source">
                  <p:pipe step="this" port="source"/>
               </p:input>
            </p:identity>
         </p:otherwise>
      </p:choose>
   </p:declare-step>

   <p:declare-step type="proj:generate-pkg-desc" name="this">
      <p:documentation>
         <p>From the recursive content of src/ and the project descriptor, generate
            the expath-pkg.xml descriptor.</p>
      </p:documentation>
      <!-- the project descriptor -->
      <p:input  port="project" primary="true"/>
      <!-- the recursive src/ structure -->
      <p:input  port="sources"/>
      <!-- the package descriptor -->
      <p:output port="result" primary="true"/>
      <!-- components to ignore, comma-separated list of anchored regexes -->
      <p:option name="ignore-components" required="true"/>
      <proj:project-to-pkg-desc name="skeleton"/>
      <proj:component-descriptors path="" name="components">
         <p:with-option name="ignore-components" select="$ignore-components"/>
         <p:input port="source">
            <p:pipe step="this" port="sources"/>
         </p:input>
         <p:with-option name="href" select="/*/@xml:base">
            <p:pipe step="this" port="sources"/>
         </p:with-option>
      </proj:component-descriptors>
      <p:insert match="/*" position="last-child">
         <p:input port="source">
            <p:pipe step="skeleton" port="result"/>
         </p:input>
         <p:input port="insertion">
            <p:pipe step="components" port="result"/>
         </p:input>
      </p:insert>
   </p:declare-step>

   <p:declare-step type="proj:project-to-pkg-desc">
      <p:documentation>
         <p>From the project descriptor, generate a first skeleton of the package
            descriptor (without the components themselves).</p>
      </p:documentation>
      <!-- the project descriptor -->
      <p:input  port="source" primary="true"/>
      <!-- the package descriptor (without components) -->
      <p:output port="result" primary="true"/>
      <!-- TODO: This does not work with pxp:zip?!? -->
      <!--p:xslt output-base-uri="http://expath.org/ns/project/expath-pkg.xml"-->
      <p:xslt>
         <p:input port="stylesheet">
            <p:inline>
               <xsl:stylesheet version="2.0">
                  <xsl:template match="proj:*">
                     <xsl:element name="{ local-name(.) }" namespace="http://expath.org/ns/pkg">
                        <xsl:copy-of select="@*"/>
                        <xsl:apply-templates/>
                     </xsl:element>
                  </xsl:template>
                  <xsl:template match="proj:project">
                     <xsl:element name="package" namespace="http://expath.org/ns/pkg">
                        <xsl:attribute name="spec" select="'1.0'"/>
                        <xsl:copy-of select="@*"/>
                        <xsl:apply-templates select="*"/>
                     </xsl:element>
                  </xsl:template>
                  <!-- Ignore the element "tests".  TODO: Get back here when those extra elements
                       (and other "processor" configs...) are finalized -->
                  <xsl:template match="proj:tests">
                     <!-- ignore -->
                  </xsl:template>
               </xsl:stylesheet>
            </p:inline>
         </p:input>
         <p:input port="parameters">
            <p:empty/>
         </p:input>
      </p:xslt>
   </p:declare-step>

   <p:declare-step type="proj:component-descriptors">
      <p:documentation>
         <p>From the recursive content of a directory (src/ or descendant), generate
            the elements to describe the components in the package descriptor (that
            is, the elements 'xslt', 'xquery', etc. to add to the pkg desc).</p>
      </p:documentation>
      <!-- the recursive src/ structure -->
      <p:input  port="source" primary="true"/>
      <!-- the package descriptor -->
      <p:output port="result" primary="true" sequence="true"/>
      <!-- the path to use in the pkg desc (the start of the path) -->
      <p:option name="path" required="true"/>
      <!-- the real URI to the current dir -->
      <p:option name="href" required="true"/>
      <!-- components to ignore, comma-separated list of anchored regexes -->
      <p:option name="ignore-components" required="true"/>
      <p:for-each name="loop">
         <p:iteration-source select="/*/*"/>
         <p:choose>
            <p:when test="/* instance of element(c:directory)">
               <p:variable name="name"      select="concat(/*/@name, '/')"/>
               <p:variable name="this-href" select="resolve-uri($name, $href)"/>
               <!-- recurse on the dir -->
               <proj:component-descriptors>
                  <p:with-option name="path" select="concat($path, $name)"/>
                  <p:with-option name="href" select="$this-href"/>
                  <p:with-option name="ignore-components" select="$ignore-components"/>
               </proj:component-descriptors>
            </p:when>
            <p:when test="/* instance of element(c:file)">
               <p:variable name="name"      select="/*/@name"/>
               <p:variable name="this-href" select="resolve-uri($name, $href)"/>
               <!--cx:message>
                  <p:with-option name="message" select="
                      concat('debug component:',
                             '&#10;  $path: ', $path,
                             '&#10;  $href: ', $href,
                             '&#10;  $name: ', $name,
                             '&#10;  $this-href: ', $this-href,
                             '&#10;  $ignore-components: ', $ignore-components)"/>
               </cx:message-->
               <p:choose>
                  <p:when test="
                      some $re in tokenize($ignore-components, ',') satisfies
                        matches($name, concat('^', $re, '$'))">
                     <!-- ignore this file -->
                     <p:identity>
                        <p:input port="source">
                           <p:empty/>
                        </p:input>
                     </p:identity>
                  </p:when>
                  <p:otherwise>
                     <!-- handle the file, depending on its type... -->
                     <proj:dispatch-component>
                        <p:with-option name="path" select="concat($path, $name)"/>
                        <p:with-option name="href" select="$this-href"/>
                     </proj:dispatch-component>
                  </p:otherwise>
               </p:choose>
            </p:when>
            <p:otherwise>
               <p:error code="proj:BUILD001">
                  <p:input port="source">
                     <p:pipe step="loop" port="current"/>
                  </p:input>
               </p:error>
            </p:otherwise>
         </p:choose>
      </p:for-each>
   </p:declare-step>

   <p:declare-step type="proj:dispatch-component">
      <p:documentation>
         <p>TODO: ...</p>
      </p:documentation>
      <!-- the descriptor of this one component (or none if not a component) -->
      <p:output port="result" primary="true" sequence="true"/>
      <!-- the path to use in the pkg desc -->
      <p:option name="path" required="true"/>
      <!-- the real URI to the current component -->
      <p:option name="href" required="true"/>
      <!-- TODO: The following message should be generated only with -debug. -->
      <cx:message>
         <p:input port="source">
            <p:empty/>
         </p:input>
         <p:with-option name="message" select="
             concat('Handle component ', $path)"/>
      </cx:message>
      <p:choose>
         <p:when test="ends-with($path, '.xsl') or ends-with($path, '.xslt')">
            <proj:handle-stylesheet>
               <p:with-option name="path" select="$path"/>
               <p:with-option name="href" select="$href"/>
            </proj:handle-stylesheet>
         </p:when>
         <p:when test="ends-with($path, '.xq')
                       or ends-with($path, '.xquery')
                       or ends-with($path, '.xqy')">
            <proj:handle-main-query>
               <p:with-option name="path" select="$path"/>
               <p:with-option name="href" select="$href"/>
            </proj:handle-main-query>
         </p:when>
         <p:when test="ends-with($path, '.xql') or ends-with($path, '.xqm')">
            <proj:handle-query-lib>
               <p:with-option name="path" select="$path"/>
               <p:with-option name="href" select="$href"/>
            </proj:handle-query-lib>
         </p:when>
         <p:when test="ends-with($path, '.xpl') or ends-with($path, '.xproc')">
            <proj:handle-xproc>
               <p:with-option name="path" select="$path"/>
               <p:with-option name="href" select="$href"/>
            </proj:handle-xproc>
         </p:when>
         <p:otherwise>
            <p:identity>
               <p:input port="source">
                  <p:empty/>
               </p:input>
            </p:identity>
         </p:otherwise>
      </p:choose>
   </p:declare-step>

   <p:declare-step type="proj:handle-stylesheet">
      <p:documentation>
         <p>TODO: ...</p>
      </p:documentation>
      <!-- the descriptor of this one component -->
      <p:output port="result" primary="true" sequence="true"/>
      <!-- the path to use in the pkg desc -->
      <p:option name="path" required="true"/>
      <!-- the real URI to the current component -->
      <p:option name="href" required="true"/>
      <p:variable name="uri" select="doc($href)/*/pkg:import-uri/string(.)"/>
      <proj:create-component-descriptor elem-name="xslt">
         <p:with-option name="uri"  select="$uri"/>
         <p:with-option name="path" select="$path"/>
      </proj:create-component-descriptor>
   </p:declare-step>

   <p:declare-step type="proj:handle-main-query">
      <p:documentation>
         <p>TODO: ...</p>
      </p:documentation>
      <!-- the descriptor of this one component -->
      <p:output port="result" primary="true" sequence="true"/>
      <!-- the path to use in the pkg desc -->
      <p:option name="path" required="true"/>
      <!-- the real URI to the current component -->
      <p:option name="href" required="true"/>
      <!-- TODO: This is the only way I am aware of to load data from a dynamic URI.  Gosh! -->
      <p:xslt template-name="main">
         <p:with-param name="href" select="$href"/>
         <p:input port="source">
            <p:empty/>
         </p:input>
         <p:input port="stylesheet">
            <p:inline>
               <xsl:stylesheet version="2.0">
                  <xsl:param name="href" as="xs:string"/>
                  <xsl:template name="main">
                     <c:data>
                        <xsl:value-of select="
                            substring-before(unparsed-text($href), '&#10;')"/>
                     </c:data>
                  </xsl:template>
               </xsl:stylesheet>
            </p:inline>
         </p:input>
      </p:xslt>
      <p:group>
         <p:variable name="first-line" select="string(.)"/>
         <p:variable name="regex"      select="'\(:\s+import\s+uri:\s+(.+)\s+:\)'"/>
         <p:variable name="uri"        select="
             if ( matches($first-line, $regex) ) then
               replace($first-line, $regex, '$1')
             else
               ''"/>
         <proj:create-component-descriptor elem-name="xquery">
            <p:with-option name="uri"  select="$uri"/>
            <p:with-option name="path" select="$path"/>
         </proj:create-component-descriptor>
      </p:group>
   </p:declare-step>

   <p:declare-step type="proj:handle-query-lib">
      <p:documentation>
         <p>TODO: ...</p>
      </p:documentation>
      <!-- the descriptor of this one component -->
      <p:output port="result" primary="true" sequence="true"/>
      <!-- the path to use in the pkg desc -->
      <p:option name="path" required="true"/>
      <!-- the real URI to the current component -->
      <p:option name="href" required="true"/>
      <!-- TODO: This is the only way I am aware of to load data from a dynamic URI.  Gosh! -->
      <!-- If we were using XQuery 3.0, we could use fn:unparsed-text() from within the query. -->
      <p:xslt template-name="main">
         <p:with-param name="href" select="$href"/>
         <p:input port="source">
            <p:empty/>
         </p:input>
         <p:input port="stylesheet">
            <p:inline>
               <xsl:stylesheet version="2.0">
                  <xsl:param name="href" as="xs:string"/>
                  <xsl:template name="main">
                     <c:data>
                        <xsl:value-of select="unparsed-text($href)"/>
                     </c:data>
                  </xsl:template>
               </xsl:stylesheet>
            </p:inline>
         </p:input>
      </p:xslt>
      <p:xquery>
         <p:with-param name="href"  select="$href"/>
         <p:with-param name="query" select="."/>
         <p:input port="source">
            <p:empty/>
         </p:input>
         <p:input port="query">
            <p:inline>
               <c:query>
		  xquery version "1.0";
                  import module namespace p = "xquery-30" at "xquery-parser.xql";
                  declare variable $href  as xs:string external;
                  declare variable $query as xs:string external;
                  let $parse-tree := p:parse-XQuery($query)
                  let $literal    := $parse-tree/Module/LibraryModule/ModuleDecl/URILiteral
                  return
                    &lt;namespace> {
                      (:
                        URILiteral must contain the leading and tailing " chars.  Remove them.
                      :)
		      if ( exists($parse-tree/self::ERROR) ) then
		        error(
			  QName('http://expath.org/ns/project', 'proj:syntax-error'),
			  concat('Syntax error parsing ', $href, ': ', $parse-tree))
                      else if ( starts-with($literal, '"') and ends-with($literal, '"') ) then
                        substring($literal, 2, string-length($literal) - 2)
                      else
                        (: TODO: Or an error instead? :)
                        $literal
                    }
                    &lt;/namespace>
               </c:query>
            </p:inline>
         </p:input>
      </p:xquery>
      <p:group>
         <p:variable name="uri" select="string(.)"/>
         <p:sink/>
         <proj:create-component-descriptor elem-name="xquery" uri-name="namespace">
            <p:with-option name="uri"  select="$uri"/>
            <p:with-option name="path" select="$path"/>
         </proj:create-component-descriptor>
      </p:group>
   </p:declare-step>

   <p:declare-step type="proj:handle-xproc">
      <p:documentation>
         <p>TODO: ...</p>
      </p:documentation>
      <!-- the descriptor of this one component -->
      <p:output port="result" primary="true" sequence="true"/>
      <!-- the path to use in the pkg desc -->
      <p:option name="path" required="true"/>
      <!-- the real URI to the current component -->
      <p:option name="href" required="true"/>
      <p:variable name="uri" select="doc($href)/*/@pkg:import-uri/string(.)"/>
      <proj:create-component-descriptor elem-name="xproc">
         <p:with-option name="uri"  select="$uri"/>
         <p:with-option name="path" select="$path"/>
      </proj:create-component-descriptor>
   </p:declare-step>

   <p:declare-step type="proj:create-component-descriptor">
      <p:documentation>
         <p>TODO: ...</p>
      </p:documentation>
      <!-- the descriptor of this one component -->
      <p:output port="result" primary="true" sequence="true"/>
      <!-- the element name to use for the component in the pkg desc -->
      <p:option name="elem-name" required="true"/>
      <!-- the path to use in the pkg desc to the current component -->
      <p:option name="path" required="true"/>
      <!-- the import URI -->
      <p:option name="uri" required="true"/>
      <!-- the element name to use for the import URI (by default 'import-uri') -->
      <p:option name="uri-name" select="'import-uri'"/>
      <p:identity>
         <p:input port="source">
            <p:empty/>
         </p:input>
      </p:identity>
      <p:choose>
         <!-- TODO: Should probably use another mechanism for that purpose...?
              Maybe tagging the file as 'private' to not include it in the package
              descriptor and not emit a warning neither... -->
         <p:when test="$uri eq '##none'">
            <!-- ignore -->
            <p:identity/>
         </p:when>
         <p:when test="not($uri)">
            <cx:message>
               <p:with-option name="message" select="
                   concat('Warning: Component has no public import URI&#10;  at ', $path)"/>
            </cx:message>
         </p:when>
         <p:otherwise>
            <p:xslt template-name="main">
               <p:with-param name="elem-name" select="$elem-name"/>
               <p:with-param name="path"      select="$path"/>
               <p:with-param name="uri"       select="$uri"/>
               <p:with-param name="uri-name"  select="$uri-name"/>
               <p:input port="stylesheet">
                  <p:inline>
                     <xsl:stylesheet version="2.0">
                        <xsl:param name="elem-name" as="xs:string"/>
                        <xsl:param name="path"      as="xs:string"/>
                        <xsl:param name="uri"       as="xs:string"/>
                        <xsl:param name="uri-name"  as="xs:string"/>
                        <xsl:variable name="ns" select="'http://expath.org/ns/pkg'"/>
                        <xsl:template name="main">
                           <xsl:element name="{ $elem-name }" namespace="{ $ns }">
                              <xsl:element name="{ $uri-name }" namespace="{ $ns }">
                                 <xsl:value-of select="$uri"/>
                              </xsl:element>
                              <xsl:element name="file" namespace="{ $ns }">
                                 <xsl:value-of select="$path"/>
                              </xsl:element>
                           </xsl:element>
                        </xsl:template>
                     </xsl:stylesheet>
                  </p:inline>
               </p:input>
            </p:xslt>
         </p:otherwise>
      </p:choose>
   </p:declare-step>

   <!--
       Several variables extracted from project.xml, and from its base URI.
   -->
   <p:variable name="project-dir"  select="resolve-uri('../', base-uri(/))"/>
   <p:variable name="src-dir"      select="resolve-uri('src/', $project-dir)"/>
   <p:variable name="samples-dir"  select="resolve-uri('samples/', $project-dir)"/>
   <p:variable name="dist-dir"     select="resolve-uri('dist/', $project-dir)"/>
   <p:variable name="private-dir"  select="resolve-uri('xproject/', $project-dir)"/>
   <p:variable name="web-desc"     select="resolve-uri('expath-web.xml', $private-dir)"/>
   <p:variable name="abbrev"       select="/proj:project/@abbrev"/>
   <p:variable name="version"      select="/proj:project/@version"/>
   <p:variable name="xar-name"     select="concat($abbrev, '-', $version)"/>
   <p:variable name="is-web"       select="doc-available($web-desc)"/>
   <p:variable name="xar-ext"      select="if ( xs:boolean($is-web) ) then '.xaw' else '.xar'"/>
   <p:variable name="xar-file"     select="concat($xar-name, $xar-ext)"/>
   <p:variable name="xar-uri"      select="resolve-uri($xar-file, $dist-dir)"/>

   <cx:message>
      <p:with-option name="message" select="concat('Building project ', $project-dir)"/>
   </cx:message>

   <!--
       The recursive content of src/.
   -->
   <proj:recurse-dir name="src">
      <p:with-option name="dir"         select="$src-dir"/>
      <p:with-option name="ignore-dirs" select="$ignore-dirs"/>
   </proj:recurse-dir>

   <!--
       Generate the ZIP manifest.
   -->
   <proj:zip-structure>
      <p:input port="manifest">
         <p:pipe step="pipeline" port="manifest"/>
      </p:input>
   </proj:zip-structure>

   <proj:add-extension-entry desc-name="saxon.xml">
      <p:with-option name="private-dir" select="$private-dir"/>
   </proj:add-extension-entry>

   <proj:add-extension-entry desc-name="cxan.xml">
      <p:with-option name="private-dir" select="$private-dir"/>
   </proj:add-extension-entry>

   <proj:add-extension-entry desc-name="expath-web.xml">
      <p:with-option name="private-dir" select="$private-dir"/>
   </proj:add-extension-entry>

   <p:insert position="first-child" name="manifest">
      <p:input port="insertion">
         <p:inline>
            <c:entry name="expath-pkg.xml" href="http://expath.org/ns/project/expath-pkg.xml"/>
         </p:inline>
      </p:input>
   </p:insert>

   <!--
       Generate the package descriptor.
   -->
   <proj:generate-pkg-desc>
      <p:with-option name="ignore-components" select="$ignore-components"/>
      <p:input port="sources">
         <p:pipe step="src" port="result"/>
      </p:input>
      <p:input port="project">
         <p:pipe step="pipeline" port="source"/>
      </p:input>
   </proj:generate-pkg-desc>

   <!-- TODO: This does make the descriptor invalid against the schema.  We need
        another way to set the base URI of a document (than altering its content
        by adding an attribute).  I talk to Norm, we agreed on the need to
        provide another way to achieve this.
        
        TODO: Send an email to XProc Dev (see above...)
        
        TODO: Should work anyway with output-base-uri on p:xslt, but it does
        not.  When I try, it fails on pxp:zip... -->
   <p:add-attribute
       name="pkg-desc"
       match="/*"
       attribute-name="xml:base"
       attribute-value="http://expath.org/ns/project/expath-pkg.xml"/>

   <!--
       Actually create the ZIP.
       
       TODO: What if the file already exists?  Abort?  Depend on an option (like
       -force)?  Something else?
   -->
   <pxp:zip command="create">
      <p:with-option name="href" select="$xar-uri"/>
      <p:input port="source">
         <p:pipe step="pkg-desc" port="result"/>
         <p:pipe step="pipeline" port="files"/>
      </p:input>
      <p:input port="manifest">
         <p:pipe step="manifest" port="result"/>
      </p:input>
   </pxp:zip>

   <cx:message>
      <p:with-option name="message" select="
          concat('Generated XAR file ', substring-after($xar-uri, $project-dir))"/>
   </cx:message>

   <p:sink/>

</p:declare-step>
