glassConfig =
    name: 'browser-build'
    coffee:
        input: 'src'
        output: 'lib'

browserConfig =
    input:
        "browser-build": "lib"
        "sugar": true           # built for testing
        "glass-platform": true  # built for testing
    output:
        directory: 'www'
        debug: true
        test: 'mocha'
        include:
            name: 'includes.js'
            base: './'

# TODO: move glass-platform to glass-build
glassBuilder = require "glass-platform/lib/build"
browserBuilder = require "./#{glassConfig.coffee.input}"

task 'build', ->
    glassBuilder.build glassConfig, ->
        browserBuilder.build browserConfig
task 'watch', ->
    glassBuilder.watch glassConfig
    browserBuilder.watch browserConfig
task 'test' , ->
    glassBuilder.test glassConfig
