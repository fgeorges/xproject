<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:proj="http://expath.org/ns/project"
                version="1.0">

   <!-- the project.xml -->
   <p:input port="source" primary="true"/>

   <!--p:import href="http://expath.org/ns/project/build.xproc"/-->
   <p:import href="../src/build.xproc"/>

   <proj:build ignore-dirs=".~,.svn,templates" ignore-components="xquery-parser.xql"/>

</p:declare-step>
