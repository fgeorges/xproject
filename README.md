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
support for your prefered language, if you ask loud enough to be
heard):

- XProc
- XQuery
- XSLT

For more information: `xproj help`.


## Install

Install it directly from CXAN with: `cxan install xproject`.

You can also download the XAR or the release file from the [download
area](http://code.google.com/p/expath-pkg/downloads).  Look for the
latest file named `xproject-x.y.z.xar`.  Install it in your package
repository with: `xrepo install xproject-x.y.z.xar`.

If you don't have the EXPath Repository manager, install it first from
[expath-pkg-java](https://github.com/fgeorges/expath-pkg-java).


## Related project

An XProject plugin for oXygen also exists.  The repository is at
[xproject-oxygen](https://github.com/fgeorges/xproject-oxygen), and
you can download it from the same place as XProject itself (just look
for the latest `xproject-oxygen-plugin-x.y.z.zip` file instead).
