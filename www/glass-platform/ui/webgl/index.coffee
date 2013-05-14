Enum = require '../../Enum'

# re-export all the gl-matrix properties
Object.merge exports, require 'gl-matrix'

# export all of the constants out as Enums values
for key, value of webglConstants = require './constants'
    exports[key] = new Enum key, value

Object.merge exports,
    Canvas: require './Canvas'