# XProject

XProject, a project manager for XML technologies.

Documentation can be found at http://expath.org/modules/xproject/.


## What's it do?

XProject provides a command-line tool to manage a project using
XML-related technologies.  Based on simple directories conventions,
and annotations with the XML components, it can:

- build automatically EXPath packages for your project
- create a release ZIP file
- run unit tests
- generate the documentation out of the sources

It understands the following languages (but we are happy to add
support for your preferred language, if you ask loud enough to be
heard):

- XProc
- XQuery
- XSLT

For more information: `xproj help`.


## Install

### From CXAN

Run the command: `cxan install xproject`.

### Using xrepo

- Visit the [download area](http://code.google.com/p/expath-pkg/downloads)
- Look for the latest file named `xproject-x.y.z.zip`
- Install the XAR file it contains within your package repository: `xrepo install xproject-x.y.z.xar`
- Put the schell script into your PATH

If you don't have the EXPath Repository manager, install it first from
[expath-pkg-java](https://github.com/fgeorges/expath-pkg-java).


## Related project

An XProject plugin for oXygen also exists.  The repository is at
[xproject-oxygen](https://github.com/fgeorges/xproject-oxygen).

You can install it directly from within oXygen, using the EXPath
[oXygen addon repository](http://expath.org/oxygen/).

Alternatively, you can download it from the same place as XProject
itself.  Just look for the latest `xproject-oxygen-plugin-x.y.z.zip`
file instead, and unzip it into your oXygen `plugins/` sub-directory.
