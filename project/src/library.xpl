<p:library xmlns:p="http://www.w3.org/ns/xproc"
           xmlns:c="http://www.w3.org/ns/xproc-step"
           xmlns:pkg="http://expath.org/ns/pkg"
           xmlns:proj="http://expath.org/ns/project"
           pkg:import-uri="http://expath.org/ns/project/library.xpl"
           version="1.0">

   <p:declare-step type="proj:recurse-dir">
      <p:documentation>
         <p>Like p:directory-list, but recursive.</p>
      </p:documentation>
      <!-- the recursive dir structure -->
      <p:output port="result" primary="true"/>
      <p:option name="dir"         required="true"/>
      <p:option name="ignore-dirs" required="true"/>
      <p:directory-list>
         <p:with-option name="path" select="$dir"/>
      </p:directory-list>
      <p:viewport match="/*/c:directory">
         <p:choose>
            <!-- TODO: Optionalize this list... -->
            <p:when test="/*/@name = tokenize($ignore-dirs, ',')">
               <p:identity>
                  <p:input port="source">
                     <p:empty/>
                  </p:input>
               </p:identity>
            </p:when>
            <p:otherwise>
               <proj:recurse-dir>
                  <p:with-option name="dir" select="resolve-uri(concat(/*/@name, '/'), $dir)"/>
                  <p:with-option name="ignore-dirs" select="$ignore-dirs"/>
               </proj:recurse-dir>
            </p:otherwise>
         </p:choose>
      </p:viewport>
   </p:declare-step>

</p:library>
