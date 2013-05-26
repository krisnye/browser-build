require 'sugar'
utility = require "./utility"
watcher = require "./watcher"
np = require "path"
fs = require 'fs'

log = (config, message) ->
    console.log message unless config.silent

getInputKeyValueForFile = (config, file) ->
    for name, input of config.input when Object.isString input
        if file.startsWith input
            return [name,input]
    throw new Error "input not found in config.input: #{file}"

getInputDirectory = (config, file) ->
    getInputKeyValueForFile(config, file)[1]

getBaseModuleName = (config, file) ->
    getInputKeyValueForFile(config, file)[0]

getModuleId = (config, file) ->
    name = getBaseModuleName config, file
    inputDirectory = getInputDirectory config, file
    # get the relative path from root
    path = np.relative inputDirectory, file
    # replace \ with /
    path = path.replace /\\/g, "\/"
    # add the output base name
    path = name + "/" + path
    # remove trailing /
    path = path.replace /\/$/, ""
    # remove trailing .js
    path = path.replace /\.js$/, ""

getOutputModuleDirectory = (config) ->
    np.join config.output.directory, "modules"

getOutputFile = (config, file, id) ->
    id ?= getModuleId config, file
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
                    console.warn "Source not found: #{mapInput} -> #{source}"
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

buildFile = (config, file, id) ->
    outputFile = getOutputFile config, file, id
    if not fs.existsSync file
        # delete source map files
        copySourceMap config, file, outputFile, true
        deleteFile outputFile
        return
    id ?= getModuleId config, file
    input = utility.read file
    output = "(function(){require.register('#{id}',function(module,exports,require){#{input}\n})})()"
    utility.write outputFile, output
    log config, "Wrapped #{outputFile}"
    copySourceMap config, file, outputFile

buildIncludes = (config) ->

    list = utility.list getOutputModuleDirectory(config), {include:".js"}
    list = list.map (x) ->
        np.relative(config.output.directory, x).replace(/\\/g,'\/')
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
    includeFile = np.join config.output.directory, "debug.js"
    utility.write includeFile, script
    log config, "Created #{includeFile}"
    # also build the test file
    buildBrowserTestFile config

copyRequire = (config) ->
    # copy the require from our source to the output directory
    source = np.join __dirname, 'require.js'
    # in case we're running from .coffee sources
    if not fs.existsSync source
        source = np.join __dirname, '../lib/require.js'
    target = np.join getOutputModuleDirectory(config), 'require.js'
    if not fs.existsSync target
        utility.copy source, target
        log config, "Copied #{target}"

check = (config) ->
    throw new Error "config.input is required" unless config?.input?
    for key, value of config.input
        config[key] = np.normalize value
    return

getDependencies = (file, id, deps = {}) ->
    getRelativeFileAndIds = (name) ->
        dependent = np.normalize np.join(np.dirname(file), name) + ".js"
        dependentId = np.join(id, name).replace(/\\/g, '\/')
        recurseId = dependentId
        if not fs.existsSync dependent
            dependent = np.normalize np.join(np.dirname(file), name) + "/index.js"
            dependentId = np.join(id, name).replace(/\\/g, '\/') + "/index"
        [dependent, dependentId, recurseId]

    content = utility.read file
    names = utility.getMatches content, /\brequire\s*\(\s*(['"][^'"]+['"])\s*\)/g, 1
    names = names.map (x) -> eval(x)
    for name in names when name[0] is '.'
        [dependentFile, fileId, recurseId] = getRelativeFileAndIds name
        if not fs.existsSync dependentFile
            console.warn "file not found #{dependentFile} referenced from #{file}"
            continue
        if not deps[dependentFile]
            deps[dependentFile] = fileId
            # recurse
            getDependencies dependentFile, recurseId, deps
    deps

buildStatic = (config, moduleId) ->
    main =
        try
            require.resolve moduleId
        catch e
            null
    throw new Error "Module not found: #{moduleId}" unless main?
    deps = {}
    deps[main] = moduleId + "/index"
    deps = getDependencies main, moduleId, deps
    for file, id of deps
        buildFile config, file, id

buildCommon = (config) ->
    check config
    copyRequire config
    for name, input of config.input when input is true
        buildStatic config, name

exports.build = (config, callback) ->
    buildCommon config
    for name, input of config.input when Object.isString input
        list = utility.list input, {include: ".js"}
        for file in list
            buildFile config, file
    buildIncludes config
    callback?()

exports.watch = (config) ->
    buildCommon config
    buildIncludes config
    for name, input of config.input when Object.isString input
        watcher.watchDirectory input, {include: ".js",initial:false},
            (file, curr, prev, change) ->
                buildFile config, file
                if change is "deleted" or change is "created"
                    buildIncludes config
