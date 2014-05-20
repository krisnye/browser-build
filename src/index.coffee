require 'sugar'
utility = require "./utility"
watcher = require "./watcher"
np = require "path"
fs = require 'fs'

log = (config, message) ->
    console.log message unless config.silent

normalize = (file) -> file.replace /\\/g, "\/"

getInputKeyValueForFile = (config, file) ->
    # normalize file name to / format
    file = normalize file
    for name, input of config.input when Object.isString input
        if file.startsWith input
            return [name,input]
    throw new Error "input not found in config.input: #{file}"

getInputDirectory = (config, file) ->
    getInputKeyValueForFile(config, file)[1]

getBaseModuleName = (config, file) ->
    getInputKeyValueForFile(config, file)[0]

getOutputModuleDirectory = (config) ->
    np.join config.output.directory, "modules"

getOutputFile = (config, file, id) ->
    file = np.normalize np.join(getOutputModuleDirectory(config), id) + ".js"

deleteFile = (file) ->
    if fs.existsSync file
        fs.unlinkSync file

buildBrowserTestFile = (config) ->
    type = config.output.test
    return unless type?

    testFolder = np.join(__dirname,  "../test", type)
    if not fs.existsSync testFolder
        throw new Error "Test files for #{type} not found, expected at #{testFolder}"
    # copy this folder to the output test folder
    outputFolder = np.join config.output.directory, "test"
    # copy our test files to the output folder
    utility.copy testFolder, outputFolder

copySourceMap = (config, inputFile, outputFile, deleteOutput = false) ->
    mapInput = inputFile.replace /\.js$/, ".map"
    mapOutput = outputFile.replace /\.js$/, ".map"
    if fs.existsSync mapInput
        try
            map = JSON.parse utility.read mapInput
        catch e
            # this can happen sometimes if we're reading
            # while this file is getting written by coffee -c
            map =
                sourceRoot: "."
                sources: []
        # modify the sourceRoot and sources
        # to expect the source to be in the same directory
        # find and copy each source to the output directory
        for source, index in map.sources
            source = np.join np.dirname(mapInput), map.sourceRoot, source
            copyTo = np.join np.dirname(mapOutput), shortName = source.split(/[\/\\]/g).pop()
            if deleteOutput
                deleteFile copyTo
            else
                if not fs.existsSync source
                    # console.warn "Source not found: #{mapInput} -> #{source}"
                    continue
                utility.copy source, copyTo
            # also change the source reference to the shortName
            map.sources[index] = shortName
        # finally, make the source root the current directory
        map.sourceRoot = "."
        # then write out the sourceMap inputFile
        if deleteOutput
            deleteFile mapInput
            deleteFile mapOutput
        else
            utility.write mapOutput, JSON.stringify map, null, '    '

buildMap = {}
buildFile = (config, file, id) ->
    # check build map to avoid duplicates
    previousFile = buildMap[id]
    if previousFile? and previousFile isnt file
        return
    buildMap[id] = file

    outputFile = getOutputFile config, file, id
    if not fs.existsSync file
        # delete source map files
        copySourceMap config, file, outputFile, true
        deleteFile outputFile
        return
    input = utility.read file
    output = "(function(process, global){
                require.register('#{id}',function(module,exports,require){
                    #{input}\
                })
             }({browser: typeof window !== 'undefined'},
                typeof self !== 'undefined' ? self :
                  typeof window !== 'undefined' ? window :
                  typeof global !== 'undefined' ? global : {}))"
    # lets also name our anonymous functions
    output = output.replace /\b([a-zA-Z_$0-9]+)\s*([=:])\s*function\b\s*\(/g, "$1 $2 function _$1("
    utility.write outputFile, output
    log config, "Wrapped #{outputFile}"
    copySourceMap config, file, outputFile

buildIncludes = (config) ->

    list = utility.list getOutputModuleDirectory(config), {include:".js"}
    list = list.map (x) ->
        normalize np.relative(config.output.directory, x)
    # sort by shallowest directory, then alphabetical
    list = list.sort (a, b) ->
        aa = a.split '/'
        bb = b.split '/'
        if aa.length != bb.length
            return aa.length - bb.length
        for aitem, index in aa
            bitem = bb[index]
            compare = aitem.localeCompare bitem
            if compare != 0
                return compare
        return 0
    script = ""
    # figure out the include base relative to the web root.
    webroot = config.output.webroot ? config.output.directory
    base = np.relative(webroot, config.output.directory).replace(/\\/g, '\/')
    base = "/#{base}/".replace(/\/+/, '/')
    for file in list
        script += """document.writeln("<script src='#{base}#{file}'></script>");\n"""
    includeFile = getDebugIncludeFile config
    utility.write includeFile, script
    log config, "Created #{includeFile}"
    # also build the manifest
    manifest = getDebugManifestFile config
    manifestParent = np.dirname manifest
    manifestList = list.map (x) -> normalize np.relative manifestParent, np.join(config.output.directory, x)
    utility.write getDebugManifestFile(config), JSON.stringify(manifestList, null, "  ")
    # also build the test file
    buildBrowserTestFile config

getDebugIncludeFile = (config) -> np.join config.output.directory, "debug.js"
getDebugManifestFile = (config) -> np.join config.output.directory, "modules/manifest.json"

copyRequire = (config) ->
    # copy the require from our source to the output directory
    source = np.join __dirname, 'require.js'
    # in case we're running from .coffee sources
    if not fs.existsSync source
        source = np.join __dirname, '../lib/require.js'
    target = np.join getOutputModuleDirectory(config), 'require.js'
    utility.copy source, target

check = (config) ->
    config.input ?= {"": true}
    resolve = (root, module, source) ->
        paths = [
            root
            np.join(root, "node_modules")
            np.join(root, "../node_modules")
            np.join(root, "../../node_modules")
        ]
        if process.env.NODE_PATH?
            paths = paths.concat process.env.NODE_PATH.split np.delimiter
        for path in paths
            main = np.join path, module + "/package.json"
            if fs.existsSync main
                json = eval "(#{utility.read main})"
                module = json.name
                if json.dependencies?
                    for name of json.dependencies
                        fixOptions name, true, np.dirname(main), main
                main = np.join np.dirname(main), (json.main ? "index.js")
                return [module,main]
            main = np.join path, module + ".js"
            if fs.existsSync main
                return [module,main]
            main = np.join path, module + "/index.js"
            if fs.existsSync main
                return [module,main]
        throw new Error "module not found: " + module + ", source: " + source

    fixOptions = (name, options, root, source) ->
        # never mess with exclude options
        if excludeModule config, name
            return
        if Object.isString options
            config.input[name] =
                name: name
                main: 'index.js'
                directory: np.normalize options
        else if options is true or not options?
            # remove original value, because name may change
            delete config.input[name]
            [name,main] = resolve root, name, source
            config.input[name] =
                name: name
                main: np.basename main
                directory: np.dirname main

    for key, value of config.input when value
        fixOptions key, value, '.', 'config'

    return

buildCommon = (config) ->
    check config
    copyRequire config

getModuleId = (inputConfig, file) ->
    relative = np.relative inputConfig.directory, file
    if relative is inputConfig.main
        relative = "index.js"
    # remove extension
    relative = relative.slice 0, -".js".length
    normalize np.join inputConfig.name, relative

excludeFile = (file) ->
    if /WEB-INF/.test file
        return true
    return false
excludeModule = (config, moduleId) ->
    if moduleId.endsWith '/index'
        moduleId = moduleId.substring(0, moduleId.length - '/index'.length)
    value = config.input[moduleId]
    return value is false
exports.build = (config, callback) ->
    buildCommon config
    for name, input of config.input when input isnt false
        list = utility.list input.directory, {include: ".js"}
        for file in list when not excludeFile file
            id = getModuleId input, file
            if not excludeModule config, id
                buildFile config, file, id
    buildIncludes config
    callback?()

watchInput = (config, input) ->
    watcher.watchDirectory input.directory, {include: ".js", initial:false},
        (file, curr, prev, change) ->
            if excludeFile file
                return
            id = getModuleId input, file
            if excludeModule config, id
                return
            buildFile config, file, id
            if change is "deleted" or change is "created"
                buildIncludes config
            else
                # touch the manifest file so others can fs.watch it
                utility.touch getDebugManifestFile config

exports.watch = (config) ->
    exports.build config
    for name, input of config.input when not excludeModule config, name
        watchInput config, input

# re-export utility and watcher
exports.utility = utility
exports.watcher = watcher
