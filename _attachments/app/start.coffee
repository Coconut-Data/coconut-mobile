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

console.log "ZZZZ"

console.log navigator.serviceWorker

if navigator.serviceWorker?
  console.log "Adding load event listener"
  window.addEventListener 'load', =>
    navigator.serviceWorker.register('/sw.js').then (registration) =>
      console.log('ServiceWorker registration successful with scope: ', registration.scope)
    , (err) =>
      console.log('ServiceWorker registration failed: ', err)

  #window.applicationCache.addEventListener 'updateready', =>
  #if confirm "A new version of the app is available, click Ok to load it"
  #  document.location.reload()
  #, false

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
