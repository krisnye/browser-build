
if typeof describe is 'function'
    assert = require 'assert'
    r = require '../www/require'
    describe 'require', ->
        describe 'normalize', ->
            it "glass/index + ./global should be glass.global", ->
                assert.equal "glass/global", r.normalize "glass/index", "./global"
