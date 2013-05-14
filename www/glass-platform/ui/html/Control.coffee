UiControl = require('../Control')
{isElement,isNode,createElement} = require './index'

module.exports = exports =
    Control = UiControl.extend
        id: 'glass.ui.html.Control'
        properties:
            initialize: initialize = ->
                # instantiate the element if necessary
                if Object.isString @element
                    @element = createElement @element
                # make sure the element is a valid node
                throw new Error "element property is required" unless isNode @element
                # set the container property
                @container ?= @element
                # find the parent element
                parentNode =
                    if isElement @parent.container
                        @parent.container
                    else if isElement @parent
                        @parent
                    else if global.window?
                        global.window.document.body
                # add our element to our parent node
                parentNode.appendChild @element
                # finally, we call subclass initialize
                @inner initialize
            dispose: dispose = ->
                # remove our element from the DOM now.
                @element.parentNode.removeChild @element
                @inner dispose
            element:
                description: '''
                    The actual DOM node or element.
                    This can also be set to a tag name or html element declaration.
                    If a string it will be converted to an element at construction.
                    '''
                value: 'span'
            container:
                description: 'The element to add children to.  Usually same as this.element.'

if typeof describe is 'function'
    assert = require 'assert'
    describe 'glass.ui.html.Control', ->
        if global.window
            it 'should be able to add to window', ->
                control = new Control
                    parent: global
                    element: createElement '<span>Test</span>'
                # check that parent is the body
                assert.equal window.document.body, control.element.parentNode
                # check that the last child in the body is the element
                assert.equal window.document.body.lastChild, control.element
                # now dispose the control
                control.dispose()
                # and make sure the element was actually removed
                assert not control.element.parentNode?

