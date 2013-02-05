(: import uri: http://example.org/hello-world/hello-world.xq :)

(:~
 : Sample main module.
 :
 : @author Florent Georges - H2O Consulting
 : @version 1.0.0
 : @see http://expath.org/
 :)

declare namespace pkg = "http://expath.org/ns/pkg";

declare variable $pkg:import-uri as xs:string
  := 'http://example.org/hello-world/hello-world.xq';

<greetings>Hello, world!</greetings>
