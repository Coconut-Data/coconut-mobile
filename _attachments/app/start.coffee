_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
BackbonePouch = require 'backbone-pouch'
appCacheNanny = require 'appcache-nanny'

Cookie = require 'js-cookie'
LoginView = require './views/LoginView'

currentUser = Cookie('current_user')
currentPassword = Cookie('current_password')

# Note that this function is called below

initializeDatabaseAndStart = (user,password) ->
  global.username = user

  Coconut = require('./Coconut')
  global.Coconut = Coconut # useful for debugging
  Config = require './models/Config'
  Router = require './Router'
  Sync = require './models/Sync'

  Coconut.database.crypto(password).then ->

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

        [cloudUrl, appName, username, password, showPrompt] = [getParameterByName("cloudUrl"), getParameterByName("appName"), getParameterByName("username"), getParameterByName("password"), getParameterByName("showPrompt")]

        if showPrompt is "yes" or not (cloudUrl and appName and username and password)
          cloudUrl = prompt "Enter cloud URL", cloudUrl or ""
          appName = prompt "Enter application name", appName or ""
          username = prompt "Enter cloud username", username or ""
          password = prompt "Enter cloud password", password or ""

          configureApplicationAndSync(cloudUrl, appName, username,password)

        else if cloudUrl and appName and username and password
          configureApplicationAndSync(cloudUrl,appName,username,password)



if currentUser? and currentUser isnt "" and currentPassword?
  initializeDatabaseAndStart(currentUser,currentPassword)
else
  console.log "No user/pass in cookie"
  anotherLoginView = new LoginView()
  anotherLoginView.alternativeLoginCallback = () ->
    username = $('#username').val()
    password = $('#password').val()
    Cookie('current_user', username)
    Cookie('current_password', password)
    initializeDatabaseAndStart(username,password)

  anotherLoginView.render()
