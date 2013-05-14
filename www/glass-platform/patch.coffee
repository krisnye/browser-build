require './global'

# target value should never include reference types from values
apply = (target, values, deleteUndefined = true) ->
    return Object.clone(values, true) unless values?.constructor is Object
    if target?.constructor isnt Object
        target = {}
    for key, value of values
        patchedValue = apply target[key], value, deleteUndefined
        if value is undefined and deleteUndefined
            delete target[key]
        else
            target[key] = patchedValue
    return target

# combines two patches to make a single patch
combine = (patch1, patch2) -> apply patch1, patch2, false

canWatch = (object) -> object? and typeof object is 'object'
# watches object for changes and calls the handler with patches
watch = (object, handler, callInitial = true) ->
    throw new Error "Cannot watch: #{object}" unless canWatch object
    # recurse watching and unwatching
    subWatchers = {}
    # pending patch allows several changes at simultaneous levels of the
    # heirarchy to be combined into a single patch call
    pendingPatch = null
    processPatch = (patchValues) ->
        # watch sub objects
        for name of patchValues
            # unwatch any current value being watched
            subWatchers[name]?()
            # now watch sub values if we can
            value = object[name]
            if canWatch value
                do ->
                    saveName = name # so it's not changed by other closures
                    subHandler = (patch) ->
                        basePatch = {}
                        basePatch[saveName] = patch
                        if pendingPatch?
                            pendingPatch = combine pendingPatch, basePatch
                        else
                            handler basePatch
                    subWatchers[saveName] = watch value, subHandler, false
        return
    watcher = (changes) ->
        pendingPatch = {}
        for change in changes
            pendingPatch[change.name] = object[change.name]
        processPatch pendingPatch
        process.nextTick ->
            handler pendingPatch
            pendingPatch = null
    # call process patch on the object to watch children
    processPatch object
    Object.observe object, watcher
    # return an function that lets us unwatch
    return ->
        Object.unobserve object, watcher
        # unwatch subWatchers
        for key, value of subWatchers
            value()

module.exports = exports =
    apply: apply
    combine: combine
    watch: watch

if typeof describe is 'function'
    assert = require 'assert'
    describe 'glass.patch', ->
        it 'should work', (done) ->
            source =
                name: 'Kris'
                age: 41
                children:
                    Sadera:
                        grandchildren:
                            One: 1
                            Two: 2
                    Orion: {}
            target = Object.clone source
            unwatch = watch source, (patch) ->
                target = apply target, patch
                # test that source and target are equivalent
                assert Object.equal source, target
                done()
                unwatch()
            source.name = 'Fred'
            source.children.Orion = {a:1,b:2}
            source.children.Orion.c = 12
            source.children.Sadera.grandchildren.three = 3



