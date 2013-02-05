(:~
 : Sample library module.
 :
 : @author Florent Georges - H2O Consulting
 : @version 1.0.0
 : @see http://expath.org/
 :)
module namespace hw = "http://example.org/hello-world";

(:~
 : Return greetings (an element) from a name (which is used as content).
 :
 : @since 1.0.0
 : @param $who The name to create greetings for.
 : @return Return greetings as en element.
 : @error There is no error.
 :)
declare function hw:hello-world($who as item())
{
  <greetings>Hello, { $who }!</greetings>
};
