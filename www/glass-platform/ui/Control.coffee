Element = require './Element'

module.exports = exports =
    Control = Element.extend
        id: 'glass.ui.Control'
        properties:
            # rectangle properties here.
            draw: draw = (c) ->
                # translate by position
                @inner draw, c
                # untranslate by position
            # position and size are determined dynamically by html elements.
            position: null
            size: null

