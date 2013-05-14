# properties
Object.merge exports,
    isNode: (a) -> a?.nodeName?
    isElement: (a) -> a?.tagName?
    createElement: do ->
        if global.document?.createElement?
            creator = global.document.createElement 'div'
            (html) ->
                if html.isId() # its just a tag name
                    return global.document.createElement html
                creator.innerHTML = html
                element = creator.firstChild
                if element?
                    creator.removeChild element
                element
        else
            -> throw new Error "Can't create elements without document"

# classes
Object.merge exports,
    Control: require './Control'

# namespaces


# tests
if typeof describe is 'function'
    assert = require 'assert'
    describe 'glass.ui.html', ->
        if global.window?
            describe 'createElement', ->
                it 'creates with correct tag, attributes and children', ->
                    element = exports.createElement '<div id="test">Test</div>'
                    assert.equal element.tagName, 'DIV'
                    assert.equal element.getAttribute('id'), 'test'
                    assert.equal element.innerHTML, 'Test'