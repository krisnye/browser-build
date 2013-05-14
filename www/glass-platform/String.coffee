
Object.merge String.prototype,
    isId: -> /^[^\d\W]\w*$/.test @

if typeof describe is 'function'
    assert = require 'assert'
    describe 'String', ->
        describe '#isId', ->
            it "should match foo", -> assert "foo".isId()
            it "should not match <foo>", -> assert not "<foo>".isId()
            it "should not match 2foo", -> assert not "2foo".isId()

