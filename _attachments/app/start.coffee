$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
Coconut = require './Coconut'

Router = require './Router'

appCacheNanny = require 'appcache-nanny'

window.Coconut = new Coconut()

window.Coconut.router = new Router()
Backbone.history.start()

# Note that this function is called below
