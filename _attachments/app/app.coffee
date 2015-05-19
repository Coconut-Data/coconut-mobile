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
    "sync": "sync"
    "sync/send": "syncSend"
    "sync/get": "syncGet"
    "configure": "configure"
    "help": "help"
    "help/:helpDocument": "help"
    "csv/:question/startDate/:startDate/endDate/:endDate": "csv"
    "": "default"

  route: (route, name, callback) ->
    Backbone.history || (Backbone.history = new Backbone.History)
    if !_.isRegExp(route)
      route = this._routeToRegExp(route)
    Backbone.history.route(route, (fragment) =>
      args = this._extractParameters(route, fragment)
      callback.apply(this, args)

# Run this before
      $('#loading').slideDown()
      this.trigger.apply(this, ['route:' + name].concat(args))
# Run this after
      $('#loading').fadeOut()

    , this)

  userLoggedIn: (callback) ->
    User.isAuthenticated
      success: (user) ->
        callback.success(user)
      error: ->
        Coconut.loginView.callback = callback
        Coconut.loginView.render()

  csv: (question,startDate,endDate) ->
    @userLoggedIn
      success: ->
        if User.currentUser.hasRole "reports"
          csvView = new CsvView
          csvView.question = question
          csvView.startDate = endDate
          csvView.endDate = startDate
          csvView.render()

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
        $("#content").html ""


  configure: ->
    @userLoggedIn
      success: ->
        Coconut.localConfigView ?= new LocalConfigView()
        Coconut.localConfigView.render()

  editQuestion: (question_id) ->
    @userLoggedIn
      success: ->
        Coconut.designView ?= new DesignView()
        Coconut.designView.render()
        Coconut.designView.loadQuestion unescape(question_id)

  deleteQuestion: (question_id) ->
    @userLoggedIn
      success: ->
        Coconut.questions.get(unescape(question_id)).destroy
          success: ->
            Coconut.menuView.render()
            Coconut.router.navigate("manage",true)


  syncSend: (action) ->
    Coconut.router.navigate("",false)
    @userLoggedIn
      success: ->
        Coconut.syncView ?= new SyncView()
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
        Coconut.syncView ?= new SyncView()
        Coconut.syncView.render()
        Coconut.syncView.sync.getFromCloud()

  manage: ->
    @adminLoggedIn
      success: ->
        Coconut.manageView ?= new ManageView()
        Coconut.manageView.render()


  newResult: (question_id) ->
    @userLoggedIn
      success: ->
        Coconut.questionView ?= new QuestionView()
        Coconut.questionView.result = new Result
          question: unescape(question_id)
        Coconut.questionView.model = new Question {id: unescape(question_id)}
        Coconut.questionView.model.fetch
          success: ->
            Coconut.questionView.render()


  showResult: (result_id) ->
    @userLoggedIn
      success: ->
        Coconut.questionView ?= new QuestionView()
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
        Coconut.questionView ?= new QuestionView()
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
        Coconut.questionView ?= new QuestionView()
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
    @userLoggedIn
      success: ->
        if confirm "Are you sure you want to reset the database? All data that has not yet been sent to the cloud will be lost."
          database.destroy (error, result) ->
            Coconut.router.navigate("",true)
            document.location.reload()


  startApp: ->
    Coconut.config = new Config()
    Coconut.config.fetch
      success: ->
        if Coconut.config.local.get("mode") is "cloud"
          $("body").append "
            <style>
              .leaflet-map-pane {
                    z-index: 2 !important;
              }
              .leaflet-google-layer {
                    z-index: 1 !important;
              }
            </style>
          "
        $("#footer-menu").html "
          <center>
          <span style='font-size:75%;display:inline-block'>
            <span id='district'></span><br/>
            <span id='user'></span>
          </span>
          <a href='#login'>Login</a>
          <a href='#logout'>Logout</a>
          #{
          if Coconut.config.local.get("mode") is "cloud"
            "<a id='reports-button' href='#reports'>Reports</a>"
          else
            "
              <a href='#sync/send'>Send data (last success: <span class='sync-sent-status'></span>)</a>
              <a href='#sync/get'>Get data (last success: <span class='sync-get-status'></span>)</a>
              <a href='#reset/database'>Reset database</a>
            "
          }
          &nbsp;
          <a id='manage-button' style='display:none' href='#manage'>Manage</a>
          &nbsp;
          <a href='#help'>Help</a>
          <span style='font-size:75%;display:inline-block'>Version<br/><span id='version'></span></span>
          <span style='font-size:75%;display:inline-block'><br/><span id='databaseStatus'></span></span>
          </center>
        "
        $("[data-role=footer]").navbar()
        $('#application-title').html Coconut.config.title()

        # This makes sure all views are created and loads any classes that are necessary
        classesToLoad = [UserCollection, ResultCollection]

        startApplication = _.after classesToLoad.length, ->
          Coconut.loginView = new LoginView()
          Coconut.questionView = new QuestionView()
          Coconut.menuView = new MenuView()
          Coconut.syncView = new SyncView()
          Coconut.menuView.render()
          Coconut.syncView.update()
          Backbone.history.start()

        QuestionCollection.load
          error: (error) ->
            alert "Could not load #{ClassToLoad}: #{error}. Recommendation: Press get data again."
          success: ->

            _.each classesToLoad, (ClassToLoad) ->
              ClassToLoad.load
                success: -> startApplication()
                error: (error) ->
                  alert "Could not load #{ClassToLoad}: #{error}. Recommendation: Press get data again."
                  #start application even on error to enable syncing to fix problems
                  startApplication()

      error: ->
        Coconut.localConfigView ?= new LocalConfigView()
        Coconut.localConfigView.render()

Coconut = {}
Coconut.router = new Router()

database.get '_local/initial_load_complete', (error, result) ->

  if error
    throw error if (error.status isnt 404)

    cloudUrl = prompt "Enter cloud URL", "http://mikeymckay.iriscouch.com"
    cloudUrl = cloudUrl.replace(/http:\/\//,"")
    Coconut.config = new Config
      cloud: cloudUrl
      cloud_database_name: prompt("Enter application name")
      cloud_credentials: "#{prompt "Enter cloud username", "admin"}:#{prompt "Enter cloud password", "admin"}"

    Coconut.config.save()
    console.log Coconut.config.toJSON()


    sync = new Sync
    sync.replicateApplicationDocs
      error: (error) ->
        console.error "Updating application docs failed: #{JSON.stringify error}"
      success: ->
        database.put {_id: '_local/initial_load_complete'}, (error, result) ->
          console.log error if error
        Coconut.router.startApp()
        _.delay ->
          $("#log").html ""
        ,5000

  else
    _.delay appCacheNanny.start, 5000
    Coconut.router.startApp()

Coconut.debug = (string) ->
  console.log string
  $("#log").append string + "<br/>"
