#! /bin/bash

PROJ_NS=http://expath.org/ns/project

if [[ -z "$SAXON" ]]; then
    SAXON=saxon
fi
if [[ -z "$CALABASH" ]]; then
    CALABASH=calabash
fi
# # the stylesheet is either overloaded in the project, or the standard one
# if [[ -f xproject/package-project.xsl ]]; then
#     PACKAGER=xproject/package-project.xsl
# else
#     PACKAGER=http://expath.org/ns/project/package.xsl
# fi
# the pipeline is either overloaded in the project, or the standard one
if [[ -f xproject/build-project.xproc ]]; then
    BUILDER=xproject/build-project.xproc
else
    BUILDER=http://expath.org/ns/project/build.xproc
fi
# the pipeline is either overloaded in the project, or the standard one
if [[ -f xproject/test-project.xproc ]]; then
    TESTER=xproject/test-project.xproc
else
    TESTER=http://expath.org/ns/project/test.xproc
fi
# the pipeline is either overloaded in the project, or the standard one
if [[ -f xproject/doc-project.xproc ]]; then
    DOCER=xproject/doc-project.xproc
else
    # TODO: Replace by a standard pipeline, for which we can control the interface (options)
    DOCER=http://xqdoc.org/xquerydoc.xpl
fi
# the stylesheet is either overloaded in the project, or the standard one
if [[ -f xproject/release-project.xsl ]]; then
    RELEASER=xproject/release-project.xsl
else
    RELEASER=http://expath.org/ns/project/release.xsl
fi

if [[ -z "$1" ]]; then
    echo First option mandatory, got nothing;
    echo Try '"xproj help"';
    exit 1;
fi

if [[ "$1" == help ]]; then
    echo "Invoke xproj with one of the following command:";
    echo ;
    echo "    build       Build the package";
    echo "    test        Run the tests";
    echo "    doc         Generate the documentation from sources";
    echo "    deploy      Deploy the current project as a web application";
    echo "    release     Create a delivery file, containing the package";
    echo "    help        Display this help message";
    echo ;
    echo "For instance, go to your project root directory (the one containing the";
    echo "sub-directory xproject/), and type \"xproj build\".";
    exit 0;
fi

if [[ "$1" != build && "$1" != test && "$1" != doc && "$1" != deploy && "$1" != release ]]; then
    echo Only help, build, test, doc, deploy and release commands accepted, got \'$1\';
    exit 1;
fi

if [[ ! -z "$2" ]]; then
    echo Second option not accepted, got \'$2\';
    exit 1;
fi

if [[ ! -d xproject ]]; then
    echo Not a valid project, xproject/ does not exist;
    exit 1;
fi

if [[ ! -d src ]]; then
    echo Not a valid project, src/ does not exist;
    exit 1;
fi

if [[ ! -f xproject/project.xml ]]; then
    echo Not a valid project, xproject/project.xml does not exist;
    exit 1;
fi

if [[ "$1" == build ]]; then
    if [[ ! -d dist ]]; then
        mkdir dist;
    fi
    if [[ -d .svn ]]; then
        "$CALABASH" -i source=xproject/project.xml -b "proj=${PROJ_NS}" \
            -p "proj:revision=`svnversion 2>/dev/null`" "$BUILDER";
    elif [[ -d .git ]]; then
        "$CALABASH" -i source=xproject/project.xml -b "proj=${PROJ_NS}" \
            -p "proj:revision=`git describe --always 2>/dev/null`" "$BUILDER";
    else
        "$CALABASH" -i source=xproject/project.xml "$BUILDER";
    fi
elif [[ "$1" == test ]]; then
    # 
    # TODO: Define a way (like a specific, overloadable step) that gives the
    # opportunity for a specific project to define their own "custom
    # processors".
    # 
    "$CALABASH" -i source=xproject/project.xml \
        "$TESTER";
elif [[ "$1" == doc ]]; then
    if [[ ! -d dist ]]; then
        mkdir dist;
    fi
    if [[ ! -d dist/xqdoc ]]; then
        mkdir dist/xqdoc;
    fi
    #
    # TODO: An XProject pipeline should import the xquerydoc pipeline
    # and get project.xml as input, in order to be able to configurize
    # this target in this file, like for the other targets...
    # 
    "$CALABASH" "$DOCER" \
        xquery=`pwd`/src/ \
        output=`pwd`/dist/xqdoc/ \
        currentdir=`pwd`/src/ \
        format=html \
        > dist/xqdoc/index.html;
elif [[ "$1" == deploy ]]; then
    echo 'deploy' target not supported yet!;
elif [[ "$1" == release ]]; then
    if [[ -d .svn ]]; then
        "$SAXON" --xslt -xsl:"$RELEASER" -s:xproject/project.xml \
            "{${PROJ_NS}}revision"=`svnversion 2>/dev/null`;
    elif [[ -d .git ]]; then
        "$SAXON" --xslt -xsl:"$RELEASER" -s:xproject/project.xml \
            "{${PROJ_NS}}revision"=`git describe --always 2>/dev/null`;
    else
        "$SAXON" --xslt -xsl:"$RELEASER" -s:xproject/project.xml;
    fi
fi
