(function() {
    var require = function require(path) {
        // Find in cache
        var m = modules[path] || modules[path + "/index"];
        if (!m) {
            throw new Error("Couldn't find module for: " + path);
        }
        // Instantiate the module if it's export object is not yet defined
        if (!m.exports) {
            m.exports = {};
            m.filename = path;
            m.call(this, m, m.exports, resolve(path));
        }
        // Return the exports object
        return m.exports;
    };

    // Cache of module objects
    var modules = {};

    var normalize = require.normalize = function(curr, path) {
        var segs = curr.split('/'), seg;

        // Non relative path
        if (path[0] != '.')
            return path;

        // Use 'from' path segments to resolve relative 'to' path
        segs.pop();
        path = path.split('/');
        for (var i = 0; i < path.length; ++i) {
            seg = path[i];
            if (seg == '..') {
                segs.pop();
            } else if (seg != '.') {
                segs.push(seg);
            }
        }
        return segs.join('/');
    }

    var resolve = function(path) {
        return function(p) {
            return require(normalize(path, p));
        };
    };

    require.register = function(path, fn) {
        return modules[path] = fn;
    };

    require.loadAll = function() {
        var id;
        for (id in modules)
            require(id);
    }

    // export
    if (typeof module == "undefined")
        this.require = require;
    else
        module.exports = require;

})();