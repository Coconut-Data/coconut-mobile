_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
BackbonePouch = require 'backbone-pouch'
appCacheNanny = require 'appcache-nanny'

window.PouchDB = require 'pouchdb'
require('pouchdb-all-dbs')(window.PouchDB)

Cookie = require 'js-cookie'
window.Cookie = Cookie
LoginView = require './views/LoginView'

User = require './models/User'

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

        startApp = ->
          _.delay appCacheNanny.start, 5000
          Coconut.router.startApp()

        resetDatabase = (message) ->
          console.log "RESETTING DATABASE"
          console.log message
          $('.coconut-mdl-card__title').html message
          $('#content').html "<h2>#{message}</h2>"

          _.delay ->
            Cookie('current_user',"")
            Cookie('current_password',"")
            Coconut.database.destroy().then ->
              document.location.reload()
          ,3000

        user = new User
          _id: "user.#{user}"
        user.fetch
          success: =>
            if user.passwordIsValid password
              startApp()
            else
              # Encryption key is wrong, so destroy it and try again
              resetDatabase "Password is invalid, resetting database in 3 seconds."
          error: (error) ->
            resetDatabase "Username and password aren't in database, resetting database in 3 seconds."

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

          Cookie("coconut.config", JSON.stringify Coconut.config.toJSON())

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
                console.log "Clearing configuration params"
                document.location = document.location.origin
              ,5000

        # First check the URL for configuration, then check cookie, finally prompt
        [cloudUrl, appName, username, password, showPrompt] = [getParameterByName("cloudUrl"), getParameterByName("appName"), getParameterByName("username"), getParameterByName("password"), getParameterByName("showPrompt")]

        configFromCookie = JSON.parse Cookie('coconut.config') if Cookie('coconut.config') and Cookie('coconut.config') isnt ""
        console.log configFromCookie
        if configFromCookie? and configFromCookie.cloud? and configFromCookie.cloud_database_name? and configFromCookie.cloud_credentials?
          cloudUrl = cloudUrl or configFromCookie.cloud
          appName = appName or configFromCookie.cloud_database_name
          username = username or configFromCookie.cloud_credentials.split(":")[0]
          password = password or configFromCookie.cloud_credentials.split(":")[1]

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
  anotherLoginView = new LoginView()
  anotherLoginView.alternativeLoginCallback = () ->
    username = $('#username').val().toLowerCase()
    password = $('#password').val()
    Cookie('current_user', username)
    Cookie('current_password', password)
    initializeDatabaseAndStart(username,password)

  anotherLoginView.render()
  # Destroys all CouchDBs for this domain
  $("nav").append("<button id='resetAll' type='button'>RESET ALL</button>")

  $("#resetAll").click  ->
    if prompt("Enter reset password") is "newclear"
      $(".mdl-layout__drawer").toggleClass("is-visible")
      $("#content").html ""
      PouchDB.allDbs().then (dbs) ->
        for db in dbs
          (new PouchDB(db)).destroy()
          .then () -> $("#content").append "<h2>Deleted #{db}</h2>"
          .catch (error) -> $("#content").append "Error deleting #{db}: #{JSON.stringify error}"
      _.delay ->
        $('#content').append "<h1>Refreshing in 1 second</h1>"
        Cookie('current_user', '')
        Cookie('current_password', '')
        Cookie('coconut.config', '')
      , 4000

      _.delay ->
        document.location.reload()
      , 5000
    else
      alert "Incorrect reset password"
