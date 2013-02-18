<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:proj="http://expath.org/ns/project"
                xmlns:pxf="http://exproc.org/proposed/steps/file"
                pkg:import-uri="http://expath.org/ns/project/setup.xproc"
                name="pipeline"
                exclude-inline-prefixes="p c xs pkg proj pxf"
                version="1.0">

   <p:documentation>
      <p>Create a new project structure.</p>
      <p>A directory is created at $path, which must not exist.  This is the root of the new
         project.  A template of the project decsriptor is also created in xproject/project.xml,
         as well as an empty src/ sub-directory.</p>
   </p:documentation>

   <p:output port="result" primary="true">
      <p:documentation>
         <p>A c:result element with the path to the new project descriptor (aka
            [project]/xproject/project.xml).</p>
      </p:documentation>
   </p:output>

   <p:option name="path" required="true">
      <p:documentation>
         <p>The directory to create (must not exist, must be absolute).</p>
      </p:documentation>
   </p:option>

   <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

   <p:declare-step type="proj:noop">
      <p:documentation>
         <p>A real sink, without any input nor output.</p>
      </p:documentation>
      <p:sink>
         <p:input port="source">
            <p:empty/>
         </p:input>
      </p:sink>
   </p:declare-step>

   <p:declare-step type="proj:error">
      <p:documentation>
         <p>A real error step, without any input nor output, and a message option.</p>
      </p:documentation>
      <p:option name="code" required="true"/>
      <p:option name="msg"  required="true"/>
      <p:template>
         <p:input port="source">
            <p:empty/>
         </p:input>
         <p:input port="template">
            <p:inline>
               <msg>{ $msg }</msg>
            </p:inline>
         </p:input>
         <p:with-param name="msg" select="$msg"/>
      </p:template>
      <p:error>
         <p:with-option name="code" select="$code"/>
      </p:error>
      <p:sink/>
   </p:declare-step>

   <p:declare-step type="proj:file-does-not-exist">
      <p:documentation>
         <p>No-op if the file does not exist, or raise an error.</p>
      </p:documentation>
      <p:option name="path" required="true"/>
      <p:try>
         <p:group>
            <pxf:info>
               <p:with-option name="href" select="$path"/>
            </pxf:info>
            <proj:error code="proj:STP001" msg="Bla bla..."/>
         </p:group>
         <p:catch>
            <proj:noop/>
         </p:catch>
      </p:try>
   </p:declare-step>

   <!--
       Main processing:
       - ensure the dir does not exist
       - ensure the path is absolute
       - create the dir (+ src/ and xproject/)
   -->

   <p:variable name="dir"      select="
       if ( ends-with($path, '/') ) then
         $path
       else
         concat($path, '/')"/>
   <p:variable name="project"  select="
       if ( starts-with($dir, '/') ) then
         concat('file:', $dir)
       else
         $dir"/>
   <!-- resolve-uri ensure $project is absolute -->
   <p:variable name="src"      select="resolve-uri('src/', $project)"/>
   <p:variable name="xproject" select="resolve-uri('xproject/', $project)"/>
   <p:variable name="desc"     select="resolve-uri('project.xml', $xproject)"/>

   <proj:file-does-not-exist>
      <p:with-option name="path" select="$project"/>
   </proj:file-does-not-exist>

   <pxf:mkdir>
      <p:with-option name="href" select="$project"/>
   </pxf:mkdir>

   <pxf:mkdir>
      <p:with-option name="href" select="$src"/>
   </pxf:mkdir>

   <pxf:mkdir>
      <p:with-option name="href" select="$xproject"/>
   </pxf:mkdir>

   <p:store indent="true">
      <p:with-option name="href" select="$desc"/>
      <p:input port="source">
         <p:document href="project-template.xml"/>
      </p:input>
   </p:store>

   <p:template>
      <p:input port="source">
         <p:empty/>
      </p:input>
      <p:input port="template">
         <p:inline><c:result>{ $desc }</c:result></p:inline>
      </p:input>
      <p:with-param name="desc" select="$desc"/>
   </p:template>

</p:declare-step>
