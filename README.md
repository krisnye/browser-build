browser-build
=============

Makes commonjs modules available in the browser via window.require("module-name")

Assuming you have the following directory structure:

    /
        lib/
            index.js
            alpha.js
            foo/
                beta.js

Running the following script:

    require("browser-build").build({
        input: {
            directory: "lib"
        },
        output: {
            directory: "www/js",
            name: "mymodule",
            debug: true,
            include: {
                name: "all.js",
                base: "/js/"
            }
        }
    });

Will create the following structure:

    /
        www/
            js/
                require.js # defines window.require function
                all.js # with content:
                    document.writeln("<script src='/js/mymodule/index.js'></script>");
                    document.writeln("<script src='/js/mymodule/alpha.js'></script>");
                    document.writeln("<script src='/js/mymodule/foo/beta.js'></script>");
                mymodule/
                    index.js
                    alpha.js
                    foo/
                        beta.js
        lib/
            index.js
            alpha.js
            foo/
                beta.js
