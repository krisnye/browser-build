glassConfig =
    name: 'browser-build'
    source:
        directory: 'src'
    node:
        directory: 'lib'

browserConfig =
    input:
        "browser-build": "lib"
        "sugar": true           # built for testing
    output:
        directory: 'www'
        debug: true
        test: 'mocha'
        include:
            name: 'includes.js'
            base: './'

# TODO: move glass-platform to glass-build
glassBuilder = require "glass-build"
browserBuilder = require "./#{glassConfig.source.directory}"

task 'build', ->
    glassBuilder.build glassConfig, ->
        browserBuilder.build browserConfig
task 'watch', ->
    glassBuilder.watch glassConfig
    browserBuilder.watch browserConfig
task 'test' , ->
    glassBuilder.test glassConfig
task 'bump' , ->
    glassBuilder.bump glassConfig
task 'publish' , ->
    glassBuilder.publish glassConfig

