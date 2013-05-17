(->
    # This provides the require function in the browser
    require = (path) ->
        originalPath = path
        m = modules[path]
        unless m
            path += "/index"
            m = modules[path]
        unless m
            steps = path.replace(/\/index$/, "").split(/\//)
            object = this
            i = 0

            while object? and i < steps.length
                object = object[steps[i]]
                i++
            m = modules[originalPath] = exports: object  if object?
        throw new Error("Couldn't find module for: " + path)  unless m
        unless m.exports
            m.exports = {}
            m.filename = path
            m.call this, m, m.exports, resolve(path)
        m.exports

    modules = {}
    normalize = require.normalize = (curr, path) ->
        segs = curr.split("/")
        seg = undefined
        return path  unless path[0] is "."
        segs.pop()
        path = path.split("/")
        i = 0

        while i < path.length
            seg = path[i]
            if seg is ".."
                segs.pop()
            else segs.push seg  unless seg is "."
            ++i
        segs.join "/"

    resolve = (path) ->
        (p) ->
            require normalize(path, p)

    require.register = (path, fn) ->
        modules[path] = fn

    require.loadAll = ->
        id = undefined
        for id of modules
            require id

    if typeof module is "undefined"
        @require = require
    else
        module.exports = require
)()