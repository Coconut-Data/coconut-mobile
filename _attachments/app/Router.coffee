_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

window.PouchDB = require 'pouchdb'
require('pouchdb-all-dbs')(window.PouchDB)

replicationStream = require('pouchdb-replication-stream')
PouchDB.plugin(replicationStream.plugin)
PouchDB.adapter('writableStream', replicationStream.adapters.writableStream)

Config = require './models/Config'
HelpView = require './views/HelpView'
AboutView = require './views/AboutView'
LoginView = require './views/LoginView'
ManageView = require './views/ManageView'
MenuView = require './views/MenuView'
HeaderView = require './views/HeaderView'
Question = require './models/Question'
QuestionCollection = require './models/QuestionCollection'
QuestionView = require './views/QuestionView'
# Make this global so that plugins can create new results
global.Result = require './models/Result'
global.ResultsView = require './views/ResultsView'
ResultCollection = require './models/ResultCollection'
SelectApplicationView = require './views/SelectApplicationView'
SettingsView = require './views/SettingsView'
SetupView = require './views/SetupView'
SyncView = require './views/SyncView'
User = require './models/User'
UserCollection = require './models/UserCollection'

Cookie = require 'js-cookie'
JSZip = require 'jszip'
global.FileSaver = require 'file-saver'

class Router extends Backbone.Router
  # This gets called before a route is applied
  execute: (callback, args, name) ->
    if name is "setup"
      callback.apply(this, args) if callback
    else
      Coconut.databaseName = args.shift()
      if Coconut.databaseName
        @userLoggedIn
          success: ->
            Coconut.headerView.render()
            Coconut.menuView.render()
            Coconut.syncView.update()
            callback.apply(this, args) if callback
      else
        # forced user logout. User should not be logged in at this point.
        User.logout()
        Coconut.headerView = (new HeaderView()).render()
        selectDatabaseView = new SelectApplicationView()
        selectDatabaseView.render()


  routes:
    # Note that the database param gets removed from the args pased to the route handler in the execute function
    ":database/login": "login"
    ":database/logout": "logout"
    ":database/show/results/:question_id": "showResults"
    ":database/new/result/:question_id": "newResult"
    ":database/show/result/:result_id": "showResult"
    ":database/edit/result/:result_id": "editResult"
    ":database/delete/result/:result_id": "deleteResult"
    ":database/delete/result/:result_id/:confirmed": "deleteResult"
    ":database/reset/database": "resetDatabase"
    ":database/sync": "sendAndGet"
#    "sync/send": "syncSend"
#    "sync/get": "syncGet"
    ":database/settings": "settings"
    ":database/help": "help"
    ":database/help/:helpDocument": "help"
    ":database/manage": "manage"
    ":database/send/backup": "sendBackup"
    ":database/save/backup": "saveBackup"
    ":database/get/cloud/results": "getCloudResults"
    "setup": "setup"
# TODO handle cloudUrl with http:// in it
    "setup/:httpType/:cloudUrl/:applicationName/:cloudUsername/:cloudPassword": "setup"
    ":database": "default"
    "": "default"
    ":database/*noMatch": "noMatch"
    "*noMatch": "noMatch"

  noMatch: =>
    if @routeFails
      console.error "Invalid URL, no matching route"
      $("#content").html "Page not found."
    else
      @routeFails = true
      # Delay needed in case routes are added by plugins
      console.debug "Trying route again in 1 second"
      _.delay =>
        @.navigate Backbone.history.getFragment(), {trigger: true}
      ,1000

  default: ->
    defaultQuestion = Coconut.questions.filter (question) ->
      question.get("default") is true
    if defaultQuestion.length is 0
      defaultQuestion = Coconut.questions.first()
    Coconut.router.navigate "#{Coconut.databaseName}/show/results/#{defaultQuestion.get "id"}", trigger:true

  setup: ->
    setupView = new SetupView()
    setupView.render()

  userLoggedIn: (options) ->
    User.isAuthenticated
      success: (user) ->
        Coconut.menuView.render()
        options.success(user)
      error: ->
        Coconut.loginView = new LoginView()
        Coconut.loginView.callback = options.success
        Coconut.loginView.render()
        $('.mdl-layout__drawer-button').hide()

  help: (helpDocument) ->
    Coconut.helpView ?= new HelpView()
    if helpDocument?
      Coconut.helpView.helpDocument = helpDocument
    else
      Coconut.helpView.helpDocument = null
    Coconut.helpView.render()

  login: ->
    Coconut.loginView = new LoginView()
    Coconut.loginView.callback =
      success: ->
        Coconut.router.navigate("",true)

  logout: ->
    User.logout()
    Coconut.router.navigate("",true)
    document.location.reload()


  syncSend: (action) ->
    Coconut.router.navigate("",false)
    Coconut.syncView.render()
    Coconut.syncView.sync.sendToCloud
      success: ->
        Coconut.syncView.update()
      error: ->
        Coconut.syncView.update()

  syncGet: (action) ->
    Coconut.router.navigate("",false)
    Coconut.syncView.render()
    Coconut.syncView.sync.getFromCloud()

  sendAndGet: (action) ->
    Coconut.router.navigate("##{Coconut.databaseName}",false)
    Coconut.syncView.render()
    $("#status").html "Sending data..."
    Coconut.syncView.sync.sendToCloud
      completeResultsOnly: true
      success: ->
        $("#status").html "Receiving data..."
        Coconut.syncView.sync.getFromCloud
          success: ->
            $("#status").html "Complete!"
            document.location.reload()
          error: ->
            $("#log").show()
            Coconut.debug "Refreshing app in 5 seconds, please wait"
            $("#status").html "Error occurred, app refreshing in 5 seconds!"
            _.delay ->
              document.location.reload()
            , 5000
      error: (error) ->
        $("#log").show()
        Coconut.debug "Error sending data to cloud, proceeding to get updates from cloud."
        console.error error
        Coconut.syncView.sync.getFromCloud()


  newResult: (question_id) ->
    Coconut.questionView.readonly = false
    Coconut.questionView.result = new Result
      question: unescape(question_id)
    Coconut.questionView.model = new Question {id: unescape(question_id)}
    Coconut.questionView.model.fetch
      success: ->
        Coconut.questionView.render()


  showResult: (result_id) ->
    Coconut.questionView.readonly = true

    Coconut.questionView.result = new Result
      _id: result_id
    Coconut.questionView.result.fetch
      success: ->
        question = Coconut.questionView.result.question()
        Coconut.questionView.model = new Question
          id: question
        Coconut.questionView.model.fetch
          success: ->
            Coconut.questionView.render()

  editResult: (result_id) ->
    Coconut.questionView.readonly = false

    Coconut.questionView.result = new Result
      _id: result_id
    Coconut.questionView.result.fetch
      success: ->
        question = Coconut.questionView.result.question()
        if question?
          Coconut.questionView.model = new Question
            id: question
          Coconut.questionView.model.fetch
            success: ->
              Coconut.questionView.render()
        else # Reach here for USSD Notifications
          $("#content").html "
            <button id='delete' type='button'>Delete</button>
            <br/>
            <pre>#{JSON.stringify Coconut.questionView.result,null,2}</pre>

          "
          $("button#delete").click ->
            if confirm("Are you sure you want to delete this result?")
              Coconut.questionView.result.destroy
                success: ->
                  $("#content").html "Result deleted, redirecting..."
                  _.delay ->
                    Coconut.router.navigate("/",true)
                  , 2000

  deleteResult: (result_id, confirmed) ->
    Coconut.questionView.readonly = true

    Coconut.questionView.result = new Result
      _id: result_id
    Coconut.questionView.result.fetch
      success: ->
        question = Coconut.questionView.result.question()
        if question?
          if confirmed is "confirmed"
            Coconut.questionView.result.destroy
              success: ->
                Coconut.menuView.update()
                Coconut.router.navigate("#{Coconut.databaseName}/show/results/#{escape(Coconut.questionView.result.question())}",true)
          else
            Coconut.questionView.model = new Question
              id: question
            Coconut.questionView.model.fetch
              success: ->
                Coconut.questionView.render()
                $('#askConfirm').html "
                  <h4>Are you sure you want to delete this record?</h4>
                  <div id='confirm'>
                    <a href='##{Coconut.databaseName}/delete/result/#{result_id}/confirmed'><button class='mdl-button mdl-button--accent mdl-js-button mdl-js-ripple-effect'>Yes</button></a>
                    <a href='##{Coconut.databaseName}/show/results/#{escape(Coconut.questionView.result.question())}'><button class='mdl-button mdl-js-button mdl-js-ripple-effect'>Cancel</button></a>
                  </div>
                "
                $("#content form").css
                  "background-color": "rgba(0,0,0,0.1)"
                  "margin":"0px"
                  "padding":"0px 15px 15px"
                $("#content form label").css
                  "color":"rgb(63,81,181)"
        else
          Coconut.router.navigate("#{Coconut.databaseName}/edit/result/#{result_id}",true)

  showResults:(question_id) ->
    Coconut.resultsView ?= new ResultsView()
    Coconut.resultsView.question = new Question
      id: unescape(question_id)
    Coconut.resultsView.question.fetch
      success: ->
        Coconut.resultsView.render()

  resetDatabase: () ->
    if confirm "Are you sure you want to reset #{Coconut.databaseName}? All data that has not yet been sent to the cloud will be lost."
      Coconut.destroyApplicationDatabases
        applicationName: Coconut.databaseName
        success: ->

          # Forces a new login to occur
          Cookie('mobile_current_user', '')
          Cookie('mobile_current_password', '')

          cloudUrl = Coconut.config.get("cloud")
          applicationName = Coconut.config.get("cloud_database_name")
          [username,password] = Coconut.config.get("cloud_credentials").split(":")
          Coconut.router.navigate("setup/#{cloudUrl}/#{applicationName}/#{username}/#{password}",true)

  manage: ->
    Coconut.manageView ?= new ManageView( el: $("#content") )
    Coconut.manageView.render()

  settings: ->
    Coconut.settingsView ?= new SettingsView()
    Coconut.settingsView.render()

  startApp: (options) ->
    Coconut.config = new Config()
    Coconut.config.fetch
      error: ->
        Coconut.debug "Error loading config"
      success: ->

        # This makes sure all views are created and loads any classes that are necessary
        classesToLoad = [UserCollection, ResultCollection]

        startApplication = _.after classesToLoad.length, ->
          Coconut.questionView = new QuestionView()
          Coconut.menuView = new MenuView()
          Coconut.headerView = new HeaderView() if !Coconut.headerView
#          Coconut.headerView.render()
          Coconut.syncView = new SyncView()
          Coconut.syncView.sync.setMinMinsBetweenSync()
          Coconut.syncView.update()
          options.success()

        QuestionCollection.load
          error: (error) ->
            alert "Could not load #{ClassToLoad}: #{error}. Recommendation: Press get data again."
          success: ->
            _.each classesToLoad, (ClassToLoad) ->
              ClassToLoad.load
                success: ->
                  startApplication()
                error: (error) ->
                  alert "Could not load #{ClassToLoad}: #{error}. Recommendation: Press get data again."
                  #start application even on error to enable syncing to fix problems
                  startApplication()

module.exports = Router
