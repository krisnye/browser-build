require 'sugar'

# get the global object
global = do -> @
# define some global functions we need for compatibility between browser and nodejs
global.global ?= global
# export the global object
module.exports = exports = global
