_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

window.PouchDB = require 'pouchdb'
require('pouchdb-all-dbs')(window.PouchDB)

Config = require './models/Config'
HelpView = require './views/HelpView'
LoginView = require './views/LoginView'
MenuView = require './views/MenuView'
Question = require './models/Question'
QuestionCollection = require './models/QuestionCollection'
QuestionView = require './views/QuestionView'
Result = require './models/Result'
ResultsView = require './views/ResultsView'
ResultCollection = require './models/ResultCollection'
SelectApplicationView = require './views/SelectApplicationView'
SetupView = require './views/SetupView'
SyncView = require './views/SyncView'
User = require './models/User'
UserCollection = require './models/UserCollection'

Cookie = require 'js-cookie'

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
            callback.apply(this, args) if callback
      else
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
    ":database/configure": "configure"
    ":database/help": "help"
    ":database/help/:helpDocument": "help"
    "setup": "setup"
    "setup/:cloudUrl/:applicationName/:cloudUsername/:cloudPassword": "setup"
    ":database": "default"
    "": "default"
    "*noMatch": "noMatch"

  noMatch: ->
    console.error "Invalid URL, no matching route"
    $("#content").html "Page not found."

  default: ->
    defaultQuestion = Coconut.questions.filter (question) ->
      question.get("default") is true
    if defaultQuestion.length is 0
      defaultQuestion = Coconut.questions.first()
    Coconut.router.navigate "#{Coconut.databaseName}/show/results/#{defaultQuestion.get "id"}", trigger:true

  setup: (cloudUrl,applicationName,cloudUsername,cloudPassword) ->
    setupView = new SetupView()
    setupView.render()
    setupView.prefill
      "Cloud URL": cloudUrl
      "Application Name": applicationName
      "Cloud Username": cloudUsername
      "Cloud Password": cloudPassword

  userLoggedIn: (options) ->
    User.isAuthenticated
      success: (user) ->
        Coconut.menuView.render()
        options.success(user)
      error: ->
        Coconut.loginView = new LoginView()
        Coconut.loginView.callback = options.success
        Coconut.loginView.render()

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
    Coconut.loginView.render()

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
    Coconut.router.navigate("",false)
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
            _.delay ->
              document.location.reload()
            , 5000
      error: (error) ->
        $("#log").show()
        Coconut.debug "Error sending data to cloud, proceeding to get updates from cloud."
        Coconut.syncView.sync.getFromCloud()


  newResult: (question_id) ->
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
                Coconut.router.navigate("#{Coconut.database}/show/results/#{escape(Coconut.questionView.result.question())}",true)
          else
            Coconut.questionView.model = new Question
              id: question
            Coconut.questionView.model.fetch
              success: ->
                Coconut.questionView.render()
                $("#content").prepend "
                  <h2>Are you sure you want to delete this result?</h2>
                  <div id='confirm'>
                    <a href='##{Coconut.databaseName}/delete/result/#{result_id}/confirmed'>Yes</a>
                    <a href='##{Coconut.databaseName}/show/results/#{escape(Coconut.questionView.result.question())}'>Cancel</a>
                  </div>
                "
                $("#confirm a").button()
                $("#content form").css
                  "background-color": "#333"
                  "margin":"50px"
                  "padding":"10px"
                $("#content form label").css
                  "color":"white"
        else
          Coconut.router.navigate("#{Coconut.database}/edit/result/#{result_id}",true)

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
          Cookie('current_user', '')
          Cookie('current_password', '')

          cloudUrl = Coconut.config.get("cloud")
          applicationName = Coconut.config.get("cloud_database_name")
          [username,password] = Coconut.config.get("cloud_credentials").split(":")
          Coconut.router.navigate("setup/#{cloudUrl}/#{applicationName}/#{username}/#{password}",true)

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
          Coconut.syncView = new SyncView()
          # TODO background sync turned off
          # After 5 minutes, start the backgroundSync process
          #_.delay Coconut.syncView.sync.backgroundSync, 5*60*1000
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
