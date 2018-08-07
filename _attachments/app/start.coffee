# Make these global so that plugins can use them
global.$ = require 'jquery'
global.Backbone = require 'backbone'
global._ = require 'underscore'
global.moment = require 'moment'

try
  localStorage.setItem("test", "value")
catch error
  console.log "Disk quota exceeded"
  console.error error

Backbone.$  = $

Coconut = require './Coconut'
global.Router = require './Router'
AppView = require './AppView'

appView = new AppView()
window.Coconut = new Coconut()

window.Coconut.router = new Router(appView)
Backbone.history.start()
