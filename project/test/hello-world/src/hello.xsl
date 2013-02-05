<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pkg="http://expath.org/ns/pkg"
                xmlns:hw="http://example.org/hello-world"
                version="2.0">

   <pkg:import-uri>http://example.org/hello-world/hello.xsl</pkg:import-uri>

   <xsl:template name="main" match="/">
      <greetings>Hello, world!</greetings>
   </xsl:template>

   <xsl:function name="hw:hello-world">
      <xsl:param name="who" as="xs:string"/>
      <greetings>
         <xsl:text>Hello, </xsl:text>
         <xsl:value-of select="$who"/>
         <xsl:text>!</xsl:text>
      </greetings>
   </xsl:function>

</xsl:stylesheet>
