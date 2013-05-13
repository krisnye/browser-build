utility = require "glass-platform/node/build/utility"
watcher = require "glass-platform/node/build/watcher"
np = require "path"
fs = require 'fs'

config =
    input:
        directory: "node"
        exclude: "node_modules"
    output:
        directory: "browser"
        name: "glass"

log = (config, message) ->
    console.log message unless config.silent

getModuleId = (config, file) ->
    # get the relative path from root
    path = np.relative config.input.directory, file
    # replace \ with /
    path = path.replace /\\/g, "\/"
    # remove trailing index.js
    path = path.replace /\bindex\.js$/, ""
    # add the output base name
    path = config.output.name + "/" + path
    # remove trailing /
    path = path.replace /\/$/, ""
    # remove trailing .js
    path = path.replace /\.js$/, ""

getOutputFile = (config, file) ->
    # get the relative path from root
    path = np.relative config.input.directory, file
    # replace \ with /
    path = path.replace /\\/g, "\/"
    # add the output base name
    path = config.output.name + "/" + path
    # join to output directory
    path = np.join config.output.directory, path

deleteFile = (file) ->
    if fs.existsSync file
        fs.unlinkSync file

copySourceMap = (config, inputFile, outputFile, deleteOutput = false) ->
    mapInput = inputFile.replace /\.js$/, ".map"
    mapOutput = outputFile.replace /\.js$/, ".map"
    if fs.existsSync mapInput
        map = JSON.parse utility.read mapInput
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

buildFile = (config, file) ->
    outputFile = getOutputFile config, file
    if not fs.existsSync file
        # delete source map files
        copySourceMap config, file, outputFile, true
        deleteFile outputFile
        return
    id = getModuleId config, file
    input = utility.read file
    output = "(function(){require.register('#{id}',function(module,exports,require){#{input}\n})})()"
    utility.write outputFile, output
    log config, "Wrapped #{outputFile}"
    # copy the mapFile if it exists
    if config.output.debug
        copySourceMap config, file, outputFile

buildIncludes = (config) ->
    return unless config.output.include?
    list = utility.list config.output.directory, {include:".js",exclude:[config.output.include.name,"require.js"]}
    list = list.map (x) ->
        np.relative(config.output.directory, x).replace(/\\/g,'\/')
    # sort shortest to longest
    list = list.sort (a,b) -> a.length - b.length
    script = ""
    base = config.output.include.base ? ""
    for file in list
        script += """document.writeln("<script src='#{base}#{file}'></script>");\n"""
    includeFile = np.join config.output.directory, config.output.include.name
    utility.write includeFile, script
    log config, "Created #{includeFile}"

copyRequire = (config) ->
    source = np.join __dirname, '../browser/require.js'
    target = np.join config.output.directory, 'require.js'
    if not fs.existsSync target
        utility.copy source, target
        log config, "Copied #{target}"

exports.build = (config, callback) ->
    list = utility.list config.input.directory, {include: ".js"}
    for file in list
        buildFile config, file
    buildIncludes config
    copyRequire config
    callback?()
exports.watch = (config) ->
    buildIncludes config
    copyRequire config
    watcher.watchDirectory config.input.directory, {include: ".js",initial:false},
        (file, curr, prev, change) ->
            buildFile config, file
            if change is "deleted" or change is "created"
                buildIncludes config
