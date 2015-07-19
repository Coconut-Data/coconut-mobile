_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
BackbonePouch = require 'backbone-pouch'
appCacheNanny = require 'appcache-nanny'

Coconut = require './Coconut'
global.Coconut = Coconut # useful for debugging
Config = require './models/Config'
Router = require './Router'
Sync = require './models/Sync'

Backbone.sync = BackbonePouch.sync
  db: Coconut.database
  fetch: 'query'

Backbone.Model.prototype.idAttribute = '_id'

Coconut.router = new Router()

Coconut.database.get '_local/initial_load_complete', (error, result) ->

  if not error
    _.delay appCacheNanny.start, 5000
    Coconut.router.startApp()
  else
    throw error if (error.status isnt 404)

    getParameterByName = (name) ->
      match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search)
      match && decodeURIComponent(match[1].replace(/\+/g, ' '))

    configureApplicationAndSync = (cloudUrl, appName, username,password) ->
      Coconut.config = new Config
        cloud: cloudUrl
        cloud_database_name: appName
        cloud_credentials: "#{username}:#{password}"

      Coconut.config.save()

      sync = new Sync
      sync.replicateApplicationDocs
        error: (error) ->
          console.error "Updating application docs failed: #{JSON.stringify error}"
        success: ->
          Coconut.database.put {_id: '_local/initial_load_complete'}, (error, result) ->
            console.log error if error
          Coconut.router.startApp()
          _.delay ->
            # Use this to remove configuration params from the URL
            document.location = document.location.origin
          ,5000

    [cloudUrl, appName, username, password] = [getParameterByName("cloudUrl"), getParameterByName("appName"), getParameterByName("username"), getParameterByName("password")]

    if cloudUrl and appName and username and password
      configureApplicationAndSync(cloudUrl,appName,username,password)
    else

      cloudDefault = ""
      usernameDefault = ""
      passwordDefault = ""

      $.ajax
        url: "defaults.json",
        success: (result) ->
          if result
            cloudDefault = result.cloud
            [usernameDefault,passwordDefault] = result.cloud_credentials.split(":")

        complete: ->
          cloudUrl = prompt "Enter cloud URL", cloudDefault
          cloudUrl = cloudUrl.replace(/http:\/\//,"")
          appName = prompt("Enter application name")
          username = prompt "Enter cloud username", usernameDefault
          password = prompt "Enter cloud password", passwordDefault

          configureApplicationAndSync(cloudUrl, appName, username,password)
