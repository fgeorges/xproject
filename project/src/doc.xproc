<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:cx="http://xmlcalabash.com/ns/extensions"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:proj="http://expath.org/ns/project"
                pkg:import-uri="http://expath.org/ns/project/doc.xproc"
                name="pipeline"
                exclude-inline-prefixes="p c pkg proj"
                version="1.0">

   <!-- the project.xml -->
   <p:input port="source" primary="true"/>

   <!-- the list of generated files -->
   <!-- TODO: Still to be done. -->
   <!--p:output port="result" primary="true" sequence="true"/-->

   <!-- indent the overall report -->
   <!--p:serialization port="result" indent="true"/-->

   <!-- the standard xquerydoc pipeline -->
   <p:import href="http://xqdoc.org/xquerydoc.xpl"/>

   <p:variable name="proj:project" select="resolve-uri('..', base-uri(.))"/>
   <p:variable name="proj:src"     select="resolve-uri('src/', $proj:project)"/>
   <p:variable name="proj:dist"    select="resolve-uri('dist/xqdoc/', $proj:project)"/>

   <p:variable name="project" select="
       if ( starts-with($proj:project, 'file:///') ) then
         substring($proj:project, 8)
       else if ( starts-with($proj:project, 'file:/') ) then
         substring($proj:project, 6)
       else
         $proj:project"/>
   <p:variable name="src"     select="
       if ( starts-with($proj:src, 'file:///') ) then
         substring($proj:src, 8)
       else if ( starts-with($proj:src, 'file:/') ) then
         substring($proj:src, 6)
       else
         $proj:src"/>
   <p:variable name="dist"    select="
       if ( starts-with($proj:dist, 'file:///') ) then
         substring($proj:dist, 8)
       else if ( starts-with($proj:dist, 'file:/') ) then
         substring($proj:dist, 6)
       else
         $proj:dist"/>

   <!--p:xslt template-name="main">
      <p:input port="stylesheet">
         <p:inline>
            <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                            version="2.0">
               <xsl:param name="project"/>
               <xsl:param name="src"/>
               <xsl:param name="dist"/>
               <xsl:template name="main">
                  <xsl:message>
                     PROJ: <xsl:value-of select="$project"/>
                     SRC : <xsl:value-of select="$src"/>
                     DIST: <xsl:value-of select="$dist"/>
                  </xsl:message>
                  <dummy/>
               </xsl:template>
            </xsl:stylesheet>
         </p:inline>
      </p:input>
      <p:with-param name="project" select="$project"/>
      <p:with-param name="src"     select="$src"/>
      <p:with-param name="dist"    select="$dist"/>
   </p:xslt-->

   <!-- TODO: Change the @type of this step in xqdoc... -->
   <cx:xqdoc format="html">
      <p:with-option name="xquery"     select="$src"/>
      <p:with-option name="output"     select="$dist"/>
      <p:with-option name="currentdir" select="$src"/>
   </cx:xqdoc>

   <p:store>
      <p:with-option name="href" select="resolve-uri('index.html', $proj:dist)"/>
   </p:store>

   <!-- TODO: Save the output in $dist/index.html. -->
   <!-- TODO: Generate the report on the result port. -->

</p:declare-step>
