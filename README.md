

                     * expath/pkg/repo/packager *

                                README



     The goal of this project is to implement a packager using
   directly XSLT, with the EXPath ZIP extensions.  To achieve this, it
   defines an XML project structure (aka "directory layout") so it can
   generate automatically the package drescriptor: expath-pkg.xml.

       xml-proj/
         build/
           packager.xml
         src/
           style.xsl
           query.xq
           lib.xql

       xml-proj/build/xml-proj-1.0.xar!/
         expath-pkg.xml
         xml-proj/
           style.xsl
           query.xq
           lib.xql

       <!-- xml-proj/build/packager.xml -->
       <package xmlns="http://expath.org/ns/packager"
                name="http://example.org/xml-proj">
          <module name="xml-proj" version="1.0">
             <title>Example XML project</title>
          </module>
       </package>

       <!-- xml-proj/build/xml-proj-1.0.xar!expath-pkg.xml -->
       <package xmlns="http://expath.org/ns/pkg"
                name="http://example.org/xml-proj">
          <module name="xml-proj" version="1.0">
             <title>Example XML project</title>
             <xslt>
                <import-uri>http://example.org/xml-proj/style.xsl</import-uri>
                <file>style.xsl</file>
             </xslt>
             <xquery>
                <import-uri>http://example.org/xml-proj/query.xq</import-uri>
                <file>query.xql</file>
             </xquery>
             <xquery>
                <namespace>http://example.org/xml-proj</namespace>
                <file>lib.xql</file>
             </xquery>
          </module>
       </package>

       <!-- xml-proj/src/style.xsl -->
       <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                       xmlns:pkg="http://expath.org/ns/pkg"
                       version="2.0">
          <pkg:import-uri>http://example.org/xml-proj/style.xsl</pkg:import-uri>
          ...

       <!-- xml-proj/src/query.xq -->
       (: import uri: http://example.org/xml-proj/query.xq :)
       ...

       <!-- xml-proj/src/lib.xql -->
       (: target namespace: http://example.org/xml-proj :)
       module namespace my = "http://example.org/xml-proj";
       ...

     TODO: Add tests to test the override mechanism to put a local
   script in xproject/ to override a standard script.  E.g. the file
   xproject/release-project.xsl overrides the standard release.xsl if
   present.

     TODO: Add the ability to define per-project xproj targets.  For
   instance, to properly package xquerydoc (the package supporting the
   xqDoc framework), we should be able to define our own target
   "grammars" for that project, that would compile the grammars from
   EBNF to corresponding XQuery code, when executing "xproj grammars"
   from the command line.

     TODO: Projectify xquerydoc... (and put it on CXAN)

     TODO: Put a sample project online.  One can browse the project
   files, including the generated files (so the XAR, the ZIP, but also
   the test reports and xqDoc and XSLStyle doc, so displaying it
   directly in the browser).

     TODO: Put those TODOs on Google Code issue tracker.
