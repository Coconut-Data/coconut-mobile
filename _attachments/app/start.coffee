# Make these global so that plugins can use them

global.$ = require 'jquery'
global.Backbone = require 'backbone'
global._ = require 'underscore'
global.moment = require 'moment'

Backbone.$  = $

Coconut = require './Coconut'

Router = require './Router'

appCacheNanny = require 'appcache-nanny'

window.Coconut = new Coconut()

window.Coconut.router = new Router()
Backbone.history.start()

# Note that this function is called below
