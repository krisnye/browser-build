source = 'src'
node = 'lib'

config =
    input:
        "browser-build": node
        "sugar": true           # built for testing
    output:
        directory: 'www'
        debug: true
        test: 'mocha'
        include:
            name: 'includes.js'
            base: './'

browserBuilder = require "./#{source}"
utility = require "./#{source}/utility"

buildCommon = ->
    utility.copyMetadata '.', node

task 'build', build = (callback) ->
    buildCommon()
    utility.buildCoffee source, node, ->
        browserBuilder.build config, callback
task 'watch', ->
    buildCommon()
    utility.watchCoffee source, node
    browserBuilder.watch config
task 'publish', ->
    build ->
        utility.spawn "npm.cmd publish #{node}"
