_ = require 'underscore'
$ = require 'jquery'
Backbone = require 'backbone'
Backbone.$  = $
radix64 = require('radix-64')()

window.PouchDB = require 'pouchdb'
pouchDBOptions = {
  auto_compaction: true
}

if isCordovaApp
  PouchDB.plugin(require "pouchdb-adapter-cordova-sqlite")
  pouchDBOptions['adapter'] = 'cordova-sqlite'

require('pouchdb-all-dbs')(window.PouchDB)

PouchDB.plugin(require 'pouchdb-upsert')


replicationStream = require('pouchdb-replication-stream')
PouchDB.plugin(replicationStream.plugin)
PouchDB.adapter('writableStream', replicationStream.adapters.writableStream)

Dialog = require '../js-libraries/modal-dialog'
Config = require './models/Config'
HelpView = require './views/HelpView'
global.AboutView = require './views/AboutView'
LoginView = require './views/LoginView'
global.ManageView = require './views/ManageView'
global.MenuView = require './views/MenuView'
global.HeaderView = require './views/HeaderView'
global.Question = require './models/Question'
QuestionCollection = require './models/QuestionCollection'
global.QuestionView = require './views/QuestionView'
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
MemoryStream = require 'memorystream'
global.FileSaver = require 'file-saver'
titleize = require "underscore.string/titleize"
underscored = require("underscore.string/underscored")

class Router extends Backbone.Router

  initialize: (appView) ->
    @appView = appView

  # This gets called before a route is applied
  execute: (callback, args, name) ->
    if name.match(/^(setup|selectApplication|presetInstall)/)
      callback.apply(this, args) if callback
    else
      # turn off residual spinner from other views that did not complete.
      Coconut.toggleSpinner(false)
      Coconut.databaseName = args.shift()
      document.title = _(document.location.hash.split("/")).map (fragment) ->
        titleize(fragment.replace('#',""))
      .join(": ")
      if Coconut.databaseName
        # SL - hack to reverse strange value in Coconut.databaseName that came out of the blue
        Coconut.databaseName = Coconut.database.name.replace(/coconut-/,"") if Coconut.databaseName is 'not-complete-panel'

        # Check the the db exists before trying to login
        db = new PouchDB("coconut-#{Coconut.databaseName}", pouchDBOptions)
        db.info()
        .then (info) =>
          if (info.doc_count is 0)
            # By opening an empty database we create it
            db.destroy().then =>
              alert("#{Coconut.databaseName} is empty - is the application installed?")
        .catch (error) =>
          alert("Error finding database: #{Coconut.databaseName}")

        User.isAuthenticated()
        .catch (error) =>
          console.info error
          Coconut.loginView = new LoginView()
          Coconut.loginView.callback = =>
            # This reload will force the page to reload and use cookies to login
            # It's a hack but it keeps things simple
            Coconut.headerView.render()
            Coconut.menuView.render()
            Coconut.syncView.update()
            callback.apply(this, args) if callback
          Coconut.loginView.render()
          throw "Waiting for login to proceed"
        .then =>
          Coconut.headerView.render()
          Coconut.menuView.render()
          Coconut.syncView.update()
          callback.apply(this, args) if callback
        .catch (error) =>
          console.error error

      else
        # forced user logout. User should not be logged in at this point.
        User.logout()
        Coconut.router.navigate("#selectapp",true)

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
    "setup/:httpType/:cloudUrl/:applicationName/:cloudUsername/:cloudPassword": "setup"
    "i/:installName": "presetInstall"
    "selectapp": "selectApplication"
    ":database": "default"
    "": "default"
    ":database/*noMatch": "noMatch"
    "*noMatch": "noMatch"

  noMatch: =>
    if @routeFails
      console.error "Invalid URL #{Backbone.history.getFragment()}, no matching route"
      $("#content").html "Loading. Please wait...."
    else
      console.log "ROUTE FAILS"
      @routeFails = true
      @targetURL = Backbone.history.getFragment()
      # Strange hack needed because plugins load routes
      @.navigate "##{Coconut.databaseName}", {trigger: true}
      _.delay =>
        @.navigate @targetURL, {trigger: true}
      , 100

  default: ->
    # Hack by SL to refresh to the plugin's default method.
    Backbone.history.loadUrl()

    if @defaultRouteRefreshCount > 50

      defaultQuestion = Coconut.questions.filter (question) ->
        question.get("default") is true
      if defaultQuestion.length is 0
        defaultQuestion = Coconut.questions.first()
      Coconut.router.navigate "#{Coconut.databaseName}/show/results/#{defaultQuestion.id}", trigger:true


    @defaultRouteRefreshTimestamp = Date.now()
    @defaultRouteRefreshCount ?= 0
    @defaultRouteRefreshCount += 1
    Coconut.router.navigate "#{Backbone.history.getFragment()}", trigger:true


  setup: (httpType, cloudUrl, applicationName, cloudUsername, cloudPassword) ->
    setupView = new SetupView()
    setupView.render()
    if httpType and cloudUrl and applicationName and cloudUsername and cloudPassword
      setupView.prefill httpType,
        cloudUrl: cloudUrl
        applicationName: applicationName
        cloudUsername: cloudUsername
        cloudPassword: cloudPassword

  selectApplication: =>
    Coconut.headerView = (new HeaderView()).render()
    selectDatabaseView = new SelectApplicationView()
    selectDatabaseView.render()

  presetInstall: (installName) =>
    (new PouchDB("https://installer:***REMOVED***@cococloud.co/install-configuration")).get "install-#{installName}"
    .catch (error) =>
      console.error error
      @setup()
    .then (configuration) =>
      setupView = new SetupView()
      setupView.render()
      setupView.prefill configuration.options[0],
        cloudUrl: configuration.options[1]
        applicationName: configuration.options[2]
        cloudUsername: configuration.options[3]
        cloudPassword: configuration.options[4]
      setupView.install()

  userLoggedIn: ->
    User.isAuthenticated()
    .catch (error) =>
      console.info error
      Coconut.loginView = new LoginView()
      Coconut.loginView.callback = options.success
      Coconut.loginView.render()

  help: (helpDocument) ->
    Coconut.helpView ?= new HelpView()
    if helpDocument?
      Coconut.helpView.helpDocument = helpDocument
    else
      Coconut.helpView.helpDocument = null
    # Coconut.helpView.render()
    @appView.showView(Coconut.helpView)


  login: ->
    Coconut.loginView = new LoginView()
    Coconut.loginView.callback =
      success: ->
        Coconut.router.navigate("",true)
#        Coconut.router.navigate("##{Coconut.databaseName}/summary",true)

  logout: ->
    User.logout()
    document.location.reload()
    Coconut.router.navigate("",true)


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

            # Save last_sync as a local doc
            time = moment().format("HH:mm, Do MMM YYYY")
            Coconut.database.get('_local/last_sync')
            .then (doc) ->
              doc.time = time
              Coconut.database.put doc
              .then ->
                Coconut.router.default()
                document.location.reload() # Without this, plugin changes aren't applied
            .catch (error) =>
              if error.name is "not_found"
                Coconut.database.put
                  _id: "_local/last_sync"
                  time: moment().format("HH:mm, Do MMM YYYY")
                .then ->
                  document.location.reload()
                  Coconut.router.default()
              else
                console.error error

          error: ->
            $("#log").show()
            Coconut.debug "Refreshing app in 5 seconds, please wait"
            $("#status").html "Error occurred, app refreshing in 5 seconds!"
            _.delay ->
              Backbone.history.loadUrl()
            , 5000
      error: (error) ->
        $("#log").show()
        Coconut.debug "Error sending data to cloud, proceeding to get updates from cloud."
        console.error error
        if error isnt 'No Internet connection'
          Coconut.syncView.sync.getFromCloud
            success: -> document.location.reload()
            error: -> document.location.reload()

  newResult: (question_id) ->
    Coconut.questionView.readonly = false
    Coconut.questionView.result = new Result
      question: unescape(question_id)
      # result ids now don't use UUIDs to reduce indexing, format is:
      # result-questionName-millisecondtimestamp-instanceId
      _id: "result-#{underscored(question_id)}-#{radix64.encodeInt(moment().format('x'))}-#{Coconut.instanceId}"
    Coconut.questionView.model = new Question {id: unescape(question_id)}
    vw = @appView
    Coconut.questionView.model.fetch
      success: ->
        # Coconut.questionView.render()
        vw.showView(Coconut.questionView)


  showResult: (result_id) ->
    Coconut.questionView.readonly = true
    vw = @appView
    Coconut.questionView.result = new Result
      _id: result_id
    Coconut.questionView.result.fetch()
    .catch (error) => alert "Could not find result: #{result_id}"
    .then =>
      Coconut.questionView.model = Coconut.questionView.result.question()
      # Coconut.questionView.render()
      vw.showView(Coconut.questionView)

  editResult: (result_id) ->
    Coconut.questionView.readonly = false
    vw = @appView
    Coconut.questionView.result = new Result
      _id: result_id
    Coconut.questionView.result.fetch()
    .catch (error) => alert "Could not find result: #{result_id}"
    .then =>
      question = Coconut.questionView.result.question()
      if question?
        Coconut.questionView.model = Coconut.questionView.result.question()
        vw.showView(Coconut.questionView)
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
    vw = @appView
    Coconut.questionView.result = new Result
      _id: result_id
    Coconut.questionView.result.fetch()
    .catch (error) => alert "Could not find result: #{result_id}"
    .then =>
      question = Coconut.questionView.result.question()
      if question?
        if confirmed is "confirmed"
          Coconut.questionView.result.destroy
            success: ->
              Coconut.router.navigate("#{Coconut.databaseName}/show/results/#{escape(Coconut.questionView.result.questionName())}",true)
        else
          Coconut.questionView.model = new Question
            id: question
          Coconut.questionView.model.fetch()
            success: ->
              # Coconut.questionView.render()
              vw.showView(Coconut.questionView)
              $('#askConfirm').html "
                <h4>Are you sure you want to delete this record?</h4>
                <div id='confirm'>
                  <a href='##{Coconut.databaseName}/delete/result/#{result_id}/confirmed'><button class='mdl-button mdl-button--accent mdl-js-button mdl-js-ripple-effect'>Yes</button></a>
                  <a href='##{Coconut.databaseName}/show/results/#{escape(Coconut.questionView.result.questionName())}'><button class='mdl-button mdl-js-button mdl-js-ripple-effect'>Cancel</button></a>
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
    Coconut.resultsView.question = Coconut.questions.get question_id
    vw = @appView
    # Coconut.resultsView.render()
    vw.showView(Coconut.resultsView)

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

  manage: ->
    Coconut.manageView ?= new ManageView( el: $("#content") )
    # Coconut.manageView.render()
    @appView.showView(Coconut.manageView)

  dumpDatabase: (options) =>
    dumpedString = ''
    stream = new MemoryStream()
    stream.on 'data', (chunk) ->
      dumpedString += chunk.toString()

    Coconut.database.dump stream,
      filter: (doc) -> doc.collection is "result"
    .then ->
      console.log dumpedString
      options.success(dumpedString)

  sendBackup: =>
    # TODO figure out how to make the destination server use https
    destination = "#{Coconut.config.cloud_url_hostname()}:3000/backup"
    @dumpDatabase
      error: (error) -> console.error error
      success: (dumpedString) ->
        $.ajax
          url: destination
          type: 'post'
          data:
            destination: Coconut.config.cloud_url_with_credentials()
            value: dumpedString
          success: (result) ->
            $("#content").html "Database backup sent to: #{destination} where it was loaded into #{Coconut.config.cloud_url()}<br/>Result from server: #{result}"
          error: (error) ->
            console.error error
            $("#content").html "Error backing up database: #{JSON.stringify error}"

  saveBackup: =>
    @dumpDatabase
      error: (error) -> console.error error
      success: (dumpedString) ->
        $("#content").html "Database backup created, beginning download. File will be available in Downloads folder on tablet."
        zip = new JSZip()
        zip.file "backup.pouchdb", dumpedString
        zip.generateAsync
          type:"blob"
          compression:"DEFLATE"
        .then (content) ->
          FileSaver.saveAs(content, "coconut.pouchdb.zip")

  getCloudResults: =>
    Coconut.cloudDB.query "resultsByUserAndDate",
      startkey: [Coconut.currentUser.username(), moment().subtract(1,"month").format(Coconut.config.get "date_format")]
      endkey: [Coconut.currentUser.username(), moment().endOf("day").format(Coconut.config.get "date_format")]
    .catch (error) => console.error "ERROR, could not download list of results for user: #{Coconut.currentUser.username()}: #{JSON.stringify error}"
    .then (result) =>
      lastMonthIds = _.pluck result.rows, "id"

      downloadResults = (docIds) ->
        Coconut.debug "Downloading #{docIds.length} results"
        Coconut.database.replicate.from Coconut.cloudDB,
          doc_ids: docIds
        .on 'complete', (info) =>
          $("#log").html ""
          $("#content").html "
            <h2>
              Complete.
            </h2>
            It may take a few minutes before all results are shown, but you can capture new data while these results are loading.<br/>
          "
        .on 'error', (error) =>
          console.log JSON.stringify error
        .on 'change', (info) =>
          $("#content").html "
            <h2>
              #{info.docs_written} written out of #{docIds.length} (#{parseInt(100*(info.docs_written/docIds.length))}%)
            </h2>
          "

      if confirm "Do you want to get #{lastMonthIds.length} results from last month saved by #{Coconut.currentUser.username()}"
        downloadResults(lastMonthIds)

  settings: ->
    Coconut.settingsView ?= new SettingsView()
    # Coconut.settingsView.render()
    @appView.showView(Coconut.settingsView)

  startApp: (options) ->
    # This makes sure all views are created and loads any classes that are necessary
    for ClassToLoad in [QuestionCollection, UserCollection, ResultCollection]
      console.log ClassToLoad.name
      await ClassToLoad.load()
      .catch (error) =>
        console.error "Could not load #{ClassToLoad}:"
        console.error error
        alert "Could not load #{ClassToLoad}: #{JSON.stringify error}. Recommendation: Press get data again."
    console.log "Done setting up classes"
    Coconut.questionView = new QuestionView()
    Coconut.menuView = new MenuView()
    Coconut.headerView = new HeaderView()
    Coconut.syncView = new SyncView()
    Coconut.syncView.sync.setMinMinsBetweenSync()
    Coconut.syncView.update()
    Promise.resolve()

module.exports = Router
