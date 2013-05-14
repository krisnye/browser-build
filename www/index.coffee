require './global'
require './String'

# we write ourselves to the global object
global.glass = exports

# properties

# classes
Object.merge exports,
    Component: require './Component'
    Enum: require './Enum'

# namespaces
Object.merge exports,
    patch: require './patch'
    ui: require './ui'
