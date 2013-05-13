browser-build
=============

Makes commonjs modules available in the browser via window.require("module-name") with fast incremental recompiling for any project size.

Why did I write this when we already have browserify and commonjs-everywhere?

**Speed**

browser-build takes less than 3 milliseconds to rebuild any file you edit and that time will not increase as your project grows.

When developing for the browser, I need to be able to edit a source file and reload it in the browser as quickly as possible.  Browserify does not have an incremental build, so it's build time will grow in time as your project grows. Commonjs-everywhere does have a somewhat incremental build, but it still generates the entire bundle internally for every change, so its compile time also grows with your project.

Browser-build is insanely fast and because it only compiles files that you touch, it will never take any longer to incrementally build as your project grows.  If you edit your source, it will be ready before you can refresh your browser.

Debugging is also supported both by making source maps and source code available in the browser, and it's aided by using individual, (almost) original files when your source is vanilla js.

Your module files are only lightly shimmed into a require.register function that doesn't change your line numbers.

Installation:

    npm install browser-build

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
            require.js              # defines window.require function
            includes.js             # client-side includes all modules
            mymodule/
                index.js            # wrapped in require.register function
                alpha.js            # wrapped in require.register function
                foo/
                    beta.js         # wrapped in require.register function
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
