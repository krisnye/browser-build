glassConfig =
    name: name = 'browser-build'
    input: 'src'
    node:
        output: 'node'
browserConfig =
    input:
        directory: glassConfig.node.output
    output:
        directory: 'browser'
        name: name
        debug: true
        include:
            name: 'includes.js'
            base: './'

glassBuilder = require "glass-platform/node/build"
browserBuilder = require "./#{glassConfig.input}"

task 'build', ->
    glassBuilder.build glassConfig, ->
        browserBuilder.build browserConfig
task 'watch', ->
    glassBuilder.watch glassConfig
    browserBuilder.watch browserConfig
task 'test' , ->
    glassBuilder.test glassConfig
