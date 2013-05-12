browser-build
=============

Makes commonjs modules available in the browser via window.require("module-name")

Assuming you have the following directory structure:

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
            debug: true,  // copy source code and maps if present?
            include: {
                name: "includes.js",
                base: "/js/"
            }
        }
    });

Will create the following structure:

    www/
        js/
            require.js  # defines window.require function
            includes.js # client-side includes all modules
            mymodule/
                index.js # wrapped in browser define function
                alpha.js # wrapped in browser define function
                foo/
                    beta.js # wrapped in browser define function
    lib/
        index.js
        alpha.js
        foo/
            beta.js

And then you can use the modules in the browser:

    <html>
        <head>
            <script src="require.js"></script>
            <script src="includes.js"></script>
        </head>
        <body>
            <script>
            var mm = require("mymodule");
            mm.doSomethingAwesome();
            </script>
        </body>
    </html>

You can also call the "watch" function with the same config as above and it will dynamically watch for changes and incrementally build the output files as needed.  It will compile new files, and remove output files when you delete input files as well.

    require("browser-build").watch(config);

Note: I do not perform any special shimming of nodejs specific built in properties like "process" etc.  If your module contains code which will not run in the browser, then you will have to provide your own shims or environment tests.

TODO: Add support for building dependent modules not found in original source directory.
