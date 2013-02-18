<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:proj="http://expath.org/ns/project"
                version="1.0">

   <!-- the project.xml -->
   <p:input port="source" primary="true"/>

   <!-- the parameters -->
   <p:input port="parameters" primary="true" kind="parameter"/>

   <!-- This project is special, we can use the current implementation
        if we want, without requiring to install it, because it is
        just right here... -->
   <p:import href="../src/build.xproc"/>
   <!--p:import href="http://expath.org/ns/project/build.xproc"/-->

   <proj:build ignore-dirs=".~,templates" ignore-components="xquery-parser.xql"/>

</p:declare-step>
