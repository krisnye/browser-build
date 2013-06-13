source = 'src'
node = 'lib'

config =
    input:
        "": true
    output:
        directory: 'www/js'
        webroot: 'www'
        test: 'mocha'

browserBuilder = require "./#{source}"
utility = require "./#{source}/utility"

task 'build', build = (callback) ->
    console.log 'alpha'
    utility.buildCoffee source, node, ->
        console.log 'beta'
        browserBuilder.build config, callback
task 'watch', ->
    utility.watchCoffee source, node
    browserBuilder.watch config
