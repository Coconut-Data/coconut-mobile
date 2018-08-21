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

window.isCordovaApp = document.URL.indexOf('http://') is -1 and document.URL.indexOf('https://') is -1

Backbone.$  = $

Coconut = require './Coconut'
global.Router = require './Router'
AppView = require './AppView'

appView = new AppView()
window.Coconut = new Coconut()

if isCordovaApp
  document.addEventListener 'deviceready', =>
    window.Coconut.router = new Router(appView)
    Backbone.history.start()
else
  window.Coconut.router = new Router(appView)
  Backbone.history.start()
