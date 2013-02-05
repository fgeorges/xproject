<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:proj="http://expath.org/ns/project"
                xmlns:t="http://www.jenitennison.com/xslt/xspec"
                pkg:import-uri="http://expath.org/ns/project/test.xproc"
                name="pipeline"
                exclude-inline-prefixes="p c pkg proj t"
                version="1.0">

   <!-- the project.xml -->
   <p:input port="source" primary="true"/>

   <!-- the list of suites -->
   <p:output port="result" primary="true" sequence="true"/>

   <!-- indent the overall report -->
   <p:serialization port="result" indent="true"/>

   <!-- the standard test harnesses -->
   <!-- TODO: Really, I don't like that...  Find a new pattern for dynamic import,
        like to have several implementations of a single one interface... -->
   <p:import href="http://www.jenitennison.com/xslt/xspec/basex/harness/server/xquery.xproc"/>
   <p:import href="http://www.jenitennison.com/xslt/xspec/basex/harness/standalone/xquery.xproc"/>
   <p:import href="http://www.jenitennison.com/xslt/xspec/exist/harness/xquery.xproc"/>
   <p:import href="http://www.jenitennison.com/xslt/xspec/marklogic/harness/xquery.xproc"/>
   <p:import href="http://www.jenitennison.com/xslt/xspec/saxon/harness/xquery.xproc"/>
   <p:import href="http://www.jenitennison.com/xslt/xspec/saxon/harness/xslt.xproc"/>
   <p:import href="http://www.jenitennison.com/xslt/xspec/zorba/harness/xquery.xproc"/>

   <p:declare-step type="t:run-suites">
      <p:input  port="source"     primary="true"/>
      <p:input  port="parameters" primary="true" kind="parameter"/>
      <p:output port="result"     primary="true"/>
      <p:option name="processor"   required="true"/>
      <p:option name="report-re"   required="true"/>
      <p:option name="project-dir" required="true"/>
      <p:for-each>
         <p:iteration-source select="/suites/suite"/>
         <t:run-suite>
            <p:with-option name="processor"   select="$processor"/>
            <p:with-option name="report-re"   select="$report-re"/>
            <p:with-option name="project-dir" select="$project-dir"/>
         </t:run-suite>
      </p:for-each>
      <p:wrap-sequence wrapper="processor"/>
      <p:add-attribute attribute-name="name" match="/*">
         <p:with-option name="attribute-value" select="$processor"/>
      </p:add-attribute>
   </p:declare-step>

   <!--
       TODO: step run-suite
       - receive the XSpec doc (source port)
       - receive the processor name (processor option)
       - receive other useful options (XSpec home, etc.)
         (config file in ~/.xproject.xml ?, to configure BaseX JAR, XSpec home,
         zorba script, ...)
       - dispatch to the appropriate step
       
       NEW: Receive <suite uri="..."/> on the source port, enrich it with report="..."
   -->
   <p:declare-step type="t:run-suite" name="me">
      <p:input  port="source"     primary="true"/>
      <p:output port="result"     primary="true"/>
      <p:input  port="parameters" primary="true" kind="parameter"/>
      <p:option name="processor"   required="true"/>
      <p:option name="report-re"   required="true"/>
      <p:option name="project-dir" required="true"/>
      <!--p:option name="xspec-home" required="true"/-->
      <p:variable name="suite"  select="/*/@uri"/>
      <!-- TODO: Generate something nicer. -->
      <p:variable name="report" select="replace($suite, '(.*/)?([^/]+).xspec', $report-re)"/>
      <p:load>
         <p:with-option name="href" select="/suite/@uri"/>
      </p:load>
      <t:dispatch-to-processor>
        <p:input port="parameters">
           <p:pipe step="me" port="parameters"/>
        </p:input>
         <p:with-option name="processor"   select="$processor"/>
         <p:with-option name="project-dir" select="$project-dir"/>
      </t:dispatch-to-processor>
      <p:store>
         <p:with-option name="href" select="$report"/>
      </p:store>
      <p:add-attribute match="/suite" attribute-name="report">
         <p:input port="source">
            <p:pipe step="me" port="source"/>
         </p:input>
         <p:with-option name="attribute-value" select="$report"/>
      </p:add-attribute>
   </p:declare-step>

   <!--
       TODO: How to handle suites dedicated to EITHER XQuery or XSLT?  Which is by far the
       nust usual case.  E.g. if we have test/ with suites for XQuery and XSLT (that is,
       some for XQuery, and others for XSLT), then we should be able to say processors to
       be ued for tests are Saxon (XSLT) and say BaseX (XQuery) and eXist (XQuery).
       Depending on the suite's @stylesheet and/or @query, then the corresponding
       processors will be actually applied or not...
       
       The only case where a suite is both about XSLT and XQuery is when we implement a
       library of XPath function, either as an extension module (e.g. written in Java for
       eXist) or a library of functions in both languages (like FunctX does)...
   -->
   <p:declare-step type="t:dispatch-to-processor">
      <p:input  port="source"     primary="true"/>
      <p:input  port="parameters" primary="true" kind="parameter"/>
      <p:output port="result"     primary="true"/>
      <p:option name="processor"   required="true"/>
      <p:option name="project-dir" required="true"/>
      <!-- dispatch between processors -->
      <!--
          TODO: Those URIs are temporary, fix them ASAP, before they propagate!
          But as they must be defined by the implementation, I need their approval
          to use their domain name (or should I simply use expath.org for that, and
          maintain a list of known processor URIs?)
      -->
      <!--
          TODO: Use parameters instead of options?  In order to be more flexible and
          allow a config file or something?
      -->
      <p:choose>
         <p:when test="$processor eq 'http://expath.org/tmp/basex/server/xquery'">
            <t:basex-server-xquery-harness/>
         </p:when>
         <p:when test="$processor eq 'http://expath.org/tmp/basex/standalone/xquery'">
            <t:basex-standalone-xquery-harness/>
         </p:when>
         <p:when test="$processor eq 'http://expath.org/tmp/exist/xquery'">
            <t:exist-xquery-harness>
               <p:with-option name="project-dir" select="$project-dir"/>
            </t:exist-xquery-harness>
         </p:when>
         <p:when test="$processor eq 'http://expath.org/tmp/marklogic/xquery'">
            <t:ml-xquery-harness>
               <p:with-option name="project-dir" select="$project-dir"/>
            </t:ml-xquery-harness>
         </p:when>
         <p:when test="$processor eq 'http://expath.org/tmp/saxon/xquery'">
            <t:saxon-xquery-harness/>
         </p:when>
         <p:when test="$processor eq 'http://expath.org/tmp/saxon/xslt'">
            <t:saxon-xslt-harness/>
         </p:when>
         <p:when test="$processor eq 'http://expath.org/tmp/zorba/xquery'">
            <t:zorba-xquery-harness/>
         </p:when>
         <!-- unknown processor URI -->
         <p:otherwise>
            <p:template name="err-msg">
               <p:input port="source">
                  <p:empty/>
               </p:input>
               <p:input port="template">
                  <p:inline>
                     <message>Unknown processor: '{ $proc }'</message>
                  </p:inline>
               </p:input>
               <p:with-param name="proc" select="$processor"/>
            </p:template>
            <p:error code="proj:TEST001">
               <p:input port="source">
                  <p:pipe step="err-msg" port="result"/>
               </p:input>
            </p:error>
         </p:otherwise>
      </p:choose>
   </p:declare-step>

   <!--
       - filter the XSpec suites in each dir
       - recurse on subdirs
   -->
   <p:declare-step type="t:find-suites">
      <p:output port="result" sequence="true"/>
      <p:option name="dir" required="true"/>
      <!-- read the directory content -->
      <p:directory-list>
         <p:with-option name="path" select="$dir"/>
      </p:directory-list>
      <p:for-each>
         <p:iteration-source select="/*/c:*"/>
         <!--
             - ignore elements where @name starts with a '.'
             - include c:file iff @name matches *.xspec
             - recurse over c:directory
         -->
         <p:choose>
            <p:when test="starts-with(/*/@name, '.')">
               <p:identity>
                  <p:input port="source">
                     <p:empty/>
                  </p:input>
               </p:identity>
            </p:when>
            <p:when test="ends-with(/c:file/@name, '.xspec')">
               <p:template>
                  <p:input port="source">
                     <p:empty/>
                  </p:input>
                  <p:input port="template">
                     <p:inline>
                        <suite uri="{ $suite }"/>
                     </p:inline>
                  </p:input>
                  <p:with-param name="suite" select="resolve-uri(/*/@name, base-uri(/))"/>
               </p:template>
            </p:when>
            <p:when test="exists(/c:directory)">
               <t:find-suites>
                  <p:with-option name="dir" select="resolve-uri(/*/@name, base-uri(/))"/>
               </t:find-suites>
            </p:when>
            <p:otherwise>
               <p:identity>
                  <p:input port="source">
                     <p:empty/>
                  </p:input>
               </p:identity>
            </p:otherwise>
         </p:choose>
      </p:for-each>
   </p:declare-step>

   <p:variable name="proj:project" select="resolve-uri('..', base-uri(.))"/>

   <!--
       Main pipeline: loop over /proj:project/proj:tests
   -->
   <p:for-each>
      <p:iteration-source select="/proj:project/proj:tests"/>
      <p:variable name="dir" select="resolve-uri(/*/@dir, $proj:project)"/>
      <!--
          TODO: Would probably be better to compute the suites document only once (as it
          scans the filesystem), and to then iterate over the processors (that could
          potentially allow a processor to use some caching or something..., at least the
          resolution of the step for the given proc)...
      -->
      <p:for-each name="loop">
         <p:iteration-source select="/proj:tests/proj:processor"/>
         <p:variable name="processor" select="/proj:processor/@name"/>
         <p:variable name="report-re" select="/proj:processor/@report"/>
         <p:xquery name="props">
            <p:input port="query">
               <p:inline>
                  <c:query>
                     declare namespace c    = "http://www.w3.org/ns/xproc-step";
                     declare namespace proj = "http://expath.org/ns/project";
                     &lt;c:param-set> {
                       for $prop in /proj:processor/proj:property
                       return
                         &lt;c:param>{ $prop/(@name|@value) }&lt;/c:param>
                     }
                     &lt;/c:param-set>
                  </c:query>
               </p:inline>
            </p:input>
            <p:input port="parameters">
               <p:empty/>
            </p:input>
         </p:xquery>
         <!-- TODO: Must recurse on .//proj:tests elements (really?) -->
         <t:find-suites>
            <p:with-option name="dir" select="$dir"/>
         </t:find-suites>
         <p:wrap-sequence wrapper="suites"/>
         <p:try>
            <p:group>
               <t:run-suites>
                  <p:input port="parameters">
                     <p:pipe step="props" port="result"/>
                  </p:input>
                  <p:with-option name="processor"   select="$processor"/>
                  <p:with-option name="report-re"   select="$report-re"/>
                  <p:with-option name="project-dir" select="$proj:project"/>
               </t:run-suites>
            </p:group>
            <p:catch name="catch">
               <p:identity>
                  <p:input port="source">
                     <p:pipe step="catch" port="error"/>
                  </p:input>
               </p:identity>
            </p:catch>
         </p:try>
      </p:for-each>
   </p:for-each>

   <p:wrap-sequence wrapper="suites"/>

   <!--
       TODO: If called from the command line, provide a text-only output (or at
       least provide this feature as an option).
   -->

</p:declare-step>
