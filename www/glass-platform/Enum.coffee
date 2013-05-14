
module.exports = class Enum
    constructor: (@name, @value) ->
    toString: -> @name
    valueOf: -> @value

