Component = require '../Component'

module.exports = exports =
    Element = Component.extend
        id: 'glass.ui.Element'
        properties:
            visible: true
            draw: draw = (c) ->
                if @visible
                    @inner draw, c
            getBoundingRect: ->
            getBoundingSphere: ->
            getBoundingBox: ->
            pick: (ray, radius) ->

