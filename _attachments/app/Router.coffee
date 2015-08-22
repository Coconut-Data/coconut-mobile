_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $

Coconut = require './Coconut'
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
SyncView = require './views/SyncView'
User = require './models/User'
UserCollection = require './models/UserCollection'


class Router extends Backbone.Router
  routes:
    "login": "login"
    "logout": "logout"
    "show/results/:question_id": "showResults"
    "new/result/:question_id": "newResult"
    "show/result/:result_id": "showResult"
    "edit/result/:result_id": "editResult"
    "delete/result/:result_id": "deleteResult"
    "delete/result/:result_id/:confirmed": "deleteResult"
    "reset/database": "resetDatabase"
    "sync": "sendAndGet"
#    "sync/send": "syncSend"
#    "sync/get": "syncGet"
    "configure": "configure"
    "help": "help"
    "help/:helpDocument": "help"
    "": "default"

  userLoggedIn: (callback) ->
    User.isAuthenticated
      success: (user) ->
        Coconut.menuView.render()
        callback.success(user)
      error: ->
        Coconut.loginView.callback = callback
        Coconut.loginView.render()

  help: (helpDocument) ->
    @userLoggedIn
      success: ->
        Coconut.helpView ?= new HelpView()
        if helpDocument?
          Coconut.helpView.helpDocument = helpDocument
        else
          Coconut.helpView.helpDocument = null
        Coconut.helpView.render()

  login: ->
    Coconut.loginView.callback =
      success: ->
        Coconut.router.navigate("",true)
    Coconut.loginView.render()


  userWithRoleLoggedIn: (role,callback) =>
    @userLoggedIn
      success: (user) ->
        if user.hasRole role
          callback.success(user)
        else
          $("#content").html "<h2>User '#{user.username()}' must have role: '#{role}'</h2>"
      error: ->
        $("#content").html "<h2>User '#{user.username()}' must have role: '#{role}'</h2>"

  adminLoggedIn: (callback) ->
    @userLoggedIn
      success: (user) ->
        if user.isAdmin()
          callback.success(user)
      error: ->
        $("#content").html "<h2>Must be an admin user</h2>"

  logout: ->
    User.logout()
    Coconut.router.navigate("",true)
    document.location.reload()

  default: ->
    @userLoggedIn
      success: ->
        if User.currentUser.hasRole "reports"
          Coconut.router.navigate("reports",true)
        else
          Coconut.router.navigate "show/results/#{Coconut.questions.first().id}", true

  syncSend: (action) ->
    Coconut.router.navigate("",false)
    @userLoggedIn
      success: ->
        Coconut.syncView.render()
        Coconut.syncView.sync.sendToCloud
          success: ->
            Coconut.syncView.update()
          error: ->
            Coconut.syncView.update()

  syncGet: (action) ->
    Coconut.router.navigate("",false)
    @userLoggedIn
      success: ->
        Coconut.syncView.render()
        Coconut.syncView.sync.getFromCloud()

  sendAndGet: (action) ->
    Coconut.router.navigate("",false)
    @userLoggedIn
      success: ->
        Coconut.syncView.render()
        Coconut.syncView.sync.sendToCloud
          completeResultsOnly: true
          success: ->
            Coconut.syncView.sync.getFromCloud
              success: ->
                Coconut.debug "Refreshing app in 5 seconds, please wait"
          error: (error) ->
            Coconut.debug "Error sending data to cloud, proceeding to get updates from cloud."
            Coconut.syncView.sync.getFromCloud()


  newResult: (question_id) ->
    @userLoggedIn
      success: ->
        Coconut.questionView.result = new Result
          question: unescape(question_id)
        Coconut.questionView.model = new Question {id: unescape(question_id)}
        Coconut.questionView.model.fetch
          success: ->
            Coconut.questionView.render()


  showResult: (result_id) ->
    @userLoggedIn
      success: ->
        Coconut.questionView.readonly = true

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



  editResult: (result_id) ->
    @userLoggedIn
      success: ->
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
                (Editing not supported for USSD Notifications)
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
    @userLoggedIn
      success: ->
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
                    Coconut.router.navigate("show/results/#{escape(Coconut.questionView.result.question())}",true)
              else
                Coconut.questionView.model = new Question
                  id: question
                Coconut.questionView.model.fetch
                  success: ->
                    Coconut.questionView.render()
                    $("#content").prepend "
                      <h2>Are you sure you want to delete this result?</h2>
                      <div id='confirm'>
                        <a href='#delete/result/#{result_id}/confirmed'>Yes</a>
                        <a href='#show/results/#{escape(Coconut.questionView.result.question())}'>Cancel</a>
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
              Coconut.router.navigate("edit/result/#{result_id}",true)

  showResults:(question_id) ->
    @userLoggedIn
      success: ->
        Coconut.resultsView ?= new ResultsView()
        Coconut.resultsView.question = new Question
          id: unescape(question_id)
        Coconut.resultsView.question.fetch
          success: ->
            Coconut.resultsView.render()

  resetDatabase: () ->
    confirmReset = ->
      if confirm "Are you sure you want to reset the database? All data that has not yet been sent to the cloud will be lost."
        Coconut.database.destroy (error, result) ->
          cloudUrl = Coconut.config.get("cloud")
          appName = Coconut.config.get("cloud_database_name")
          [username,password] = Coconut.config.get("cloud_credentials").split(":")
          Coconut.router.navigate("",true)

          document.location = document.location.origin + document.location.pathname + "?cloudUrl=#{cloudUrl}&appName=#{appName}&username=#{username}&password=#{password}&showPrompt=yes"

    # Allow database reset if there are no users to login as
    confirmReset() if Coconut.users.length is 0
    @userLoggedIn
      success: -> confirmReset()


  startApp: ->

    Coconut.config = new Config()
    Coconut.config.fetch
      error: ->
        Coconut.debug "Error loading config"
      success: ->
        $("header.coconut-drawer-header").html "
          <h3><span id='user'></span></h3>
          Last sync: <span class='sync-sent-status'></span>
        "
        $("nav.coconut-navigation").html(
          _([
            "#sync,sync,Sync data"
            "#logout,person,Logout"
            "#reset/database,warning,Reset database"
          ]).map (linkData) ->
            [url,icon,linktext] = linkData.split(",")
            "<a class='mdl-navigation__link' href='#{url}'><i class='mdl-color-text--accent material-icons'>#{icon}</i>#{linktext}</a><br/>"
          .join("")

          $("nav.coconut-navigation").on "click",".mdl-navigation__link", ->
            $(".mdl-layout__drawer").removeClass("is-visible")

        )

        # This makes sure all views are created and loads any classes that are necessary
        classesToLoad = [UserCollection, ResultCollection]

        startApplication = _.after classesToLoad.length, ->
          Coconut.loginView = new LoginView()
          Coconut.questionView = new QuestionView()
          Coconut.menuView = new MenuView()
          Coconut.syncView = new SyncView()
          # After 5 minutes, start the backgroundSync process
          _.delay Coconut.syncView.sync.backgroundSync, 5*60*1000
          Coconut.syncView.update()
          Backbone.history.start()

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
