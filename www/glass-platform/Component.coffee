require './global'

generateId = (parent, type) ->
    name = type.name
    throw new Error "type did not have a name: #{type}" unless name?
    counts = parent._Component_generateId_counts ?= {}
    count = counts[name] ?= 0
    count++
    counts[name] = count
    return "#{name}_#{count}"

module.exports = Component = class glass_Component
    constructor: (properties) ->
        @initialize properties
        @

isPrimitive = (object) ->
    Object.isNumber(object) or Object.isBoolean(object) or Object.isString(object)

Component.normalizeProperties = (properties={}, definingClass) ->
    for name, property of properties
        if Object.isFunction(property)
            property =
                writable: false
                value: property
        else if not property? or isPrimitive(property) or Object.isArray(property)
            property =
                value: property

        if not property.get? and not property.set? and not property.hasOwnProperty('value')
            property.value = null

        if property.hasOwnProperty 'value'
            # default property values to writable
            property.writable ?= true

        # set the id of functions to their property name
        if Object.isFunction property.value
            property.value.id ?= name

        if definingClass?
            property.definingClass ?= definingClass
            if Object.isFunction property.value
                property.value.definingClass ?= definingClass
        properties[name] = property
    properties

Component.defineProperties = (object, properties, definingClass) ->
    properties = Component.normalizeProperties properties, definingClass
    Object.defineProperties object, properties
    properties

Component.disposeProperties = (object) ->
    for key, value of object
        if value? and value.parent is object and Object.isFunction value.dispose
            value.dispose()
    return

Component.id = "glass.Component"
Component.toString = -> @id
Component.valueOf = -> @value ? @id

properties =
    # composition
    id:
        get: -> @_id
        set: (value) ->
            throw new Error "id has already been set to #{@_id}" if @_id?
            @_id = value
    parent:
        get: -> @_parent
        set: (value) ->
            throw new Error "parent has already been set to #{@_parent}" if @_parent?
            @_parent = value
    inner:
        description: "Calls the subclass defined function if present."
        value: (fn, args...)->
            # get and cache the name of the underride function
            innerName = fn.innerName ?= getUnderrideName fn.definingClass, fn.id
            @[innerName]?.apply @, args
    # lifecycle
    initialize: initialize = (properties) ->
        throw new Error "properties object is required #{properties}" unless properties?
        throw new Error "parent is required" unless properties.parent?
        # first set ourselves onto parent
        parent = properties.parent
        id = properties.id ?= generateId parent, @constructor
        parent[id] = @
        # second we set all properties in case setters access parent
        for key, value of properties
            @[key] = value
        # finally we call subclass initializer
        @inner initialize
    dispose: dispose = ->
        if @_parent?
            Component.disposeProperties @
            if @_parent is global
                delete @_parent[@id]
            else
                @_parent[@id] = null
            @_parent = null
            @inner dispose
        return
    disposed:
        get: -> @_parent is null
    # discovery
    get: (id, parsed) ->
        throw new Error "id is required" unless id?
        value = @[id]
        if value?
            if value.disposed is true
                value = null
            else
                return value
        # we only throw error from the original method call.
        throwError = not parsed?
        # now we have to look for it
        # parse the id if it matches our format
        if not parsed?
            colon = id.indexOf ':'
            if colon > 0
                parsed =
                    type: id.substring 0, colon
                    properties: JSON.parse id.substring colon + 1
            else
                parsed = false
        # if we recognize the parse object then
        # check for a local factory of its type
        if parsed
            type = parsed.type
            properties = parsed.properties
            # look for a factory method with that type
            factory = this[type]
            if Object.isFunction factory
                # set this as the parent on the properties
                properties.parent = @
                isClass = factory.properties?
                if isClass
                    value = new factory properties
                else
                    value = factory properties
        # if we don't have a value, try to get from parent
        value ?= @parent.get?(id, parsed)
        if value?
            # cache the result locally for next time it's requested
            this[id] = value
        else if throwError
            throw new Error "Component not found: #{id}"
        return value

Component.properties = Component.defineProperties Component.prototype, properties, Component

getUnderrideName = (baseDefiningClass, name) ->
    "#{baseDefiningClass.name}_subclass_#{name}"

getBaseDefiningClass = (classDefinition, properties, name) ->
    baseProperty = properties[name]
    # now traverse the underride chain.
    while true
        baseFunction = baseProperty.value
        baseDefiningClass = baseProperty.definingClass
        # search the text for a call to the underride function
        underrideName = getUnderrideName baseDefiningClass, name
        callsUnderride =
            baseFunction.toString().has(underrideName) or
            baseFunction.toString().has(/\binner\b/)
        if not callsUnderride
            throw new Error "#{classDefinition.name}.#{name} cannot be defined because #{baseDefiningClass.name}.#{name} does not call #{underrideName}."
        # now check to see if it has already been underridden
        underrideProperty = properties[underrideName]
        if underrideProperty?
            baseProperty = underrideProperty
        else
            return baseDefiningClass
    return

underride = (classDefinition, properties, rootDefiningClass, name, fn) ->
    baseDefiningClass = getBaseDefiningClass classDefinition, properties, name
    properties[getUnderrideName baseDefiningClass, name] = fn
    return

extend = (baseClass, subClassDefinition) ->
    throw new Error "missing id property" unless Object.isString subClassDefinition?.id

    subClassDefinition.name = subClassDefinition.id.replace /[\.\/]/g, '_'

    subClass = eval """
        (function #{subClassDefinition.name}(properties) {
            this.initialize(properties);
        })
    """

    subProperties = subClassDefinition.properties = Component.normalizeProperties subClassDefinition.properties, subClass
    prototype = subClass.prototype
    properties = Object.clone baseClass.properties

    for name, property of subProperties
        baseProperty = properties[name]
        if Object.isFunction baseProperty?.value
            if not Object.isFunction property.value
                throw new Error "Functions can only be overridden with other functions: #{property.value}"
            # if method defined in A, but not overrode in B, then C
            # must override the correct name from A
            underride subClassDefinition, properties, baseProperty.definingClass, name, property.value
        else
            properties[name] = property

    subClassDefinition.properties = properties
    Object.merge subClass, subClassDefinition

    Component.defineProperties prototype, properties, subClass
    # add an extend method to the subclass
    subClass.extend = (subClassDefinition) -> extend subClass, subClassDefinition
    subClass

Component.extend = (subClassDefinition) ->
    extend Component, subClassDefinition

if typeof describe is 'function'
    assert = require 'assert'
    describe 'glass.Component', ->
        it "should have an id", ->
            assert Object.isString Component.id
        it "its toString should return it's id", ->
            assert.equal Component.toString(), "glass.Component"
        it "should have a name", ->
            assert.equal Component.name, "glass_Component"
        describe '#dispose', ->
            it 'should mark self disposed', ->
                a = new Component parent:global
                a.dispose()
                assert a.disposed
            it 'should dispose of children', ->
                a = new Component parent:global
                b = new Component parent:a
                a.dispose()
                assert b.disposed
            it 'should remove property from parent', ->
                a = new Component parent:global
                a.dispose()
                assert not global[a.id]?
        describe '#defineProperties', ->
            it "should allow primitive values", ->
                object = {}
                Component.defineProperties object,
                    f: -> "function"
                    i: 2
                    b: true
                    a: []
                    s: "hello"
                assert Object.isFunction object.f
                assert.equal object.f(), "function"
                assert.equal object.i, 2
                assert.equal object.b, true
                assert Object.equal object.a, []
                assert.equal object.s, "hello"
        describe '#Constructor', ->
            it 'should set itself as property on parent', ->
                a = new Component parent:global
                assert Object.isString a.id
                assert.equal global[a.id], a
                a.dispose()
            it 'should require parent', ->
                assert.throws -> a = new Component
            it 'should generate a missing id', ->
                a = new Component parent:global
                assert Object.isString a.id
                a.dispose()
        describe "#get", ->
            it 'should throw exception if instance not found', ->
                a = new Component parent:global
                assert.throws -> a.get "foo"
                a.dispose()
            it 'should create instances with factory', ->
                a = new Component parent:global
                b = new Component parent: a
                # register a factory on the parent a
                a[Component] = Component
                c = b.get 'glass.Component:{"x":2,"y":3}'
                assert.equal c.x, 2
                assert.equal c.y, 3
                assert.equal c.parent, a
                a.dispose()
        describe 'extend', ->
            it 'should inherit base properties', ->
                SubComponent = Component.extend
                    id: 'SubComponent'
                assert SubComponent.properties.id?
            it 'should allow underriding constructors and functions', ->
                SubComponent = Component.extend
                    id: 'SubComponent'
                    properties:
                        initialize: ->
                            @constructorCalled = true
                            @
                        dispose: ->
                            @disposeCalled = true
                            return
                sub = new SubComponent parent:global
                assert sub.constructorCalled
                sub.dispose()
                assert sub.disposed
                assert sub.disposeCalled
            it 'should allow recursive extension', ->
                AComponent = Component.extend
                    id: 'AComponent'
                    properties:
                        dispose: -> # does not call AComponent_subclass_dispose
                BComponent = AComponent.extend
                    id: 'BComponent'
                    properties:
                        foo: ->
            it 'should not allow final functions to be underridden', ->
                AComponent = Component.extend
                    id: 'AComponent'
                    properties:
                        dispose: -> # does not call AComponent_subclass_dispose
                assert.throws ->
                    BComponent = AComponent.extend
                        id: 'BComponent'
                        properties:
                            dispose: -> # cannot underride this method

